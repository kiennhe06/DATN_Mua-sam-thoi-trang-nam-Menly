import { Request, Response, NextFunction } from 'express';
import { AdminViewModel } from '../../viewmodels/admin.viewmodel.js';
import { ProductViewModel } from '../../viewmodels/product.viewmodel.js';
import { ReviewViewModel } from '../../viewmodels/review.viewmodel.js';
import {
  adjustStockSchema,
  updateOrderStatusSchema,
  setUserRoleSchema,
  adminOrdersQuerySchema,
} from '../../presentation/http/schemas/admin.schema.js';
import {
  listProductsSchema,
  productIdParamSchema,
} from '../../presentation/http/schemas/product.schema.js';

export class AdminController {
  constructor(
    private readonly adminVm: AdminViewModel,
    private readonly productVm: ProductViewModel,
    private readonly reviewVm?: ReviewViewModel
  ) {}

  listProducts = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const query = listProductsSchema.parse(req.query);
      const page = await this.productVm.listProducts({ ...query, includeInactive: true });
      res.json(page);
    } catch (err) {
      next(err);
    }
  };

  createProduct = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const created = await this.productVm.createProduct(req.body);
      res.status(201).json(created);
    } catch (err) {
      next(err);
    }
  };

  updateProduct = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const { id } = productIdParamSchema.parse(req.params);
      const updated = await this.productVm.updateProduct(id, req.body);
      res.json(updated);
    } catch (err) {
      next(err);
    }
  };

  deleteProduct = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const { id } = productIdParamSchema.parse(req.params);
      await this.productVm.deleteProduct(id);
      res.json({ message: 'Xóa sản phẩm thành công', id });
    } catch (err) {
      next(err);
    }
  };

  adjustStock = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const body = adjustStockSchema.parse(req.body);
      const result = await this.adminVm.adjustStock(
        body.variantId,
        body.delta,
        body.reason,
        body.note,
        req.user!.id
      );
      res.json(result);
    } catch (err) {
      next(err);
    }
  };

  listMovements = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const variantId = req.query.variantId as string | undefined;
      const limit = Number(req.query.limit) || 50;
      const list = await this.adminVm.listMovements(variantId, limit);
      res.json(list);
    } catch (err) {
      next(err);
    }
  };

  listOrders = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const query = adminOrdersQuerySchema.parse(req.query);
      const orders = await this.adminVm.listOrders(
        query.limit,
        query.status,
        query.cursor,
        query.fromDate,
        query.toDate,
        query.day
      );
      res.json(orders);
    } catch (err) {
      next(err);
    }
  };

  updateOrderStatus = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const body = updateOrderStatusSchema.parse(req.body);
      await this.adminVm.updateOrderStatus(req.params.id, body.status, body.note, req.user!.id);
      res.json({ message: 'Cập nhật trạng thái thành công' });
    } catch (err) {
      next(err);
    }
  };

  listAudit = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const limit = Number(req.query.limit) || 50;
      const logs = await this.adminVm.listAudit(limit);
      res.json(logs);
    } catch (err) {
      next(err);
    }
  };

  setUserRole = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const body = setUserRoleSchema.parse(req.body);
      await this.adminVm.setUserRole(req.params.id, body.role);
      res.json({ message: 'Gán vai trò thành công' });
    } catch (err) {
      next(err);
    }
  };

  listReviews = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    if (!this.reviewVm) {
      res.status(501).json({ message: 'Review service not configured' });
      return;
    }
    try {
      const limit = Number(req.query.limit) || 20;
      const page = Number(req.query.page) || 1;
      const result = await this.reviewVm.getAdminReviews(limit, page);
      res.json(result);
    } catch (err) {
      next(err);
    }
  };

  deleteReview = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    if (!this.reviewVm) {
      res.status(501).json({ message: 'Review service not configured' });
      return;
    }
    try {
      await this.reviewVm.adminDeleteReview(req.params.id, req.user!.id);
      res.json({ message: 'Đã xóa đánh giá vi phạm' });
    } catch (err) {
      next(err);
    }
  };
}
