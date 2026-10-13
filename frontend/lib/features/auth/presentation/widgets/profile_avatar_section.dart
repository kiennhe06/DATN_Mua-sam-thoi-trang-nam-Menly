import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import 'user_avatar_view.dart';

class ProfileAvatarSection extends StatefulWidget {
  final AuthUser user;

  const ProfileAvatarSection({
    super.key,
    required this.user,
  });

  @override
  State<ProfileAvatarSection> createState() => _ProfileAvatarSectionState();
}

class _ProfileAvatarSectionState extends State<ProfileAvatarSection> {
  bool _uploadingAvatar = false;

  void _showAvatarSourceSheet() {
    final c = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Thay đổi ảnh đại diện',
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Chọn nguồn ảnh bạn muốn sử dụng làm ảnh đại diện',
              style: TextStyle(color: c.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.camera_alt_rounded, color: c.secondary),
              ),
              title: Text(
                'Chụp ảnh từ Camera',
                style: TextStyle(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                'Mở máy ảnh chụp ảnh trực tiếp',
                style: TextStyle(color: c.textMuted, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadAvatar(ImageSource.camera);
              },
            ),
            Divider(color: c.border.withValues(alpha: 0.6)),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: Color(0xFF3B82F6),
                ),
              ),
              title: Text(
                'Chọn ảnh từ Thư viện',
                style: TextStyle(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                'Tải ảnh có sẵn từ bộ sưu tập máy',
                style: TextStyle(color: c.textMuted, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadAvatar(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: c.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Hủy bỏ',
                style: TextStyle(
                  color: c.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _uploadingAvatar = true);
      final bytes = await picked.readAsBytes();
      final ext = picked.path.split('.').last.toLowerCase();
      final mimeType = (ext == 'png') ? 'image/png' : 'image/jpeg';

      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final res = await auth.uploadAvatar(bytes, mimeType: mimeType);

      if (!mounted) return;
      setState(() => _uploadingAvatar = false);
      final c = AppColors.of(context);

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: c.onPrimary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    res['message'] ?? 'Đổi ảnh đại diện thành công!',
                  ),
                ),
              ],
            ),
            backgroundColor: c.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Lỗi khi tải ảnh lên'),
            backgroundColor: c.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final c = AppColors.of(context);
        setState(() => _uploadingAvatar = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: c.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final user = widget.user;

    String roleLabel = 'Khách hàng';
    Color roleColor = c.secondary;
    if (user.isAdmin) {
      roleLabel = 'Quản trị viên (Admin)';
      roleColor = const Color(0xFFEF4444);
    } else if (user.isStaff) {
      roleLabel = 'Nhân viên vận hành';
      roleColor = const Color(0xFF3B82F6);
    }

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _uploadingAvatar ? null : _showAvatarSourceSheet,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                UserAvatarView(
                  avatarUrl: user.avatarUrl,
                  fullName: user.fullName,
                  size: 92,
                ),
                if (_uploadingAvatar)
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.65),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: c.primary,
                        ),
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: c.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.background, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: c.shadow,
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: 15,
                    color: c.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _uploadingAvatar ? null : _showAvatarSourceSheet,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.photo_camera_outlined,
                    size: 13,
                    color: _uploadingAvatar ? c.textMuted : c.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _uploadingAvatar
                        ? 'Đang tải ảnh...'
                        : 'Chạm để đổi ảnh đại diện',
                    style: TextStyle(
                      color: _uploadingAvatar ? c.textMuted : c.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user.fullName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: TextStyle(
              fontSize: 13,
              color: c.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          // Role pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: roleColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  user.isAdmin
                      ? Icons.shield_rounded
                      : (user.isStaff
                          ? Icons.badge_rounded
                          : Icons.person_rounded),
                  size: 13,
                  color: roleColor,
                ),
                const SizedBox(width: 5),
                Text(
                  roleLabel,
                  style: TextStyle(
                    color: roleColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
