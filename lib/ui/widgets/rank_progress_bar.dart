import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/rank_system.dart';

class RankProgressBar extends StatelessWidget {
  final String rank;
  final int? subRank;
  final int points;
  final double height;

  const RankProgressBar({
    super.key,
    required this.rank,
    this.subRank,
    required this.points,
    this.height = 10,
  });

  @override
  Widget build(BuildContext context) {
    if (rank == 'Legend' || rank == 'Unranked') {
      return const SizedBox.shrink();
    }

    final progress = (points / 100).clamp(0.0, 1.0);
    final rankColor = RankSystem.getRankColor(rank);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              RankSystem.getRankName(rank, subRank),
              style: TextStyle(
                color: rankColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Text(
              '$points / 100 RP',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: height,
            backgroundColor: AppColors.surface,
            color: rankColor,
          ),
        ),
      ],
    );
  }
}
