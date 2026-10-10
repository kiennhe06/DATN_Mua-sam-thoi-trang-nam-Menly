import { z } from 'zod';

export const addressBodySchema = z.object({
  recipientName: z.string().trim().min(1, 'Vui lòng nhập họ tên người nhận').max(100).optional(),
  name: z.string().trim().min(1).max(100).optional(),
  phone: z.string().trim().min(9, 'Số điện thoại tối thiểu 9 số').max(20),
  province: z.string().trim().max(100).optional(),
  district: z.string().trim().max(100).optional(),
  ward: z.string().trim().max(100).optional(),
  detailAddress: z.string().trim().min(5, 'Địa chỉ chi tiết tối thiểu 5 ký tự').max(255).optional(),
  address: z.string().trim().min(5, 'Địa chỉ tối thiểu 5 ký tự').max(255).optional(),
  isDefault: z.boolean().optional(),
});

export const updateAddressBodySchema = addressBodySchema.partial();

export const addressIdParamSchema = z.object({
  id: z.string().min(1),
});
