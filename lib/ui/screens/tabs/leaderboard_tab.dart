// WHAT THIS FILE DOES:
// Displays the global rankings with a "Hall of Fame" feel.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../providers/leaderboard_providers.dart';
import '../../../providers/user_providers.dart';
import '../../../data/models/leaderboard_model.dart';

class LeaderboardTab extends ConsumerWidget {
  const LeaderboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final currentUser = ref.watch(currentUserProvider).value;
    final weeklyMvp = ref.watch(weeklyMvpProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('RANKINGS', style: AppTextStyles.display.copyWith(fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: leaderboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, s) => Center(child: Text('Error: $e')),
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
                  child: Text('LEADERBOARD', style: AppTextStyles.label.copyWith(letterSpacing: 2)),
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
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.surface,
                              child: ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: player.avatarUrl ?? '',
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 1),
                                  errorWidget: (context, url, error) => const Icon(Icons.person, size: 20),
                                ),
                              ),
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
                                  Text('LVL ${player.level} • ${player.rank}', style: AppTextStyles.label.copyWith(fontSize: 10)),
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
                      );
                    },
                    childCount: players.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }
}

class _MvpCard extends StatelessWidget {
  final LeaderboardModel player;
  const _MvpCard({required this.player});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2D2645),
            Color(0xFF1A1625),
          ],
        ),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Ambient Glow
          Positioned(
            top: -50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.gold.withValues(alpha: 0.15),
                      AppColors.gold.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Particles (More visible and varied)
          ...List.generate(12, (index) {
            final isGold = index % 3 == 0;
            return Positioned(
              left: (index * 45) % 320 + 10,
              top: (index * 65) % 300 + 10,
              child: Icon(
                index % 2 == 0 ? Icons.star_rounded: Icons.auto_awesome,
                color: (isGold ? AppColors.gold : Colors.orangeAccent).withValues(alpha: 0.5),
                size: index % 3 == 0 ? 10 : 14,
              ).animate(onPlay: (c) => c.repeat())
               .moveY(begin: 0, end: -30, duration: (2000 + index * 400).ms, curve: Curves.easeInOut)
               .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 1000.ms)
               .fadeIn(duration: 800.ms)
               .then()
               .fadeOut(duration: 800.ms),
            );
          }),

          // Vignette
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                ],
                stops: const [0.6, 1.0],
                radius: 1.2,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // MVP Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'MVP HOLDER',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.gold, 
                          fontSize: 10, 
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Avatar
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: AppColors.gold.withValues(alpha: 0.5),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.surface,
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: player.avatarUrl ?? '',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Text(player.username, style: AppTextStyles.headline.copyWith(fontSize: 22, letterSpacing: 1)),
                Text(player.rank, style: AppTextStyles.label.copyWith(color: AppColors.gold, fontSize: 12)),

                const SizedBox(height: 24),

                // Stats Row
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MvpStat(icon: Icons.stars_rounded, value: '${player.xp}', label: 'XP', color: AppColors.purple),
                      _MvpStat(icon: Icons.emoji_events_rounded, value: '${player.totalWins}', label: 'WINS', color: AppColors.teal),
                      _MvpStat(icon: Icons.whatshot_rounded, value: '${player.currentStreak}', label: 'STREAK', color: AppColors.red),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MvpStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MvpStat({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value, style: AppTextStyles.headline.copyWith(fontSize: 16)),
        Text(label, style: AppTextStyles.label.copyWith(fontSize: 8, color: AppColors.textMuted)),
      ],
    );
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
      style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    );
  }
}
