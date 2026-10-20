import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format.dart';
import '../../data/order_model.dart';
import '../../data/vnpay_service.dart';
import '../providers/order_provider.dart';
import 'vnpay_payment_page.dart';

/// Trang thanh toán VNPay trực tuyến tích hợp flutter_inappwebview chính thức
class VNPayWebViewPage extends StatefulWidget {
  final Order order;
  final String? paymentUrl;
  final String? bankCode;

  const VNPayWebViewPage({
    super.key,
    required this.order,
    this.paymentUrl,
    this.bankCode,
  });

  @override
  State<VNPayWebViewPage> createState() => _VNPayWebViewPageState();
}

class _VNPayWebViewPageState extends State<VNPayWebViewPage> {
  InAppWebViewController? _webViewController;
  double _progress = 0;
  bool _isLoading = true;
  bool _isGeneratingUrl = false;
  String? _currentUrl;
  String? _urlError;
  bool _hasHandledResult = false;
  bool _showCredentialsCard = false;
  bool _isSettlingDemo = false;
  bool _isVnpayUnapproved = false;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.paymentUrl;
    if (_currentUrl == null || _currentUrl!.trim().isEmpty) {
      _generatePaymentUrl();
    } else {
      _isLoading = true;
    }
  }

  Future<void> _generatePaymentUrl() async {
    setState(() {
      _isGeneratingUrl = true;
      _urlError = null;
    });

    try {
      final url = await VNPayService.instance.createPaymentUrl(
        orderId: widget.order.id,
        bankCode: widget.bankCode,
      );
      if (!mounted) return;
      setState(() {
        _currentUrl = url;
        _isGeneratingUrl = false;
        _isLoading = true;
      });

      if (_webViewController != null) {
        await _webViewController!.loadUrl(
          urlRequest: URLRequest(url: WebUri(url)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGeneratingUrl = false;
        _urlError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  bool _handleReturnUrl(WebUri uri) {
    if (_hasHandledResult) return true;

    final query = uri.queryParameters;
    final responseCode = query['vnp_ResponseCode'];

    final isReturnEndpoint = uri.path.contains('/payments/vnpay/return') ||
        uri.path.contains('vnpay_return') ||
        uri.host.contains('localhost') ||
        uri.host.contains('10.0.2.2');

    if (responseCode != null || isReturnEndpoint) {
      _hasHandledResult = true;

      if (responseCode == '00') {
        _handleSuccess(bankCode: query['vnp_BankCode']);
      } else {
        _handleFailure(responseCode ?? 'unknown');
      }
      return true;
    }

    return false;
  }

  void _handleSuccess({String? bankCode}) async {
    if (!mounted) return;
    try {
      // 1. Đồng bộ lên backend để database chuyển sang paid
      await VNPayService.instance.settleDemoPayment(
        orderId: widget.order.id,
        success: true,
        bankCode: bankCode ?? widget.bankCode ?? 'NCB',
      );
    } catch (_) {}

    if (!mounted) return;
    try {
      // 2. Cập nhật trạng thái đơn hàng trên app
      await context.read<OrderProvider>().markOrderPaid(widget.order.id);
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Thanh toán VNPay thành công! Đơn hàng đã được xác nhận.'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    context.go(
      '/order-success?code=${Uri.encodeComponent(widget.order.code)}&total=${widget.order.total}&vnpay=true',
    );
  }

  void _handleFailure(String code) {
    if (!mounted) return;

    String message = 'Giao dịch không thành công';
    switch (code) {
      case '24':
        message = 'Bạn đã hủy giao dịch thanh toán VNPay.';
        break;
      case '51':
        message = 'Tài khoản không đủ số dư để thực hiện giao dịch.';
        break;
      case '11':
        message = 'Đã hết thời hạn chờ thanh toán.';
        break;
      case '65':
        message = 'Tài khoản đã vượt quá hạn mức giao dịch trong ngày.';
        break;
      case '75':
        message = 'Ngân hàng thanh toán đang bảo trì.';
        break;
      default:
        message = 'Thanh toán VNPay không thành công (Mã: $code).';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );

    context.pop();
  }

  Future<void> _settleDemoDirectly() async {
    setState(() => _isSettlingDemo = true);
    try {
      final res = await VNPayService.instance.settleDemoPayment(
        orderId: widget.order.id,
        success: true,
        bankCode: widget.bankCode ?? 'NCB',
      );

      if (res.success && mounted) {
        await context.read<OrderProvider>().markOrderPaid(widget.order.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Mô phỏng thanh toán VNPay Sandbox thành công!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go(
          '/order-success?code=${Uri.encodeComponent(widget.order.code)}&total=${widget.order.total}&vnpay=true',
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message),
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSettlingDemo = false);
      }
    }
  }

  Future<bool> _onWillPop() async {
    final c = AppColors.of(context);
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Thoát phiên thanh toán?'),
        content: const Text(
          'Giao dịch VNPay của bạn đang được thực hiện. Bạn có chắc muốn quay lại không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tiếp tục thanh toán'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Thoát'),
          ),
        ],
      ),
    );
    return shouldLeave ?? false;
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label: $text'),
        duration: const Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF005BAA),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Đóng',
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                context.pop();
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cổng thanh toán VNPay',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Đơn: ${widget.order.code} • ${formatVnd(widget.order.total)}',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
          actions: [
            // Nút xem thẻ test Sandbox
            IconButton(
              icon: Icon(
                _showCredentialsCard ? Icons.credit_card : Icons.credit_card_outlined,
                color: Colors.amberAccent,
              ),
              tooltip: 'Thẻ Sandbox thử nghiệm',
              onPressed: () => setState(() => _showCredentialsCard = !_showCredentialsCard),
            ),
            // Nút mô phỏng nhanh Demo Sandbox
            IconButton(
              icon: const Icon(Icons.flash_on_rounded, color: Colors.orangeAccent),
              tooltip: 'Mô phỏng Sandbox hoàn tất',
              onPressed: _isSettlingDemo ? null : _settleDemoDirectly,
            ),
            // Menu tùy chọn thêm
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              tooltip: 'Tùy chọn thanh toán',
              onSelected: (val) {
                if (val == 'reload') {
                  _webViewController?.reload();
                } else if (val == 'banks') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VNPayPaymentPage(order: widget.order),
                    ),
                  );
                } else if (val == 'demo') {
                  _settleDemoDirectly();
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'reload',
                  child: Row(
                    children: [
                      Icon(Icons.refresh_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Tải lại trang'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'banks',
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Danh sách ngân hàng'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'demo',
                  child: Row(
                    children: [
                      Icon(Icons.flash_on_rounded, size: 18, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Mô phỏng Demo Sandbox'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Stack(
          children: [
            if (_isGeneratingUrl)
              _buildGeneratingUrlView(c)
            else if (_urlError != null)
              _buildErrorView(c)
            else
              Column(
                children: [
                  if (_isLoading && _progress < 1.0)
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFED1C24)),
                      minHeight: 3,
                    ),
                  Expanded(
                    child: InAppWebView(
                      initialUrlRequest: _currentUrl != null
                          ? URLRequest(url: WebUri(_currentUrl!))
                          : null,
                      initialSettings: InAppWebViewSettings(
                        isInspectable: kDebugMode,
                        javaScriptEnabled: true,
                        useShouldOverrideUrlLoading: true,
                        mediaPlaybackRequiresUserGesture: false,
                        allowsInlineMediaPlayback: true,
                        useHybridComposition: true,
                        transparentBackground: false,
                        cacheEnabled: true,
                        domStorageEnabled: true,
                        databaseEnabled: true,
                        allowContentAccess: true,
                        allowFileAccess: true,
                        supportZoom: true,
                        builtInZoomControls: false,
                        displayZoomControls: false,
                      ),
                      onWebViewCreated: (controller) {
                        _webViewController = controller;
                        if (_currentUrl != null) {
                          controller.loadUrl(urlRequest: URLRequest(url: WebUri(_currentUrl!)));
                        }
                      },
                      onProgressChanged: (controller, progress) {
                        setState(() {
                          _progress = progress / 100;
                          if (progress == 100) {
                            _isLoading = false;
                          }
                        });
                      },
                      shouldOverrideUrlLoading: (controller, navigationAction) async {
                        final uri = navigationAction.request.url;
                        if (uri != null && _handleReturnUrl(uri)) {
                          return NavigationActionPolicy.CANCEL;
                        }
                        return NavigationActionPolicy.ALLOW;
                      },
                      onLoadStop: (controller, url) async {
                        setState(() => _isLoading = false);
                        if (url != null) {
                          _handleReturnUrl(url);
                        }
                        try {
                          final res = await controller.evaluateJavascript(source: "document.body.innerText");
                          final pageText = res?.toString().toLowerCase() ?? '';
                          if (pageText.contains('chưa được phê duyệt') ||
                              pageText.contains('chua duoc phe duyet') ||
                              pageText.contains('website này chưa được') ||
                              pageText.contains('not approved') ||
                              pageText.contains('not support') ||
                              pageText.contains('không hỗ trợ') ||
                              pageText.contains('khong ho tro') ||
                              pageText.contains('an error occurred') ||
                              pageText.contains('đã có lỗi xảy ra')) {
                            if (mounted) {
                              setState(() => _isVnpayUnapproved = true);
                            }
                          }
                        } catch (_) {}
                      },
                      onUpdateVisitedHistory: (controller, url, isReload) {
                        if (url != null) {
                          _handleReturnUrl(url);
                        }
                      },
                      onReceivedError: (controller, request, error) {
                        setState(() => _isLoading = false);
                      },
                    ),
                  ),
                ],
              ),

            // Card hướng dẫn thẻ test nổi phía trên
            if (_showCredentialsCard)
              Positioned(
                top: 8,
                left: 12,
                right: 12,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(14),
                  color: c.surface,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF005BAA).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.credit_card_rounded, color: Color(0xFF005BAA), size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Thông tin thẻ NCB Sandbox thử nghiệm',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () => setState(() => _showCredentialsCard = false),
                              child: Icon(Icons.close, size: 18, color: c.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildCredentialRow('Số thẻ', '9704 1985 2619 1432 198'),
                        _buildCredentialRow('Tên chủ thẻ', 'NGUYEN VAN A'),
                        _buildCredentialRow('Ngày phát hành', '07/15'),
                        _buildCredentialRow('Mã OTP', '123456'),
                        const SizedBox(height: 6),
                        Text(
                          '💡 Bấm vào từng dòng để sao chép nhanh khi nhập trên cổng VNPay.',
                          style: TextStyle(color: c.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Card trợ giúp khi VNPay báo Website chưa được duyệt
            if (_isVnpayUnapproved)
              Positioned(
                left: 14,
                right: 14,
                bottom: 18,
                child: Material(
                  elevation: 10,
                  borderRadius: BorderRadius.circular(16),
                  color: c.surface,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.shade400, width: 1.5),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Cổng Sandbox VNPay báo lỗi / chưa duyệt',
                                style: TextStyle(
                                  color: c.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => setState(() => _isVnpayUnapproved = false),
                              child: Icon(Icons.close, size: 18, color: c.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Cổng VNPay Sandbox đang phản hồi "Ngân hàng không hỗ trợ" hoặc tài khoản Sandbox chưa được kích hoạt đầy đủ kênh ngân hàng. Bạn có thể bấm xác nhận bên dưới để hoàn tất đơn hàng thử nghiệm ngay lập tức.',
                          style: TextStyle(color: c.textSecondary, fontSize: 12, height: 1.35),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSettlingDemo ? null : _settleDemoDirectly,
                            icon: _isSettlingDemo
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.flash_on_rounded, size: 18),
                            label: Text(
                              _isSettlingDemo ? 'Đang xác nhận...' : 'Xác nhận thanh toán Demo ngay',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF005BAA),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratingUrlView(AppColors c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF005BAA).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.language_rounded,
                size: 48,
                color: Color(0xFF005BAA),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Đang khởi tạo cổng VNPay...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Đang kết nối đến hệ thống thanh toán điện tử VNPay cho đơn ${widget.order.code}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(AppColors c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: Colors.orange.shade700),
            const SizedBox(height: 16),
            Text(
              'Không thể tạo cổng thanh toán VNPay',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _urlError ?? 'Đã có lỗi xảy ra khi tạo liên kết thanh toán.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _generatePaymentUrl,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại kết nối'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005BAA),
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isSettlingDemo ? null : _settleDemoDirectly,
              icon: const Icon(Icons.flash_on_rounded, color: Colors.orange),
              label: Text(_isSettlingDemo ? 'Đang xử lý...' : 'Mô phỏng Sandbox hoàn tất'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(200, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.pop(),
              child: Text('Quay lại', style: TextStyle(color: c.textMuted)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value) {
    return InkWell(
      onTap: () => _copyToClipboard(value, label),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$label:', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF005BAA)),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.copy_rounded, size: 13, color: Color(0xFF005BAA)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
