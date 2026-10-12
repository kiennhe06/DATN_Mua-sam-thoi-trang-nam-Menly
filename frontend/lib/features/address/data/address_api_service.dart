import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import 'address_model.dart';

class AddressApiService {
  final Dio _dio;

  AddressApiService({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  Map<String, dynamic> _unwrap(dynamic data) {
    if (data is Map) {
      final inner = data['data'];
      if (inner is Map) return Map<String, dynamic>.from(inner);
      return Map<String, dynamic>.from(data);
    }
    return <String, dynamic>{};
  }

  /// Lấy danh sách địa chỉ giao hàng của người dùng hiện tại
  Future<List<Address>> getAddresses() async {
    final response = await _dio.get('/addresses');
    final data = response.data;
    final List list = data is List ? data : (data?['data'] ?? []);
    return list
        .map((e) => Address.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Thêm địa chỉ mới
  Future<Address> create({
    required String recipientName,
    required String phone,
    required String detailAddress,
    String province = '',
    String district = '',
    String ward = '',
    bool isDefault = false,
  }) async {
    final response = await _dio.post('/addresses', data: {
      'recipientName': recipientName,
      'phone': phone,
      'province': province,
      'district': district,
      'ward': ward,
      'detailAddress': detailAddress,
      'isDefault': isDefault,
    });
    return Address.fromJson(_unwrap(response.data));
  }

  /// Cập nhật địa chỉ
  Future<Address> update(
    String id, {
    String? recipientName,
    String? phone,
    String? detailAddress,
    String? province,
    String? district,
    String? ward,
    bool? isDefault,
  }) async {
    final payload = <String, dynamic>{};
    if (recipientName != null) payload['recipientName'] = recipientName;
    if (phone != null) payload['phone'] = phone;
    if (detailAddress != null) payload['detailAddress'] = detailAddress;
    if (province != null) payload['province'] = province;
    if (district != null) payload['district'] = district;
    if (ward != null) payload['ward'] = ward;
    if (isDefault != null) payload['isDefault'] = isDefault;

    final response = await _dio.put('/addresses/$id', data: payload);
    return Address.fromJson(_unwrap(response.data));
  }

  /// Xoá địa chỉ
  Future<void> delete(String id) async {
    await _dio.delete('/addresses/$id');
  }

  /// Đặt địa chỉ làm mặc định
  Future<Address> setDefault(String id) async {
    final response = await _dio.put('/addresses/$id/default');
    return Address.fromJson(_unwrap(response.data));
  }
}
