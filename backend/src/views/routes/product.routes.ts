import { Router } from 'express';
import { ProductViewModel } from '../../viewmodels/product.viewmodel.js';
import { ProductController } from '../controllers/product.controller.js';

export const productRoutes = (
  vmOrController: ProductViewModel | ProductController
): Router => {
  const router = Router();
  const controller =
    vmOrController instanceof ProductController
      ? vmOrController
      : new ProductController(vmOrController);

  router.get('/', controller.listProducts);
  router.get('/:id', controller.getProductDetail);

  return router;
};
