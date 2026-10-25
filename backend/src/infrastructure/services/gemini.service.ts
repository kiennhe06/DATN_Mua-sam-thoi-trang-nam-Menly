import { GoogleGenAI } from '@google/genai';
import { env } from '../../config/env.js';
import { MENLY_SYSTEM_PROMPT } from './gemini.prompt.js';
import { MOCK_PRODUCTS } from '../../models/mock-data.js';

export interface ChatHistoryItem {
  role: 'user' | 'model';
  content: string;
}

export interface SuggestedProductItem {
  id: string;
  name: string;
  price: number;
  thumbnailUrl: string | null;
  slug: string;
}

export interface StylistResponse {
  reply: string;
  suggestedProducts: SuggestedProductItem[];
}

let aiClient: GoogleGenAI | null = null;

function getAiClient(): GoogleGenAI | null {
  const apiKey = env.GEMINI_API_KEY || process.env.GEMINI_API_KEY;
  if (!apiKey) return null;
  if (!aiClient) {
    aiClient = new GoogleGenAI({ apiKey });
  }
  return aiClient;
}

function cleanPlainChatText(text: string): string {
  return text
    .replace(/\*\*(.*?)\*\*/g, '$1')
    .replace(/\*(.*?)\*/g, '$1')
    .replace(/^#+\s*/gm, '')
    .replace(/\[Mã:\s*p\d+\]/gi, '')
    .replace(/\[Mã:\s*[^\]]+\]/gi, '')
    .replace(/[ ]{2,}/g, ' ')
    .trim();
}

/**
 * Chuyển đổi mã ngắn như 'p1', 'p26', 'p51' thành UUID sản phẩm chuẩn Menly
 */
function resolveProductId(shortCode: string): string | null {
  const trimmed = shortCode.trim().toLowerCase();
  const match = trimmed.match(/^p(\d{1,3})$/);
  if (match) {
    const num = parseInt(match[1], 10);
    if (num >= 1 && num <= 125) {
      return `a0000000-0000-0000-0000-${String(num).padStart(12, '0')}`;
    }
  } else if (trimmed.startsWith('a0000000-')) {
    return trimmed;
  }
  return null;
}

/**
 * Tìm kiếm thông tin chi tiết sản phẩm theo danh sách ID
 */
function findProductsByIds(ids: string[]): SuggestedProductItem[] {
  const result: SuggestedProductItem[] = [];
  const seen = new Set<string>();

  for (const id of ids) {
    const resolvedId = resolveProductId(id);
    if (!resolvedId || seen.has(resolvedId)) continue;
    seen.add(resolvedId);

    const product = MOCK_PRODUCTS.find((p) => p.id === resolvedId);
    if (product) {
      result.push({
        id: product.id,
        name: product.name,
        price: product.price,
        thumbnailUrl: product.thumbnailUrl,
        slug: product.slug,
      });
    }
  }

  return result;
}

/**
 * Fallback thông minh: Nếu khách hỏi gợi ý trang phục nhưng AI quên trả tag [GOI_Y: ...]
 */
function fallbackSuggestedProducts(userMessage: string, aiReply: string): SuggestedProductItem[] {
  const text = (userMessage + ' ' + aiReply).toLowerCase();
  const sampleIds: string[] = [];

  if (text.includes('tiệc') || text.includes('hẹn hò') || text.includes('sang trọng')) {
    sampleIds.push('p16', 'p57', 'p101'); // Sơ mi đi tiệc, quần âu cạp cao, blazer Ý
  } else if (text.includes('công sở') || text.includes('đi làm') || text.includes('sơ mi')) {
    sampleIds.push('p1', 'p51', 'p101'); // Sơ mi Oxford, quần tây, blazer
  } else if (text.includes('đi chơi') || text.includes('dạo phố') || text.includes('polo')) {
    sampleIds.push('p26', 'p76', 'p103'); // Polo cotton, jeans slimfit, bomber
  } else if (text.includes('hè') || text.includes('mát') || text.includes('du lịch')) {
    sampleIds.push('p14', 'p60', 'p122'); // Sơ mi linen, short kaki, blazer linen
  }

  return sampleIds.length > 0 ? findProductsByIds(sampleIds) : [];
}

/**
 * Gọi Gemini AI tư vấn phong cách & kèm sản phẩm thật
 */
export async function askMenlyStylistWithProducts(
  userMessage: string,
  history: ChatHistoryItem[] = []
): Promise<StylistResponse> {
  const client = getAiClient();
  if (!client) {
    return {
      reply: 'Dạ hiện tại kênh AI tư vấn đang tạm ngắt kết nối cấu hình khóa API. Anh vui lòng thử lại sau nhé!',
      suggestedProducts: [],
    };
  }

  try {
    const recentHistory = history.slice(-10).map((item) => ({
      role: item.role === 'model' ? 'model' : 'user',
      parts: [{ text: item.content }],
    }));

    const chat = client.chats.create({
      model: 'gemini-3.5-flash-lite',
      config: {
        systemInstruction: MENLY_SYSTEM_PROMPT,
        temperature: 0.7,
      },
      history: recentHistory,
    });

    const result = await chat.sendMessage({ message: userMessage });
    let rawText = result.text || '';

    // Trích xuất cú pháp [GOI_Y: p1, p51, p101]
    const tagMatch = rawText.match(/\[GOI_Y:\s*([^\]]+)\]/i);
    let suggestedProducts: SuggestedProductItem[] = [];

    if (tagMatch) {
      const rawIds = tagMatch[1].split(',').map((s) => s.trim());
      suggestedProducts = findProductsByIds(rawIds);
      // Xóa thẻ [GOI_Y: ...] khỏi câu trả lời hiển thị cho khách
      rawText = rawText.replace(/\[GOI_Y:\s*([^\]]+)\]/gi, '').trim();
    }

    // Nếu không có tag nhưng câu chuyện xoay quanh phối đồ, kích hoạt gợi ý thông minh
    if (suggestedProducts.length === 0) {
      suggestedProducts = fallbackSuggestedProducts(userMessage, rawText);
    }

    const cleanReply = cleanPlainChatText(rawText);

    return {
      reply: cleanReply || 'Dạ em có thể tư vấn mẫu phù hợp với vóc dáng của anh ngay ạ!',
      suggestedProducts,
    };
  } catch (error: any) {
    console.error('[GeminiService] Lỗi khi tạo câu trả lời:', error?.message || error);
    return {
      reply: 'Dạ hiện tại hệ thống tư vấn đang bận một chút, anh đợi em vài giây rồi thử nhắn lại giúp em nhé! 🙏',
      suggestedProducts: [],
    };
  }
}
