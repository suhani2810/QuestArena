import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../providers/user_providers.dart';
import '../../../providers/matchmaking_providers.dart';
import '../../../data/models/matchmaking_model.dart';
import '../store_screen.dart';
import '../matchmaking_screen.dart';
import '../match_history_screen.dart';
import '../../widgets/category_picker_sheet.dart';
import '../../../core/utils/rank_system.dart';
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

                      // BATTLE BUTTON (Quick Action from Upstream)
                      GestureDetector(
                        onTap: () async {
                          final category = await CategoryPickerSheet.show(context);
                          if (category == null || !context.mounted) return;
                          final ticket = MatchmakingModel(
                            uid: user.uid,
                            username: user.username,
                            avatarUrl: user.avatarUrl,
                            rank: user.rank,
                            categoryId: category.id,
                            categoryName: category.name,
                            eloRating: user.eloRating,
                            searchStartedAt: DateTime.now(),
                          );

                          await ref.read(matchmakingRepositoryProvider).startSearching(ticket);

                          if (context.mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MatchmakingScreen(categoryName: category.name),
                              ),
                            );
                          }
                        },
                        child: Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.purple, Color(0xFF5A3EBC)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.purple.withValues(alpha: 0.5),
                                blurRadius: 30,
                                spreadRadius: 2,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -20,
                                bottom: -20,
                                child: Icon(
                                  Icons.flash_on_rounded,
                                  size: 140,
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.play_arrow_rounded,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                    Text(
                                      'BATTLE NOW',
                                      style: AppTextStyles.display.copyWith(
                                        color: Colors.white,
                                        fontSize: 24,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 600.ms).scale(),
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
