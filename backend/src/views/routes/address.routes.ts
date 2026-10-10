import { Router, RequestHandler } from 'express';
import { z } from 'zod';
import { AddressViewModel } from '../../viewmodels/address.viewmodel.js';
import { AddressInput } from '../../models/address.model.js';
import {
  addressBodySchema,
  updateAddressBodySchema,
  addressIdParamSchema,
} from '../../presentation/http/schemas/address.schema.js';

type RawBody = z.infer<typeof addressBodySchema>;
type RawUpdateBody = z.infer<typeof updateAddressBodySchema>;

const normalize = (body: RawBody | RawUpdateBody): Partial<AddressInput> => {
  const out: Partial<AddressInput> = {};
  const name = body.recipientName ?? body.name;
  if (name !== undefined) out.recipientName = name;
  if (body.phone !== undefined) out.phone = body.phone;
  if (body.province !== undefined) out.province = body.province;
  if (body.district !== undefined) out.district = body.district;
  if (body.ward !== undefined) out.ward = body.ward;
  const detail = body.detailAddress ?? body.address;
  if (detail !== undefined) out.detailAddress = detail;
  if (body.isDefault !== undefined) out.isDefault = body.isDefault;
  return out;
};

export const addressRoutes = (
  requireAuth: RequestHandler,
  requireCustomer: RequestHandler,
  vm: AddressViewModel
): Router => {
  const router = Router();
  // Chỉ người dùng đã đăng nhập (không phải khách ẩn danh) mới quản lý địa chỉ
  router.use(requireAuth, requireCustomer);

  // 1. Danh sách địa chỉ giao hàng của người dùng
  router.get('/', async (req, res, next) => {
    try {
      const data = await vm.list(req.user!.id);
      res.json({ data });
    } catch (err) {
      next(err);
    }
  });

  // 2. Thêm địa chỉ mới
  router.post('/', async (req, res, next) => {
    try {
      const body = addressBodySchema.parse(req.body);
      const input = normalize(body) as AddressInput;
      const data = await vm.create(req.user!.id, input);
      res.status(201).json({ message: 'Thêm địa chỉ thành công', data });
    } catch (err) {
      next(err);
    }
  });

  // 3. Đặt địa chỉ làm mặc định
  const setDefaultHandler: RequestHandler = async (req, res, next) => {
    try {
      const { id } = addressIdParamSchema.parse(req.params);
      const data = await vm.setDefault(req.user!.id, id);
      res.json({ message: 'Đã đặt làm địa chỉ mặc định', data });
    } catch (err) {
      next(err);
    }
  };
  router.put('/:id/default', setDefaultHandler);
  router.post('/:id/default', setDefaultHandler);

  // 4. Cập nhật địa chỉ
  const updateHandler: RequestHandler = async (req, res, next) => {
    try {
      const { id } = addressIdParamSchema.parse(req.params);
      const body = updateAddressBodySchema.parse(req.body);
      const input = normalize(body);
      const data = await vm.update(req.user!.id, id, input);
      res.json({ message: 'Cập nhật địa chỉ thành công', data });
    } catch (err) {
      next(err);
    }
  };
  router.put('/:id', updateHandler);
  router.patch('/:id', updateHandler);

  // 5. Xoá địa chỉ
  router.delete('/:id', async (req, res, next) => {
    try {
      const { id } = addressIdParamSchema.parse(req.params);
      await vm.remove(req.user!.id, id);
      res.json({ message: 'Đã xoá địa chỉ', data: { id } });
    } catch (err) {
      next(err);
    }
  });

  return router;
};
