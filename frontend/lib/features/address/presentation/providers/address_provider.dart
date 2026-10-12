import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../data/address_api_service.dart';
import '../../data/address_model.dart';

class AddressProvider extends ChangeNotifier {
  final AddressApiService _service;

  AddressProvider({AddressApiService? service})
      : _service = service ?? AddressApiService();

  List<Address> _addresses = [];
  bool _loading = false;
  bool _loaded = false;
  String? _error;

  List<Address> get addresses => List.unmodifiable(_addresses);
  bool get loading => _loading;
  bool get loaded => _loaded;
  String? get error => _error;

  Address? get defaultAddress {
    if (_addresses.isEmpty) return null;
    for (final a in _addresses) {
      if (a.isDefault) return a;
    }
    return _addresses.first;
  }

  String _msg(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        if (data['error'] is Map && data['error']['message'] != null) {
          return data['error']['message'].toString();
        }
        if (data['message'] != null) return data['message'].toString();
      }
      return e.message ?? 'Đã có lỗi xảy ra. Vui lòng thử lại';
    }
    return e.toString();
  }

  /// Tải danh sách địa chỉ từ server
  Future<void> load({bool force = false}) async {
    if (_loading) return;
    if (_loaded && !force) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _addresses = await _service.getAddresses();
      _loaded = true;
    } catch (e) {
      _error = _msg(e);
      _addresses = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Address> add({
    required String recipientName,
    required String phone,
    required String detailAddress,
    String province = '',
    String district = '',
    String ward = '',
    bool isDefault = false,
  }) async {
    try {
      final created = await _service.create(
        recipientName: recipientName,
        phone: phone,
        detailAddress: detailAddress,
        province: province,
        district: district,
        ward: ward,
        isDefault: isDefault,
      );
      if (created.isDefault) {
        _addresses = _addresses
            .map((a) => Address(
                  id: a.id,
                  recipientName: a.recipientName,
                  phone: a.phone,
                  province: a.province,
                  district: a.district,
                  ward: a.ward,
                  detailAddress: a.detailAddress,
                  isDefault: false,
                ))
            .toList();
      }
      _addresses = [created, ..._addresses];
      _loaded = true;
      notifyListeners();
      return created;
    } catch (e) {
      throw _msg(e);
    }
  }

  Future<Address> updateAddress(
    String id, {
    String? recipientName,
    String? phone,
    String? detailAddress,
    String? province,
    String? district,
    String? ward,
    bool? isDefault,
  }) async {
    try {
      final updated = await _service.update(
        id,
        recipientName: recipientName,
        phone: phone,
        detailAddress: detailAddress,
        province: province,
        district: district,
        ward: ward,
        isDefault: isDefault,
      );
      _replace(updated);
      notifyListeners();
      return updated;
    } catch (e) {
      throw _msg(e);
    }
  }

  Future<void> remove(String id) async {
    try {
      await _service.delete(id);
      final wasDefault = _addresses.any((a) => a.id == id && a.isDefault);
      _addresses = _addresses.where((a) => a.id != id).toList();
      if (wasDefault && _addresses.isNotEmpty) {
        _addresses = [
          Address(
            id: _addresses.first.id,
            recipientName: _addresses.first.recipientName,
            phone: _addresses.first.phone,
            province: _addresses.first.province,
            district: _addresses.first.district,
            ward: _addresses.first.ward,
            detailAddress: _addresses.first.detailAddress,
            isDefault: true,
          ),
          ..._addresses.skip(1),
        ];
      }
      notifyListeners();
    } catch (e) {
      throw _msg(e);
    }
  }

  Future<Address> setDefault(String id) async {
    try {
      final updated = await _service.setDefault(id);
      _addresses = _addresses
          .map((a) => Address(
                id: a.id,
                recipientName: a.recipientName,
                phone: a.phone,
                province: a.province,
                district: a.district,
                ward: a.ward,
                detailAddress: a.detailAddress,
                isDefault: a.id == id,
              ))
          .toList();
      _replace(updated);
      notifyListeners();
      return updated;
    } catch (e) {
      throw _msg(e);
    }
  }

  void _replace(Address updated) {
    _addresses = _addresses
        .map((a) => a.id == updated.id ? updated : a)
        .toList();
  }

  void reset() {
    _addresses = [];
    _loaded = false;
    _error = null;
    notifyListeners();
  }
}
