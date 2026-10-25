import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { askMenlyStylistWithProducts } from '../../infrastructure/services/gemini.service.js';

const aiChatMessageSchema = z.object({
  message: z.string().min(1, 'Tin nhắn không được để trống'),
  history: z
    .array(
      z.object({
        role: z.enum(['user', 'model']),
        content: z.string(),
      })
    )
    .optional()
    .default([]),
});

export class AiChatController {
  sendMessage = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const { message, history } = aiChatMessageSchema.parse(req.body);
      const result = await askMenlyStylistWithProducts(message, history);
      res.json({
        success: true,
        reply: result.reply,
        suggestedProducts: result.suggestedProducts,
      });
    } catch (err) {
      next(err);
    }
  };
}
