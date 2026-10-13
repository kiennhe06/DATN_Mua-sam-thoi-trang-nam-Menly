import { SupabaseClient } from '@supabase/supabase-js';
import { AppNotification } from './types.js';

export interface INotificationModel {
  list(userId: string, limit?: number, offset?: number): Promise<AppNotification[]>;
  create(data: {
    userId: string;
    title: string;
    body: string;
    type: 'order' | 'promo' | 'system';
    data?: Record<string, any>;
  }): Promise<AppNotification>;
  markAsRead(id: string, userId: string): Promise<void>;
  markAllAsRead(userId: string): Promise<void>;
  delete(id: string, userId: string): Promise<void>;
  getUnreadCount(userId: string): Promise<number>;
}

export class NotificationModel implements INotificationModel {
  private inMemoryNotifications: AppNotification[] = [
    {
      id: 'notif-1',
      userId: '00000000-0000-0000-0000-000000000002',
      title: 'Chào mừng bạn đến với Menly!',
      body: 'Khám phá bộ sưu tập thời trang nam cao cấp phong cách Soft Premium mới nhất cùng ưu đãi hấp dẫn.',
      type: 'promo',
      data: {},
      isRead: false,
      createdAt: new Date(Date.now() - 1000 * 60 * 30).toISOString(),
    },
    {
      id: 'notif-2',
      userId: '00000000-0000-0000-0000-000000000002',
      title: 'Mã giảm giá đặc quyền',
      body: 'Bạn có mã giảm giá MENLY10 giảm 10% áp dụng cho mọi đơn hàng từ 500.000đ.',
      type: 'promo',
      data: { code: 'MENLY10' },
      isRead: false,
      createdAt: new Date(Date.now() - 1000 * 60 * 120).toISOString(),
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

  async list(userId: string, limit = 50, offset = 0): Promise<AppNotification[]> {
    const lookupId = this.resolveLookupId(userId);
    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(lookupId);

    if (this.supabase && isUuid) {
      try {
        const { data, error } = await this.supabase
          .from('notifications')
          .select('*')
          .eq('user_id', lookupId)
          .order('created_at', { ascending: false })
          .range(offset, offset + limit - 1);

        if (!error && data) {
          return data.map((row) => ({
            id: row.id,
            userId: row.user_id,
            title: row.title,
            body: row.body,
            type: row.type,
            data: row.data || {},
            isRead: Boolean(row.is_read),
            createdAt: row.created_at,
          }));
        }
      } catch (err) {
        console.warn('Supabase fetch notifications error:', err);
      }
    }

    return this.inMemoryNotifications
      .filter((n) => n.userId === userId || n.userId === lookupId)
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt))
      .slice(offset, offset + limit);
  }

  async create(data: {
    userId: string;
    title: string;
    body: string;
    type: 'order' | 'promo' | 'system';
    data?: Record<string, any>;
  }): Promise<AppNotification> {
    const lookupId = this.resolveLookupId(data.userId);
    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(lookupId);

    if (this.supabase && isUuid) {
      try {
        const { data: inserted, error } = await this.supabase
          .from('notifications')
          .insert({
            user_id: lookupId,
            title: data.title,
            body: data.body,
            type: data.type,
            data: data.data || {},
            is_read: false,
          })
          .select()
          .single();

        if (!error && inserted) {
          return {
            id: inserted.id,
            userId: inserted.user_id,
            title: inserted.title,
            body: inserted.body,
            type: inserted.type,
            data: inserted.data || {},
            isRead: Boolean(inserted.is_read),
            createdAt: inserted.created_at,
          };
        }
      } catch (err) {
        console.warn('Supabase insert notification error:', err);
      }
    }

    const item: AppNotification = {
      id: `notif-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
      userId: lookupId,
      title: data.title,
      body: data.body,
      type: data.type,
      data: data.data || {},
      isRead: false,
      createdAt: new Date().toISOString(),
    };
    this.inMemoryNotifications.unshift(item);
    return item;
  }

  async markAsRead(id: string, userId: string): Promise<void> {
    const lookupId = this.resolveLookupId(userId);
    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(lookupId);

    if (this.supabase && isUuid) {
      try {
        await this.supabase
          .from('notifications')
          .update({ is_read: true })
          .eq('id', id)
          .eq('user_id', lookupId);
      } catch (err) {
        console.warn('Supabase mark read error:', err);
      }
    }

    const target = this.inMemoryNotifications.find((n) => n.id === id);
    if (target) {
      target.isRead = true;
    }
  }

  async markAllAsRead(userId: string): Promise<void> {
    const lookupId = this.resolveLookupId(userId);
    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(lookupId);

    if (this.supabase && isUuid) {
      try {
        await this.supabase
          .from('notifications')
          .update({ is_read: true })
          .eq('user_id', lookupId);
      } catch (err) {
        console.warn('Supabase mark all read error:', err);
      }
    }

    this.inMemoryNotifications.forEach((n) => {
      if (n.userId === userId || n.userId === lookupId) {
        n.isRead = true;
      }
    });
  }

  async delete(id: string, userId: string): Promise<void> {
    const lookupId = this.resolveLookupId(userId);
    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(lookupId);

    if (this.supabase && isUuid) {
      try {
        await this.supabase
          .from('notifications')
          .delete()
          .eq('id', id)
          .eq('user_id', lookupId);
      } catch (err) {
        console.warn('Supabase delete notification error:', err);
      }
    }

    this.inMemoryNotifications = this.inMemoryNotifications.filter((n) => n.id !== id);
  }

  async getUnreadCount(userId: string): Promise<number> {
    const lookupId = this.resolveLookupId(userId);
    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(lookupId);

    if (this.supabase && isUuid) {
      try {
        const { count, error } = await this.supabase
          .from('notifications')
          .select('*', { count: 'exact', head: true })
          .eq('user_id', lookupId)
          .eq('is_read', false);

        if (!error && count !== null) {
          return count;
        }
      } catch (err) {
        console.warn('Supabase unread count error:', err);
      }
    }

    return this.inMemoryNotifications.filter(
      (n) => (n.userId === userId || n.userId === lookupId) && !n.isRead
    ).length;
  }
}
