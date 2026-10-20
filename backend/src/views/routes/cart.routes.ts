import { Router, RequestHandler } from 'express';
import { CartViewModel } from '../../viewmodels/cart.viewmodel.js';
import { CartController } from '../controllers/cart.controller.js';

export const cartRoutes = (
  requireAuth: RequestHandler,
  vmOrController: CartViewModel | CartController
): Router => {
  const router = Router();
  const controller =
    vmOrController instanceof CartController
      ? vmOrController
      : new CartController(vmOrController);

  router.use(requireAuth);

  router.get('/', controller.getCart);
  router.put('/items', controller.updateItem);
  router.delete('/items/:variantId', controller.removeItem);
  router.delete('/', controller.clearCart);

  return router;
};
