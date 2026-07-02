// WHAT THIS FILE DOES:
// Main navigation hub with automatic daily reward logic.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../providers/user_providers.dart';
import '../../providers/streak_providers.dart';
import '../../providers/achievement_providers.dart';
import '../../core/errors/result.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/battle_tab.dart';
import 'tabs/leaderboard_tab.dart';
import 'tabs/profile_tab.dart';
import '../widgets/streak_reward_popup.dart';
import '../widgets/achievement_popup.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  bool _checkedDailyReward = false;

  final List<Widget> _tabs = [
    const DashboardTab(),
    const BattleTab(),
    const LeaderboardTab(),
    const ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyReward();
    });
  }

  void _checkDailyReward() async {
    if (_checkedDailyReward) return;

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    _checkedDailyReward = true;

    // Check Login Streak
    final streakService = ref.read(streakServiceProvider);
    final streakResult = await streakService.checkAndUpdateLoginStreak(user);

    if (mounted && streakResult is Success<int> && streakResult.data > 0) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => StreakRewardPopup(
          title: '7-DAY STREAK',
          message: 'Consistency is key! 🔥',
          reward: streakResult.data,
          icon: Icons.whatshot_rounded,
          color: AppColors.gold,
          onClaim: () => Navigator.pop(context),
        ),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for achievements
    ref.listen(lastUnlockedAchievementProvider, (previous, next) {
      if (next != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AchievementPopup(
            achievement: next,
            onDismiss: () {
              Navigator.pop(context);
              ref.read(lastUnlockedAchievementProvider.notifier).state = null;
            },
          ),
        );
      }
    });

    // Listen for user data to trigger daily reward check once loaded
    ref.listen(currentUserProvider, (previous, next) {
      if (next.value != null && !_checkedDailyReward) {
        _checkDailyReward();
      }
    });

    return Scaffold(
      body: _tabs[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider.withValues(alpha: 0.5), width: 0.5)),
        ),
        child: NavigationBar(
          height: 65,
          elevation: 0,
          backgroundColor: AppColors.bgBase,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) => setState(() => _selectedIndex = index),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          indicatorColor: AppColors.neonCyan.withValues(alpha: 0.1),
          destinations: [
            _buildNavItem(0, Icons.dashboard_rounded, Icons.dashboard_outlined, 'HUB'),
            _buildNavItem(1, Icons.bolt_rounded, Icons.bolt_outlined, 'BATTLE'),
            _buildNavItem(2, Icons.leaderboard_rounded, Icons.leaderboard_outlined, 'RANKS'),
            _buildNavItem(3, Icons.person_rounded, Icons.person_outlined, 'PROFILE'),
          ],
        ),
      ),
    );
  }

  NavigationDestination _buildNavItem(int index, IconData activeIcon, IconData icon, String label) {
    return NavigationDestination(
      icon: Icon(icon, color: AppColors.textMuted),
      selectedIcon: Icon(activeIcon, color: AppColors.neonCyan),
      label: label,
    );
  }
}
