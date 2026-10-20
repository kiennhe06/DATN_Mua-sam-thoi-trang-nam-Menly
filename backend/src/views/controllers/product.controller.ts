import { Request, Response, NextFunction } from 'express';
import { ProductViewModel } from '../../viewmodels/product.viewmodel.js';
import {
  listProductsSchema,
  productIdParamSchema,
} from '../../presentation/http/schemas/product.schema.js';

export class ProductController {
  constructor(private readonly vm: ProductViewModel) {}

  listProducts = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      res.set('Cache-Control', 'public, max-age=30');
      const query = listProductsSchema.parse(req.query);
      const page = await this.vm.listProducts(query);
      res.json(page);
    } catch (err) {
      next(err);
    }
  };

  getProductDetail = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const { id } = productIdParamSchema.parse(req.params);
      const product = await this.vm.getProductDetail(id);
      res.json(product);
    } catch (err) {
      next(err);
    }
  };
}
