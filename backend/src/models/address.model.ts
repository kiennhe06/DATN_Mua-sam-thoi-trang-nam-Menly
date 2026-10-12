import { SupabaseClient } from '@supabase/supabase-js';
import { AppError } from './types.js';

export interface UserAddress {
  id: string;
  recipientName: string;
  phone: string;
  province: string;
  district: string;
  ward: string;
  detailAddress: string;
  isDefault: boolean;
  createdAt?: string;
}

export interface AddressInput {
  recipientName: string;
  phone: string;
  province?: string;
  district?: string;
  ward?: string;
  detailAddress: string;
  isDefault?: boolean;
}

export interface IAddressModel {
  list(userId: string): Promise<UserAddress[]>;
  create(userId: string, input: AddressInput): Promise<UserAddress>;
  update(userId: string, id: string, input: Partial<AddressInput>): Promise<UserAddress>;
  remove(userId: string, id: string): Promise<void>;
  setDefault(userId: string, id: string): Promise<UserAddress>;
}

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const sortAddresses = (list: UserAddress[]): UserAddress[] =>
  [...list].sort((a, b) => {
    if (a.isDefault !== b.isDefault) return a.isDefault ? -1 : 1;
    return 0;
  });

export class AddressModel implements IAddressModel {
  // In-memory fallback: Map<userId, UserAddress[]>
  private inMemory = new Map<string, UserAddress[]>();

  constructor(private readonly supabase?: SupabaseClient) {}

  private canUseSupabase(userId: string): boolean {
    return Boolean(this.supabase) && UUID_RE.test(userId);
  }

  private memoryList(userId: string): UserAddress[] {
    return this.inMemory.get(userId) || [];
  }

  private setMemory(userId: string, list: UserAddress[]): void {
    this.inMemory.set(userId, list);
  }

  private mapRow(row: any): UserAddress {
    return {
      id: row.id,
      recipientName: row.recipient_name ?? '',
      phone: row.phone ?? '',
      province: row.province ?? '',
      district: row.district ?? '',
      ward: row.ward ?? '',
      detailAddress: row.detail_address ?? '',
      isDefault: row.is_default === true,
      createdAt: row.created_at,
    };
  }

  private async dbList(userId: string): Promise<UserAddress[]> {
    if (!this.canUseSupabase(userId)) return [];
    try {
      const { data, error } = await this.supabase!
        .from('user_addresses')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', { ascending: false });
      if (error) throw error;
      return (data || []).map((row: any) => this.mapRow(row));
    } catch (err: any) {
      console.warn('AddressModel.dbList fallback to memory:', err?.message);
      return [];
    }
  }

  async list(userId: string): Promise<UserAddress[]> {
    const memory = this.memoryList(userId);
    const db = await this.dbList(userId);
    const seen = new Set(memory.map((a) => a.id));
    const merged = [...memory, ...db.filter((a) => !seen.has(a.id))];
    return sortAddresses(merged);
  }

  async create(userId: string, input: AddressInput): Promise<UserAddress> {
    if (this.canUseSupabase(userId)) {
      try {
        const existing = await this.list(userId);
        const shouldBeDefault = input.isDefault === true || existing.length === 0;

        if (shouldBeDefault && existing.length > 0) {
          await this.supabase!
            .from('user_addresses')
            .update({ is_default: false })
            .eq('user_id', userId);
        }

        const { data, error } = await this.supabase!
          .from('user_addresses')
          .insert({
            user_id: userId,
            recipient_name: input.recipientName,
            phone: input.phone,
            province: input.province ?? '',
            district: input.district ?? '',
            ward: input.ward ?? '',
            detail_address: input.detailAddress,
            is_default: shouldBeDefault,
          })
          .select('*')
          .single();

        if (error) throw error;
        return this.mapRow(data);
      } catch (err: any) {
        console.warn('AddressModel.create fallback to memory:', err?.message);
      }
    }

    return this.memoryCreate(userId, input);
  }

  private memoryCreate(userId: string, input: AddressInput): UserAddress {
    const list = this.memoryList(userId);
    const shouldBeDefault = input.isDefault === true || list.length === 0;
    if (shouldBeDefault) {
      list.forEach((a) => (a.isDefault = false));
    }
    const created: UserAddress = {
      id: `addr-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
      recipientName: input.recipientName,
      phone: input.phone,
      province: input.province ?? '',
      district: input.district ?? '',
      ward: input.ward ?? '',
      detailAddress: input.detailAddress,
      isDefault: shouldBeDefault,
      createdAt: new Date().toISOString(),
    };
    list.unshift(created);
    this.setMemory(userId, list);
    return created;
  }

  private memoryUpdate(
    userId: string,
    id: string,
    input: Partial<AddressInput>
  ): UserAddress {
    const list = this.memoryList(userId);
    const idx = list.findIndex((a) => a.id === id);
    if (idx === -1) {
      throw new AppError('NOT_FOUND', 404, 'Không tìm thấy địa chỉ');
    }
    if (input.isDefault === true) {
      list.forEach((a) => (a.isDefault = false));
    }
    const current = list[idx];
    list[idx] = {
      ...current,
      recipientName: input.recipientName ?? current.recipientName,
      phone: input.phone ?? current.phone,
      province: input.province ?? current.province,
      district: input.district ?? current.district,
      ward: input.ward ?? current.ward,
      detailAddress: input.detailAddress ?? current.detailAddress,
      isDefault: input.isDefault === true ? true : current.isDefault,
    };
    this.setMemory(userId, list);
    return list[idx];
  }

  async update(
    userId: string,
    id: string,
    input: Partial<AddressInput>
  ): Promise<UserAddress> {
    if (this.memoryList(userId).some((a) => a.id === id)) {
      return this.memoryUpdate(userId, id, input);
    }

    if (this.canUseSupabase(userId)) {
      try {
        const patch: Record<string, any> = {};
        if (input.recipientName !== undefined) patch.recipient_name = input.recipientName;
        if (input.phone !== undefined) patch.phone = input.phone;
        if (input.province !== undefined) patch.province = input.province;
        if (input.district !== undefined) patch.district = input.district;
        if (input.ward !== undefined) patch.ward = input.ward;
        if (input.detailAddress !== undefined) patch.detail_address = input.detailAddress;

        if (input.isDefault === true) {
          await this.supabase!
            .from('user_addresses')
            .update({ is_default: false })
            .eq('user_id', userId);
          patch.is_default = true;
        }

        const { data, error } = await this.supabase!
          .from('user_addresses')
          .update(patch)
          .eq('id', id)
          .eq('user_id', userId)
          .select('*')
          .single();

        if (error) throw error;
        return this.mapRow(data);
      } catch (err: any) {
        console.warn('AddressModel.update fallback to memory:', err?.message);
      }
    }

    return this.memoryUpdate(userId, id, input);
  }

  private memoryRemove(userId: string, id: string): void {
    const list = this.memoryList(userId);
    const idx = list.findIndex((a) => a.id === id);
    if (idx === -1) {
      throw new AppError('NOT_FOUND', 404, 'Không tìm thấy địa chỉ');
    }
    const [removed] = list.splice(idx, 1);
    if (removed.isDefault && list.length > 0) {
      list[0].isDefault = true;
    }
    this.setMemory(userId, list);
  }

  async remove(userId: string, id: string): Promise<void> {
    if (this.memoryList(userId).some((a) => a.id === id)) {
      return this.memoryRemove(userId, id);
    }

    if (this.canUseSupabase(userId)) {
      try {
        const { data: target } = await this.supabase!
          .from('user_addresses')
          .select('is_default')
          .eq('id', id)
          .eq('user_id', userId)
          .maybeSingle();

        const { error } = await this.supabase!
          .from('user_addresses')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);

        if (error) throw error;

        // Nếu xoá địa chỉ mặc định, chọn địa chỉ còn lại làm mặc định
        if (target?.is_default) {
          const { data: remaining } = await this.supabase!
            .from('user_addresses')
            .select('id')
            .eq('user_id', userId)
            .order('created_at', { ascending: false })
            .limit(1);
          if (remaining && remaining.length > 0) {
            await this.supabase!
              .from('user_addresses')
              .update({ is_default: true })
              .eq('id', remaining[0].id);
          }
        }
        return;
      } catch (err: any) {
        console.warn('AddressModel.remove fallback to memory:', err?.message);
      }
    }

    this.memoryRemove(userId, id);
  }

  private memorySetDefault(userId: string, id: string): UserAddress {
    const list = this.memoryList(userId);
    const target = list.find((a) => a.id === id);
    if (!target) {
      throw new AppError('NOT_FOUND', 404, 'Không tìm thấy địa chỉ');
    }
    list.forEach((a) => (a.isDefault = a.id === id));
    this.setMemory(userId, list);
    return target;
  }

  async setDefault(userId: string, id: string): Promise<UserAddress> {
    if (this.memoryList(userId).some((a) => a.id === id)) {
      return this.memorySetDefault(userId, id);
    }

    if (this.canUseSupabase(userId)) {
      try {
        await this.supabase!
          .from('user_addresses')
          .update({ is_default: false })
          .eq('user_id', userId);

        const { data, error } = await this.supabase!
          .from('user_addresses')
          .update({ is_default: true })
          .eq('id', id)
          .eq('user_id', userId)
          .select('*')
          .single();

        if (error) throw error;
        return this.mapRow(data);
      } catch (err: any) {
        console.warn('AddressModel.setDefault fallback to memory:', err?.message);
      }
    }

    return this.memorySetDefault(userId, id);
  }
}
