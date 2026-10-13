import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/order_model.dart';
import '../../data/vnpay_bank_model.dart';
import '../../data/vnpay_service.dart';
import '../providers/order_provider.dart';

class VNPayPaymentController extends ChangeNotifier {
  late VNPayBank selectedBank;
  VNPayPaymentCategory selectedCategory = VNPayPaymentCategory.all;
  final TextEditingController searchCtrl = TextEditingController();
  String searchQuery = '';

  int remainingSeconds = 15 * 60;
  Timer? countdownTimer;

  bool isCreatingUrl = false;
  bool isSettling = false;

  VNPayPaymentController() {
    selectedBank = kVNPayBankList.firstWhere(
      (b) => b.isSandboxRecommended,
      orElse: () => kVNPayBankList.first,
    );
    startCountdown();
  }

  void startCountdown() {
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        remainingSeconds--;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  String get formattedTimer {
    final m = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void setSelectedCategory(VNPayPaymentCategory category) {
    selectedCategory = category;
    notifyListeners();
  }

  void setSelectedBank(VNPayBank bank) {
    selectedBank = bank;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  List<VNPayBank> get filteredBanks {
    return kVNPayBankList.where((b) {
      if (selectedCategory == VNPayPaymentCategory.qr && b.category != 'qr') {
        return false;
      }
      if (selectedCategory == VNPayPaymentCategory.atm && b.category != 'atm') {
        return false;
      }
      if (selectedCategory == VNPayPaymentCategory.intl && b.category != 'intl') {
        return false;
      }

      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matchName = b.name.toLowerCase().contains(q);
        final matchFullName = b.fullName.toLowerCase().contains(q);
        final matchCode = b.code.toLowerCase().contains(q);
        return matchName || matchFullName || matchCode;
      }
      return true;
    }).toList();
  }

  Future<String?> createPaymentUrl(
    Order order, {
    required void Function(String msg, {Color? bg}) onMessage,
  }) async {
    isCreatingUrl = true;
    notifyListeners();

    try {
      final url = await VNPayService.instance.createPaymentUrl(
        orderId: order.id,
        bankCode: selectedBank.code,
      );
      return url;
    } catch (e) {
      onMessage(e.toString().replaceAll('Exception: ', ''), bg: Colors.red.shade800);
      return null;
    } finally {
      isCreatingUrl = false;
      notifyListeners();
    }
  }

  Future<void> openVNPaySandboxUrl(
    BuildContext context,
    Order order, {
    required void Function(String msg, {Color? bg}) onMessage,
    required VoidCallback onPostBrowser,
  }) async {
    isCreatingUrl = true;
    notifyListeners();

    try {
      final url = await VNPayService.instance.createPaymentUrl(
        orderId: order.id,
        bankCode: selectedBank.code,
      );

      final uri = Uri.parse(url);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        onMessage('Không thể mở trình duyệt, vui lòng thử lại', bg: Colors.red.shade800);
        return;
      }

      onPostBrowser();
    } catch (e) {
      onMessage(e.toString().replaceAll('Exception: ', ''), bg: Colors.red.shade800);
    } finally {
      isCreatingUrl = false;
      notifyListeners();
    }
  }

  Future<void> completeDemoPayment(
    BuildContext context,
    Order order,
    bool success, {
    required void Function(String msg, {Color? bg}) onMessage,
    required void Function(String path) onNavigate,
  }) async {
    isSettling = true;
    notifyListeners();

    try {
      final res = await VNPayService.instance.settleDemoPayment(
        orderId: order.id,
        success: success,
        bankCode: selectedBank.code,
      );

      if (res.success) {
        if (context.mounted) {
          await context.read<OrderProvider>().markOrderPaid(order.id);
        }
        if (context.mounted) {
          onMessage('🎉 Thanh toán đơn hàng qua VNPay thành công!', bg: Colors.green.shade800);
          onNavigate('/order-success?code=${Uri.encodeComponent(order.code)}&total=${order.total}&vnpay=true');
        }
      } else {
        if (context.mounted) {
          onMessage(res.message, bg: Colors.orange.shade800);
        }
      }
    } catch (e) {
      if (context.mounted) {
        onMessage('Lỗi: $e', bg: Colors.red.shade800);
      }
    } finally {
      isSettling = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    searchCtrl.dispose();
    super.dispose();
  }
}
