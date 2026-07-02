import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/rank_system.dart';
import '../../../providers/leaderboard_providers.dart';
import '../../../providers/user_providers.dart';
import '../../../data/models/leaderboard_model.dart';
import '../../widgets/smart_avatar.dart';

class LeaderboardTab extends ConsumerWidget {
  const LeaderboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final weeklyMvp = ref.watch(weeklyMvpProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    return leaderboardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (e, s) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Failed to load leaderboard: $e',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.red),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (players) {
        return CustomScrollView(
          slivers: [
            // Weekly MVP Section
            if (weeklyMvp != null)
              SliverToBoxAdapter(
                child: _MvpCard(player: weeklyMvp),
              ),

            // Leaderboard Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Text('GLOBAL LEADERBOARD', style: AppTextStyles.label.copyWith(letterSpacing: 2, fontWeight: FontWeight.bold)),
              ),
            ),

            // Players List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final player = players[index];
                    final isMe = player.uid == currentUser?.uid;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMe ? AppColors.purple.withValues(alpha: 0.2) : AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isMe ? AppColors.purple : AppColors.surface,
                          width: isMe ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 40, child: _RankBadge(index: index)),
                          SmartAvatar(
                            avatarUrl: player.avatarUrl,
                            size: 40,
                            showBorder: false,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  player.username,
                                  style: AppTextStyles.bodyMd.copyWith(
                                    fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                                    color: isMe ? AppColors.gold : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'LVL ${player.level} • ${RankSystem.getRankName(player.rank, player.subRank)}', 
                                  style: AppTextStyles.label.copyWith(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${player.xp}', style: AppTextStyles.headline.copyWith(fontSize: 18, color: AppColors.gold)),
                              Text('XP', style: AppTextStyles.label.copyWith(fontSize: 8)),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
                  },
                  childCount: players.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        );
      },
    );
  }
}

class _MvpCard extends StatelessWidget {
  final LeaderboardModel player;

  const _MvpCard({required this.player});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gold.withValues(alpha: 0.2), AppColors.purple.withValues(alpha: 0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(color: AppColors.gold.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 5),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SmartAvatar(
                avatarUrl: player.avatarUrl,
                size: 80,
                showGlow: true,
                showBorder: true,
              ),
              const Positioned(
                top: -5,
                child: Icon(Icons.workspace_premium, color: AppColors.gold, size: 28),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WEEKLY MVP', style: AppTextStyles.label.copyWith(color: AppColors.gold, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 4),
                Text(player.username, style: AppTextStyles.display.copyWith(fontSize: 24)),
                const SizedBox(height: 4),
                Text(
                  '${player.totalWins} WINS THIS WEEK',
                  style: AppTextStyles.label.copyWith(color: AppColors.teal, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().shimmer(duration: 2.seconds).scale(duration: 600.ms, curve: Curves.easeOutBack);
  }
}

class _RankBadge extends StatelessWidget {
  final int index;

  const _RankBadge({required this.index});

  @override
  Widget build(BuildContext context) {
    if (index == 0) return const Icon(Icons.workspace_premium, color: AppColors.gold, size: 28);
    if (index == 1) return const Icon(Icons.workspace_premium, color: AppColors.rankSilver, size: 24);
    if (index == 2) return const Icon(Icons.workspace_premium, color: AppColors.rankBronze, size: 24);
    
    return Text(
      '${index + 1}',
      style: AppTextStyles.headline.copyWith(fontSize: 18, color: AppColors.textMuted),
    );
  }
}
