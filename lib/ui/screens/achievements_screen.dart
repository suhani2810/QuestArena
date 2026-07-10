import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../providers/achievement_providers.dart';
import '../../providers/user_providers.dart';
import '../../providers/auth_providers.dart';
import '../../providers/avatar_providers.dart';
import '../../providers/border_providers.dart';
import '../../data/models/achievement_model.dart';
import '../../data/models/user_model.dart';
import '../../core/errors/result.dart';
import '../widgets/neon_swirl_background.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('ACHIEVEMENTS', style: AppTextStyles.display.copyWith(fontSize: 18, letterSpacing: 4)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _isSyncing ? null : () => _syncAchievements(user),
            icon: _isSyncing 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold))
                : const Icon(Icons.sync_rounded, color: AppColors.gold),
          ),
        ],
      ),
      body: NeonSwirlBackground(
        colors: const [AppColors.purple, AppColors.neonPink],
        child: _buildAchievementsList(user.uid),
      ),
    );
  }

  Future<void> _syncAchievements(UserModel user) async {
    setState(() => _isSyncing = true);
    try {
      final userRepo = ref.read(userRepositoryProvider);
      final auth = ref.read(authStateProvider).value;
      if (auth == null) return;
      
      final userResult = await userRepo.getUserProfile(auth.uid);
      if (userResult is Success<UserModel>) {
        final freshUser = userResult.data;
        await ref.read(achievementServiceProvider).syncAll(freshUser);
        await ref.read(avatarServiceProvider).checkAndUnlockLeagues(freshUser.uid, freshUser.rank);
        await ref.read(borderServiceProvider).checkAndUnlockLeagues(freshUser.uid, freshUser.rank);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Achievements Synced! 🔥'),
              backgroundColor: AppColors.teal,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e'), backgroundColor: AppColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Widget _buildAchievementsList(String uid) {
    final achievementsAsync = ref.watch(userAchievementsProvider);

    return achievementsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      data: (achievements) {
        if (achievements.isEmpty) {
          return const Center(child: Text('No achievements found.', style: TextStyle(color: Colors.white70)));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: achievements.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return _AchievementTile(achievement: achievements[index], uid: uid);
          },
        );
      },
    );
  }
}

class _AchievementTile extends ConsumerWidget {
  final Achievement achievement;
  final String uid;

  const _AchievementTile({required this.achievement, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isUnlocked = achievement.isUnlocked;
    final bool isClaimed = achievement.isClaimed;
    final double progressPercent = (achievement.progress / achievement.target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked ? AppColors.cardBg : AppColors.cardBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isClaimed 
              ? Colors.green.withValues(alpha: 0.5) 
              : (isUnlocked ? AppColors.gold : AppColors.surface),
          width: isUnlocked ? 2 : 1,
        ),
        boxShadow: isUnlocked && !isClaimed ? [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ] : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isUnlocked ? AppColors.gold.withValues(alpha: 0.1) : Colors.black12,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIcon(achievement.type),
                  color: isUnlocked ? AppColors.gold : AppColors.textMuted,
                  size: 24,
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
                      style: AppTextStyles.label.copyWith(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (isClaimed)
                _buildStatusBadge('CLAIMED', Colors.green)
              else if (isUnlocked)
                _buildClaimButton(context, ref)
              else
                _buildStatusBadge('LOCKED', AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressPercent,
                    backgroundColor: AppColors.surface,
                    color: isUnlocked ? AppColors.gold : AppColors.purple,
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${achievement.progress}/${achievement.target}',
                style: AppTextStyles.label.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildRewardsInfo(),
        ],
      ),
    );
  }

  Widget _buildRewardsInfo() {
    final reward = achievement.reward;
    List<Widget> rewards = [];

    if (reward.coins > 0) {
      rewards.add(_rewardItem(Icons.monetization_on_rounded, '${reward.coins}', AppColors.gold));
    }
    if (reward.xp > 0) {
      rewards.add(_rewardItem(Icons.stars_rounded, '${reward.xp} XP', AppColors.purple));
    }
    if (reward.avatarId != null) {
      rewards.add(_rewardItem(Icons.person_rounded, 'AVATAR', AppColors.neonCyan));
    }
    if (reward.borderId != null) {
      rewards.add(_rewardItem(Icons.verified_user_rounded, 'BORDER', AppColors.gold));
    }

    return Row(
      children: [
        Text('REWARD: ', style: AppTextStyles.label.copyWith(fontSize: 9, color: AppColors.textMuted)),
        ...rewards.expand((w) => [w, const SizedBox(width: 8)]).toList()..removeLast(),
      ],
    );
  }

  Widget _rewardItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(text, style: AppTextStyles.label.copyWith(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildClaimButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: () async {
          final result = await ref.read(achievementServiceProvider).claimReward(uid, achievement.id);
          if (result is Failure && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to claim: ${result.error.message}'), backgroundColor: AppColors.red),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
        child: const Text('CLAIM'),
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
      case AchievementType.loginStreak:
        return Icons.whatshot_rounded;
      case AchievementType.rankReached:
        return Icons.workspace_premium_rounded;
      case AchievementType.winStreak:
        return Icons.flash_on_rounded;
      case AchievementType.levelReached:
        return Icons.military_tech_rounded;
      case AchievementType.accuracy:
        return Icons.my_location_rounded;
      case AchievementType.arenaBreakerWins:
        return Icons.shield_rounded;
    }
  }
}
