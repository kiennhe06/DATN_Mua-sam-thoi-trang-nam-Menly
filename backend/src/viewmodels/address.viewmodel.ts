import {
  IAddressModel,
  AddressInput,
  UserAddress,
} from '../models/address.model.js';
import { AppError } from '../models/types.js';

export class AddressViewModel {
  constructor(private readonly model: IAddressModel) {}

  list(userId: string): Promise<UserAddress[]> {
    return this.model.list(userId);
  }

  create(userId: string, input: AddressInput): Promise<UserAddress> {
    if (!input.recipientName?.trim()) {
      throw new AppError('VALIDATION_ERROR', 400, 'Vui lòng nhập họ tên người nhận');
    }
    if (!input.phone?.trim() || input.phone.trim().length < 9) {
      throw new AppError('VALIDATION_ERROR', 400, 'Số điện thoại không hợp lệ');
    }
    if (!input.detailAddress?.trim() || input.detailAddress.trim().length < 5) {
      throw new AppError('VALIDATION_ERROR', 400, 'Địa chỉ chi tiết tối thiểu 5 ký tự');
    }
    return this.model.create(userId, {
      ...input,
      recipientName: input.recipientName.trim(),
      phone: input.phone.trim(),
      detailAddress: input.detailAddress.trim(),
    });
  }

  update(
    userId: string,
    id: string,
    input: Partial<AddressInput>
  ): Promise<UserAddress> {
    return this.model.update(userId, id, input);
  }

  remove(userId: string, id: string): Promise<void> {
    return this.model.remove(userId, id);
  }

  setDefault(userId: string, id: string): Promise<UserAddress> {
    return this.model.setDefault(userId, id);
  }
}
