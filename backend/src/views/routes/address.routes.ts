import { Router, RequestHandler } from 'express';
import { AddressViewModel } from '../../viewmodels/address.viewmodel.js';

export function addressRoutes(
  requireAuth: RequestHandler,
  viewModel: AddressViewModel
): Router {
  const router = Router();
  router.use(requireAuth);

  // GET /api/v1/addresses — Lấy danh sách địa chỉ nhận hàng
  router.get('/', async (req, res, next) => {
    try {
      const headerUserId = (req.headers['x-user-id'] as string) || undefined;
      const effectiveUserId = headerUserId || req.user!.id;
      const addresses = await viewModel.listAddresses(effectiveUserId);
      res.json({ data: addresses });
    } catch (err) {
      next(err);
    }
  });

  // POST /api/v1/addresses — Thêm địa chỉ mới
  router.post('/', async (req, res, next) => {
    try {
      const headerUserId = (req.headers['x-user-id'] as string) || undefined;
      const effectiveUserId = headerUserId || req.user!.id;
      const newAddress = await viewModel.createAddress(effectiveUserId, req.body);
      res.status(201).json({ message: 'Thêm địa chỉ thành công', data: newAddress });
    } catch (err) {
      next(err);
    }
  });

  // PUT /api/v1/addresses/:id — Sửa địa chỉ
  router.put('/:id', async (req, res, next) => {
    try {
      const headerUserId = (req.headers['x-user-id'] as string) || undefined;
      const effectiveUserId = headerUserId || req.user!.id;
      const updated = await viewModel.updateAddress(req.params.id, effectiveUserId, req.body);
      res.json({ message: 'Cập nhật địa chỉ thành công', data: updated });
    } catch (err) {
      next(err);
    }
  });

  // DELETE /api/v1/addresses/:id — Xóa địa chỉ
  router.delete('/:id', async (req, res, next) => {
    try {
      const headerUserId = (req.headers['x-user-id'] as string) || undefined;
      const effectiveUserId = headerUserId || req.user!.id;
      await viewModel.deleteAddress(req.params.id, effectiveUserId);
      res.json({ message: 'Đã xóa địa chỉ thành công' });
    } catch (err) {
      next(err);
    }
  });

  // PATCH /api/v1/addresses/:id/default — Đặt làm địa chỉ mặc định
  router.patch('/:id/default', async (req, res, next) => {
    try {
      const headerUserId = (req.headers['x-user-id'] as string) || undefined;
      const effectiveUserId = headerUserId || req.user!.id;
      const updated = await viewModel.setDefaultAddress(req.params.id, effectiveUserId);
      res.json({ message: 'Đã đặt làm địa chỉ mặc định', data: updated });
    } catch (err) {
      next(err);
    }
  });

  return router;
}
