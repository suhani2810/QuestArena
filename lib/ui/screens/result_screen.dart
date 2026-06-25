// WHAT THIS FILE DOES:
// Displays the final scores, the winner, and rewards (XP/Coins).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../providers/user_providers.dart';
import '../../providers/game_providers.dart';
import '../../data/models/game_room_model.dart';
import '../../data/models/match_history_model.dart';
import '../../data/models/match_end_result.dart';
import '../../core/utils/level_system.dart';
import '../../core/utils/rank_system.dart';
import '../widgets/xp_progress_bar.dart';
import '../widgets/xp_summary_card.dart';
import '../widgets/rank_badge.dart';
import '../widgets/rank_progress_bar.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final GameRoomModel room;
  const ResultScreen({super.key, required this.room});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  bool _rewardsClaimed = false;
  MatchEndResult? _matchResult;
  bool _leveledUp = false;

  @override
  void initState() {
    super.initState();
    _handleRewards();
  }

  void _handleRewards() async {
    if (_rewardsClaimed) return;

    try {
      final userValue = ref.read(currentUserProvider);
      final currentUser = userValue.value;
      
      if (currentUser == null) {
        // If data is still loading or null, wait and retry a few times
        debugPrint('Current user is null, retrying reward claim...');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) _handleRewards();
        return;
      }

      final isWinner = widget.room.winnerId == currentUser.uid;
      final isDraw = widget.room.winnerId == 'draw';

      final myScore = currentUser.uid == widget.room.player1['uid'] 
          ? widget.room.player1['score'] 
          : (widget.room.player2?['score'] ?? 0);
      
      final correctAnswers = myScore ~/ 10;
      const totalQuestions = 10;

      final oldLevel = currentUser.level;

      // 1. Process XP and Rank updates
      final result = await ref.read(userRepositoryProvider).processMatchEnd(
        uid: currentUser.uid,
        isWin: isWinner,
        isDraw: isDraw,
        correctAnswers: correctAnswers,
        totalQuestions: totalQuestions,
        coinsGained: isWinner ? 20 : 5,
      );

      final opponentScore = currentUser.uid == widget.room.player1['uid'] 
          ? (widget.room.player2?['score'] ?? 0)
          : widget.room.player1['score'];
          
      final opponentName = currentUser.uid == widget.room.player1['uid']
          ? (widget.room.player2?['username'] ?? 'Opponent')
          : widget.room.player1['username'];

      final history = MatchHistoryModel(
        matchId: widget.room.roomId,
        opponentName: opponentName,
        isWin: isWinner,
        myScore: myScore,
        opponentScore: opponentScore,
        xpGained: result?.xpRewards.total ?? 0,
        playedAt: DateTime.now(),
      );

      // 2. Mark rewards as claimed and save history
      await Future.wait([
        ref.read(gameRepositoryProvider).claimRewards(
          widget.room.roomId,
          currentUser.uid,
          isWinner,
        ),
        ref.read(userRepositoryProvider).saveMatchHistory(currentUser.uid, history),
      ]).timeout(const Duration(seconds: 10));
      
      if (mounted) {
        setState(() {
          _matchResult = result;
          _rewardsClaimed = true;
          if (result != null) {
            _leveledUp = LevelSystem.getCurrentLevel(currentUser.xp + result.xpRewards.total) > oldLevel;
          }
        });
      }
    } catch (e) {
      debugPrint('Error claiming rewards: $e');
      if (mounted) {
        setState(() => _rewardsClaimed = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rewards saved, but some data might be delayed.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;
    if (currentUser == null) return const Scaffold();

    final isWinner = widget.room.winnerId == currentUser.uid;
    final isDraw = widget.room.winnerId == 'draw';
    
    final myScore = currentUser.uid == widget.room.player1['uid'] 
        ? widget.room.player1['score'] 
        : (widget.room.player2?['score'] ?? 0);
        
    final opponentScore = currentUser.uid == widget.room.player1['uid'] 
        ? (widget.room.player2?['score'] ?? 0)
        : widget.room.player1['score'];

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  isWinner ? AppColors.teal.withValues(alpha: 0.2) : AppColors.red.withValues(alpha: 0.2),
                  AppColors.primaryBg,
                ],
                radius: 1.0,
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_leveledUp)
                    _buildStatusBanner('LEVEL UP!', AppColors.gold),
                  
                  if (_matchResult?.rankUpdate.promoted == true)
                    _buildStatusBanner('PROMOTED!', AppColors.teal),
                  
                  if (_matchResult?.rankUpdate.demoted == true)
                    _buildStatusBanner('DEMOTED', AppColors.red),

                  SizedBox(
                    height: 100,
                    child: isWinner 
                      ? const Icon(Icons.emoji_events_rounded, size: 80, color: AppColors.gold)
                      : const Icon(Icons.sentiment_very_dissatisfied_rounded, size: 80, color: AppColors.red),
                  ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 16),

                  Text(
                    isDraw ? "IT'S A DRAW!" : (isWinner ? 'VICTORY!' : 'DEFEAT'),
                    style: AppTextStyles.display.copyWith(
                      fontSize: 32,
                      color: isWinner ? AppColors.teal : AppColors.red,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().slideY(begin: 0.5, end: 0),

                  const SizedBox(height: 24),

                  _buildScoreCard(myScore, opponentScore),

                  const SizedBox(height: 24),

                  if (_matchResult != null) ...[
                    XpSummaryCard(rewards: _matchResult!.xpRewards)
                        .animate()
                        .fadeIn(delay: 400.ms),
                    
                    const SizedBox(height: 24),
                    
                    _buildRankSection(_matchResult!.rankUpdate)
                        .animate()
                        .fadeIn(delay: 600.ms),
                  ],

                  const SizedBox(height: 40),

                  ElevatedButton(
                    onPressed: !_rewardsClaimed ? null : () => Navigator.of(context).popUntil((route) => route.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _rewardsClaimed 
                        ? const Text('BACK TO HOME', style: TextStyle(fontWeight: FontWeight.bold))
                        : const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ).animate().shimmer().scale(duration: 500.ms),
    );
  }

  Widget _buildScoreCard(int myScore, int opponentScore) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surface),
      ),
      child: Column(
        children: [
          _ResultRow(label: 'YOUR SCORE', value: '$myScore', color: AppColors.gold),
          const Divider(color: AppColors.surface, height: 24),
          _ResultRow(label: 'OPPONENT', value: '$opponentScore', color: AppColors.textSecondary),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildRankSection(rankUpdate) {
    final pointsDiff = rankUpdate.pointsGained;
    final pointsColor = pointsDiff >= 0 ? AppColors.teal : AppColors.red;
    final pointsText = pointsDiff >= 0 ? '+$pointsDiff RP' : '$pointsDiff RP';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surface),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('RANK PROGRESS', style: AppTextStyles.label),
              Text(pointsText, style: AppTextStyles.label.copyWith(color: pointsColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RankBadge(rank: rankUpdate.oldRank, subRank: rankUpdate.oldSubRank, size: 50),
              const SizedBox(width: 16),
              const Icon(Icons.arrow_forward_rounded, color: AppColors.textMuted),
              const SizedBox(width: 16),
              RankBadge(rank: rankUpdate.newRank, subRank: rankUpdate.newSubRank, size: 60)
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1000.ms),
            ],
          ),
          const SizedBox(height: 20),
          RankProgressBar(rank: rankUpdate.newRank, subRank: rankUpdate.newSubRank, points: rankUpdate.newPoints),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ResultRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.label),
        Text(value, style: AppTextStyles.display.copyWith(fontSize: 24, color: color)),
      ],
    );
  }
}
