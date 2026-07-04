import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/rank_system.dart';
import '../../../providers/user_providers.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/leaderboard_providers.dart';
import '../../../data/models/leaderboard_model.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/xp_progress_bar.dart';
import '../../widgets/rank_progress_bar.dart';
import '../../widgets/neon_swirl_background.dart';
import '../../widgets/smart_avatar.dart';
import 'edit_profile_screen.dart';
import 'leaderboard_tab.dart'; 

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
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showDeleteConfirmation(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('DELETE ACCOUNT?', style: AppTextStyles.headline.copyWith(color: AppColors.red)),
        content: const Text('This action is permanent. All your data will be lost.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('CANCEL', style: AppTextStyles.label)),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(userRepositoryProvider).deleteUserProfile(uid);
              await ref.read(authRepositoryProvider).deleteAccount();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('DELETE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _reportIssue() {
    // ignore: deprecated_member_use
    Share.share('Hi support, I found an issue in QuestArena: ', subject: 'QuestArena Bug Report');
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final weeklyMvp = ref.watch(weeklyMvpProvider);

    return userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (user) {
        if (user == null) return const Center(child: Text('User not found'));
        final isMvp = (weeklyMvp != null && weeklyMvp.uid == user.uid);

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text('PLAYER PROFILE', style: AppTextStyles.display.copyWith(fontSize: 18, letterSpacing: 2)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
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
                      SmartAvatar(avatarUrl: user.avatarUrl, size: 110, showGlow: true, showBorder: true),
                      const SizedBox(height: 16),
                      Text(user.username, style: AppTextStyles.headline.copyWith(fontSize: 24)),
                      Text(
                        RankSystem.getRankName(user.rank, user.subRank),
                        style: AppTextStyles.label.copyWith(color: AppColors.gold, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                          icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.white),
                          label: const Text('EDIT PROFILE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.purple.withValues(alpha: 0.6),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.neonViolet.withValues(alpha: 0.3))),
                          ),
                        ),
                      ),

                      if (isMvp) _buildMvpBadge(),
                      const SizedBox(height: 40),

                      _buildStatsOverview(user),

                      const SizedBox(height: 32),

                      _buildProgressSection(user),
                      
                      const SizedBox(height: 32),

                      const _FriendRequestsSection(),
                      const _FriendsListSection(),

                      const SizedBox(height: 32),

                      _buildDetailedStats(user),

                      const SizedBox(height: 48),

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.surface),
                        ),
                        child: Column(
                          children: [
                            const Text('NEED HELP?', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                            const SizedBox(height: 16),
                            _SupportButton(
                              icon: Icons.bug_report_rounded,
                              label: 'REPORT AN ISSUE',
                              color: AppColors.neonPink,
                              onTap: _reportIssue,
                            ),
                            const Divider(color: AppColors.surface, height: 24),
                            Text(
                              'Email: imaginati.appdev@gmail.com',
                              style: AppTextStyles.label.copyWith(fontSize: 9, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      TextButton.icon(
                        onPressed: () => _showDeleteConfirmation(context, user.uid),
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

  Widget _buildMvpBadge() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 14),
              const SizedBox(width: 6),
              Text('🏆 MVP HOLDER', style: AppTextStyles.label.copyWith(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsOverview(UserModel user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ProfileStat(label: 'XP', value: '${user.xp}', color: AppColors.purple, icon: Icons.stars_rounded),
        _ProfileStat(label: 'WINS', value: '${user.wins}', color: AppColors.teal, icon: Icons.emoji_events_rounded),
        _ProfileStat(label: 'COINS', value: '${user.coins}', color: AppColors.gold, icon: Icons.monetization_on_rounded),
        _ProfileStat(label: 'STREAK', value: '${user.currentWinStreak}', color: AppColors.red, icon: Icons.whatshot_rounded),
      ],
    );
  }

  Widget _buildProgressSection(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surface),
      ),
      child: Column(
        children: [
          XpProgressBar(totalXp: user.xp),
          if (user.rank != 'Legend' && user.rank != 'Unranked') ...[
            const SizedBox(height: 20),
            RankProgressBar(rank: user.rank, subRank: user.subRank, points: user.rankPoints),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailedStats(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surface),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ProfileStatItem(label: 'MATCHES', value: '${user.matchesPlayed}'),
              _ProfileStatItem(label: 'WIN RATE', value: '${user.winRate.toStringAsFixed(0)}%'),
              _ProfileStatItem(label: 'LEVEL', value: '${user.level}'),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: AppColors.surface, height: 1)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ProfileStatItem(label: 'LOSSES', value: '${user.losses}'),
              _ProfileStatItem(label: 'DRAWS', value: '${user.draws}'),
              _ProfileStatItem(label: 'BEST STREAK', value: '${user.highestWinStreak}'),
            ],
          ),
        ],
      ),
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

class _ProfileStatItem extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileStatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.headline.copyWith(fontSize: 20)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.label.copyWith(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _SupportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SupportButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 12),
            Text(label, style: AppTextStyles.label.copyWith(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _FriendRequestsSection extends ConsumerWidget {
  const _FriendRequestsSection();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(incomingRequestsProvider);
    return requestsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
      data: (requests) {
        if (requests.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('FRIEND REQUESTS', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                final data = request.data();
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surface),
                  ),
                  child: Row(
                    children: [
                      SmartAvatar(avatarUrl: data['senderAvatar'], size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['senderUsername'], style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)),
                            Text('Sent you a request', style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => ref.read(friendsRepositoryProvider).acceptFriendRequest(request.id, data),
                            icon: const Icon(Icons.check_circle_rounded, color: AppColors.teal),
                          ),
                          IconButton(
                            onPressed: () => ref.read(friendsRepositoryProvider).rejectFriendRequest(request.id),
                            icon: const Icon(Icons.cancel_rounded, color: AppColors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}

class _FriendsListSection extends ConsumerWidget {
  const _FriendsListSection();
  void _showFriendProfile(BuildContext context, WidgetRef ref, LeaderboardModel friend) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    SmartAvatar(avatarUrl: friend.avatarUrl, size: 60),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(friend.username, style: AppTextStyles.headline.copyWith(fontSize: 20)),
                          Text('LVL ${friend.level} • ${RankSystem.getRankName(friend.rank, friend.subRank)}',
                            style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ExpandedDetails(uid: friend.uid, player: friend, isMe: false),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('CLOSE', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('FRIENDS', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 16),
        friendsAsync.when(
          loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
          error: (e, s) => Text('Error: $e'),
          data: (friends) {
            if (friends.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('You haven\'t added any friends yet.', style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted)),
              );
            }
            return SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  return GestureDetector(
                    onTap: () => _showFriendProfile(context, ref, friend),
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.surface),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SmartAvatar(avatarUrl: friend.avatarUrl, size: 40),
                          const SizedBox(height: 8),
                          Text(friend.username, style: AppTextStyles.bodyMd.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('LVL ${friend.level}', style: AppTextStyles.label.copyWith(fontSize: 9, color: AppColors.gold)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
