import 'package:flutter/material.dart';
import 'dart:convert';
import '../constants/colors.dart';

class UserAvatar extends StatelessWidget {
  final String? name;
  final String? avatarUrl;
  final String? avatarBase64;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;

  const UserAvatar({
    super.key,
    this.name,
    this.avatarUrl,
    this.avatarBase64,
    this.radius = 18,
    this.backgroundColor,
    this.textColor,
  });

  bool get _hasNetworkAvatar {
    final value = (avatarUrl ?? '').trim();
    return value.startsWith('http://') || value.startsWith('https://');
  }

  bool get _hasBase64Avatar => (avatarBase64 ?? '').trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final initial = (name != null && name!.trim().isNotEmpty)
        ? name!.trim()[0].toUpperCase()
        : 'U';

    ImageProvider? imageProvider;
    if (_hasBase64Avatar) {
      try {
        imageProvider = MemoryImage(base64Decode(avatarBase64!.trim()));
      } catch (_) {
        imageProvider = null;
      }
    }
    if (imageProvider == null && _hasNetworkAvatar) {
      imageProvider = NetworkImage(avatarUrl!.trim());
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? AppColors.primary.withOpacity(0.18),
      backgroundImage: imageProvider,
      child: imageProvider != null
          ? null
          : Text(
              initial,
              style: TextStyle(
                color: textColor ?? AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.95,
              ),
            ),
    );
  }
}
