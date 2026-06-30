import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';
import '../../providers/game_providers.dart';
import '../../providers/user_providers.dart';
import '../widgets/character_avatar.dart';
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

  Future<void> _enterGame() async {
    if (_isStartingGame || !mounted) return;
    _isStartingGame = true;

    await ref.read(gameRepositoryProvider).startGame(widget.roomId);
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => GameScreen(roomId: widget.roomId)),
    );
  }

  void _startCountdown() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
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
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (room) {
          if (room == null) return const Center(child: Text('Room not found'));

          final p1 = room.player1;
          final p2 = room.player2;
          
          if (p1['isReady'] == true && p2 != null && p2['isReady'] == true) {
            _startCountdown();
          }

          final char1 = kCharacters.firstWhere(
                (c) => c.id == (p1['avatarUrl'] ?? ''),
            orElse: () => kCharacters.first,
          );

          final char2 = p2 != null ? kCharacters.firstWhere(
                (c) => c.id == (p2['avatarUrl'] ?? ''),
            orElse: () => kCharacters.first,
          ) : null;

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
                          CharacterAvatar(
                            character: char1,
                            size: 120,
                            showGlow: true,
                            showBorder: true,
                          ),
                          const SizedBox(height: 16),
                          Text(p1['username'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: 1)),
                          _ReadyBadge(isReady: p1['isReady'] ?? false, color: AppColors.neonViolet),
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
                              const CircularProgressIndicator(color: AppColors.neonAmber, strokeWidth: 2),
                              const SizedBox(height: 24),
                              const Text('WAITING FOR OPPONENT', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2)),
                              const SizedBox(height: 8),
                              const Text('ROOM CODE:', style: TextStyle(color: AppColors.textMuted, fontSize: 10, letterSpacing: 1)),
                              Text(room.roomCode, style: const TextStyle(color: AppColors.neonAmber, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 4)),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _ReadyBadge(isReady: p2['isReady'] ?? false, color: AppColors.neonAmber),
                              const SizedBox(height: 16),
                              Text(p2['username'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: 1)),
                              const SizedBox(height: 16),
                              CharacterAvatar(
                                character: char2!,
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
                  decoration: const BoxDecoration(color: AppColors.bgDeep, shape: BoxShape.circle),
                  child: const Text('VS', style: TextStyle(color: AppColors.neonAmber, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ).animate().scale(delay: 400.ms, curve: Curves.elasticOut),
              ),

              if (p1['isReady'] == true && p2 != null && p2['isReady'] == true)
                Container(
                  color: Colors.black87,
                  child: Center(
                    child: Text('$_countdown', style: const TextStyle(fontSize: 120, fontWeight: FontWeight.w900, color: AppColors.neonCyan))
                        .animate(key: ValueKey(_countdown))
                        .scale(duration: 500.ms)
                        .fadeOut(delay: 500.ms),
                  ),
                ),

              if (p2 != null && !(p1['isReady'] == true && p2['isReady'] == true))
                Positioned(
                  bottom: 40,
                  left: 40,
                  right: 40,
                    child: ElevatedButton(
                      onPressed: () {
                        if (currentUser == null) return;
                        final isP1 = currentUser.uid == p1['uid'];
                        ref.read(gameRepositoryProvider).setPlayerReady(
                            widget.roomId,
                            isP1 ? 1 : 2,
                            currentUser.uid,
                          );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonViolet,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('I AM READY!', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
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
        style: TextStyle(color: isReady ? color : AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }
}
