import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../providers/auth_provider.dart';
import '../widgets/discard_changes_dialog.dart';
import '../widgets/edit_profile_form.dart';
import '../widgets/profile_avatar_section.dart';
import '../widgets/profile_shortcuts_card.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;

  bool _loading = false;
  bool _initialized = false;
  bool _forcePop = false;

  String _initialName = '';
  String _initialPhone = '';
  String _initialAddress = '';

  bool get _hasChanges {
    return _nameCtrl.text.trim() != _initialName ||
        _phoneCtrl.text.trim() != _initialPhone ||
        _addressCtrl.text.trim() != _initialAddress;
  }

  bool get _canPop => _forcePop || !_hasChanges || _loading;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _addressCtrl = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentData();
    });
  }

  void _loadCurrentData() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameCtrl.text = user.fullName;
      _phoneCtrl.text = user.phone ?? '';
      _addressCtrl.text = user.address ?? '';
      _initialName = _nameCtrl.text.trim();
      _initialPhone = _phoneCtrl.text.trim();
      _initialAddress = _addressCtrl.text.trim();
    }
    setState(() => _initialized = true);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<bool> _handleSave() async {
    if (!_formKey.currentState!.validate()) return false;

    setState(() => _loading = true);

    final auth = context.read<AuthProvider>();
    final result = await auth.updateProfile(
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
    );

    if (!mounted) return false;
    setState(() => _loading = false);

    final c = AppColors.of(context);
    if (result['success'] == true) {
      _initialName = _nameCtrl.text.trim();
      _initialPhone = _phoneCtrl.text.trim();
      _initialAddress = _addressCtrl.text.trim();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: c.onPrimary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result['message'] ?? 'Cập nhật thông tin thành công!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: c.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      setState(() => _forcePop = true);
      if (mounted) {
        context.pop();
      }
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: c.onPrimary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result['message'] ?? 'Cập nhật thất bại, vui lòng thử lại',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: c.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return false;
    }
  }

  Future<void> _onBack() async {
    if (!_hasChanges || _loading) {
      setState(() => _forcePop = true);
      if (mounted) context.pop();
      return;
    }

    final wantSave = await DiscardChangesDialog.show(context);
    if (wantSave == null) {
      return;
    }

    if (wantSave) {
      await _handleSave();
    } else {
      setState(() => _forcePop = true);
      if (mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      return Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          title: Text(
            'Thông tin cá nhân',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: c.textPrimary,
            ),
          ),
          backgroundColor: c.background,
          foregroundColor: c.textPrimary,
          elevation: 0,
        ),
        body: Center(
          child: Text(
            'Vui lòng đăng nhập để xem thông tin',
            style: TextStyle(color: c.textMuted),
          ),
        ),
      );
    }

    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        await _onBack();
      },
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          title: Text(
            'Chỉnh sửa hồ sơ',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: c.textPrimary,
            ),
          ),
          backgroundColor: c.background,
          foregroundColor: c.textPrimary,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              size: 20,
              color: c.textPrimary,
            ),
            onPressed: _onBack,
          ),
        ),
        body: !_initialized
            ? Center(
                child: CircularProgressIndicator(color: c.primary),
              )
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ProfileAvatarSection(user: user),
                      const SizedBox(height: 28),
                      EditProfileForm(
                        nameCtrl: _nameCtrl,
                        phoneCtrl: _phoneCtrl,
                        addressCtrl: _addressCtrl,
                        user: user,
                      ),
                      const ProfileShortcutsCard(),
                      const SizedBox(height: 32),
                      PrimaryButton(
                        label: 'Lưu thay đổi',
                        icon: Icons.save_rounded,
                        loading: _loading,
                        onPressed: _handleSave,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
