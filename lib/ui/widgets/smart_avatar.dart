import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'character_avatar.dart';
import '../../core/constants/colors.dart';

class SmartAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double size;
  final bool showGlow;
  final bool showBorder;

  const SmartAvatar({
    super.key,
    required this.avatarUrl,
    this.size = 56,
    this.showGlow = false,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl == null || avatarUrl!.isEmpty) {
      return _buildFallback();
    }

    // Check if it's a character ID (e.g., 'f1', 'm2')
    final character = kCharacters.cast<CharacterData?>().firstWhere(
          (c) => c?.id == avatarUrl,
          orElse: () => null,
        );

    if (character != null) {
      return CharacterAvatar(
        character: character,
        size: size,
        showGlow: showGlow,
        showBorder: showBorder,
      );
    }

    // Otherwise, assume it's a network URL
    return _buildNetworkAvatar();
  }

  Widget _buildNetworkAvatar() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: AppColors.surface, width: 2)
            : null,
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: AppColors.neonCyan.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: AppColors.surface,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
            ),
          ),
          errorWidget: (context, url, error) => _buildFallback(),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: AppColors.textMuted.withValues(alpha: 0.5), width: 1)
            : null,
      ),
      child: Icon(
        Icons.person_rounded,
        size: size * 0.6,
        color: AppColors.textMuted,
      ),
    );
  }
}
