import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/level_system.dart';

class XpProgressBar extends StatelessWidget {
  final int totalXp;
  final bool showText;
  final double height;

  const XpProgressBar({
    super.key,
    required this.totalXp,
    this.showText = true,
    this.height = 12,
  });

  @override
  Widget build(BuildContext context) {
    final progress = LevelSystem.getProgress(totalXp);
    final level = LevelSystem.getCurrentLevel(totalXp);
    final xpInLevel = LevelSystem.getXpInCurrentLevel(totalXp);
    final xpNeeded = LevelSystem.xpForNextLevel(level);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showText)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level $level',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                '$xpInLevel / $xpNeeded XP',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        if (showText) const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: height,
            backgroundColor: AppColors.surface,
            color: AppColors.purple,
          ),
        ),
      ],
    );
  }
}
