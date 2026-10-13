import 'package:flutter/material.dart';

enum VNPayPaymentCategory {
  all,
  qr,
  atm,
  intl,
}

class VNPayBank {
  final String code;
  final String name;
  final String fullName;
  final String category; // 'qr' | 'atm' | 'intl'
  final bool isSandboxRecommended;
  final Color primaryColor;
  final IconData icon;

  const VNPayBank({
    required this.code,
    required this.name,
    required this.fullName,
    required this.category,
    this.isSandboxRecommended = false,
    required this.primaryColor,
    required this.icon,
  });
}

/// Danh sách ngân hàng & phương thức hỗ trợ bởi VNPay Sandbox
final List<VNPayBank> kVNPayBankList = [
  // --- Sandbox Khuyên dùng ---
  const VNPayBank(
    code: 'NCB',
    name: 'NCB',
    fullName: 'Ngân hàng Quốc Dân (Demo Thử Nghiệm)',
    category: 'atm',
    isSandboxRecommended: true,
    primaryColor: Color(0xFF005AAB),
    icon: Icons.account_balance_rounded,
  ),

  // --- VNPAY QR ---
  const VNPayBank(
    code: 'VNPAYQR',
    name: 'VNPAY-QR',
    fullName: 'Quét mã QR qua ứng dụng Ngân hàng / Ví',
    category: 'qr',
    primaryColor: Color(0xFFE11B22),
    icon: Icons.qr_code_scanner_rounded,
  ),

  // --- Ngân hàng nội địa ATM ---
  const VNPayBank(
    code: 'VIETCOMBANK',
    name: 'Vietcombank',
    fullName: 'Ngân hàng TMCP Ngoại Thương Việt Nam',
    category: 'atm',
    primaryColor: Color(0xFF007A33),
    icon: Icons.account_balance_rounded,
  ),
  const VNPayBank(
    code: 'VIETINBANK',
    name: 'VietinBank',
    fullName: 'Ngân hàng TMCP Công Thương Việt Nam',
    category: 'atm',
    primaryColor: Color(0xFF004B87),
    icon: Icons.account_balance_rounded,
  ),
  const VNPayBank(
    code: 'BIDV',
    name: 'BIDV',
    fullName: 'Ngân hàng Đầu tư và Phát triển Việt Nam',
    category: 'atm',
    primaryColor: Color(0xFF006838),
    icon: Icons.account_balance_rounded,
  ),
  const VNPayBank(
    code: 'AGRIBANK',
    name: 'Agribank',
    fullName: 'Ngân hàng Nông nghiệp & Phát triển Nông thôn',
    category: 'atm',
    primaryColor: Color(0xFF8A1538),
    icon: Icons.account_balance_rounded,
  ),
  const VNPayBank(
    code: 'TECHCOMBANK',
    name: 'Techcombank',
    fullName: 'Ngân hàng TMCP Kỹ Thương Việt Nam',
    category: 'atm',
    primaryColor: Color(0xFFE31837),
    icon: Icons.account_balance_rounded,
  ),
  const VNPayBank(
    code: 'MBBANK',
    name: 'MBBank',
    fullName: 'Ngân hàng TMCP Quân Đội',
    category: 'atm',
    primaryColor: Color(0xFF1D39C4),
    icon: Icons.account_balance_rounded,
  ),
  const VNPayBank(
    code: 'ACB',
    name: 'ACB',
    fullName: 'Ngân hàng TMCP Á Châu',
    category: 'atm',
    primaryColor: Color(0xFF0066B2),
    icon: Icons.account_balance_rounded,
  ),
  const VNPayBank(
    code: 'VPBANK',
    name: 'VPBank',
    fullName: 'Ngân hàng TMCP Việt Nam Thịnh Vượng',
    category: 'atm',
    primaryColor: Color(0xFF00A651),
    icon: Icons.account_balance_rounded,
  ),
  const VNPayBank(
    code: 'TPBANK',
    name: 'TPBank',
    fullName: 'Ngân hàng TMCP Tiên Phong',
    category: 'atm',
    primaryColor: Color(0xFF782F8F),
    icon: Icons.account_balance_rounded,
  ),
  const VNPayBank(
    code: 'SACOMBANK',
    name: 'Sacombank',
    fullName: 'Ngân hàng TMCP Sài Gòn Thương Tín',
    category: 'atm',
    primaryColor: Color(0xFF004D99),
    icon: Icons.account_balance_rounded,
  ),
  const VNPayBank(
    code: 'HDBANK',
    name: 'HDBank',
    fullName: 'Ngân hàng TMCP Phát triển TP.HCM',
    category: 'atm',
    primaryColor: Color(0xFFED1C24),
    icon: Icons.account_balance_rounded,
  ),
  const VNPayBank(
    code: 'VIB',
    name: 'VIB',
    fullName: 'Ngân hàng TMCP Quốc tế Việt Nam',
    category: 'atm',
    primaryColor: Color(0xFF004F9E),
    icon: Icons.account_balance_rounded,
  ),

  // --- Thẻ quốc tế ---
  const VNPayBank(
    code: 'INTCARD',
    name: 'Visa / Master / JCB',
    fullName: 'Thẻ thanh toán quốc tế Visa, MasterCard, JCB',
    category: 'intl',
    primaryColor: Color(0xFF1A1F71),
    icon: Icons.credit_card_rounded,
  ),
];
