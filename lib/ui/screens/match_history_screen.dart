import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../providers/user_providers.dart';
import '../widgets/smart_avatar.dart';
import '../widgets/neon_swirl_background.dart';
import 'match_summary_screen.dart';

class MatchHistoryScreen extends ConsumerWidget {
  const MatchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(matchHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        title: Text('BATTLE HISTORY', style: AppTextStyles.display.copyWith(fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: NeonSwirlBackground(
        colors: const [AppColors.neonCyan, AppColors.purple],
        child: historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
          error: (e, s) {
            debugPrint('Match History Screen Error: $e');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.history_toggle_off_rounded, size: 64, color: AppColors.textMuted),
                    const SizedBox(height: 24),
                    Text(
                      'UNABLE TO LOAD HISTORY',
                      style: AppTextStyles.headline.copyWith(color: Colors.white, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We encountered a database issue while fetching your records. Please check back in a few minutes.',
                      style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
          data: (history) {
            if (history.isEmpty) {
              return const Center(
                child: Text('No matches recorded yet.', style: TextStyle(color: AppColors.textMuted)),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final match = history[index];
                final isWin = match.playerScore > match.opponentScore;
                final isDraw = match.playerScore == match.opponentScore;

                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MatchSummaryScreen(match: match)),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isWin ? AppColors.teal.withValues(alpha: 0.3) : AppColors.surface,
                      ),
                    ),
                    child: Row(
                      children: [
                        SmartAvatar(
                          avatarUrl: match.opponentAvatarUrl,
                          size: 50,
                          showBorder: true,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                match.opponentName,
                                style: AppTextStyles.headline.copyWith(fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${match.matchTypeLabel} • ${isWin ? 'VICTORY' : (isDraw ? 'DRAW' : 'DEFEAT')}',
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 10,
                                  color: isWin ? AppColors.teal : (isDraw ? AppColors.gold : AppColors.red),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (match.matchTypeLabel == 'Ranked' && match.rpChange != 0)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${match.playerScore} - ${match.opponentScore}',
                                style: AppTextStyles.display.copyWith(fontSize: 20),
                              ),
                              Text(
                                match.rpChange > 0 ? '+${match.rpChange} RP' : '${match.rpChange} RP',
                                style: AppTextStyles.label.copyWith(
                                  color: match.rpChange > 0 ? AppColors.teal : AppColors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${match.playerScore} - ${match.opponentScore}',
                                style: AppTextStyles.display.copyWith(fontSize: 20),
                              ),
                              Text(
                                '+${match.xpEarned} XP',
                                style: AppTextStyles.label.copyWith(color: AppColors.gold, fontSize: 10),
                              ),
                            ],
                          ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1, end: 0);
              },
            );
          },
        ),
      ),
    );
  }
}
