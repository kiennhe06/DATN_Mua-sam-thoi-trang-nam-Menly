import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { PaymentViewModel } from '../../viewmodels/payment.viewmodel.js';
import { createPaymentSchema } from '../../presentation/http/schemas/payment.schema.js';
import { clientIp } from '../../infrastructure/vnpay/vnpay.sign.js';

export class PaymentController {
  constructor(private readonly vm: PaymentViewModel) {}

  createVNPayPayment = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const body = createPaymentSchema.parse(req.body);
      const ip = clientIp(req.ip);
      const headerUserId = (req.headers['x-user-id'] as string) || undefined;
      const headerEmail = (req.headers['x-user-email'] as string) || undefined;
      const result = await this.vm.createPaymentUrl({
        orderId: body.orderId,
        userId: headerUserId || req.user!.id,
        userEmail: req.user?.email || headerEmail,
        headerUserId,
        clientIp: ip,
        bankCode: body.bankCode ?? undefined,
      });
      res.json(result);
    } catch (err) {
      next(err);
    }
  };

  demoSettle = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const demoSchema = z.object({
        orderId: z.string().min(1),
        success: z.boolean().default(true),
        bankCode: z.string().nullish(),
      });
      const body = demoSchema.parse(req.body);
      const headerUserId = (req.headers['x-user-id'] as string) || undefined;
      const headerEmail = (req.headers['x-user-email'] as string) || undefined;
      const result = await this.vm.settleDemoPayment({
        orderId: body.orderId,
        userId: headerUserId || req.user!.id,
        userEmail: req.user?.email || headerEmail,
        headerUserId,
        success: body.success,
        bankCode: body.bankCode ?? undefined,
      });
      res.json(result);
    } catch (err) {
      next(err);
    }
  };

  handleIpn = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const query = req.query as Record<string, string>;
      const result = await this.vm.handleIpn(query);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  };

  handleReturn = async (req: Request, res: Response): Promise<void> => {
    const isSuccess = req.query.vnp_ResponseCode === '00';
    const txnRef = (req.query.vnp_TxnRef as string) || '';
    const amount = Number(req.query.vnp_Amount || 0) / 100;

    if (txnRef && isSuccess) {
      try {
        await this.vm.settleByTxnRef({
          txnRef,
          success: true,
          txnNo: (req.query.vnp_TransactionNo as string) || undefined,
          bankCode: (req.query.vnp_BankCode as string) || undefined,
          responseCode: req.query.vnp_ResponseCode as string,
          raw: req.query,
        });
      } catch (e) {
        console.warn('handleReturn auto settle warning:', e);
      }
    }

    res.send(`
      <!DOCTYPE html>
      <html lang="vi">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Kết quả thanh toán MenShop</title>
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; background: #f8fafc; }
          .card { background: white; padding: 32px; border-radius: 16px; box-shadow: 0 10px 25px rgba(0,0,0,0.08); text-align: center; max-width: 420px; width: 90%; }
          .icon { font-size: 48px; margin-bottom: 12px; }
          .status { font-size: 22px; font-weight: bold; color: ${isSuccess ? '#16a34a' : '#dc2626'}; margin-bottom: 12px; }
          .info { color: #475569; margin: 8px 0; font-size: 14px; }
        </style>
      </head>
      <body>
        <div class="card">
          <div class="icon">${isSuccess ? '🎉' : '⚠️'}</div>
          <div class="status">${isSuccess ? 'Thanh toán VNPay thành công!' : 'Thanh toán thất bại'}</div>
          <p class="info">Mã giao dịch: <strong>${txnRef}</strong></p>
          <p class="info">Số tiền: <strong>${amount.toLocaleString('vi-VN')} VND</strong></p>
          <p class="info">${isSuccess ? 'Đơn hàng của bạn đã được xác nhận thanh toán.' : 'Giao dịch chưa hoàn tất.'}</p>
          <p class="info" style="font-size: 12px; color: #94a3b8; margin-top: 16px;">Bạn có thể đóng trang này để quay lại ứng dụng.</p>
        </div>
      </body>
      </html>
    `);
  };
}
