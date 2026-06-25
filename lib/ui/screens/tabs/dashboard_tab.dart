// WHAT THIS FILE DOES:
// Shows the player's summary, stats, and quick-start button.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../providers/user_providers.dart';
import '../store_screen.dart';
import '../../../core/utils/rank_calculator.dart';
import '../../../core/utils/rank_system.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../widgets/rank_badge.dart';
import '../../widgets/rank_progress_bar.dart';
import '../../widgets/xp_progress_bar.dart';

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (user) {
        if (user == null) return const Center(child: Text('User not found'));

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar with Store
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('DASHBOARD', style: AppTextStyles.headline.copyWith(fontSize: 18)),
                    IconButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreScreen())),
                      icon: const Icon(Icons.shopping_bag_rounded, color: AppColors.gold),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),

                // Player Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.surface),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 35,
                                backgroundColor: AppColors.surface,
                                child: ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: user.avatarUrl ?? '',
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
                                    errorWidget: (context, url, error) => const Icon(Icons.person),
                                  ),
                                ),
                              ),
                              RankBadge(rank: user.rank, subRank: user.subRank, size: 28),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.username, style: AppTextStyles.headline),
                                Text(
                                  RankSystem.getRankName(user.rank, user.subRank),
                                  style: AppTextStyles.label.copyWith(
                                    color: RankSystem.getRankColor(user.rank),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // XP Bar
                                XpProgressBar(totalXp: user.xp),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (user.rank != 'Legend' && user.rank != 'Unranked') ...[
                        const SizedBox(height: 16),
                        const Divider(color: AppColors.surface),
                        const SizedBox(height: 8),
                        RankProgressBar(rank: user.rank, subRank: user.subRank, points: user.rankPoints),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Text('QUICK STATS', style: AppTextStyles.label),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    _StatCard(label: 'WINS', value: user.wins.toString(), color: AppColors.teal),
                    const SizedBox(width: 16),
                    _StatCard(label: 'LOSSES', value: user.losses.toString(), color: AppColors.red),
                  ],
                ),
                
                const SizedBox(height: 32),

                Text('RECENT HISTORY', style: AppTextStyles.label),
                const SizedBox(height: 12),
                
                ref.watch(matchHistoryProvider).when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Text('History Error: $e'),
                  data: (history) {
                    if (history.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.surface, style: BorderStyle.solid),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.history_rounded, color: AppColors.textMuted, size: 32),
                            const SizedBox(height: 12),
                            Text(
                              'No match history yet.\nStart a battle to see your results!',
                              style: AppTextStyles.label.copyWith(color: AppColors.textMuted),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = history[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.surface),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (item.isWin ? AppColors.teal : AppColors.red).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  item.isWin ? Icons.emoji_events_rounded : Icons.close_rounded, 
                                  color: item.isWin ? AppColors.teal : AppColors.red,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.isWin ? 'Victory against ${item.opponentName}' : 'Defeat by ${item.opponentName}',
                                      style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${DateFormat('MMM d, HH:mm').format(item.playedAt)}  •  ${item.myScore}-${item.opponentScore}',
                                      style: AppTextStyles.label.copyWith(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '+${item.xpGained} XP', 
                                style: AppTextStyles.label.copyWith(color: AppColors.gold, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surface),
        ),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.headline.copyWith(color: color)),
            Text(label, style: AppTextStyles.label),
          ],
        ),
      ),
    );
  }
}
