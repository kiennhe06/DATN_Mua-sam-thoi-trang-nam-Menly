import { z } from 'zod';
import dotenv from 'dotenv';

dotenv.config();

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().int().default(5000),
  SUPABASE_URL: z.string().default(''),
  SUPABASE_ANON_KEY: z.string().default(''),
  SUPABASE_SERVICE_ROLE_KEY: z.string().optional().default(''),
  VNPAY_TMN_CODE: z.string().default(''),
  VNPAY_HASH_SECRET: z.string().default(''),
  VNPAY_PAY_URL: z.string().url().default('https://sandbox.vnpayment.vn/paymentv2/vpcpay.html'),
  VNPAY_RETURN_URL: z.string().url().default('http://localhost:5000/api/v1/payments/vnpay/return'),
  USE_MOCK_DB: z.string().transform((val) => val === 'true').default('false'),
});

export const env = envSchema.parse(process.env);
export type Env = z.infer<typeof envSchema>;
