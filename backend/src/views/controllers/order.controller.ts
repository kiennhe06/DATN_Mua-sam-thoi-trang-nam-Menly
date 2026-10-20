import { Request, Response, NextFunction } from 'express';
import { OrderViewModel } from '../../viewmodels/order.viewmodel.js';
import {
  createOrderSchema,
  trackOrderSchema,
  listOrdersQuerySchema,
} from '../../presentation/http/schemas/order.schema.js';

export class OrderController {
  constructor(private readonly vm: OrderViewModel) {}

  trackOrder = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const { code, phone } = trackOrderSchema.parse(req.query);
      const result = await this.vm.trackOrder(code, phone);
      res.json(result);
    } catch (err) {
      next(err);
    }
  };

  createOrder = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const body = createOrderSchema.parse(req.body);
      const idempotencyKey = req.headers['idempotency-key'] as string | undefined;
      const headerUserId = (req.headers['x-user-id'] as string) || undefined;
      const headerEmail = (req.headers['x-user-email'] as string) || undefined;

      const order = await this.vm.createOrder({
        userId: headerUserId || req.user!.id,
        userEmail: req.user?.email || headerEmail,
        ship: body.ship,
        paymentMethod: body.paymentMethod,
        items: body.items,
        idempotencyKey,
        note: body.note,
        voucherCode: body.voucherCode,
        discountAmount: body.discountAmount,
      });

      res.status(201).json(order);
    } catch (err) {
      next(err);
    }
  };

  listMyOrders = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const query = listOrdersQuerySchema.parse(req.query);
      const headerUserId = (req.headers['x-user-id'] as string) || undefined;
      const headerEmail = (req.headers['x-user-email'] as string) || undefined;
      const orders = await this.vm.listMyOrders(
        req.user!.id,
        query.limit,
        query.cursor,
        req.user?.email || headerEmail,
        headerUserId
      );
      res.json(orders);
    } catch (err) {
      next(err);
    }
  };

  cancelOrder = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const headerUserId = (req.headers['x-user-id'] as string) || undefined;
      const headerEmail = (req.headers['x-user-email'] as string) || undefined;
      const { note } = req.body || {};
      const order = await this.vm.cancelOrder(
        req.params.id,
        req.user!.id,
        note,
        req.user?.email || headerEmail,
        headerUserId
      );
      res.json(order);
    } catch (err) {
      next(err);
    }
  };

  getOrder = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const order = await this.vm.getOrder(
        req.params.id,
        req.user!.id,
        req.user!.role === 'admin'
      );
      res.json(order);
    } catch (err) {
      next(err);
    }
  };
}
