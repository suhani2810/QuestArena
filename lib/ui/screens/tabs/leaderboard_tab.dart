// WHAT THIS FILE DOES:
// Displays the global rankings with an interactive expandable profile card system.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../data/models/leaderboard_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/match_history_model.dart';
import '../../../providers/leaderboard_providers.dart';
import '../../../providers/user_providers.dart';
import '../../../providers/navigation_providers.dart';
import '../../../core/utils/rank_system.dart';
import '../../widgets/smart_avatar.dart';

class LeaderboardTab extends ConsumerStatefulWidget {
  const LeaderboardTab({super.key});

  @override
  ConsumerState<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends ConsumerState<LeaderboardTab> {
  String? _selectedUid;

  void _toggleProfile(String uid) {
    setState(() {
      if (_selectedUid == uid) {
        _selectedUid = null;
      } else {
        _selectedUid = uid;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Text('GLOBAL LEADERBOARD', style: AppTextStyles.label.copyWith(letterSpacing: 2, fontWeight: FontWeight.bold)),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final player = players[index];
                      final isMe = player.uid == currentUser?.uid;
                      final isExpanded = _selectedUid == player.uid;

                      return _ExpandablePlayerCard(
                        player: player,
                        isMe: isMe,
                        isExpanded: isExpanded,
                        index: index,
                        onTap: () => _toggleProfile(player.uid),
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

class _ExpandablePlayerCard extends ConsumerWidget {
  final LeaderboardModel player;
  final bool isMe;
  final bool isExpanded;
  final int index;
  final VoidCallback onTap;

  const _ExpandablePlayerCard({
    required this.player,
    required this.isMe,
    required this.isExpanded,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isExpanded ? 1.02 : 1.0,
        duration: 400.ms,
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: 400.ms,
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(isExpanded ? 20 : 12),
          decoration: BoxDecoration(
            color: isMe ? AppColors.purple.withValues(alpha: 0.2) : AppColors.cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isExpanded ? Colors.white : (isMe ? AppColors.purple : AppColors.surface),
              width: isExpanded ? 2.0 : (isMe ? 2 : 1),
            ),
            boxShadow: isExpanded ? [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ] : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Section
              Row(
                children: [
                  // Rank Badge / Number
                  SizedBox(
                    width: 40,
                    child: isExpanded 
                      ? Text('${index + 1}', style: AppTextStyles.headline.copyWith(fontSize: 25, color: AppColors.textMuted.withValues(alpha: 0.5)))
                      : _RankBadge(index: index),
                  ),

                  // Avatar with Glow
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isExpanded)
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ).animate().scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 400.ms),
                      SmartAvatar(
                        avatarUrl: player.avatarUrl,
                        size: isExpanded ? 70 : 40,
                        showBorder: isExpanded,
                        showGlow: false,
                      ),
                    ],
                  ),

                  const SizedBox(width: 16),

                  // Username & Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.username,
                          style: AppTextStyles.headline.copyWith(
                            fontSize: isExpanded ? 20 : 16,
                            color: isMe ? AppColors.gold : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'LVL ${player.level} • ${RankSystem.getRankName(player.rank, player.subRank)}',
                          style: AppTextStyles.label.copyWith(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (isExpanded) ...[
                          const SizedBox(height: 12),
                          _ActionButton(uid: player.uid, isMe: isMe),
                        ],
                      ],
                    ),
                  ),

                  // XP (Only when collapsed)
                  if (!isExpanded)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${player.xp}', style: AppTextStyles.headline.copyWith(fontSize: 20, color: AppColors.gold)),
                        Text('XP', style: AppTextStyles.label.copyWith(fontSize: 8)),
                      ],
                    ).animate().fadeIn(duration: 300.ms),
                ],
              ),

              // Expanded Details
              AnimatedSize(
                duration: 450.ms,
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: isExpanded
                    ? _ExpandedDetails(uid: player.uid, player: player, isMe: isMe)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
  }
}

class _ExpandedDetails extends ConsumerWidget {
  final String uid;
  final LeaderboardModel player;
  final bool isMe;

  const _ExpandedDetails({required this.uid, required this.player, required this.isMe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(uid));
    final historyAsync = ref.watch(userMatchHistoryProvider(uid));

    return profileAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)),
      ),
      error: (e, s) => Text('Error loading stats', style: AppTextStyles.label.copyWith(color: AppColors.red)),
      data: (user) {
        return historyAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)),
          ),
          error: (e, s) => _buildContent(user, []),
          data: (history) => _buildContent(user, history),
        );
      },
    );
  }

  Widget _buildContent(UserModel? user, List<MatchModel> history) {
    int totalMatches;
    int wins;
    int streak;
    int xp;
    String rank;
    double winRate;

    if (isMe && user != null) {
      totalMatches = user.matchesPlayed;
      wins = user.wins;
      streak = user.currentWinStreak;
      xp = user.xp;
      rank = user.rank;
      winRate = user.winRate;
    } else {
      // Use history if available for other players, otherwise aggregate
      totalMatches = history.length > 0 ? history.length : player.totalMatches;
      wins = history.length > 0 ? history.where((m) => m.result == MatchResult.win).length : player.wins;
      streak = player.currentWinStreak;
      xp = player.xp;
      rank = player.rank;
      winRate = totalMatches > 0 ? (wins / totalMatches * 100) : 0.0;
    }

    final achievements = [
      {'id': 'first_win', 'name': 'First Blood', 'icon': Icons.flash_on_rounded},
      {'id': 'on_fire', 'name': 'On Fire', 'icon': Icons.whatshot},
      {'id': 'veteran', 'name': 'Veteran', 'icon': Icons.military_tech},
      {'id': 'scholar', 'name': 'Scholar', 'icon': Icons.school},
      {'id': 'arena_breaker', 'name': 'Arena Breaker', 'icon': Icons.security},
    ];

    final unlockedIds = user?.achievements ?? [];
    final unlocked = achievements.where((a) => unlockedIds.contains(a['id'])).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          // Main Stats Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(icon: Icons.stars_rounded, value: '$xp', label: 'XP', color: AppColors.purple),
                _StatItem(icon: Icons.emoji_events_rounded, value: '$wins', label: 'WINS', color: AppColors.teal),
                _StatItem(icon: Icons.whatshot_rounded, value: '$streak', label: 'STREAK', color: AppColors.red),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 16),

          // Details List
          _OverviewRow(label: 'Matches Played', value: '$totalMatches'),
          _OverviewRow(label: 'Win Rate', value: '${winRate.toStringAsFixed(1)}%'),
          _OverviewRow(label: 'Current Rank', value: RankSystem.getRankName(rank, user?.subRank ?? player.subRank)),
          _OverviewRow(label: 'Total XP', value: '$xp'),

          if (unlocked.isNotEmpty) ...[
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('ACHIEVEMENTS', style: AppTextStyles.label.copyWith(fontSize: 10, letterSpacing: 1, color: AppColors.textMuted)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: unlocked.map((a) => _AchievementChip(icon: a['icon'] as IconData, name: a['name'] as String)).toList(),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
          ],
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: AppTextStyles.headline.copyWith(fontSize: 18)),
        Text(label, style: AppTextStyles.label.copyWith(fontSize: 8, color: AppColors.textMuted)),
      ],
    );
  }
}

class _OverviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _OverviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTextStyles.headline.copyWith(fontSize: 16)),
        ],
      ),
    );
  }
}

class _ActionButton extends ConsumerWidget {
  final String uid;
  final bool isMe;

  const _ActionButton({required this.uid, required this.isMe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(friendsProvider);
    final isFriend = friends.contains(uid);

    return ElevatedButton(
      onPressed: () {
        if (isMe) {
          ref.read(tabIndexProvider.notifier).state = 3;
        } else if (isFriend) {
          _showRemoveDialog(context, ref);
        } else {
          ref.read(friendsProvider.notifier).update((s) => {...s, uid});
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isMe ? Colors.white : (isFriend ? AppColors.teal.withValues(alpha: 0.2) : AppColors.purple),
        minimumSize: const Size(120, 36),
        shape: const StadiumBorder(),
        side: isFriend ? const BorderSide(color: AppColors.teal, width: 1) : null,
        elevation: 0,
      ),
      child: Text(
        isMe ? 'Profile' : (isFriend ? '✓ Friends' : '+ Add Friend'),
        style: AppTextStyles.label.copyWith(
          color: isMe ? Colors.black : Colors.white, 
          fontWeight: FontWeight.bold, 
          fontSize: 11,
        ),
      ),
    );
  }

  void _showRemoveDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('Remove Friend?', style: AppTextStyles.headline.copyWith(fontSize: 18)),
        content: const Text('Are you sure you want to remove this friend?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(friendsProvider.notifier).update((s) {
                final n = Set<String>.from(s);
                n.remove(uid);
                return n;
              });
              Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}

class _AchievementChip extends StatelessWidget {
  final IconData icon;
  final String name;

  const _AchievementChip({required this.icon, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.gold, size: 14),
          const SizedBox(width: 8),
          Text(name.toUpperCase(), style: AppTextStyles.label.copyWith(color: AppColors.gold, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
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
      style: AppTextStyles.headline.copyWith(fontSize: 18, color: AppColors.textMuted),
    );
  }
}
