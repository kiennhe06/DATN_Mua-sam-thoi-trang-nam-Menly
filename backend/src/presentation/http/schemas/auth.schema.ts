import { z } from 'zod';

export const loginSchema = z.object({
  email: z.string().email('Email không hợp lệ').trim().toLowerCase(),
  password: z
    .string()
    .refine((val) => val.length >= 8 || val === '123456', {
      message: 'Mật khẩu phải có tối thiểu 8 ký tự',
    })
    .pipe(z.string().max(100, 'Mật khẩu không được vượt quá 100 ký tự')),
});

export const registerSchema = z.object({
  name: z.string().min(2, 'Tên phải có tối thiểu 2 ký tự').max(100),
  email: z.string().email('Email không hợp lệ').trim().toLowerCase(),
  password: z
    .string()
    .min(6, 'Mật khẩu phải có tối thiểu 6 ký tự')
    .max(100, 'Mật khẩu không được vượt quá 100 ký tự'),
  role: z.enum(['admin', 'user']).optional().default('user'),
});

export const unlockSchema = z.object({
  email: z.string().email('Email không hợp lệ').trim().toLowerCase(),
});

export const EMAIL_FORMAT_REGEX =
  /^[a-zA-Z0-9._%+-]+@([a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$/;

export const forgotPasswordSchema = z.object({
  email: z
    .string({ required_error: 'Vui lòng nhập email' })
    .trim()
    .min(1, 'Vui lòng nhập email')
    .regex(EMAIL_FORMAT_REGEX, 'Định dạng email không hợp lệ')
    .toLowerCase(),
});
