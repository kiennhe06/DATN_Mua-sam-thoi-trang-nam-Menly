import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/api_config.dart';

class DioClient {
  late final Dio dio;

  DioClient({String? baseUrl}) {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiConfig.apiBase,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          String? token;

          // 1. Thử lấy token từ phiên Supabase Auth (chỉ lấy nếu là người dùng thật, không phải ẩn danh)
          try {
            final session = Supabase.instance.client.auth.currentSession;
            if (session != null && session.user.isAnonymous != true && session.user.email != null && session.user.email!.isNotEmpty) {
              token = session.accessToken;
            }
          } catch (_) {
            // Supabase chưa khởi tạo hoặc chưa đăng nhập
          }

          // 2. Nếu Supabase không có token người dùng thật, lấy từ SharedPreferences
          if (token == null || token.isEmpty) {
            try {
              final prefs = await SharedPreferences.getInstance();
              token = prefs.getString('access_token') ??
                  prefs.getString('token') ??
                  prefs.getString('accessToken');
              if ((token == null || token.isEmpty) && prefs.getString('user_email') != null) {
                final uid = prefs.getString('user_id') ?? '00000000-0000-0000-0000-000000000002';
                token = 'mock-user-token-$uid';
              }
              if (token == null || token.isEmpty) {
                token = 'guest-token';
              }
            } catch (_) {
              token = 'guest-token';
            }
          }

          // 3. Gắn Authorization Header nếu có token
          if (token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // 4. Thêm headers định danh x-user-email và x-user-id nếu có
          try {
            final prefs = await SharedPreferences.getInstance();
            final userEmail = prefs.getString('user_email');
            final userId = prefs.getString('user_id');
            if (userEmail != null && userEmail.isNotEmpty) {
              options.headers['x-user-email'] = userEmail;
            }
            if (userId != null && userId.isNotEmpty) {
              options.headers['x-user-id'] = userId;
            }
          } catch (_) {}

          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Xử lý và chuẩn hóa thông báo lỗi thân thiện cho người dùng
          String friendlyMsg = 'Đã có lỗi xảy ra. Vui lòng thử lại';

          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout) {
            friendlyMsg = 'Kết nối mạng quá hạn. Vui lòng kiểm tra lại đường truyền';
          } else if (e.type == DioExceptionType.connectionError) {
            friendlyMsg = 'Không thể kết nối đến máy chủ (${ApiConfig.baseUrl})';
          } else if (e.response != null) {
            final statusCode = e.response?.statusCode;
            final data = e.response?.data;

            if (data is Map) {
              if (data['error'] is Map && data['error']['message'] != null) {
                friendlyMsg = data['error']['message'].toString();
                if (data['error']['details'] is List && (data['error']['details'] as List).isNotEmpty) {
                  final details = (data['error']['details'] as List)
                      .map((d) => d is Map ? (d['message'] ?? d.toString()) : d.toString())
                      .join(', ');
                  friendlyMsg = '$friendlyMsg ($details)';
                }
              } else if (data['message'] != null) {
                friendlyMsg = data['message'].toString();
              }
            }

            if (friendlyMsg == 'Đã có lỗi xảy ra. Vui lòng thử lại') {
              if (statusCode == 401) {
                friendlyMsg = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại';
              } else if (statusCode == 403) {
                friendlyMsg = 'Bạn cần đăng nhập tài khoản để đặt hàng';
              } else if (statusCode == 404) {
                friendlyMsg = 'Không tìm thấy dữ liệu yêu cầu';
              } else if (statusCode == 500) {
                friendlyMsg = 'Lỗi hệ thống máy chủ. Vui lòng thử lại sau';
              }
            }
          }

          final customException = DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            type: e.type,
            error: friendlyMsg,
            message: friendlyMsg,
          );

          return handler.next(customException);
        },
      ),
    );
  }

  // Singleton instance tiện lợi
  static final DioClient _instance = DioClient();
  static DioClient get instance => _instance;

  /// Trích xuất và làm sạch thông báo lỗi thân thiện cho người dùng,
  /// loại bỏ các tiền tố kỹ thuật như `DioException [bad response]:` hay `Error: ...`.
  static String cleanErrorMessage(dynamic e, [String fallback = 'Đã có lỗi xảy ra. Vui lòng thử lại']) {
    if (e == null) return fallback;

    if (e is DioException) {
      if (e.message != null &&
          e.message!.trim().isNotEmpty &&
          !e.message!.startsWith('DioException')) {
        return e.message!.trim();
      }
      if (e.error is String &&
          (e.error as String).trim().isNotEmpty &&
          !(e.error as String).startsWith('DioException')) {
        return (e.error as String).trim();
      }
      final data = e.response?.data;
      if (data is Map) {
        if (data['error'] is Map && data['error']['message'] != null) {
          return data['error']['message'].toString();
        }
        if (data['message'] != null) {
          return data['message'].toString();
        }
      }
    }

    String str = e.toString().trim();
    if (str.startsWith('Exception: ')) {
      str = str.substring('Exception: '.length).trim();
    }
    final dioMatch = RegExp(r'^DioException\s*\[[^\]]*\]:\s*').firstMatch(str);
    if (dioMatch != null) {
      str = str.substring(dioMatch.end).trim();
    }
    if (str.contains('\nError: ')) {
      str = str.split('\nError: ').first.trim();
    } else if (str.startsWith('Error: ')) {
      str = str.substring('Error: '.length).trim();
    }

    return str.isNotEmpty ? str : fallback;
  }
}
