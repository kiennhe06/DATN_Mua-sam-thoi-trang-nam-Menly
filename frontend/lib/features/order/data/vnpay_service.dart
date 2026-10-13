import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class VNPayPaymentResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  const VNPayPaymentResult({
    required this.success,
    required this.message,
    this.data,
  });
}

class VNPayService {
  final DioClient _dioClient;

  VNPayService({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient.instance;

  static final VNPayService instance = VNPayService();

  /// Tạo link thanh toán VNPay Sandbox chính thức từ Backend
  Future<String> createPaymentUrl({
    required String orderId,
    String? bankCode,
  }) async {
    try {
      final res = await _dioClient.dio.post(
        '/payments/vnpay/create',
        data: {
          'orderId': orderId,
          if (bankCode != null && bankCode.trim().isNotEmpty)
            'bankCode': bankCode.trim(),
        },
      );

      final data = res.data;
      if (data is Map && data['paymentUrl'] != null) {
        return data['paymentUrl'].toString();
      }
      throw Exception('Không tìm thấy link thanh toán VNPay');
    } on DioException catch (e) {
      final err = e.response?.data;
      final msg = (err is Map && (err['message'] ?? err['error']) != null)
          ? (err['message'] ?? err['error']).toString()
          : (e.message ?? 'Lỗi kết nối cổng thanh toán VNPay');
      throw Exception(msg);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Mô phỏng thanh toán Demo Sandbox hoàn tất trực tiếp trong App
  Future<VNPayPaymentResult> settleDemoPayment({
    required String orderId,
    bool success = true,
    String? bankCode,
  }) async {
    try {
      final res = await _dioClient.dio.post(
        '/payments/vnpay/demo-settle',
        data: {
          'orderId': orderId,
          'success': success,
          if (bankCode != null && bankCode.trim().isNotEmpty)
            'bankCode': bankCode.trim(),
        },
      );

      final data = res.data is Map ? (res.data as Map<String, dynamic>) : null;
      return VNPayPaymentResult(
        success: data?['success'] == true,
        message: data?['message']?.toString() ??
            (success
                ? 'Thanh toán Demo Sandbox thành công!'
                : 'Mô phỏng hủy giao dịch thành công.'),
        data: data,
      );
    } on DioException catch (e) {
      final err = e.response?.data;
      final msg = (err is Map && (err['message'] ?? err['error']) != null)
          ? (err['message'] ?? err['error']).toString()
          : (e.message ?? 'Lỗi khi mô phỏng thanh toán');
      return VNPayPaymentResult(
        success: false,
        message: msg,
      );
    } catch (e) {
      return VNPayPaymentResult(
        success: false,
        message: e.toString(),
      );
    }
  }
}
