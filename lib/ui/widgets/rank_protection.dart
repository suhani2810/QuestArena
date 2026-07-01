import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';

class RankProtectionStatus extends StatelessWidget {
  final int remainingMatches;
  final bool showLabel;

  const RankProtectionStatus({
    super.key,
    required this.remainingMatches,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    if (remainingMatches <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.security, color: AppColors.purple, size: 14),
          const SizedBox(width: 6),
          Text(
            showLabel ? 'RANK PROTECTION: $remainingMatches MATCHES' : '$remainingMatches',
            style: AppTextStyles.label.copyWith(
              color: AppColors.purple,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
