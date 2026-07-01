import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/battle_tab.dart';
import 'tabs/leaderboard_tab.dart';
import 'tabs/profile_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    const DashboardTab(),
    const BattleTab(),
    const LeaderboardTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
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
    final isSelected = _selectedIndex == index;
    return NavigationDestination(
      icon: Icon(icon, color: AppColors.textMuted),
      selectedIcon: Icon(activeIcon, color: AppColors.neonCyan),
      label: label,
    );
  }
}
