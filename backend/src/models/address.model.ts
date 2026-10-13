import { SupabaseClient } from '@supabase/supabase-js';
import { UserAddress, AppError } from './types.js';

export interface IAddressModel {
  list(userId: string): Promise<UserAddress[]>;
  create(userId: string, data: {
    recipientName: string;
    phone: string;
    province?: string;
    district?: string;
    ward?: string;
    detailAddress: string;
    isDefault?: boolean;
  }): Promise<UserAddress>;
  update(id: string, userId: string, data: Partial<{
    recipientName: string;
    phone: string;
    province?: string;
    district?: string;
    ward?: string;
    detailAddress: string;
    isDefault?: boolean;
  }>): Promise<UserAddress>;
  delete(id: string, userId: string): Promise<void>;
  setDefault(id: string, userId: string): Promise<UserAddress>;
}

export class AddressModel implements IAddressModel {
  private inMemoryAddresses: UserAddress[] = [
    {
      id: 'addr-mock-1',
      userId: '00000000-0000-0000-0000-000000000002',
      recipientName: 'Khách hàng Menly',
      phone: '0901234567',
      province: 'Hà Nội',
      district: 'Hoàn Kiếm',
      ward: 'Hàng Bông',
      detailAddress: 'Số 12 phố Hàng Bông, Phường Hàng Bông, Quận Hoàn Kiếm, Hà Nội',
      isDefault: true,
      createdAt: new Date().toISOString(),
    },
    {
      id: 'addr-mock-2',
      userId: '00000000-0000-0000-0000-000000000002',
      recipientName: 'Văn phòng Công ty',
      phone: '0909876543',
      province: 'Hà Nội',
      district: 'Cầu Giấy',
      ward: 'Dịch Vọng Hậu',
      detailAddress: 'Tòa nhà FPT, Phố Duy Tân, Phường Dịch Vọng Hậu, Quận Cầu Giấy, Hà Nội',
      isDefault: false,
      createdAt: new Date().toISOString(),
    },
  ];

  constructor(private readonly supabase?: SupabaseClient) {}

  private resolveLookupId(userId: string): string {
    if (userId === '00000000-0000-0000-0000-000000000001' || userId === 'usr-admin-001') {
      return '0f444d92-322c-4956-b452-0c5c10950508';
    } else if (userId === '00000000-0000-0000-0000-000000000004' || userId === 'usr-staff-001') {
      return 'd604e122-aa50-47e0-ac44-10a2473af6ce';
    } else if (userId === '00000000-0000-0000-0000-000000000002') {
      return '7fb74d58-4155-4ab5-8124-cb0b5bb6651d';
    }
    return userId;
  }

  async list(userId: string): Promise<UserAddress[]> {
    const lookupId = this.resolveLookupId(userId);
    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(lookupId);

    if (this.supabase && isUuid) {
      try {
        const { data, error } = await this.supabase
          .from('user_addresses')
          .select('*')
          .eq('user_id', lookupId)
          .order('is_default', { ascending: false })
          .order('created_at', { ascending: false });

        if (!error && data && data.length > 0) {
          return data.map((row) => ({
            id: row.id,
            userId: row.user_id,
            recipientName: row.recipient_name,
            phone: row.phone,
            province: row.province || '',
            district: row.district || '',
            ward: row.ward || '',
            detailAddress: row.detail_address,
            isDefault: Boolean(row.is_default),
            createdAt: row.created_at,
          }));
        }
      } catch (err) {
        console.warn('Error fetching user_addresses from Supabase:', err);
      }
    }

    return this.inMemoryAddresses
      .filter((a) => a.userId === userId || a.userId === lookupId)
      .sort((a, b) => (b.isDefault ? 1 : 0) - (a.isDefault ? 1 : 0));
  }

  async create(userId: string, data: {
    recipientName: string;
    phone: string;
    province?: string;
    district?: string;
    ward?: string;
    detailAddress: string;
    isDefault?: boolean;
  }): Promise<UserAddress> {
    const lookupId = this.resolveLookupId(userId);
    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(lookupId);

    // If marked default or first address, clear existing default
    const existing = await this.list(userId);
    const isDefault = data.isDefault ?? (existing.length === 0);

    if (this.supabase && isUuid) {
      try {
        if (isDefault) {
          await this.supabase
            .from('user_addresses')
            .update({ is_default: false })
            .eq('user_id', lookupId);
        }

        const { data: inserted, error } = await this.supabase
          .from('user_addresses')
          .insert({
            user_id: lookupId,
            recipient_name: data.recipientName,
            phone: data.phone,
            province: data.province || 'Hà Nội',
            district: data.district || 'Hoàn Kiếm',
            ward: data.ward || '',
            detailAddress: data.detailAddress,
            is_default: isDefault,
          })
          .select()
          .single();

        if (error) {
          throw new AppError('DB_ADDRESS_CREATE_FAILED', 400, error.message);
        }

        return {
          id: inserted.id,
          userId: inserted.user_id,
          recipientName: inserted.recipient_name,
          phone: inserted.phone,
          province: inserted.province,
          district: inserted.district,
          ward: inserted.ward,
          detailAddress: inserted.detail_address,
          isDefault: Boolean(inserted.is_default),
          createdAt: inserted.created_at,
        };
      } catch (err: any) {
        if (err instanceof AppError) throw err;
        console.warn('Supabase address insert failed, fallback to in-memory:', err.message);
      }
    }

    if (isDefault) {
      this.inMemoryAddresses.forEach((a) => {
        if (a.userId === userId || a.userId === lookupId) {
          a.isDefault = false;
        }
      });
    }

    const newAddr: UserAddress = {
      id: `addr-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
      userId: lookupId,
      recipientName: data.recipientName,
      phone: data.phone,
      province: data.province || 'Hà Nội',
      district: data.district || '',
      ward: data.ward || '',
      detailAddress: data.detailAddress,
      isDefault,
      createdAt: new Date().toISOString(),
    };
    this.inMemoryAddresses.unshift(newAddr);
    return newAddr;
  }

  async update(id: string, userId: string, data: Partial<{
    recipientName: string;
    phone: string;
    province?: string;
    district?: string;
    ward?: string;
    detailAddress: string;
    isDefault?: boolean;
  }>): Promise<UserAddress> {
    const lookupId = this.resolveLookupId(userId);
    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(lookupId);

    if (data.isDefault) {
      if (this.supabase && isUuid) {
        await this.supabase
          .from('user_addresses')
          .update({ is_default: false })
          .eq('user_id', lookupId);
      }
      this.inMemoryAddresses.forEach((a) => {
        if (a.userId === userId || a.userId === lookupId) {
          a.isDefault = false;
        }
      });
    }

    if (this.supabase && isUuid) {
      try {
        const patch: Record<string, any> = {};
        if (data.recipientName !== undefined) patch.recipient_name = data.recipientName;
        if (data.phone !== undefined) patch.phone = data.phone;
        if (data.province !== undefined) patch.province = data.province;
        if (data.district !== undefined) patch.district = data.district;
        if (data.ward !== undefined) patch.ward = data.ward;
        if (data.detailAddress !== undefined) patch.detail_address = data.detailAddress;
        if (data.isDefault !== undefined) patch.is_default = data.isDefault;

        const { data: updated, error } = await this.supabase
          .from('user_addresses')
          .update(patch)
          .eq('id', id)
          .eq('user_id', lookupId)
          .select()
          .single();

        if (!error && updated) {
          return {
            id: updated.id,
            userId: updated.user_id,
            recipientName: updated.recipient_name,
            phone: updated.phone,
            province: updated.province,
            district: updated.district,
            ward: updated.ward,
            detailAddress: updated.detail_address,
            isDefault: Boolean(updated.is_default),
            createdAt: updated.created_at,
          };
        }
      } catch (err) {
        console.warn('Supabase update address failed:', err);
      }
    }

    const idx = this.inMemoryAddresses.findIndex((a) => a.id === id);
    if (idx === -1) {
      throw new AppError('NOT_FOUND', 404, 'Không tìm thấy địa chỉ giao hàng');
    }
    const current = this.inMemoryAddresses[idx];
    const updated: UserAddress = {
      ...current,
      recipientName: data.recipientName ?? current.recipientName,
      phone: data.phone ?? current.phone,
      province: data.province ?? current.province,
      district: data.district ?? current.district,
      ward: data.ward ?? current.ward,
      detailAddress: data.detailAddress ?? current.detailAddress,
      isDefault: data.isDefault ?? current.isDefault,
    };
    this.inMemoryAddresses[idx] = updated;
    return updated;
  }

  async delete(id: string, userId: string): Promise<void> {
    const lookupId = this.resolveLookupId(userId);
    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(lookupId);

    if (this.supabase && isUuid) {
      try {
        await this.supabase
          .from('user_addresses')
          .delete()
          .eq('id', id)
          .eq('user_id', lookupId);
      } catch (err) {
        console.warn('Supabase delete address failed:', err);
      }
    }

    this.inMemoryAddresses = this.inMemoryAddresses.filter((a) => a.id !== id);
  }

  async setDefault(id: string, userId: string): Promise<UserAddress> {
    return this.update(id, userId, { isDefault: true });
  }
}
