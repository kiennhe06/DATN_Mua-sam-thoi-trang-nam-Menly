import { Router, RequestHandler } from 'express';
import { OrderViewModel } from '../../viewmodels/order.viewmodel.js';
import { OrderController } from '../controllers/order.controller.js';

export const orderRoutes = (
  requireAuth: RequestHandler,
  rateLimits: {
    order: RequestHandler;
    track: RequestHandler;
  },
  vmOrController: OrderViewModel | OrderController,
  requireCustomer?: RequestHandler
): Router => {
  const router = Router();
  const controller =
    vmOrController instanceof OrderController
      ? vmOrController
      : new OrderController(vmOrController);

  const mustBeCustomer: RequestHandler[] = requireCustomer ? [requireCustomer] : [];

  // Public order tracking (guest lookup by code and phone)
  router.get('/track', rateLimits.track, controller.trackOrder);

  // Authenticated routes
  router.post('/', requireAuth, ...mustBeCustomer, rateLimits.order, controller.createOrder);
  router.get('/', requireAuth, controller.listMyOrders);
  router.put('/:id/cancel', requireAuth, controller.cancelOrder);
  router.get('/:id', requireAuth, controller.getOrder);

  return router;
};
