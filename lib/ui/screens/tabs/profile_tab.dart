import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/avatars.dart';
import '../../../providers/user_providers.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/achievement_providers.dart';
import '../../../providers/leaderboard_providers.dart';
import '../../../data/models/achievement_model.dart';
import '../../../core/errors/result.dart';
import '../../widgets/animated_coin_counter.dart';

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  Future<void> _changeAvatar(String uid) async {
    final selectedAvatar = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('SELECT NEW AVATAR', style: AppTextStyles.label.copyWith(color: AppColors.gold)),
            const SizedBox(height: 24),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: AppAvatars.avatars.length,
                itemBuilder: (context, index) {
                  final avatarUrl = AppAvatars.avatars[index];
                  return GestureDetector(
                    onTap: () => Navigator.pop(context, avatarUrl),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.surface,
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: avatarUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
                          errorWidget: (context, url, error) => const Icon(Icons.person),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (selectedAvatar != null && mounted) {
      await ref.read(userRepositoryProvider).updateAvatarUrl(uid, selectedAvatar);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (user) {
        if (user == null) return const Center(child: Text('User not found'));

        final achievementsAsync = ref.watch(userAchievementsProvider);

        return Scaffold(
          backgroundColor: AppColors.bgBase,
          appBar: AppBar(
            title: Text('PLAYER PROFILE', style: AppTextStyles.display.copyWith(fontSize: 18)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: AppColors.neonPink),
                onPressed: () => ref.read(authRepositoryProvider).logout(),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.surface,
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: user.avatarUrl ?? '',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const CircularProgressIndicator(),
                          errorWidget: (context, url, error) => const Icon(Icons.person, size: 40),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _changeAvatar(user.uid),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                          child: const Icon(Icons.edit_rounded, size: 16, color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(user.username, style: AppTextStyles.headline),
                Text(user.rank, style: AppTextStyles.label.copyWith(color: AppColors.gold)),

                const SizedBox(height: 32),

                // Stats Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ProfileStat(label: 'LEVEL', value: '${user.level}', color: AppColors.purple, icon: Icons.star_rounded),
                    _ProfileStat(label: 'WINS', value: '${user.wins}', color: AppColors.teal, icon: Icons.emoji_events_rounded),
                    Column(
                      children: [
                        const Icon(Icons.monetization_on_rounded, color: AppColors.gold, size: 24),
                        const SizedBox(height: 8),
                        AnimatedCoinCounter(
                          value: user.coins,
                          style: AppTextStyles.headline.copyWith(color: Colors.white, fontSize: 18),
                        ),
                        Text('COINS', style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Streak Stats
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.surface),
                  ),
                  child: Column(
                    children: [
                      _StreakRow(
                        label: 'Login Streak',
                        value: '${user.loginStreak} Days',
                        icon: Icons.whatshot_rounded,
                        color: AppColors.gold,
                      ),
                      const Divider(color: AppColors.surface, height: 32),
                      _StreakRow(
                        label: 'Current Win Streak',
                        value: '${user.currentWinStreak} Wins',
                        icon: Icons.auto_awesome_rounded,
                        color: AppColors.teal,
                      ),
                      const Divider(color: AppColors.surface, height: 32),
                      _StreakRow(
                        label: 'Highest Win Streak',
                        value: '${user.highestWinStreak} Wins',
                        icon: Icons.emoji_events_rounded,
                        color: AppColors.purple,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Achievement Grid
                Text('ACHIEVEMENTS', style: AppTextStyles.label),
                const SizedBox(height: 16),
                achievementsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Text('Error: $e'),
                  data: (achievements) => ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: achievements.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final ach = achievements[index];
                      return _AchievementTile(achievement: ach);
                    },
                  ),
                ),

                const SizedBox(height: 48),

                // Delete Account Button
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
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('DELETE ACCOUNT?', style: AppTextStyles.headline.copyWith(color: AppColors.red)),
        content: Text(
          'This action is permanent. All your XP, coins, and achievements will be lost forever.',
          style: AppTextStyles.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: AppTextStyles.label),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              // 1. Delete Firestore data first
              await ref.read(userRepositoryProvider).deleteUserProfile(uid);

              // 2. Delete Auth account
              final result = await ref.read(authRepositoryProvider).deleteAccount();

              if (context.mounted) {
                if (result case Failure(error: final e)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.message),
                      backgroundColor: AppColors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('DELETE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  const _AchievementTile({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final bool isUnlocked = achievement.isUnlocked;
    final double progressPercent = (achievement.progress / achievement.target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked ? AppColors.cardBg : AppColors.cardBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isUnlocked ? AppColors.gold : AppColors.surface, width: isUnlocked ? 2 : 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUnlocked ? AppColors.gold.withValues(alpha: 0.1) : AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIcon(achievement.type),
              color: isUnlocked ? AppColors.gold : AppColors.textMuted,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? Colors.white : AppColors.textMuted,
                  ),
                ),
                Text(
                  achievement.description,
                  style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressPercent,
                    backgroundColor: AppColors.surface,
                    color: isUnlocked ? AppColors.gold : AppColors.purple,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${achievement.progress}/${achievement.target}',
                      style: AppTextStyles.label.copyWith(fontSize: 9),
                    ),
                    Text(
                      'REWARD: ${achievement.rewardCoins} C',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 9,
                        color: isUnlocked ? AppColors.gold : AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(AchievementType type) {
    switch (type) {
      case AchievementType.matchesPlayed:
        return Icons.sports_esports_rounded;
      case AchievementType.matchesWon:
        return Icons.emoji_events_rounded;
      case AchievementType.questionsCorrect:
        return Icons.psychology_rounded;
      case AchievementType.perfectScores:
        return Icons.star_rounded;
    }
    return Icons.help_outline_rounded;
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

class _StreakRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StreakRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(label, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)),
        ),
        Text(value, style: AppTextStyles.headline.copyWith(fontSize: 18, color: color)),
      ],
    );
  }
}
