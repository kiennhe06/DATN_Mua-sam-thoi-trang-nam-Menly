import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/auth_guard.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../cart/data/cart_model.dart';
import '../../data/order_model.dart';
import '../../data/voucher_model.dart';
import '../providers/order_provider.dart';

class CheckoutController extends ChangeNotifier {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  final voucherCtrl = TextEditingController();

  String paymentMethod = 'cod';
  bool loading = false;

  List<Map<String, dynamic>> savedAddresses = [];
  int defaultAddressIndex = 0;
  int? selectedAddressIndex;
  bool useManualAddress = false;
  bool saveAsDefault = false;

  Voucher? appliedVoucher;
  int discountAmount = 0;
  bool applyingVoucher = false;
  List<Voucher> availableVouchers = [];
  bool loadingVouchers = false;

  void setPaymentMethod(String method) {
    if (paymentMethod != method) {
      paymentMethod = method;
      notifyListeners();
    }
  }

  void setSaveAsDefault(bool value) {
    saveAsDefault = value;
    notifyListeners();
  }

  Future<void> init(BuildContext context) async {
    if (!AuthGuard.check(
      context,
      actionTitle: 'Đăng nhập để đặt hàng',
      actionMessage:
          'Bạn đang duyệt ẩn danh. Vui lòng đăng nhập tài khoản để tiến hành đặt hàng.',
      redirectPath: '/checkout',
    )) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/cart');
      }
      return;
    }

    final auth = context.read<AuthProvider>();
    if (auth.user != null && nameCtrl.text.isEmpty) {
      nameCtrl.text = auth.user!.fullName;
      notifyListeners();
    }

    await loadSavedAddresses();
    await loadAvailableVouchers();
  }

  Future<void> loadSavedAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('shippingAddresses');
      final defIdx = prefs.getInt('defaultAddressIndex') ?? 0;
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          savedAddresses = List<Map<String, dynamic>>.from(decoded);
        }
      }
      defaultAddressIndex = defIdx;
      if (savedAddresses.isNotEmpty) {
        final targetIdx =
            (defaultAddressIndex >= 0 && defaultAddressIndex < savedAddresses.length)
                ? defaultAddressIndex
                : 0;
        selectAddress(targetIdx);
      }

      // Đồng bộ địa chỉ mới nhất từ server
      try {
        final dio = DioClient().dio;
        final res = await dio.get('/addresses');
        if (res.statusCode == 200 && res.data != null) {
          final list = (res.data['data'] as List<dynamic>?) ?? [];
          if (list.isNotEmpty) {
            final serverList = list.map((item) {
              final m = item as Map<String, dynamic>;
              return {
                'id': m['id']?.toString() ?? '',
                'name': m['recipientName'] ?? m['name'] ?? '',
                'phone': m['phone'] ?? '',
                'address': m['detailAddress'] ?? m['address'] ?? '',
                'isDefault': m['isDefault'] == true,
              };
            }).toList();

            savedAddresses = serverList;
            final foundDef = savedAddresses.indexWhere((a) => a['isDefault'] == true);
            defaultAddressIndex = foundDef >= 0 ? foundDef : 0;
            final targetIdx = (defaultAddressIndex >= 0 && defaultAddressIndex < savedAddresses.length)
                ? defaultAddressIndex
                : 0;
            selectAddress(targetIdx);

            final p = await SharedPreferences.getInstance();
            await p.setString('shippingAddresses', jsonEncode(savedAddresses));
            await p.setInt('defaultAddressIndex', defaultAddressIndex);
          }
        }
      } catch (_) {}
    } catch (_) {}
    notifyListeners();
  }

  void selectAddress(int index) {
    if (index >= 0 && index < savedAddresses.length) {
      final addr = savedAddresses[index];
      selectedAddressIndex = index;
      useManualAddress = false;
      nameCtrl.text = addr['name']?.toString() ?? '';
      phoneCtrl.text = addr['phone']?.toString() ?? '';
      addressCtrl.text = addr['address']?.toString() ?? '';
      notifyListeners();
    }
  }

  void setUseManualAddress(bool manual, {String? defaultName}) {
    useManualAddress = manual;
    if (manual) {
      nameCtrl.clear();
      phoneCtrl.clear();
      addressCtrl.clear();
      if (defaultName != null && defaultName.isNotEmpty) {
        nameCtrl.text = defaultName;
      }
    }
    notifyListeners();
  }

  Future<void> loadAvailableVouchers() async {
    loadingVouchers = true;
    notifyListeners();

    try {
      final res = await DioClient.instance.dio.get('/vouchers');
      if (res.data is List) {
        final list = (res.data as List).map((j) => Voucher.fromJson(j)).toList();
        availableVouchers = list.where((v) => v.isActive).toList();
      }
    } catch (_) {
      availableVouchers = [
        Voucher(
          id: 'vch-1',
          code: 'MENLY10',
          title: 'Giảm 10% tối đa 50k cho đơn từ 200k',
          discountType: 'percentage',
          discountValue: 10,
          minOrderValue: 200000,
          maxDiscount: 50000,
          usageLimit: 100,
          usedCount: 0,
          startDate: '2026-01-01',
          endDate: '2026-12-31',
          isActive: true,
        ),
        Voucher(
          id: 'vch-2',
          code: 'MENLY50K',
          title: 'Giảm ngay 50.000đ cho đơn từ 300k',
          discountType: 'fixed_amount',
          discountValue: 50000,
          minOrderValue: 300000,
          maxDiscount: 50000,
          usageLimit: 50,
          usedCount: 0,
          startDate: '2026-01-01',
          endDate: '2026-12-31',
          isActive: true,
        ),
        Voucher(
          id: 'vch-3',
          code: 'FREESHIP',
          title: 'Miễn phí vận chuyển (giảm 30.000đ)',
          discountType: 'fixed_amount',
          discountValue: 30000,
          minOrderValue: 250000,
          maxDiscount: 30000,
          usageLimit: 200,
          usedCount: 0,
          startDate: '2026-01-01',
          endDate: '2026-12-31',
          isActive: true,
        ),
        Voucher(
          id: 'vch-4',
          code: 'VIP100K',
          title: 'Giảm 100k cho khách VIP đơn từ 800k',
          discountType: 'fixed_amount',
          discountValue: 100000,
          minOrderValue: 800000,
          maxDiscount: 100000,
          usageLimit: 30,
          usedCount: 0,
          startDate: '2026-01-01',
          endDate: '2026-12-31',
          isActive: true,
        ),
      ];
    } finally {
      loadingVouchers = false;
      notifyListeners();
    }
  }

  Future<void> applyVoucher(
    String rawCode,
    int subtotal, {
    required void Function(String msg, {Color? bg}) onMessage,
  }) async {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      onMessage('Vui lòng nhập mã giảm giá');
      return;
    }

    applyingVoucher = true;
    notifyListeners();

    try {
      final res = await DioClient.instance.dio.post('/vouchers/apply', data: {
        'code': code,
        'subtotal': subtotal,
      });

      if (res.data != null && res.data['valid'] == true) {
        final disc = (res.data['discountAmount'] as num?)?.toInt() ?? 0;
        final vData = res.data['voucher'];
        final v = vData != null ? Voucher.fromJson(vData) : null;
        appliedVoucher = v ??
            Voucher(
              id: 'custom',
              code: code,
              title: 'Mã giảm giá $code',
              discountType: 'fixed_amount',
              discountValue: disc,
              minOrderValue: 0,
              usageLimit: 100,
              usedCount: 0,
              startDate: '',
              endDate: '',
              isActive: true,
            );
        discountAmount = disc;
        notifyListeners();
        onMessage('Áp dụng thành công mã "$code"!', bg: Colors.green.shade800);
        return;
      }
    } catch (e) {
      final found = availableVouchers.firstWhere(
        (v) => v.code.toUpperCase() == code,
        orElse: () => Voucher(
          id: '',
          code: '',
          title: '',
          discountType: '',
          discountValue: 0,
          minOrderValue: 0,
          usageLimit: 0,
          usedCount: 0,
          startDate: '',
          endDate: '',
          isActive: false,
        ),
      );

      if (found.code.isNotEmpty) {
        if (subtotal < found.minOrderValue) {
          onMessage(
            'Mã này chỉ áp dụng cho đơn hàng từ ${found.minOrderValue}đ',
            bg: Colors.red.shade800,
          );
          return;
        }
        final disc = found.calculateDiscount(subtotal);
        appliedVoucher = found;
        discountAmount = disc;
        notifyListeners();
        onMessage('Áp dụng thành công mã "$code"!', bg: Colors.green.shade800);
        return;
      }

      String errMsg = 'Mã giảm giá "$code" không hợp lệ';
      if (e is DioException && e.response?.data != null) {
        final d = e.response!.data;
        errMsg = d['error']?['message'] ?? d['message'] ?? errMsg;
      }
      onMessage(errMsg, bg: Colors.red.shade800);
    } finally {
      applyingVoucher = false;
      notifyListeners();
    }
  }

  void removeVoucher({required void Function(String msg) onMessage}) {
    appliedVoucher = null;
    discountAmount = 0;
    voucherCtrl.clear();
    notifyListeners();
    onMessage('Đã gỡ bỏ mã giảm giá');
  }

  Future<void> placeOrder(
    BuildContext context,
    CartProvider cart, {
    required void Function(String msg, {Color? bg}) onMessage,
  }) async {
    if (!AuthGuard.check(
      context,
      actionTitle: 'Đăng nhập để đặt hàng',
      actionMessage:
          'Bạn đang duyệt ẩn danh. Vui lòng đăng nhập để hoàn tất đơn hàng.',
      redirectPath: '/checkout',
    )) {
      return;
    }

    final name = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    final address = addressCtrl.text.trim();

    if (name.length < 2) {
      onMessage('Vui lòng nhập họ và tên (tối thiểu 2 ký tự)');
      return;
    }
    if (phone.length < 9) {
      onMessage('Vui lòng nhập số điện thoại hợp lệ (tối thiểu 9 số)');
      return;
    }
    if (address.length < 5) {
      onMessage('Vui lòng nhập địa chỉ giao hàng cụ thể (tối thiểu 5 ký tự)');
      return;
    }

    if (cart.selectedItems.isEmpty) {
      onMessage('Vui lòng chọn ít nhất 1 sản phẩm để thanh toán');
      return;
    }

    loading = true;
    notifyListeners();

    final orderedVariantIds =
        cart.selectedItems.map((i) => i.variant.id).toList();
    final items = cart.selectedItems
        .map((i) => {
              'variantId': i.variant.id,
              'quantity': i.quantity,
              'unitPrice': i.product.price,
              'productName': i.product.name,
              'size': i.variant.size,
              'color': i.variant.color,
            })
        .toList();

    if (saveAsDefault || savedAddresses.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final newAddr = {'name': name, 'phone': phone, 'address': address};
        final exists = savedAddresses.any((a) => a['address'] == address && a['phone'] == phone);
        if (!exists) {
          savedAddresses.insert(0, newAddr);
          await prefs.setString('shippingAddresses', jsonEncode(savedAddresses));
          await prefs.setInt('defaultAddressIndex', 0);
        }
      } catch (_) {}
    }

    try {
      final res = await DioClient.instance.dio.post('/orders', data: {
        'items': items,
        'paymentMethod': paymentMethod,
        'ship': {
          'name': name,
          'phone': phone,
          'address': address,
        },
        'note': noteCtrl.text.trim(),
        'voucherCode': appliedVoucher?.code,
        'discountAmount': discountAmount,
      });

      if (res.statusCode == 201 || res.statusCode == 200) {
        await cart.removeMany(orderedVariantIds);
        final orderData = res.data is Map ? (res.data as Map<String, dynamic>) : null;
        if (orderData != null && context.mounted) {
          final createdOrder = Order.fromJson(orderData);
          await context.read<OrderProvider>().addPlacedOrder(createdOrder);
          if (context.mounted) {
            if (paymentMethod == 'vnpay') {
              context.push('/payment/vnpay', extra: createdOrder);
            } else {
              context.go('/order-success?code=${Uri.encodeComponent(createdOrder.code)}&total=${createdOrder.total}');
            }
          }
        } else if (context.mounted) {
          context.go('/order-success');
        }
      } else {
        throw Exception('Đặt hàng thất bại');
      }
    } catch (e) {
      if (context.mounted) {
        String msg = e.toString();
        if (e is DioException) {
          final resData = e.response?.data;
          if (resData is Map && resData['message'] != null) {
            msg = resData['message'].toString();
          } else if (resData is Map && resData['error'] != null) {
            msg = resData['error'].toString();
          } else {
            msg = e.message ?? e.error?.toString() ?? 'Đã có lỗi xảy ra khi tạo đơn hàng';
          }
        }
        onMessage(msg, bg: Colors.red.shade800);
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    noteCtrl.dispose();
    voucherCtrl.dispose();
    super.dispose();
  }
}
