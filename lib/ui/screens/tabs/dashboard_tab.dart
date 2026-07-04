import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../providers/user_providers.dart';
import '../../../data/models/match_history_model.dart';
import '../store_screen.dart';
import '../match_history_screen.dart';
import '../match_summary_screen.dart';
import '../../../core/utils/rank_system.dart';
import '../../../core/utils/game_utils.dart';
import '../../widgets/rank_badge.dart';
import '../../widgets/rank_progress_bar.dart';
import '../../widgets/xp_progress_bar.dart';
import '../../widgets/smart_avatar.dart';
import '../../widgets/neon_swirl_background.dart';
import '../../widgets/daily_quests_sheet.dart';

class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (user) {
        if (user == null) {
          return const Center(child: Text('User not found', style: TextStyle(color: AppColors.textSecondary)));
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => DailyQuestsSheet.show(context),
            backgroundColor: AppColors.gold,
            icon: const Icon(Icons.bolt_rounded, color: Colors.black),
            label: const Text('QUESTS', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ).animate().slideX(begin: 1, end: 0, delay: 1000.ms, curve: Curves.easeOutBack),
          body: NeonSwirlBackground(
            colors: const [AppColors.neonCyan, AppColors.purple],
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TOP BAR
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'HUB',
                            style: AppTextStyles.headline.copyWith(fontSize: 18, letterSpacing: 3),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const MatchHistoryScreen()),
                                ),
                                icon: const Icon(Icons.history_rounded, color: Colors.white70),
                              ),
                              IconButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const StoreScreen()),
                                ),
                                icon: const Icon(Icons.shopping_bag_rounded, color: AppColors.gold),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // PLAYER HEADER CARD
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.surface),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    SmartAvatar(
                                      avatarUrl: user.avatarUrl,
                                      size: 70,
                                      showGlow: true,
                                    ),
                                    RankBadge(rank: user.rank, subRank: user.subRank, size: 28),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.username.toUpperCase(),
                                        style: AppTextStyles.headline.copyWith(
                                          letterSpacing: 2,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        RankSystem.getRankName(user.rank, user.subRank),
                                        style: AppTextStyles.label.copyWith(
                                          color: RankSystem.getRankColor(user.rank),
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
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
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 32),

                      Text('QUICK STATS', style: AppTextStyles.label.copyWith(letterSpacing: 2)),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          _StatCard(
                            label: 'WINS',
                            value: user.wins.toString(),
                            color: AppColors.teal,
                            icon: Icons.emoji_events_rounded,
                          ),
                          const SizedBox(width: 8),
                          _StatCard(
                            label: 'LOSSES',
                            value: user.losses.toString(),
                            color: AppColors.red,
                            icon: Icons.sentiment_very_dissatisfied_rounded,
                          ),
                          const SizedBox(width: 8),
                          _StatCard(
                            label: 'WIN %',
                            value: '${user.winRate.toStringAsFixed(0)}%',
                            color: AppColors.gold,
                            icon: Icons.auto_graph_rounded,
                          ),
                        ],
                      ).animate().fadeIn(delay: 400.ms),

                      const SizedBox(height: 32),

                      const _RecentMatchHistorySection(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RecentMatchHistorySection extends ConsumerWidget {
  const _RecentMatchHistorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(matchHistoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MATCH HISTORY',
              style: AppTextStyles.label.copyWith(letterSpacing: 2, fontWeight: FontWeight.w900),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MatchHistoryScreen()),
              ),
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(color: AppColors.gold.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.gold.withValues(alpha: 0.8)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        historyAsync.when(
          loading: () => const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(color: AppColors.gold),
          )),
          error: (e, s) {
            debugPrint('Match History Error: $e');
            return Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.cardBg.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.red.withValues(alpha: 0.3), width: 1),
              ),
              child: Column(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 32, color: AppColors.red),
                  const SizedBox(height: 12),
                  Text(
                    'History unavailable',
                    style: AppTextStyles.headline.copyWith(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try again later',
                    style: AppTextStyles.label.copyWith(fontSize: 10),
                  ),
                ],
              ),
            );
          },
          data: (history) {
            if (history.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.cardBg.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.surface, width: 1),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.history_rounded, size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    Text(
                      'No matches played yet.',
                      style: AppTextStyles.headline.copyWith(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Play your first battle to build your history.',
                      style: AppTextStyles.label.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              );
            }

            final recentMatches = history.take(5).toList();

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentMatches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final match = recentMatches[index];
                final isWin = match.result == MatchResult.win;
                final isDraw = match.result == MatchResult.draw;

                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MatchSummaryScreen(match: match)),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isWin 
                            ? AppColors.teal.withValues(alpha: 0.3) 
                            : (isDraw ? AppColors.gold.withValues(alpha: 0.3) : AppColors.red.withValues(alpha: 0.1)),
                        width: 1.5,
                      ),
                      boxShadow: isWin ? [
                        BoxShadow(
                          color: AppColors.teal.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ] : null,
                    ),
                    child: Row(
                      children: [
                        // Result Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isWin ? AppColors.teal : (isDraw ? AppColors.gold : AppColors.red)).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isWin ? 'WIN' : (isDraw ? 'DRAW' : 'LOSS'),
                            style: TextStyle(
                              color: isWin ? AppColors.teal : (isDraw ? AppColors.gold : AppColors.red),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Opponent Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'vs ${match.opponentName}',
                                style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${match.matchTypeLabel} • ${GameUtils.getRelativeTime(match.timestamp)}',
                                style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        // RP Change
                        if (match.matchTypeLabel == 'Ranked' && match.rpChange != 0)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                match.rpChange > 0 ? '+${match.rpChange} RP' : '${match.rpChange} RP',
                                style: AppTextStyles.headline.copyWith(
                                  fontSize: 16,
                                  color: match.rpChange > 0 ? AppColors.teal : AppColors.red,
                                  letterSpacing: 0,
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted),
                            ],
                          )
                        else
                          const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
                      ],
                    ),
                  ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1, end: 0),
                );
              },
            );
          },
        ).animate().fadeIn(delay: 600.ms),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: AppTextStyles.headline.copyWith(fontSize: 18)),
            Text(label, style: AppTextStyles.label.copyWith(fontSize: 8)),
          ],
        ),
      ),
    );
  }
}
