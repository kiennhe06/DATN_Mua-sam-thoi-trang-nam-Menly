import { IAddressModel } from '../models/address.model.js';
import { UserAddress, AppError } from '../models/types.js';

export interface CreateAddressInput {
  recipientName: string;
  phone: string;
  province?: string;
  district?: string;
  ward?: string;
  detailAddress: string;
  isDefault?: boolean;
}

export interface UpdateAddressInput {
  recipientName?: string;
  phone?: string;
  province?: string;
  district?: string;
  ward?: string;
  detailAddress?: string;
  isDefault?: boolean;
}

export class AddressViewModel {
  constructor(private readonly model: IAddressModel) {}

  async listAddresses(userId: string): Promise<UserAddress[]> {
    if (!userId) {
      throw new AppError('UNAUTHORIZED', 401, 'Vui lòng đăng nhập để xem địa chỉ');
    }
    return this.model.list(userId);
  }

  async createAddress(userId: string, input: CreateAddressInput): Promise<UserAddress> {
    if (!userId) {
      throw new AppError('UNAUTHORIZED', 401, 'Vui lòng đăng nhập');
    }
    if (!input.recipientName || !input.recipientName.trim()) {
      throw new AppError('VALIDATION_ERROR', 400, 'Họ tên người nhận không được để trống');
    }
    if (!input.phone || !input.phone.trim()) {
      throw new AppError('VALIDATION_ERROR', 400, 'Số điện thoại không được để trống');
    }
    if (!input.detailAddress || !input.detailAddress.trim()) {
      throw new AppError('VALIDATION_ERROR', 400, 'Địa chỉ chi tiết không được để trống');
    }

    return this.model.create(userId, {
      recipientName: input.recipientName.trim(),
      phone: input.phone.trim(),
      province: input.province?.trim() || 'Hà Nội',
      district: input.district?.trim() || '',
      ward: input.ward?.trim() || '',
      detailAddress: input.detailAddress.trim(),
      isDefault: input.isDefault,
    });
  }

  async updateAddress(id: string, userId: string, input: UpdateAddressInput): Promise<UserAddress> {
    if (!userId) {
      throw new AppError('UNAUTHORIZED', 401, 'Vui lòng đăng nhập');
    }
    if (!id) {
      throw new AppError('VALIDATION_ERROR', 400, 'Thiếu mã địa chỉ');
    }

    return this.model.update(id, userId, {
      recipientName: input.recipientName?.trim(),
      phone: input.phone?.trim(),
      province: input.province?.trim(),
      district: input.district?.trim(),
      ward: input.ward?.trim(),
      detailAddress: input.detailAddress?.trim(),
      isDefault: input.isDefault,
    });
  }

  async deleteAddress(id: string, userId: string): Promise<void> {
    if (!userId) {
      throw new AppError('UNAUTHORIZED', 401, 'Vui lòng đăng nhập');
    }
    if (!id) {
      throw new AppError('VALIDATION_ERROR', 400, 'Thiếu mã địa chỉ');
    }
    await this.model.delete(id, userId);
  }

  async setDefaultAddress(id: string, userId: string): Promise<UserAddress> {
    if (!userId) {
      throw new AppError('UNAUTHORIZED', 401, 'Vui lòng đăng nhập');
    }
    if (!id) {
      throw new AppError('VALIDATION_ERROR', 400, 'Thiếu mã địa chỉ');
    }
    return this.model.setDefault(id, userId);
  }
}
