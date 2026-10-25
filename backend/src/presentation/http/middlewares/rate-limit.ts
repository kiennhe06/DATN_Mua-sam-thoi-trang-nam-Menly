import rateLimit from 'express-rate-limit';

const isDev = process.env.NODE_ENV !== 'production';
const isRateLimitDisabled = process.env.DISABLE_RATE_LIMIT === 'true';

// Cho phép tuỳ chỉnh qua biến môi trường hoặc nới lỏng khi benchmark/load test
// Khi test tải 100 connections cùng 1 IP (localhost), cần giới hạn cao hoặc tắt rate limit
const generalMax = Number(process.env.RATE_LIMIT_GENERAL_MAX) || (isDev ? 100000 : 100);
const orderMax = Number(process.env.RATE_LIMIT_ORDER_MAX) || (isDev ? 500 : 20);
const trackOrderMax = Number(process.env.RATE_LIMIT_TRACK_MAX) || (isDev ? 500 : 15);

export const generalRateLimit = rateLimit({
  windowMs: 60 * 1000,
  max: generalMax,
  standardHeaders: true,
  legacyHeaders: false,
  skip: () => isRateLimitDisabled,
  message: {
    error: {
      code: 'RATE_LIMITED',
      message: 'Quá nhiều yêu cầu, vui lòng thử lại sau giây lát',
    },
  },
});

export const orderRateLimit = rateLimit({
  windowMs: 60 * 1000,
  max: orderMax,
  standardHeaders: true,
  legacyHeaders: false,
  skip: () => isRateLimitDisabled,
  message: {
    error: {
      code: 'RATE_LIMITED',
      message: 'Thao tác đặt hàng quá nhanh, vui lòng thử lại sau',
    },
  },
});

export const trackOrderRateLimit = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: trackOrderMax,
  standardHeaders: true,
  legacyHeaders: false,
  skip: () => isRateLimitDisabled,
  message: {
    error: {
      code: 'RATE_LIMITED',
      message: 'Tra cứu quá nhiều lần, vui lòng thử lại sau 1 giờ',
    },
  },
});

