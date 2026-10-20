import { Router, RequestHandler } from 'express';
import { AdminViewModel } from '../../viewmodels/admin.viewmodel.js';
import { ProductViewModel } from '../../viewmodels/product.viewmodel.js';
import { ReviewViewModel } from '../../viewmodels/review.viewmodel.js';
import { AdminController } from '../controllers/admin.controller.js';

export const adminRoutes = (
  requireAuth: RequestHandler,
  requireAdmin: RequestHandler,
  adminVmOrController: AdminViewModel | AdminController,
  productVm?: ProductViewModel,
  requireStaffOrAdmin: RequestHandler = requireAdmin,
  reviewVm?: ReviewViewModel
): Router => {
  const router = Router();
  router.use(requireAuth);

  const controller =
    adminVmOrController instanceof AdminController
      ? adminVmOrController
      : new AdminController(adminVmOrController, productVm!, reviewVm);

  // Vận hành (Staff & Admin): Sản phẩm
  router.get('/products', requireStaffOrAdmin, controller.listProducts);
  router.post('/products', requireStaffOrAdmin, controller.createProduct);
  router.put('/products/:id', requireStaffOrAdmin, controller.updateProduct);

  // Vận hành (Staff & Admin): Tồn kho
  router.post('/inventory/adjust', requireStaffOrAdmin, controller.adjustStock);
  router.get('/inventory/movements', requireStaffOrAdmin, controller.listMovements);

  // Vận hành (Staff & Admin): Đơn hàng
  router.get('/orders', requireStaffOrAdmin, controller.listOrders);
  router.put('/orders/:id/status', requireStaffOrAdmin, controller.updateOrderStatus);

  // Quyền tối cao (Chỉ Admin): Audit & Phân quyền
  router.get('/audit-log', requireAdmin, controller.listAudit);
  router.put('/users/:id/role', requireAdmin, controller.setUserRole);

  // Quản lý Đánh giá (Vận hành & Admin)
  if (reviewVm) {
    router.get('/reviews', requireStaffOrAdmin, controller.listReviews);
    router.delete('/reviews/:id', requireAdmin, controller.deleteReview);
  }

  return router;
};
