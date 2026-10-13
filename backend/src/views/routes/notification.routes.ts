import { Router, RequestHandler } from 'express';
import { NotificationViewModel } from '../../viewmodels/notification.viewmodel.js';

export function notificationRoutes(
  requireAuth: RequestHandler,
  viewModel: NotificationViewModel
): Router {
  const router = Router();
  router.use(requireAuth);

  // GET /api/v1/notifications/unread-count
  router.get('/unread-count', async (req, res, next) => {
    try {
      const headerUserId = (req.headers['x-user-id'] as string) || undefined;
      const effectiveUserId = headerUserId || req.user!.id;
      const count = await viewModel.getUnreadCount(effectiveUserId);
      res.json({ data: { unreadCount: count } });
    } catch (err) {
      next(err);
    }
  });

  // GET /api/v1/notifications — Lấy danh sách thông báo
  router.get('/', async (req, res, next) => {
    try {
      const headerUserId = (req.headers['x-user-id'] as string) || undefined;
      const effectiveUserId = headerUserId || req.user!.id;
      const limit = parseInt(req.query.limit as string) || 50;
      const offset = parseInt(req.query.offset as string) || 0;
      const notifs = await viewModel.listNotifications(effectiveUserId, limit, offset);
      res.json({ data: notifs });
    } catch (err) {
      next(err);
    }
  });

  // PATCH /api/v1/notifications/read-all — Đánh dấu tất cả đã đọc
  router.patch('/read-all', async (req, res, next) => {
    try {
      const headerUserId = (req.headers['x-user-id'] as string) || undefined;
      const effectiveUserId = headerUserId || req.user!.id;
      await viewModel.markAllAsRead(effectiveUserId);
      res.json({ message: 'Đã đánh dấu tất cả thông báo là đã đọc' });
    } catch (err) {
      next(err);
    }
  });

  // PATCH /api/v1/notifications/:id/read — Đánh dấu 1 thông báo đã đọc
  router.patch('/:id/read', async (req, res, next) => {
    try {
      const headerUserId = (req.headers['x-user-id'] as string) || undefined;
      const effectiveUserId = headerUserId || req.user!.id;
      await viewModel.markAsRead(req.params.id, effectiveUserId);
      res.json({ message: 'Đã đánh dấu thông báo là đã đọc' });
    } catch (err) {
      next(err);
    }
  });

  // DELETE /api/v1/notifications/:id — Xóa 1 thông báo
  router.delete('/:id', async (req, res, next) => {
    try {
      const headerUserId = (req.headers['x-user-id'] as string) || undefined;
      const effectiveUserId = headerUserId || req.user!.id;
      await viewModel.deleteNotification(req.params.id, effectiveUserId);
      res.json({ message: 'Đã xóa thông báo thành công' });
    } catch (err) {
      next(err);
    }
  });

  return router;
}
