// WHAT THIS FILE DOES:
// The final completed main hub.
// Now handles background match reconnection checks with user confirmation.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../providers/game_providers.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/battle_tab.dart';
import 'tabs/leaderboard_tab.dart';
import 'tabs/profile_tab.dart';
import 'game_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const DashboardTab(),
    const BattleTab(),
    const LeaderboardTab(),
    const ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    // Silently check for active matches that the user might have disconnected from
    _checkActiveMatch();
  }

  void _checkActiveMatch() async {
    // Small delay to let the Home Screen render first
    await Future.delayed(const Duration(seconds: 1));
    
    final match = await ref.read(activeMatchProvider.future);
    
    if (match != null && mounted) {
      // Show a dialog to the user instead of jumping automatically
      // This preserves the Home Screen as the main entry point (Previous functionality)
      _showReconnectionDialog(match.roomId);
    }
  }

  void _showReconnectionDialog(String roomId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('MATCH IN PROGRESS', style: AppTextStyles.headline.copyWith(color: AppColors.gold)),
        content: const Text(
          'We found an active match you were part of. Would you like to reconnect and continue?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('DISCARD', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => GameScreen(roomId: roomId)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('RECONNECT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.primaryBg,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.flash_on_rounded), label: 'Battle'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard_rounded), label: 'Rank'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
