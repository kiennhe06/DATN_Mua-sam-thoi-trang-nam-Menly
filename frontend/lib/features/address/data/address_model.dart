class Address {
  final String id;
  final String recipientName;
  final String phone;
  final String province;
  final String district;
  final String ward;
  final String detailAddress;
  final bool isDefault;

  Address({
    required this.id,
    required this.recipientName,
    required this.phone,
    this.province = '',
    this.district = '',
    this.ward = '',
    required this.detailAddress,
    this.isDefault = false,
  });

  /// Địa chỉ đầy đủ để hiển thị (chi tiết, phường/xã, quận/huyện, tỉnh/thành)
  String get fullAddress {
    final parts = [detailAddress, ward, district, province]
        .where((e) => e.trim().isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  factory Address.fromJson(Map<String, dynamic> j) => Address(
        id: (j['id'] ?? '').toString(),
        recipientName: (j['recipientName'] ??
                j['recipient_name'] ??
                j['name'] ??
                '')
            .toString(),
        phone: (j['phone'] ?? '').toString(),
        province: (j['province'] ?? '').toString(),
        district: (j['district'] ?? '').toString(),
        ward: (j['ward'] ?? '').toString(),
        detailAddress: (j['detailAddress'] ??
                j['detail_address'] ??
                j['address'] ??
                '')
            .toString(),
        isDefault: j['isDefault'] == true || j['is_default'] == true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipientName': recipientName,
        'phone': phone,
        'province': province,
        'district': district,
        'ward': ward,
        'detailAddress': detailAddress,
        'isDefault': isDefault,
      };
}
