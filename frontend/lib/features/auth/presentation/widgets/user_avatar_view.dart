import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class UserAvatarView extends StatelessWidget {
  final String? avatarUrl;
  final String fullName;
  final double size;
  final bool showBorder;

  const UserAvatarView({
    super.key,
    required this.avatarUrl,
    required this.fullName,
    this.size = 80,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    Widget content;

    final url = avatarUrl?.trim();
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('data:image')) {
        try {
          final commaIdx = url.indexOf(',');
          final base64Str = commaIdx != -1 ? url.substring(commaIdx + 1) : url;
          final bytes = base64Decode(base64Str);
          content = ClipOval(
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          );
        } catch (_) {
          content = _buildInitial(c);
        }
      } else {
        content = ClipOval(
          child: CachedNetworkImage(
            imageUrl: url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: (ctx, _) => Container(
              color: c.surfaceVariant,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.primary,
                  ),
                ),
              ),
            ),
            errorWidget: (ctx, _, __) => _buildInitial(c),
          ),
        );
      }
    } else {
      content = _buildInitial(c);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: (url == null || url.isEmpty)
            ? LinearGradient(
                colors: [c.primary, c.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
        border: showBorder ? Border.all(color: c.border, width: 2) : null,
      ),
      child: content,
    );
  }

  Widget _buildInitial(AppColors c) {
    final initial = fullName.trim().isNotEmpty ? fullName.trim()[0].toUpperCase() : 'U';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: c.onPrimary,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
