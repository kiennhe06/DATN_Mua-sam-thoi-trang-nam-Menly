import { Request, Response, NextFunction } from 'express';
import { CartViewModel } from '../../viewmodels/cart.viewmodel.js';
import {
  upsertCartItemSchema,
  removeCartItemParamSchema,
} from '../../presentation/http/schemas/cart.schema.js';

export class CartController {
  constructor(private readonly vm: CartViewModel) {}

  getCart = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const cart = await this.vm.getCart(req.user!.id);
      res.json(cart);
    } catch (err) {
      next(err);
    }
  };

  updateItem = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const body = upsertCartItemSchema.parse(req.body);
      const cart = await this.vm.updateItem(req.user!.id, body.variantId, body.quantity);
      res.json(cart);
    } catch (err) {
      next(err);
    }
  };

  removeItem = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const { variantId } = removeCartItemParamSchema.parse(req.params);
      const cart = await this.vm.removeItem(req.user!.id, variantId);
      res.json(cart);
    } catch (err) {
      next(err);
    }
  };

  clearCart = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const cart = await this.vm.clearCart(req.user!.id);
      res.json(cart);
    } catch (err) {
      next(err);
    }
  };
}
