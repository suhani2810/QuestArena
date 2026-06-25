import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../data/services/xp_service.dart';

class XpSummaryCard extends StatelessWidget {
  final XpRewardBreakdown rewards;

  const XpSummaryCard({super.key, required this.rewards});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface),
      ),
      child: Column(
        children: [
          _buildRow('Match Completed', rewards.matchCompleted),
          _buildRow('Match Outcome', rewards.outcomeXp),
          if (rewards.correctAnswersXp > 0)
            _buildRow('Correct Answers', rewards.correctAnswersXp),
          if (rewards.perfectScoreXp > 0)
            _buildRow('Perfect Score!', rewards.perfectScoreXp, color: AppColors.gold),
          if (rewards.dailyBonusXp > 0)
            _buildRow('First Match of Day', rewards.dailyBonusXp, color: AppColors.teal),
          if (rewards.streakBonusXp > 0)
            _buildRow('Win Streak Bonus', rewards.streakBonusXp, color: AppColors.purple),
          const Divider(color: AppColors.surface, height: 24),
          _buildRow('Total XP Gained', rewards.total, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildRow(String label, int value, {bool isTotal = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '+$value',
            style: TextStyle(
              color: color ?? (isTotal ? AppColors.gold : AppColors.textPrimary),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
