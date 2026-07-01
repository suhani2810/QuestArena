import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';
import '../../providers/game_providers.dart';
import '../../providers/user_providers.dart';
import '../../core/constants/text_styles.dart';
import '../widgets/smart_avatar.dart';
import 'game_screen.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  final String roomId;
  const LobbyScreen({super.key, required this.roomId});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  int _countdown = 3;
  Timer? _timer;
  bool _isStartingGame = false;
  bool _isMarkingReady = false;

  Future<void> _enterGame() async {
    if (_isStartingGame || !mounted) return;
    _isStartingGame = true;

    // Trigger the start one last time just in case, but don't await it
    // to ensure the navigation transition is instant.
    ref.read(gameRepositoryProvider).startGame(widget.roomId);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => GameScreen(roomId: widget.roomId)),
    );
  }

  void _startCountdown() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      // Pre-emptively start the game in Firestore when countdown is nearly finished.
      // This hides the network latency so the transition to GameScreen is instant.
      if (_countdown == 1) {
        ref.read(gameRepositoryProvider).startGame(widget.roomId);
      }

      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _timer?.cancel();
          _enterGame();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(gameRoomProvider(widget.roomId));
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: roomAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.neonCyan)),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (room) {
          if (room == null) return const Center(child: Text('Room not found'));

          final p1 = room.player1;
          final p2 = room.player2;

          final isP1 = currentUser?.uid == p1['uid'];
          final isP2 = p2 != null && currentUser?.uid == p2['uid'];
          final amIReady = isP1
              ? (p1['isReady'] == true)
              : (isP2 ? (p2['isReady'] == true) : false);

          // If both players are ready, start the timer
          if (p1['isReady'] == true && p2 != null && p2['isReady'] == true) {
            _startCountdown();
          }

          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      color: AppColors.neonViolet.withValues(alpha: 0.05),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SmartAvatar(
                            avatarUrl: p1['avatarUrl'],
                            size: 120,
                            showGlow: true,
                            showBorder: true,
                          ),
                          const SizedBox(height: 16),
                          Text(p1['username'],
                              style: AppTextStyles.headline
                                  .copyWith(color: AppColors.textPrimary)),
                          _ReadyBadge(
                              isReady: p1['isReady'] ?? false,
                              color: AppColors.neonViolet),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      color: AppColors.neonAmber.withValues(alpha: 0.05),
                      child: p2 == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(
                                    color: AppColors.neonAmber, strokeWidth: 2),
                                const SizedBox(height: 24),
                                Text('WAITING FOR OPPONENT',
                                    style: AppTextStyles.label
                                        .copyWith(letterSpacing: 2)),
                                const SizedBox(height: 8),
                                Text('ROOM CODE:',
                                    style: AppTextStyles.label.copyWith(
                                        fontSize: 10, letterSpacing: 1)),
                                Text(room.roomCode,
                                    style: AppTextStyles.display.copyWith(
                                        color: AppColors.neonAmber,
                                        fontSize: 32,
                                        letterSpacing: 4)),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _ReadyBadge(
                                    isReady: p2['isReady'] ?? false,
                                    color: AppColors.neonAmber),
                                const SizedBox(height: 16),
                                Text(p2['username'],
                                    style: AppTextStyles.headline.copyWith(
                                        color: AppColors.textPrimary)),
                                const SizedBox(height: 16),
                                SmartAvatar(
                                  avatarUrl: p2['avatarUrl'],
                                  size: 120,
                                  showGlow: true,
                                  showBorder: true,
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),

              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                      color: AppColors.bgDeep, shape: BoxShape.circle),
                  child: Text('VS',
                      style: AppTextStyles.display
                          .copyWith(color: AppColors.neonAmber, fontSize: 24)),
                ).animate().scale(delay: 400.ms, curve: Curves.elasticOut),
              ),

              if (p1['isReady'] == true && p2 != null && p2['isReady'] == true)
                Container(
                  color: Colors.black87,
                  child: Center(
                    child: Text('$_countdown',
                            style: AppTextStyles.display.copyWith(
                                fontSize: 120, color: AppColors.neonCyan))
                        .animate(key: ValueKey(_countdown))
                        .scale(duration: 500.ms)
                        .fadeOut(delay: 500.ms),
                  ),
                ),

              // Ready Button
              if (p2 != null && !amIReady)
                Positioned(
                  bottom: 40,
                  left: 40,
                  right: 40,
                  child: ElevatedButton(
                    onPressed: _isMarkingReady
                        ? null
                        : () async {
                            if (currentUser == null) return;

                            setState(() => _isMarkingReady = true);

                            try {
                              await ref
                                  .read(gameRepositoryProvider)
                                  .setPlayerReady(
                                    widget.roomId,
                                    isP1 ? 1 : (isP2 ? 2 : 0),
                                    currentUser.uid,
                                  );
                            } catch (e) {
                              if (mounted) {
                                setState(() => _isMarkingReady = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Failed to set ready: $e')),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonViolet,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      disabledBackgroundColor:
                          AppColors.purple.withValues(alpha: 0.6),
                    ),
                    child: _isMarkingReady
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text('I AM READY!',
                            style: AppTextStyles.bodyLg.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: Colors.white)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ReadyBadge extends StatelessWidget {
  final bool isReady;
  final Color color;
  const _ReadyBadge({required this.isReady, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isReady ? color.withValues(alpha: 0.2) : AppColors.bgInputField,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isReady ? color : AppColors.divider),
      ),
      child: Text(
        isReady ? 'READY' : 'WAITING...',
        style: TextStyle(
            color: isReady ? color : AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1),
      ),
    );
  }
}
