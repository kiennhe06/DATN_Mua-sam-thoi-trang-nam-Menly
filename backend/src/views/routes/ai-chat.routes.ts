import { Router } from 'express';
import { AiChatController } from '../controllers/ai-chat.controller.js';

export function aiChatRoutes(): Router {
  const router = Router();
  const controller = new AiChatController();

  router.post('/message', controller.sendMessage);

  return router;
}
