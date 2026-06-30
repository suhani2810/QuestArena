// WHAT THIS FILE DOES:
// Displays the final scores, the winner, and rewards (XP/Coins).
//
// KEY CONCEPTS IN THIS FILE:
// • Rematch Logic: Real-time synchronization for 1v1 rematches.
// • Lottie: Using high-quality vector animations for "Victory" or "Defeat".
// • Conditional Layouts: Different colors and text based on whether the user won or lost.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../providers/user_providers.dart';
import '../../providers/game_providers.dart';
import '../../data/models/game_room_model.dart';
import '../../data/models/match_history_model.dart';
import 'game_screen.dart';
import '../../data/models/match_end_result.dart';
import '../../core/utils/level_system.dart';
import '../../data/services/rank_service.dart';
import '../widgets/xp_summary_card.dart';
import '../widgets/rank_badge.dart';
import '../widgets/rank_progress_bar.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final GameRoomModel room;
  final bool isPractice;
  const ResultScreen({super.key, required this.room, this.isPractice = false});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  bool _rewardsClaimed = false;
  bool _rematchRequested = false;
  int _rematchTimer = 30;
  Timer? _timer;
  MatchEndResult? _matchResult;
  bool _leveledUp = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isPractice) {
      _handleRewards();
      _startRematchTimer();
    } else {
      _rewardsClaimed = true; // Mark as claimed for Practice to enable buttons
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRematchTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _rematchTimer > 0) {
        setState(() => _rematchTimer--);
      } else {
        _timer?.cancel();
      }
    });
  }

  void _handleRewards() async {
    if (_rewardsClaimed) return;

    try {
      final userValue = ref.read(currentUserProvider);
      final currentUser = userValue.value;
      
      if (currentUser == null) {
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
        isArenaBreakerWin: widget.room.isArenaBreakerWin,
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
      }
    }
  }

  void _onRematchPressed() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null || _rematchRequested) return;

    setState(() => _rematchRequested = true);
    await ref.read(gameRepositoryProvider).requestRematch(widget.room.roomId, user.uid);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;
    if (currentUser == null) return const Scaffold();

    if (!widget.isPractice) {
      ref.listen<AsyncValue<GameRoomModel?>>(gameRoomProvider(widget.room.roomId), (prev, next) {
        final room = next.value;
        if (room == null) return;

        if (room.nextMatchId != null && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => GameScreen(roomId: room.nextMatchId!)),
          );
        }

        if (room.rematchRequests.length == 2 && room.nextMatchId == null) {
          if (currentUser.uid == room.player1['uid']) {
            ref.read(gameRepositoryProvider).createRematchGame(
              oldRoomId: room.roomId,
              player1: room.player1,
              player2: room.player2!,
              categoryId: room.categoryId,
              categoryName: room.categoryName,
            );
          }
        }
      });
    }

    final roomState = !widget.isPractice 
        ? (ref.watch(gameRoomProvider(widget.room.roomId)).value ?? widget.room)
        : widget.room;

    final otherRequested = !widget.isPractice && roomState.rematchRequests.any((id) => id != currentUser.uid);
    final waitingForOpponent = !widget.isPractice && _rematchRequested && roomState.rematchRequests.length < 2;

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
                    widget.isPractice 
                        ? 'PRACTICE COMPLETE' 
                        : (isDraw ? "IT'S A DRAW!" : (widget.room.forfeitWinnerId != null ? 'MATCH FORFEITED' : (widget.room.isArenaBreakerWin ? 'WINNER BY ARENA BREAKER ⚡' : (isWinner ? 'VICTORY!' : 'DEFEAT')))),
                    style: AppTextStyles.display.copyWith(
                      fontSize: (widget.room.isArenaBreakerWin || widget.room.forfeitWinnerId != null || widget.isPractice) ? 24 : 32,
                      color: isWinner ? AppColors.teal : AppColors.red,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().slideY(begin: 0.5, end: 0),

                  const SizedBox(height: 24),

                  _buildScoreCard(myScore, opponentScore),

                  const SizedBox(height: 24),

                  if (!widget.isPractice && _matchResult != null) ...[
                    XpSummaryCard(rewards: _matchResult!.xpRewards)
                        .animate()
                        .fadeIn(delay: 400.ms),
                    
                    const SizedBox(height: 24),
                    
                    _buildRankSection(_matchResult!.rankUpdate)
                        .animate()
                        .fadeIn(delay: 600.ms),
                  ] else if (widget.isPractice)
                    Text('No rewards earned in Practice Mode', style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),

                  const SizedBox(height: 40),

                  if (widget.isPractice)
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.purple,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('CHANGE SETUP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                          child: Text('BACK TO HUB', style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
                        ),
                      ],
                    )
                  else ...[
                    if (_rematchTimer > 0 && roomState.nextMatchId == null) ...[
                      if (waitingForOpponent)
                        Column(
                          children: [
                            const CircularProgressIndicator(color: AppColors.gold),
                            const SizedBox(height: 12),
                            Text('Waiting for opponent...', style: AppTextStyles.label),
                          ],
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: _onRematchPressed,
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                          label: Text(otherRequested ? 'ACCEPT REMATCH' : 'REQUEST REMATCH', style: const TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: otherRequested ? AppColors.teal : AppColors.surface,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ).animate(target: otherRequested ? 1 : 0).shimmer(),
                      
                      const SizedBox(height: 12),
                      Text('Offer expires in $_rematchTimer s', style: AppTextStyles.label.copyWith(fontSize: 10)),
                    ],

                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: !_rewardsClaimed ? null : () => Navigator.of(context).popUntil((route) => route.isFirst),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cardBg,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.surface)),
                      ),
                      child: const Text('BACK TO HOME', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
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
          _ResultRow(label: widget.isPractice ? 'AI BOT' : 'OPPONENT', value: '$opponentScore', color: AppColors.textSecondary),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildRankSection(RankUpdateResult rankUpdate) {
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
