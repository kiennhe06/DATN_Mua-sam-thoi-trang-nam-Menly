import { INotificationModel } from '../models/notification.model.js';
import { AppNotification, AppError } from '../models/types.js';

export class NotificationViewModel {
  constructor(private readonly model: INotificationModel) {}

  async listNotifications(userId: string, limit = 50, offset = 0): Promise<AppNotification[]> {
    if (!userId) {
      throw new AppError('UNAUTHORIZED', 401, 'Vui lòng đăng nhập để xem thông báo');
    }
    return this.model.list(userId, limit, offset);
  }

  async getUnreadCount(userId: string): Promise<number> {
    if (!userId) return 0;
    return this.model.getUnreadCount(userId);
  }

  async markAsRead(id: string, userId: string): Promise<void> {
    if (!userId) {
      throw new AppError('UNAUTHORIZED', 401, 'Vui lòng đăng nhập');
    }
    if (!id) {
      throw new AppError('VALIDATION_ERROR', 400, 'Thiếu mã thông báo');
    }
    await this.model.markAsRead(id, userId);
  }

  async markAllAsRead(userId: string): Promise<void> {
    if (!userId) {
      throw new AppError('UNAUTHORIZED', 401, 'Vui lòng đăng nhập');
    }
    await this.model.markAllAsRead(userId);
  }

  async deleteNotification(id: string, userId: string): Promise<void> {
    if (!userId) {
      throw new AppError('UNAUTHORIZED', 401, 'Vui lòng đăng nhập');
    }
    if (!id) {
      throw new AppError('VALIDATION_ERROR', 400, 'Thiếu mã thông báo');
    }
    await this.model.delete(id, userId);
  }

  async createNotification(
    userId: string,
    title: string,
    body: string,
    type: 'order' | 'promo' | 'system' = 'order',
    data: Record<string, any> = {}
  ): Promise<AppNotification> {
    if (!userId) return null as any;
    return this.model.create({
      userId,
      title,
      body,
      type,
      data,
    });
  }
}
