import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/chat_message_model.dart';

class AiChatService {
  final Dio _dio;

  AiChatService({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  /// Gửi câu hỏi kèm lịch sử hội thoại gần nhất đến Gemini AI Backend
  Future<({String reply, List<SuggestedProductItem> suggestedProducts})>
      askAssistant({
    required String message,
    List<Map<String, String>> history = const [],
  }) async {
    try {
      final response = await _dio.post(
        '/ai-chat/message',
        data: {
          'message': message,
          'history': history,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && data['reply'] != null) {
          final replyText = data['reply'].toString();
          List<SuggestedProductItem> products = [];

          if (data['suggestedProducts'] is List) {
            products = (data['suggestedProducts'] as List)
                .map((p) =>
                    SuggestedProductItem.fromJson(p as Map<String, dynamic>))
                .toList();
          }

          return (reply: replyText, suggestedProducts: products);
        }
      }
      throw 'Không nhận được câu trả lời từ máy chủ';
    } catch (e) {
      rethrow;
    }
  }
}
