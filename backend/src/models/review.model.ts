import { SupabaseClient } from '@supabase/supabase-js';
import { Review, AppError, Page } from './types.js';
import { IOrderModel } from './order.model.js';

export interface CreateReviewInput {
  userId: string;
  productId: string;
  rating: number;
  comment?: string;
  userEmail?: string;
}

export interface IReviewModel {
  createReview(input: CreateReviewInput): Promise<Review>;
  getReviewsByProduct(productId: string, limit: number, page: number): Promise<Page<Review>>;
  getAllReviews(limit: number, page: number): Promise<Page<Review>>;
  deleteReview(reviewId: string, userId?: string, isAdmin?: boolean): Promise<void>;
  canUserReview(userId: string, productId: string, userEmail?: string): Promise<boolean>;
}

export class ReviewModel implements IReviewModel {
  private inMemoryReviews: Review[] = [];

  constructor(
    private readonly supabase?: SupabaseClient,
    private readonly orderModel?: IOrderModel
  ) {}

  async createReview(input: CreateReviewInput): Promise<Review> {
    if (!this.supabase) {
      const existing = this.inMemoryReviews.find(
        (r) => r.userId === input.userId && r.productId === input.productId
      );
      if (existing) {
        throw new AppError('DUPLICATE_REVIEW', 400, 'Bạn đã đánh giá sản phẩm này rồi');
      }
      const memoryRev: Review = {
        id: `rev-${Date.now()}`,
        userId: input.userId,
        productId: input.productId,
        rating: input.rating,
        comment: input.comment || null,
        createdAt: new Date().toISOString(),
      };
      this.inMemoryReviews.unshift(memoryRev);
      return memoryRev;
    }

    let effectiveUserId = input.userId;
    if (this.supabase && input.userEmail) {
      try {
        const { data: dbUser } = await this.supabase
          .from('users')
          .select('id')
          .ilike('email', input.userEmail.trim())
          .maybeSingle();
        if (dbUser?.id) {
          effectiveUserId = dbUser.id;
        }
      } catch (_) {}
    }

    if (
      effectiveUserId === 'usr-admin-001' ||
      effectiveUserId === '00000000-0000-0000-0000-000000000001' ||
      input.userEmail === 'admin@menshop.vn' ||
      input.userEmail === 'admin@gmail.com'
    ) {
      effectiveUserId = '0f444d92-322c-4956-b452-0c5c10950508';
    } else if (
      effectiveUserId === 'usr-staff-001' ||
      input.userEmail === 'staff@menshop.vn' ||
      input.userEmail === 'staff@gmail.com'
    ) {
      effectiveUserId = 'd604e122-aa50-47e0-ac44-10a2473af6ce';
    } else if (
      !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(effectiveUserId)
    ) {
      effectiveUserId = '7fb74d58-4155-4ab5-8124-cb0b5bb6651d';
    }

    // Try upserting so user can update their review if they already reviewed
    const { data: existing } = await this.supabase
      .from('reviews')
      .select('id')
      .eq('user_id', effectiveUserId)
      .eq('product_id', input.productId)
      .maybeSingle();

    let data: any = null;
    let error: any = null;

    if (existing) {
      const res = await this.supabase
        .from('reviews')
        .update({
          rating: input.rating,
          comment: input.comment || null,
        })
        .eq('id', existing.id)
        .select('*, user:users(id, email, full_name)')
        .single();
      data = res.data;
      error = res.error;
    } else {
      const res = await this.supabase
        .from('reviews')
        .insert({
          user_id: effectiveUserId,
          product_id: input.productId,
          rating: input.rating,
          comment: input.comment || null,
        })
        .select('*, user:users(id, email, full_name)')
        .single();
      data = res.data;
      error = res.error;
    }

    if (error) {
      // Fallback if user:users join failed or unique constraint
      const fallbackRes = await this.supabase
        .from('reviews')
        .upsert(
          {
            user_id: effectiveUserId,
            product_id: input.productId,
            rating: input.rating,
            comment: input.comment || null,
          },
          { onConflict: 'user_id,product_id' }
        )
        .select('*')
        .single();

      if (fallbackRes.error) {
        throw new AppError('DB_CREATE_REVIEW_FAILED', 500, fallbackRes.error.message);
      }
      data = fallbackRes.data;
    }

    return this.mapToReview(data);
  }

  async getReviewsByProduct(productId: string, limit: number, page: number): Promise<Page<Review>> {
    if (!this.supabase) {
      const filtered = this.inMemoryReviews.filter((r) => r.productId === productId);
      const from = (page - 1) * limit;
      const items = filtered.slice(from, from + limit);
      return {
        items,
        pageInfo: {
          limit,
          hasNext: from + limit < filtered.length,
          nextCursor: (page + 1).toString(),
        },
      };
    }

    const from = (page - 1) * limit;
    const to = from + limit - 1;

    let { data, error, count } = await this.supabase
      .from('reviews')
      .select('*, user:users(id, email, full_name)', { count: 'exact' })
      .eq('product_id', productId)
      .order('created_at', { ascending: false })
      .range(from, to);

    if (error) {
      // Fallback without user join
      const fallbackRes = await this.supabase
        .from('reviews')
        .select('*', { count: 'exact' })
        .eq('product_id', productId)
        .order('created_at', { ascending: false })
        .range(from, to);

      if (fallbackRes.error) {
        throw new AppError('DB_GET_REVIEWS_FAILED', 500, fallbackRes.error.message);
      }
      data = fallbackRes.data;
      count = fallbackRes.count;
    }

    const items = (data || []).map(this.mapToReview);
    return {
      items,
      pageInfo: {
        limit,
        hasNext: count !== null && from + limit < count,
        nextCursor: (page + 1).toString(),
      },
    };
  }

  async getAllReviews(limit: number, page: number): Promise<Page<Review>> {
    if (!this.supabase) {
      const from = (page - 1) * limit;
      const items = this.inMemoryReviews.slice(from, from + limit);
      return {
        items,
        pageInfo: {
          limit,
          hasNext: from + limit < this.inMemoryReviews.length,
          nextCursor: (page + 1).toString(),
        },
      };
    }

    const from = (page - 1) * limit;
    const to = from + limit - 1;

    let { data, error, count } = await this.supabase
      .from('reviews')
      .select('*, user:users(id, email, full_name)', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(from, to);

    if (error) {
      const fallbackRes = await this.supabase
        .from('reviews')
        .select('*', { count: 'exact' })
        .order('created_at', { ascending: false })
        .range(from, to);

      if (fallbackRes.error) {
        throw new AppError('DB_GET_ALL_REVIEWS_FAILED', 500, fallbackRes.error.message);
      }
      data = fallbackRes.data;
      count = fallbackRes.count;
    }

    const items = (data || []).map(this.mapToReview);
    return {
      items,
      pageInfo: {
        limit,
        hasNext: count !== null && from + limit < count,
        nextCursor: (page + 1).toString(),
      },
    };
  }

  async deleteReview(reviewId: string, userId?: string, isAdmin?: boolean): Promise<void> {
    if (!this.supabase) {
      this.inMemoryReviews = this.inMemoryReviews.filter((r) => r.id !== reviewId);
      return;
    }

    let query = this.supabase.from('reviews').delete().eq('id', reviewId);

    if (!isAdmin && userId) {
      query = query.eq('user_id', userId);
    }

    const { error } = await query;
    if (error) throw new AppError('DB_DELETE_REVIEW_FAILED', 500, error.message);
  }

  async canUserReview(userId: string, productId: string, userEmail?: string): Promise<boolean> {
    if (!this.supabase && !this.orderModel) return true;

    // Normalizing user id like in order.model.ts
    let effectiveUserId = userId;
    const allUserUuids: string[] = [];

    if (/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(userId)) {
      allUserUuids.push(userId);
    }

    if (this.supabase && userEmail) {
      try {
        const { data: dbUser } = await this.supabase
          .from('users')
          .select('id')
          .ilike('email', userEmail.trim())
          .maybeSingle();
        if (dbUser?.id) {
          effectiveUserId = dbUser.id;
          allUserUuids.push(dbUser.id);
        }
      } catch (_) {}
    }

    if (
      userId === 'usr-admin-001' ||
      userId === '00000000-0000-0000-0000-000000000001' ||
      userEmail === 'admin@menshop.vn' ||
      userEmail === 'admin@gmail.com'
    ) {
      effectiveUserId = '0f444d92-322c-4956-b452-0c5c10950508';
      allUserUuids.push(effectiveUserId);
    } else if (
      userId === 'usr-staff-001' ||
      userEmail === 'staff@menshop.vn' ||
      userEmail === 'staff@gmail.com'
    ) {
      effectiveUserId = 'd604e122-aa50-47e0-ac44-10a2473af6ce';
      allUserUuids.push(effectiveUserId);
    } else if (
      !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(effectiveUserId)
    ) {
      effectiveUserId = '7fb74d58-4155-4ab5-8124-cb0b5bb6651d';
      allUserUuids.push(effectiveUserId);
    }

    // 1. Check via orderModel if available
    if (this.orderModel) {
      try {
        const userOrders = await this.orderModel.listByUser(userId, 100, undefined, userEmail, effectiveUserId);
        const validStatuses = ['completed', 'shipping', 'processing', 'paid'];
        const successfulOrders = userOrders.filter(
          (o) => validStatuses.includes(o.status) || (o.status !== 'cancelled' && o.status !== 'pending_payment')
        );

        for (const ord of successfulOrders) {
          for (const item of (ord.items || [])) {
            if (item.productId && item.productId === productId) return true;
          }
        }
      } catch (_) {}
    }

    // 2. Check directly in Supabase
    if (this.supabase) {
      try {
        // LỌC CHỈ LẤY CÁC UUID HỢP LỆ ĐỂ TRÁNH LỖI 22P02
        const targetUserIds = Array.from(
          new Set(
            allUserUuids.filter((id) =>
              /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id)
            )
          )
        );

        if (targetUserIds.length > 0) {
          // Find variant IDs belonging to this product
          const { data: variants } = await this.supabase
            .from('product_variants')
            .select('id')
            .eq('product_id', productId);
          const variantIds = (variants || []).map((v: any) => v.id);

          // Find product name if available for fallback matching
          const { data: prod } = await this.supabase
            .from('products')
            .select('name')
            .eq('id', productId)
            .maybeSingle();
          const productName = prod?.name?.trim().toLowerCase();

          // Valid PostgreSQL enum order_status values for successful purchase:
          // 'completed', 'shipping', 'processing', 'paid'
          const validStatuses = ['completed', 'shipping', 'processing', 'paid'];

          const { data: orders } = await this.supabase
            .from('orders')
            .select('id, status')
            .in('user_id', targetUserIds)
            .in('status', validStatuses);

        if (orders && orders.length > 0) {
          const orderIds = orders.map((o: any) => o.id);

          // Check if any order_items match variant_id
          if (variantIds.length > 0) {
            const { data: items } = await this.supabase
              .from('order_items')
              .select('id')
              .in('order_id', orderIds)
              .in('variant_id', variantIds)
              .limit(1);

            if (items && items.length > 0) return true;
          }

          // Check inner join variant:product_variants
          const { data: joinItems } = await this.supabase
            .from('order_items')
            .select('id, variant:product_variants!inner(product_id)')
            .in('order_id', orderIds)
            .eq('variant.product_id', productId)
            .limit(1);

          if (joinItems && joinItems.length > 0) return true;

          // Check by product_name
          if (productName) {
            const { data: nameItems } = await this.supabase
              .from('order_items')
              .select('id, product_name')
              .in('order_id', orderIds);

            if (
              nameItems &&
              nameItems.some(
                (ni: any) =>
                  ni.product_name?.toLowerCase().includes(productName) ||
                  productName.includes(ni.product_name?.toLowerCase())
              )
            ) {
              return true;
            }
          }
        }
      }
    } catch (err) {
        console.warn('canUserReview Supabase check exception:', err);
      }
    }

    // 3. Check in-memory store in orderModel if present
    if (this.orderModel) {
      try {
        const inMemory = (this.orderModel as any).inMemoryOrders as any[] | undefined;
        if (inMemory && inMemory.length > 0) {
          const matches = inMemory.filter(
            (o) =>
              (o.userId === userId ||
                o.userId === effectiveUserId ||
                (userEmail && o.userEmail === userEmail)) &&
              o.status !== 'cancelled' &&
              o.status !== 'pending_payment'
          );
          if (matches.length > 0) {
            for (const ord of matches) {
              for (const itm of ord.items || []) {
                if (itm.productId === productId || itm.product_id === productId) return true;
              }
            }
          }
        }
      } catch (_) {}
    }

    return false;
  }

  private mapToReview(row: any): Review {
    return {
      id: row.id,
      userId: row.user_id,
      productId: row.product_id,
      rating: row.rating,
      comment: row.comment,
      createdAt: row.created_at,
      user: row.user
        ? {
            id: row.user.id,
            email: row.user.email,
            name: row.user.full_name || row.user.email,
          }
        : undefined,
    };
  }
}
