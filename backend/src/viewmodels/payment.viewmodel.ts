import { AppError } from '../models/types.js';
import { IOrderModel } from '../models/order.model.js';
import { IPaymentModel } from '../models/payment.model.js';
import { PaymentGateway } from '../application/ports/payment-gateway.js';

export interface CreatePaymentInput {
  orderId: string;
  userId: string;
  clientIp: string;
  bankCode?: string;
}

export interface IpnResponse {
  RspCode: string;
  Message: string;
}

export class PaymentViewModel {
  constructor(
    private readonly orderModel: IOrderModel,
    private readonly paymentModel: IPaymentModel,
    private readonly gateway: PaymentGateway
  ) {}

  async createPaymentUrl(i: CreatePaymentInput): Promise<{ paymentUrl: string; txnRef: string }> {
    const order = await this.orderModel.findById(i.orderId);
    if (!order) throw new AppError('ORDER_NOT_FOUND', 404, 'Đơn hàng không tồn tại');
    if (order.userId !== i.userId) throw new AppError('FORBIDDEN', 403, 'Không có quyền truy cập');
    if (order.status !== 'pending_payment') {
      throw new AppError('ORDER_NOT_PAYABLE', 409, `Đơn hàng ở trạng thái ${order.status}, không thể thanh toán`);
    }

    const txnRef = `${order.code}_${Date.now()}`;
    const expireAt = new Date(Date.now() + 15 * 60 * 1000);

    await this.paymentModel.createPending({
      orderId: order.id,
      txnRef,
      amount: order.total,
    });

    const paymentUrl = this.gateway.buildPaymentUrl({
      txnRef,
      amountVnd: order.total,
      ip: i.clientIp,
      orderInfo: `Thanh toan don hang ${order.code}`,
      expireAt,
      bankCode: i.bankCode,
    });

    return { paymentUrl, txnRef };
  }

  async settleDemoPayment(i: {
    orderId: string;
    userId: string;
    success: boolean;
    bankCode?: string;
  }): Promise<{ success: boolean; message: string; order: any }> {
    const order = await this.orderModel.findById(i.orderId);
    if (!order) throw new AppError('ORDER_NOT_FOUND', 404, 'Đơn hàng không tồn tại');
    if (order.userId !== i.userId) throw new AppError('FORBIDDEN', 403, 'Không có quyền truy cập');

    const txnRef = `${order.code}_DEMO_${Date.now()}`;
    await this.paymentModel.createPending({
      orderId: order.id,
      txnRef,
      amount: order.total,
    });

    await this.paymentModel.settle({
      txnRef,
      success: i.success,
      txnNo: `VNP_DEMO_${Date.now()}`,
      bankCode: i.bankCode || 'NCB',
      responseCode: i.success ? '00' : '24',
      raw: { demo: true, timestamp: new Date().toISOString() },
    });

    if (i.success) {
      await this.orderModel.updateStatus(order.id, 'paid', 'Thanh toán VNPay Demo thành công');
    }

    const updated = await this.orderModel.findById(order.id);
    return {
      success: i.success,
      message: i.success
        ? 'Thanh toán VNPay Demo thành công'
        : 'Giao dịch VNPay Demo đã bị hủy',
      order: updated,
    };
  }

  async handleIpn(query: Record<string, string>): Promise<IpnResponse> {
    const isValid = this.gateway.verify(query);
    if (!isValid) return { RspCode: '97', Message: 'Invalid Checksum' };

    const txnRef = query.vnp_TxnRef;
    if (!txnRef) return { RspCode: '01', Message: 'Order not found' };

    const payment = await this.paymentModel.findByTxnRef(txnRef);
    if (!payment) return { RspCode: '01', Message: 'Order not found' };

    const vnpAmount = Number(query.vnp_Amount) / 100;
    if (vnpAmount !== payment.amount) return { RspCode: '04', Message: 'Invalid amount' };
    if (payment.status !== 'pending') return { RspCode: '02', Message: 'Order already confirmed' };

    const isSuccess = query.vnp_ResponseCode === '00';
    await this.paymentModel.settle({
      txnRef,
      success: isSuccess,
      txnNo: query.vnp_TransactionNo,
      bankCode: query.vnp_BankCode,
      responseCode: query.vnp_ResponseCode,
      raw: query,
    });

    return { RspCode: '00', Message: 'Confirm Success' };
  }
}
