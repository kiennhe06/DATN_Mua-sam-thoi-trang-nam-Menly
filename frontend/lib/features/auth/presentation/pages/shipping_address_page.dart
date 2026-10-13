import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/state_views.dart';
import '../widgets/address_card_item.dart';
import '../widgets/address_delete_dialog.dart';
import '../widgets/address_form_sheet.dart';

class ShippingAddressPage extends StatefulWidget {
  const ShippingAddressPage({super.key});
  @override
  State<ShippingAddressPage> createState() => _ShippingAddressPageState();
}

class _ShippingAddressPageState extends State<ShippingAddressPage> {
  List<Map<String, dynamic>> _addresses = [];
  int _defaultIndex = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('shippingAddresses');
    _defaultIndex = prefs.getInt('defaultAddressIndex') ?? 0;
    if (raw != null) {
      try {
        _addresses = List<Map<String, dynamic>>.from(jsonDecode(raw));
      } catch (_) {}
    }

    try {
      final dio = DioClient().dio;
      final res = await dio.get('/addresses');
      if (res.statusCode == 200 && res.data != null) {
        final list = (res.data['data'] as List<dynamic>?) ?? [];
        if (list.isNotEmpty) {
          _addresses = list.map((item) {
            final m = item as Map<String, dynamic>;
            return {
              'id': m['id']?.toString() ?? '',
              'name': m['recipientName'] ?? m['name'] ?? '',
              'phone': m['phone'] ?? '',
              'address': m['detailAddress'] ?? m['address'] ?? '',
              'isDefault': m['isDefault'] == true,
            };
          }).toList();
          final defIdx = _addresses.indexWhere((a) => a['isDefault'] == true);
          _defaultIndex = defIdx >= 0 ? defIdx : 0;
          await _saveAddressesToLocal();
        }
      }
    } catch (e) {
      debugPrint('[ShippingAddress] API load failed, using local: $e');
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveAddressesToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shippingAddresses', jsonEncode(_addresses));
    await prefs.setInt('defaultAddressIndex', _defaultIndex);
  }

  void _addOrEditAddress({int? editIndex}) {
    final isEdit = editIndex != null;
    final existing = isEdit ? _addresses[editIndex] : null;

    AddressFormSheet.show(
      context: context,
      existing: existing,
      onSubmit: ({
        required String name,
        required String phone,
        required String address,
      }) async {
        final c = AppColors.of(context);
        final newAddr = {
          'id': existing?['id'] ??
              'local-${DateTime.now().millisecondsSinceEpoch}',
          'name': name,
          'phone': phone,
          'address': address,
          'isDefault': existing?['isDefault'] ?? (_addresses.isEmpty),
        };

        setState(() {
          if (isEdit) {
            _addresses[editIndex] = newAddr;
          } else {
            _addresses.add(newAddr);
            if (_addresses.length == 1) _defaultIndex = 0;
          }
        });
        await _saveAddressesToLocal();

        // Sync to Backend API
        try {
          final dio = DioClient().dio;
          if (isEdit &&
              existing?['id'] != null &&
              !existing!['id'].toString().startsWith('local-')) {
            await dio.put('/addresses/${existing['id']}', data: {
              'recipientName': name,
              'phone': phone,
              'detailAddress': address,
            });
          } else {
            final res = await dio.post('/addresses', data: {
              'recipientName': name,
              'phone': phone,
              'detailAddress': address,
              'isDefault': _addresses.length == 1,
            });
            if (res.statusCode == 201 && res.data?['data']?['id'] != null) {
              newAddr['id'] = res.data['data']['id'].toString();
              await _saveAddressesToLocal();
            }
          }
        } catch (e) {
          debugPrint('[ShippingAddress] Sync error: $e');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEdit
                    ? 'Cập nhật địa chỉ thành công'
                    : 'Đã thêm địa chỉ mới',
              ),
              backgroundColor: c.secondary,
            ),
          );
        }
      },
    );
  }

  void _deleteAddress(int index) {
    final target = _addresses[index];
    AddressDeleteDialog.show(
      context: context,
      addressTitle: target['address'] ?? '',
      onConfirm: () async {
        final c = AppColors.of(context);
        setState(() {
          _addresses.removeAt(index);
          if (_defaultIndex >= _addresses.length) {
            _defaultIndex = _addresses.isEmpty ? 0 : _addresses.length - 1;
          }
        });
        await _saveAddressesToLocal();

        // Sync delete with backend API
        final targetId = target['id']?.toString();
        if (targetId != null && !targetId.startsWith('local-')) {
          try {
            await DioClient().dio.delete('/addresses/$targetId');
          } catch (e) {
            debugPrint('[ShippingAddress] Delete API error: $e');
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Đã xoá địa chỉ'),
              backgroundColor: c.danger,
            ),
          );
        }
      },
    );
  }

  Future<void> _setDefaultAddress(int index) async {
    final c = AppColors.of(context);
    setState(() {
      _defaultIndex = index;
      for (int i = 0; i < _addresses.length; i++) {
        _addresses[i]['isDefault'] = (i == index);
      }
    });
    await _saveAddressesToLocal();

    final target = _addresses[index];
    final targetId = target['id']?.toString();
    if (targetId != null && !targetId.startsWith('local-')) {
      try {
        await DioClient().dio.patch('/addresses/$targetId/default');
      } catch (e) {
        debugPrint('[ShippingAddress] Set default API error: $e');
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã đặt làm địa chỉ mặc định'),
          backgroundColor: c.secondary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: const Text('Địa chỉ giao hàng'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: c.secondary),
            onPressed: () => _addOrEditAddress(),
          ),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _addresses.isEmpty
              ? StatusView(
                  icon: Icons.location_off_rounded,
                  title: 'Chưa có địa chỉ nào',
                  message:
                      'Thêm địa chỉ giao hàng để đặt hàng nhanh chóng và chính xác',
                  actionLabel: 'Thêm địa chỉ mới',
                  onAction: () => _addOrEditAddress(),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: _addresses.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (_, i) => AddressCardItem(
                    address: _addresses[i],
                    isDefault:
                        i == _defaultIndex || _addresses[i]['isDefault'] == true,
                    onSetDefault: () => _setDefaultAddress(i),
                    onEdit: () => _addOrEditAddress(editIndex: i),
                    onDelete: () => _deleteAddress(i),
                  ),
                ),
    );
  }
}
