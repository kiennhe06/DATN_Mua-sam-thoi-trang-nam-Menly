import { Router, RequestHandler } from 'express';
import { PaymentViewModel } from '../../viewmodels/payment.viewmodel.js';
import { PaymentController } from '../controllers/payment.controller.js';

export const paymentRoutes = (
  requireAuth: RequestHandler,
  vmOrController: PaymentViewModel | PaymentController
): Router => {
  const router = Router();
  const controller =
    vmOrController instanceof PaymentController
      ? vmOrController
      : new PaymentController(vmOrController);

  router.post('/vnpay/create', requireAuth, controller.createVNPayPayment);
  router.post('/vnpay/demo-settle', requireAuth, controller.demoSettle);
  router.get('/vnpay/ipn', controller.handleIpn);
  router.get('/vnpay/return', controller.handleReturn);

  return router;
};
