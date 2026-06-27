import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';

class VictoryCard extends StatelessWidget {
  final String username;
  final String? avatarUrl;
  final String rank;
  final String opponentName;
  final int playerScore;
  final int opponentScore;
  final int xpEarned;
  final int coinsEarned;
  final int winStreak;
  final DateTime timestamp;
  final double? accuracy;
  final bool isCompact;

  const VictoryCard({
    super.key,
    required this.username,
    this.avatarUrl,
    required this.rank,
    required this.opponentName,
    required this.playerScore,
    required this.opponentScore,
    required this.xpEarned,
    required this.coinsEarned,
    this.winStreak = 1,
    required this.timestamp,
    this.accuracy,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) return _buildCompactCard();

    return Container(
      width: 340,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.purple, AppColors.primaryBg, AppColors.cardBg],
        ),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo & Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_rounded, color: AppColors.gold, size: 24),
              const SizedBox(width: 8),
              Text(
                'QUESTARENA',
                style: AppTextStyles.headline.copyWith(
                  color: AppColors.gold,
                  fontSize: 16,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'VICTORY',
            style: AppTextStyles.display.copyWith(
              fontSize: 40,
              color: Colors.white,
              shadows: [
                const Shadow(color: AppColors.gold, blurRadius: 10),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Player Info
          Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.surface,
                  child: ClipOval(
                    child: avatarUrl != null && avatarUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: avatarUrl!,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.person, size: 40, color: AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: AppTextStyles.headline.copyWith(fontSize: 20),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      rank,
                      style: AppTextStyles.label.copyWith(color: AppColors.gold),
                    ),
                  ],
                ),
              ),
              if (winStreak > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.red.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.whatshot_rounded, color: AppColors.red, size: 14),
                      const SizedBox(width: 4),
                      Text('$winStreak', style: AppTextStyles.label.copyWith(color: AppColors.red)),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 32),

          // Match Details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Text(
                  'vs $opponentName',
                  style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  '$playerScore - $opponentScore',
                  style: AppTextStyles.display.copyWith(fontSize: 32),
                ),
                const Divider(color: Colors.white10, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(label: 'XP', value: '+$xpEarned', color: AppColors.purple),
                    _StatItem(label: 'COINS', value: '+$coinsEarned', color: AppColors.gold),
                    if (accuracy != null)
                      _StatItem(label: 'ACCURACY', value: '${(accuracy! * 100).toInt()}%', color: AppColors.teal),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Footer
          Text(
            DateFormat('MMM d, yyyy • HH:mm').format(timestamp),
            style: AppTextStyles.label.copyWith(color: AppColors.textMuted, fontSize: 10),
          ),
          const SizedBox(height: 16),
          Text(
            'Think you can beat me?',
            style: AppTextStyles.bodyMd.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          Text(
            'Challenge me on QuestArena.',
            style: AppTextStyles.label.copyWith(color: AppColors.gold),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCard() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.purple, AppColors.primaryBg],
        ),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.gold.withValues(alpha: 0.2),
            child: avatarUrl != null && avatarUrl!.isNotEmpty
                ? ClipOval(child: CachedNetworkImage(imageUrl: avatarUrl!, width: 40, height: 40, fit: BoxFit.cover))
                : const Icon(Icons.person, size: 20, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(username, style: AppTextStyles.headline.copyWith(fontSize: 14), overflow: TextOverflow.ellipsis),
                Text('VICTORY vs $opponentName', style: AppTextStyles.label.copyWith(fontSize: 8, color: AppColors.gold)),
              ],
            ),
          ),
          Text(
            '$playerScore-$opponentScore',
            style: AppTextStyles.headline.copyWith(fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.headline.copyWith(fontSize: 16, color: color)),
        Text(label, style: AppTextStyles.label.copyWith(fontSize: 8, color: AppColors.textMuted)),
      ],
    );
  }
}
