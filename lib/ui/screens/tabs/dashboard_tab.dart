// WHAT THIS FILE DOES:
// Shows the player's summary, stats, and quick-start button.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../providers/user_providers.dart';

import '../matchmaking_screen.dart';
import '../../../data/models/matchmaking_model.dart';
import '../../../providers/matchmaking_providers.dart';

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;

    if (user == null) return const Center(child: CircularProgressIndicator());

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Player Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.surface),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: NetworkImage(user.avatarUrl ?? ''),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.username, style: AppTextStyles.headline),
                        Text('Rank: ${user.rank}', style: AppTextStyles.label.copyWith(color: AppColors.gold)),
                        const SizedBox(height: 8),
                        // XP Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: user.xp / user.xpToNextLevel,
                            backgroundColor: AppColors.surface,
                            color: AppColors.gold,
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Level ${user.level} - ${user.xp}/${user.xpToNextLevel} XP', style: AppTextStyles.label),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            Text('QUICK STATS', style: AppTextStyles.label),
            const SizedBox(height: 12),
            
            Row(
              children: [
                _StatCard(label: 'WINS', value: user.totalWins.toString(), color: AppColors.teal),
                const SizedBox(width: 16),
                _StatCard(label: 'LOSSES', value: user.totalLosses.toString(), color: AppColors.red),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // Play Button
            GestureDetector(
              onTap: () async {
                final ticket = MatchmakingModel(
                  uid: user.uid,
                  username: user.username,
                  avatarUrl: user.avatarUrl,
                  rank: user.rank,
                  searchStartedAt: DateTime.now(),
                );
                
                // 1. Write the ticket to Firestore
                await ref.read(matchmakingRepositoryProvider).startSearching(ticket);
                
                // 2. Navigate to Matchmaking Screen
                if (context.mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MatchmakingScreen()),
                  );
                }
              },
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.purple, Color(0xFF5A3EBC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: AppColors.purple.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(Icons.flash_on_rounded, size: 150, color: Colors.white.withOpacity(0.1)),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow_rounded, size: 50, color: Colors.white),
                          Text('BATTLE NOW', style: AppTextStyles.display.copyWith(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surface),
        ),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.headline.copyWith(color: color)),
            Text(label, style: AppTextStyles.label),
          ],
        ),
      ),
    );
  }
}
