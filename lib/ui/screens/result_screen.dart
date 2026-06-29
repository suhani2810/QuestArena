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
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) {
        await Future.delayed(const Duration(seconds: 1));
        _handleRewards();
        return;
      }

      final isWinner = widget.room.winnerId == currentUser.uid;

      final myScore = currentUser.uid == widget.room.player1['uid'] 
          ? widget.room.player1['score'] 
          : (widget.room.player2?['score'] ?? 0);
          
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
        xpGained: isWinner ? 50 : 15,
        playedAt: DateTime.now(),
      );

      await Future.wait([
        ref.read(userRepositoryProvider).updateUserStats(
          uid: currentUser.uid,
          xpGained: isWinner ? 50 : 15,
          coinsGained: isWinner ? 20 : 5,
          isWin: isWinner,
          isArenaBreakerWin: widget.room.isArenaBreakerWin,
        ),
        ref.read(gameRepositoryProvider).claimRewards(
          widget.room.roomId,
          currentUser.uid,
          isWinner,
        ),
        ref.read(userRepositoryProvider).saveMatchHistory(currentUser.uid, history),
      ]);
    } catch (e) {
      debugPrint('Error claiming rewards: $e');
    } finally {
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
                  SizedBox(
                    height: 140,
                    child: isWinner 
                      ? const Icon(Icons.emoji_events_rounded, size: 100, color: AppColors.gold)
                      : const Icon(Icons.sentiment_very_dissatisfied_rounded, size: 100, color: AppColors.red),
                  ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 16),

                  Text(
                    widget.isPractice 
                        ? 'PRACTICE COMPLETE' 
                        : (isDraw ? "IT'S A DRAW!" : (widget.room.forfeitWinnerId != null ? 'MATCH FORFEITED' : (widget.room.isArenaBreakerWin ? 'WINNER BY ARENA BREAKER' : (isWinner ? 'VICTORY!' : 'DEFEAT')))),
                    style: AppTextStyles.display.copyWith(
                      fontSize: (widget.room.isArenaBreakerWin || widget.room.forfeitWinnerId != null || widget.isPractice) ? 24 : 36,
                      color: isWinner ? AppColors.teal : AppColors.red,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().slideY(begin: 0.5, end: 0),

                  const SizedBox(height: 24),

                  Container(
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
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 24),

                  if (widget.isPractice)
                    Text('No rewards earned in Practice Mode', style: AppTextStyles.label.copyWith(color: AppColors.textMuted))
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _RewardItem(
                          label: 'XP GAINED', 
                          value: isWinner ? '+50' : '+15', 
                          icon: Icons.trending_up_rounded, 
                          color: AppColors.purple,
                          isProcessing: !_rewardsClaimed,
                        ),
                        _RewardItem(
                          label: 'COINS', 
                          value: isWinner ? '+20' : '+5', 
                          icon: Icons.monetization_on_rounded, 
                          color: AppColors.gold,
                          isProcessing: !_rewardsClaimed,
                        ),
                      ],
                    ).animate().fadeIn(delay: 600.ms),

                  const SizedBox(height: 40),

                  if (widget.isPractice)
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(), // Will go back to Setup
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.purple,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('CHANGE SETUP', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                          child: Text('BACK TO HUB', style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
                        ),
                      ],
                    )
                  else ...[
                    // REMATCH SECTION
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
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(otherRequested ? 'ACCEPT REMATCH' : 'REQUEST REMATCH'),
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

                    TextButton(
                      onPressed: !_rewardsClaimed ? null : () => Navigator.of(context).popUntil((route) => route.isFirst),
                      child: Text('BACK TO HOME', style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
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

class _RewardItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isProcessing;
  
  const _RewardItem({
    required this.label, 
    required this.value, 
    required this.icon, 
    required this.color,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: isProcessing ? Colors.grey : color, size: 28),
        const SizedBox(height: 8),
        isProcessing 
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : Text(value, style: AppTextStyles.headline.copyWith(fontSize: 20)),
        Text(label, style: AppTextStyles.label.copyWith(fontSize: 10)),
      ],
    );
  }
}
