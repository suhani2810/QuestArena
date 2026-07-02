import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/rank_system.dart';
import '../../../providers/user_providers.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/leaderboard_providers.dart';
import '../../widgets/character_avatar.dart';
import '../../widgets/xp_progress_bar.dart';
import '../../widgets/rank_progress_bar.dart';
import '../../widgets/neon_swirl_background.dart';
import '../../widgets/smart_avatar.dart';
import '../character_select_screen.dart';
import 'edit_profile_screen.dart';

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Delete Account?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This action is permanent and will delete all your progress, ranks, and coins.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Implementation of delete account would go here
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final weeklyMvp = ref.watch(weeklyMvpProvider);

    return userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (user) {
        if (user == null) {
          return const Center(child: Text('User profile not found.'));
        }

        final isMvp = weeklyMvp?.uid == user.uid;
        final winRate = user.matchesPlayed > 0 
            ? (user.wins / user.matchesPlayed * 100).toStringAsFixed(1)
            : '0';

        final allAchievements = [
          {'id': 'first_win', 'name': 'First Blood', 'desc': 'Win your first match', 'icon': Icons.flash_on_rounded},
          {'id': 'on_fire', 'name': 'On Fire', 'desc': 'Win 3 games in a row', 'icon': Icons.whatshot},
          {'id': 'veteran', 'name': 'Veteran', 'desc': 'Win 10 matches', 'icon': Icons.military_tech},
          {'id': 'scholar', 'name': 'Scholar', 'desc': 'Get 10/10 in one match', 'icon': Icons.school},
        ];

        return Scaffold(
          backgroundColor: AppColors.bgBase,
          appBar: AppBar(
            title: const Text('PLAYER PROFILE',
                style: TextStyle(
                    letterSpacing: 3,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: AppColors.red),
                onPressed: () => ref.read(authRepositoryProvider).logout(),
              ),
            ],
          ),
          body: NeonSwirlBackground(
            colors: const [AppColors.neonCyan, AppColors.neonViolet],
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Header
                      Stack(
                        children: [
                          SmartAvatar(
                            avatarUrl: user.avatarUrl,
                            size: 100,
                            showGlow: true,
                            showBorder: true,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CharacterSelectScreen(
                                      username: user.username,
                                      onConfirm: (selected) async {
                                        await ref
                                            .read(userRepositoryProvider)
                                            .updateAvatarUrl(user.uid, selected.id);
                                        if (context.mounted) Navigator.pop(context);
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppColors.neonViolet,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 8,
                                    )
                                  ],
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      Text(user.username, style: AppTextStyles.headline),
                      Text(
                        RankSystem.getRankName(user.rank, user.subRank),
                        style: AppTextStyles.label.copyWith(color: AppColors.gold, fontWeight: FontWeight.bold),
                      ),
                      
                      const SizedBox(height: 16),

                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditProfileScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                        label: const Text('Edit Details', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purple.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      if (isMvp) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'MVP HOLDER', 
                                style: AppTextStyles.label.copyWith(
                                  color: AppColors.gold, 
                                  fontSize: 11, 
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 32),
                      
                      // Main Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ProfileStat(label: 'XP', value: '${user.xp}', color: AppColors.purple, icon: Icons.stars_rounded),
                          _ProfileStat(label: 'WINS', value: '${user.wins}', color: AppColors.teal, icon: Icons.emoji_events_rounded),
                          _ProfileStat(label: 'COINS', value: '${user.coins}', color: AppColors.gold, icon: Icons.monetization_on_rounded),
                          _ProfileStat(label: 'STREAK', value: '${user.currentWinStreak}', color: AppColors.red, icon: Icons.whatshot_rounded),
                        ],
                      ),

                      const SizedBox(height: 40),
                      
                      // Progress Bars
                      XpProgressBar(totalXp: user.xp),
                      
                      if (user.rank != 'Legend' && user.rank != 'Unranked') ...[
                        const SizedBox(height: 24),
                        RankProgressBar(rank: user.rank, subRank: user.subRank, points: user.rankPoints),
                      ],

                      const SizedBox(height: 32),
                      
                      // Detailed Stats Summary
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.surface),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _StatItem(label: 'MATCHES', value: '${user.matchesPlayed}'),
                                _StatItem(label: 'WIN RATE', value: '$winRate%'),
                                _StatItem(label: 'LEVEL', value: '${user.level}'),
                              ],
                            ),
                            const Divider(color: AppColors.surface, height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _StatItem(label: 'LOSSES', value: '${user.losses}'),
                                _StatItem(label: 'DRAWS', value: '${user.draws}'),
                                _StatItem(label: 'BEST STREAK', value: '${user.highestWinStreak}'),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Achievement Grid
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('ACHIEVEMENTS', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: allAchievements.length,
                        itemBuilder: (context, index) {
                          final achievement = allAchievements[index];
                          final isUnlocked = user.achievements.contains(achievement['id']);

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isUnlocked
                                  ? AppColors.cardBg
                                  : AppColors.cardBg.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: isUnlocked ? AppColors.gold.withValues(alpha: 0.5) : AppColors.surface),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  achievement['icon'] as IconData,
                                  color: isUnlocked ? AppColors.gold : AppColors.textMuted,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  achievement['name'] as String,
                                  style: AppTextStyles.bodyMd.copyWith(
                                    fontSize: 14,
                                    color: isUnlocked ? AppColors.textPrimary : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 48),

                      TextButton.icon(
                        onPressed: () => _showDeleteConfirmation(context, ref, user.uid),
                        icon: const Icon(Icons.delete_forever_rounded, color: AppColors.red, size: 20),
                        label: Text(
                          'DELETE ACCOUNT',
                          style: AppTextStyles.label.copyWith(color: AppColors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 24),
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

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _ProfileStat({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: AppTextStyles.headline.copyWith(fontSize: 18, color: Colors.white)),
        Text(label, style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.headline.copyWith(fontSize: 18)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.label.copyWith(fontSize: 9, color: AppColors.textSecondary)),
      ],
    );
  }
}
