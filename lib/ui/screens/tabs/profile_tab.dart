// WHAT THIS FILE DOES:
// Displays the player's detailed stats and achievements grid.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../providers/user_providers.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/leaderboard_providers.dart';
import '../../../core/errors/result.dart';
import '../../widgets/character_avatar.dart';
import '../../widgets/neon_swirl_background.dart';
import '../character_select_screen.dart';
import '../../../core/utils/rank_calculator.dart';
import 'edit_profile_screen.dart';

import '../../widgets/xp_progress_bar.dart';
import '../../widgets/rank_badge.dart';
import '../../widgets/rank_progress_bar.dart';
import '../../../core/utils/rank_system.dart';

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('DELETE ACCOUNT?',
            style: TextStyle(
                color: AppColors.neonPink, fontWeight: FontWeight.w800)),
        content: const Text(
          'This action is permanent. All your XP, coins, and achievements will be lost forever.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL',
                style: TextStyle(color: AppColors.textPrimary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              // 1. Delete Firestore data first
              await ref.read(userRepositoryProvider).deleteUserProfile(uid);

              // 2. Delete Auth account
              final result =
                  await ref.read(authRepositoryProvider).deleteAccount();

              if (context.mounted && result is Failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.error.message),
                    backgroundColor: AppColors.neonPink,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonPink),
            child: const Text('DELETE',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.neonAmber)),
        child: CircularProgressIndicator(color: AppColors.gold),
      ),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (user) {
        if (user == null) {
          return const Center(child: Text('User profile not found.'));
        }

        final totalMatches = user.totalWins + user.totalLosses;

        final winRate = user.matchesPlayed > 0 
            ? (user.wins / user.matchesPlayed * 100).toStringAsFixed(1)
            : '0';

        final isMvp = weeklyMvp?.uid == user.uid;

        // List of all possible achievements to show "Locked" ones
        final allAchievements = [
          {
            'id': 'first_win',
            'name': 'First Blood',
            'desc': 'Win your first match',
            'icon': Icons.flash_on_rounded
          },
          {
            'id': 'on_fire',
            'name': 'On Fire',
            'desc': 'Win 3 games in a row',
            'icon': Icons.whatshot
          },
          {
            'id': 'veteran',
            'name': 'Veteran',
            'desc': 'Play 100 matches',
            'icon': Icons.military_tech
          },
          {
            'id': 'scholar',
            'name': 'Scholar',
            'desc': 'Get 10/10 in one match',
            'icon': Icons.school
          },
          {'id': 'first_win', 'name': 'First Blood', 'desc': 'Win your first match', 'icon': Icons.flash_on_rounded},
          {'id': 'on_fire', 'name': 'On Fire', 'desc': 'Win 3 games in a row', 'icon': Icons.whatshot},
          {'id': 'veteran', 'name': 'Veteran', 'desc': 'Win 10 matches', 'icon': Icons.military_tech},
          {'id': 'scholar', 'name': 'Scholar', 'desc': 'Get 10/10 in one match', 'icon': Icons.school},
        ];

        final character = kCharacters.firstWhere(
          (c) => c.id == (user.avatarUrl ?? ''),
          orElse: () => kCharacters.first,
        );

        final rankColor = RankCalculator.getRankColor(user.rank);
        final xpRatio = (user.xp / user.xpToNextLevel).clamp(0.0, 1.0);

        return Scaffold(
          backgroundColor: AppColors.bgBase,
          appBar: AppBar(
            title: const Text('PLAYER PROFILE',
                style: TextStyle(
                    letterSpacing: 3,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
            title: Text(
              'PLAYER PROFILE',
              style: AppTextStyles.display.copyWith(fontSize: 18),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon:
                    const Icon(Icons.logout_rounded, color: AppColors.neonPink),
                onPressed: () => ref.read(authRepositoryProvider).logout(),
              ),
            ],
          ),
          body: NeonSwirlBackground(
            colors: const [AppColors.neonCyan, AppColors.neonAmber],
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
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: rankColor.withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: CharacterAvatar(
                              character: character,
                              size: 100,
                              showGlow: true,
                              showBorder: true,
                            ),
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
                                            .updateAvatarUrl(
                                                user.uid, selected.id);
                                        if (context.mounted)
                                          Navigator.pop(context);
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
                                      color: AppColors.glowViolet,
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.surface,
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: user.avatarUrl ?? '',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.person, size: 40),
                Stack(
                  alignment: Alignment.bottomRight,
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
                    RankBadge(rank: user.rank, subRank: user.subRank, size: 36),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  user.username,
                  style: AppTextStyles.headline,
                ),
                Text(
                  user.rank,
                  style: AppTextStyles.label.copyWith(color: AppColors.gold),
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
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Stats Summary
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1B1B30),
                        Color(0xFF131325),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.3),
                    ),
                Text(user.username, style: AppTextStyles.headline),
                
                Text(user.rank, style: AppTextStyles.label.copyWith(color: AppColors.gold)),
                
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
                    _ProfileStat(label: 'WINS', value: '${user.totalWins}', color: AppColors.teal, icon: Icons.emoji_events_rounded),
                    _ProfileStat(label: 'COINS', value: '${user.coins}', color: AppColors.gold, icon: Icons.monetization_on_rounded),
                    _ProfileStat(label: 'STREAK', value: '${user.currentStreak}', color: AppColors.red, icon: Icons.whatshot_rounded),
                  ],
                ),

                const SizedBox(height: 40),
                Text(
                  RankSystem.getRankName(user.rank, user.subRank),
                  style: AppTextStyles.label.copyWith(
                    color: RankSystem.getRankColor(user.rank),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // XP Progress Bar
                XpProgressBar(totalXp: user.xp),
                
                if (user.rank != 'Legend' && user.rank != 'Unranked') ...[
                  const SizedBox(height: 16),
                  RankProgressBar(rank: user.rank, subRank: user.subRank, points: user.rankPoints),
                ],

                const SizedBox(height: 32),
                
                // Stats Summary
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.surface),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _ProfileInfoCard(
                              title: 'RANK',
                              value: user.rank,
                              icon: Icons.workspace_premium,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ProfileInfoCard(
                              title: 'COINS',
                              value: '${user.coins}',
                              icon: Icons.monetization_on,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _ProfileInfoCard(
                              title: 'MATCHES',
                              value: '$totalMatches',
                              icon: Icons.sports_esports,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ProfileInfoCard(
                              title: 'LEVEL',
                              value: '${user.level}',
                              icon: Icons.trending_up,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'XP PROGRESS',
                          style: AppTextStyles.label,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: user.xp / user.xpToNextLevel,
                          minHeight: 10,
                          backgroundColor: AppColors.surface,
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${user.xp}/${user.xpToNextLevel} XP',
                        style: AppTextStyles.label,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ProfileStat(label: 'PLAYED', value: '${user.matchesPlayed}'),
                          _ProfileStat(label: 'WINS', value: '${user.wins}'),
                          _ProfileStat(label: 'COINS', value: '${user.coins}'),
                        ],
                      ),
                      const Divider(color: AppColors.surface, height: 32, indent: 24, endIndent: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ProfileStat(label: 'LOSSES', value: '${user.losses}'),
                          _ProfileStat(label: 'DRAWS', value: '${user.draws}'),
                          _ProfileStat(label: 'WIN RATE', value: '$winRate%'),
                        ],
                      ),
                      const Divider(color: AppColors.surface, height: 32, indent: 24, endIndent: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ProfileStat(label: 'CURRENT STREAK', value: '${user.currentWinStreak}'),
                          _ProfileStat(label: 'HIGHEST STREAK', value: '${user.highestWinStreak}'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Achievement Grid
                Text('ACHIEVEMENTS', style: AppTextStyles.label),
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
                    final isUnlocked =
                        user.achievements.contains(achievement['id']);

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? AppColors.cardBg
                            : AppColors.cardBg.withValues(alpha: 0.3),
                        color: isUnlocked ? AppColors.cardBg : AppColors.cardBg.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: isUnlocked
                                ? AppColors.gold
                                : AppColors.surface),
                      ),
                      const SizedBox(height: 16),
                      Text(user.username,
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      Text(user.rank,
                          style: const TextStyle(
                              color: AppColors.neonAmber,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5)),

                      const SizedBox(height: 32),

                      // XP Bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('EXPERIENCE',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1)),
                              Text('LVL ${user.level}',
                                  style: const TextStyle(
                                      color: AppColors.neonAmber,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: xpRatio),
                            duration: const Duration(milliseconds: 1200),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Stack(
                                children: [
                                  Container(
                                    height: 8,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: AppColors.bgInputField,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: value,
                                    child: Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: [
                                          rankColor,
                                          rankColor.withValues(alpha: 0.6)
                                        ]),
                                        borderRadius: BorderRadius.circular(4),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                rankColor.withValues(alpha: 0.5),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          Icon(
                            achievement['icon'] as IconData,
                            color: isUnlocked
                                ? AppColors.gold
                                : AppColors.textMuted,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            achievement['name'] as String,
                            style: AppTextStyles.bodyMd.copyWith(
                              fontSize: 14,
                              color: isUnlocked
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('${user.xp} / ${user.xpToNextLevel} XP',
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 10)),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Stats Summary
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ProfileStat(label: 'LEVEL', value: '${user.level}'),
                          _ProfileStat(label: 'WINS', value: '${user.totalWins}'),
                          _ProfileStat(label: 'COINS', value: '${user.coins}'),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // Achievement Grid
                      const Text('ACHIEVEMENTS',
                          style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.5)),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: allAchievements.length,
                        itemBuilder: (context, index) {
                          final achievement = allAchievements[index];
                          final isUnlocked =
                              user.achievements.contains(achievement['id']);

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isUnlocked
                                  ? AppColors.bgCard
                                  : AppColors.bgCard.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: isUnlocked
                                      ? AppColors.neonAmber
                                      : AppColors.divider),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  achievement['icon'] as IconData,
                                  color: isUnlocked
                                      ? AppColors.neonAmber
                                      : AppColors.textMuted,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  achievement['name'] as String,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isUnlocked
                                        ? AppColors.textPrimary
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 48),

                      // Delete Account Button
                      TextButton.icon(
                        onPressed: () =>
                            _showDeleteConfirmation(context, ref, user.uid),
                        icon: const Icon(Icons.delete_forever_rounded,
                            color: AppColors.neonPink, size: 20),
                        label: const Text(
                          'DELETE ACCOUNT',
                          style: TextStyle(
                              color: AppColors.neonPink,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                // Delete Account Button
                TextButton.icon(
                  onPressed: () =>
                      _showDeleteConfirmation(context, ref, user.uid),
                  icon: const Icon(Icons.delete_forever_rounded,
                      color: AppColors.red, size: 20),
                  label: Text(
                    'DELETE ACCOUNT',
                    style: AppTextStyles.label.copyWith(
                        color: AppColors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('DELETE ACCOUNT?',
            style: AppTextStyles.headline.copyWith(color: AppColors.red)),
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
              final result =
                  await ref.read(authRepositoryProvider).deleteAccount();

              if (context.mounted && result is Failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.error.message),
                    backgroundColor: AppColors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('DELETE',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  
  const _ProfileStat({
    required this.label, 
    required this.value, 
    required this.color, 
    required this.icon
  final IconData icon;

  const _ProfileInfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: AppColors.neonCyan, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonCyan.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: AppColors.neonAmber,
                  fontSize: 24,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600)),
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: AppTextStyles.headline.copyWith(color: Colors.white, fontSize: 20)),
        Text(label, style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.textMuted)),
      ],
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.surface,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.gold,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.headline,
          ),
          Text(
            title,
            style: AppTextStyles.label,
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

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
