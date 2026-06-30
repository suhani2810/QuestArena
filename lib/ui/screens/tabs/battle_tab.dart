import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../providers/user_providers.dart';
import '../../../providers/matchmaking_providers.dart';
import '../../../data/models/matchmaking_model.dart';
import '../../widgets/category_picker_sheet.dart';
import '../../widgets/neon_swirl_background.dart';
import '../matchmaking_screen.dart';
import '../private_room_screen.dart';
import '../practice_screen.dart';

class BattleTab extends ConsumerStatefulWidget {
  const BattleTab({super.key});

  @override
  ConsumerState<BattleTab> createState() => _BattleTabState();
}

class _BattleTabState extends ConsumerState<BattleTab> with TickerProviderStateMixin {
  bool _isStartingMatch = false;

  Future<void> _chooseAndStartMatch() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    final category = await CategoryPickerSheet.show(context);
    if (category == null || !mounted) return;

    setState(() => _isStartingMatch = true);
    try {
      final ticket = MatchmakingModel(
        uid: user.uid,
        username: user.username,
        avatarUrl: user.avatarUrl,
        rank: user.rank,
        categoryId: category.id,
        categoryName: category.name,
        searchStartedAt: DateTime.now(),
      );
      await ref.read(matchmakingRepositoryProvider).startSearching(ticket);
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchmakingScreen()));
      }
    } finally {
      if (mounted) setState(() => _isStartingMatch = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: NeonSwirlBackground(
        colors: const [AppColors.neonViolet, AppColors.neonCyan],
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BATTLE HUB', style: AppTextStyles.display),
                Text('Select your challenge', style: AppTextStyles.label),
                
                const SizedBox(height: 40),
                
                _BattleModeCard(
                  title: 'RANKED MATCH',
                  subtitle: _isStartingMatch ? 'Starting...' : 'Compete for XP and Rank',
                  icon: _isStartingMatch ? Icons.hourglass_bottom_rounded : Icons.flash_on_rounded,
                  color: AppColors.purple,
                  onTap: _isStartingMatch ? () {} : _chooseAndStartMatch,
                ),
                
                const SizedBox(height: 16),
                
                _BattleModeCard(
                  title: 'PRIVATE DUEL',
                  subtitle: 'Play against a friend',
                  icon: Icons.vpn_key_rounded,
                  color: AppColors.gold,
                  onTap: _isStartingMatch ? () {} : () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivateRoomScreen()));
                  },
                ),
                
                const SizedBox(height: 16),
                
                _BattleModeCard(
                  title: 'PRACTICE',
                  subtitle: 'Sharpen your skills (No XP)',
                  icon: Icons.psychology_rounded,
                  color: AppColors.teal,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PracticeScreen()));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BattleModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _BattleModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.headline.copyWith(fontSize: 18, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }
}
