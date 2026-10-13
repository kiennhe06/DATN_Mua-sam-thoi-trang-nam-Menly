import { Router } from 'express';
import { ReviewViewModel } from '../../viewmodels/review.viewmodel.js';

export function reviewRoutes(
  requireAuth: any,
  viewModel: ReviewViewModel
): Router {
  const router = Router();

  // Create a review
  router.post('/:productId', requireAuth, async (req, res, next) => {
    try {
      const headerUserId = (req.headers['x-user-id'] as string) || undefined;
      const headerEmail = (req.headers['x-user-email'] as string) || undefined;
      const effectiveUserId = headerUserId || req.user!.id;
      const effectiveEmail = req.user?.email || headerEmail;

      const review = await viewModel.createReview(effectiveUserId, req.params.productId, req.body, effectiveEmail);
      res.status(201).json({ data: review });
    } catch (error) {
      next(error);
    }
  });

  // Check if current user can review this product
  router.get('/can-review/:productId', requireAuth, async (req, res, next) => {
    try {
      const headerUserId = (req.headers['x-user-id'] as string) || undefined;
      const headerEmail = (req.headers['x-user-email'] as string) || undefined;
      const effectiveUserId = headerUserId || req.user!.id;
      const effectiveEmail = req.user?.email || headerEmail;

      const canReview = await viewModel.canUserReview(effectiveUserId, req.params.productId, effectiveEmail);
      res.json({ data: { canReview } });
    } catch (error) {
      next(error);
    }
  });

  // Get reviews for a product
  router.get('/product/:productId', async (req, res, next) => {
    try {
      const limit = parseInt(req.query.limit as string) || 10;
      const page = parseInt(req.query.page as string) || 1;
      const result = await viewModel.getProductReviews(req.params.productId, limit, page);
      res.json({ data: result });
    } catch (error) {
      next(error);
    }
  });

  // Delete own review
  router.delete('/:reviewId', requireAuth, async (req, res, next) => {
    try {
      await viewModel.deleteReview(req.params.reviewId, req.user!.id);
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  });

  return router;
}
