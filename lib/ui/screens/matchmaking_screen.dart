// WHAT THIS FILE DOES:
// Highly polished Animated UI for matchmaking.
// Uses a radar-inspired design to maintain a high-tech "Gaming" feel.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';
import '../../providers/matchmaking_providers.dart';
import '../../providers/user_providers.dart';
import '../widgets/smart_avatar.dart';
import 'lobby_screen.dart';

class MatchmakingScreen extends ConsumerWidget {
  const MatchmakingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;

    // Navigation logic: Listen for the ticket to become 'matched'
    ref.listen(matchmakingTicketProvider, (previous, next) {
      final ticket = next.value;
      if (ticket != null && ticket.status == 'matched' && ticket.gameRoomId != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => LobbyScreen(roomId: ticket.gameRoomId!)),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Stack(
        children: [
          // 1. Cyberpunk-themed background
          Container(
            decoration: const BoxDecoration(
              color: AppColors.bgDeep,
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [Color(0xFF1A1A2E), AppColors.bgDeep],
              ),
            ),
          ),

          // 2. Animated Radar Rings & Avatar (Perfectly Centered)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Sonar Rings
                    ...List.generate(4, (index) {
                      return Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.neonViolet.withValues(alpha: 0.1 * (4 - index)),
                            width: 1,
                          ),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .scale(
                        duration: 3.seconds,
                        begin: const Offset(0.2, 0.2),
                        end: const Offset(1.3, 1.3),
                        curve: Curves.easeOut,
                        delay: (index * 800).ms,
                      )
                      .fadeOut();
                    }),

                    // Rotating Radar Sweep
                    RepaintBoundary(
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.neonViolet.withValues(alpha: 0.4),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .rotate(duration: 4.seconds),
                    ),

                    // Player Avatar
                    if (user != null)
                      SmartAvatar(
                        avatarUrl: user.avatarUrl,
                        size: 110,
                        showGlow: true,
                        showBorder: true,
                      ),
                  ],
                ),
                
                const SizedBox(height: 48),

                // Center Text Group
                const Text(
                  'FINDING OPPONENT',
                  style: TextStyle(fontSize: 20, letterSpacing: 4, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 1.seconds),
                
                const SizedBox(height: 12),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.neonAmber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.neonAmber.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'RANK: ${user?.rank.toUpperCase() ?? 'BRONZE'}',
                    style: const TextStyle(color: AppColors.neonAmber, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12),
                  ),
                ),

                const SizedBox(height: 32),

                // Animated status messages
                const DefaultTextStyle(
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  child: AnimatedStatusSwitcher(),
                ),
              ],
            ),
          ),

          // 3. Cancel Button (Fixed at Bottom)
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: TextButton.icon(
                onPressed: () async {
                  if (user != null) {
                    await ref.read(matchmakingRepositoryProvider).cancelSearching(user.uid);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.close_rounded, color: AppColors.neonPink, size: 20),
                label: const Text(
                  'CANCEL SEARCH',
                  style: TextStyle(color: AppColors.neonPink, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
              ).animate().fadeIn(delay: 500.ms),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedStatusSwitcher extends StatefulWidget {
  const AnimatedStatusSwitcher({super.key});

  @override
  State<AnimatedStatusSwitcher> createState() => _AnimatedStatusSwitcherState();
}

class _AnimatedStatusSwitcherState extends State<AnimatedStatusSwitcher> {
  int _index = 0;
  final _messages = [
    'Scanning nearby warriors...',
    'Checking skill brackets...',
    'Connecting to battle arena...',
    'Preparing the questions...',
    'Almost there...',
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() {
          _index = (_index + 1) % _messages.length;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _messages[_index],
      key: ValueKey(_messages[_index]),
      textAlign: TextAlign.center,
    ).animate().fadeIn().slideY(begin: 0.1, end: 0).then(delay: 2.seconds).fadeOut();
  }
}
