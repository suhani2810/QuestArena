// WHAT THIS FILE DOES:
// Highly polished Animated UI for matchmaking.
// Uses a radar-inspired design to maintain a high-tech "Gaming" feel.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/matchmaking_providers.dart';
import '../../providers/user_providers.dart';
import '../widgets/smart_avatar.dart';
import 'lobby_screen.dart';

class MatchmakingScreen extends ConsumerStatefulWidget {
  final String? categoryName;
  const MatchmakingScreen({super.key, this.categoryName});

  @override
  ConsumerState<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends ConsumerState<MatchmakingScreen> {
  Timer? _expansionTimer;

  @override
  void initState() {
    super.initState();
    _startExpansionTimer();
  }

  @override
  void dispose() {
    _expansionTimer?.cancel();
    super.dispose();
  }

  void _startExpansionTimer() {
    _expansionTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final user = ref.read(currentUserProvider).value;
      if (user != null) {
        ref.read(matchmakingRepositoryProvider).expandSearch(user.uid);
      }
    });
  }

  String _getCategoryIcon(String category) {
    final lowerCategory = category.toLowerCase();
    if (lowerCategory.contains('computers')) return '💻';
    if (lowerCategory.contains('music')) return '🎵';
    if (lowerCategory.contains('film')) return '🎬';
    if (lowerCategory.contains('books')) return '📚';
    if (lowerCategory.contains('geography')) return '🌍';
    if (lowerCategory.contains('sports')) return '⚽';
    if (lowerCategory.contains('mathematics')) return '🧮';
    if (lowerCategory.contains('animals')) return '🐾';
    if (lowerCategory.contains('video games')) return '🎮';
    if (lowerCategory.contains('general knowledge')) return '📖';
    return '🎲'; // Mixed / Random
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final ticket = ref.watch(matchmakingTicketProvider).value;

    final displayCategory =
        ticket?.categoryName ?? widget.categoryName ?? 'Mixed / Random';

    // Navigation logic: Listen for the ticket to become 'matched'
    ref.listen(matchmakingTicketProvider, (previous, next) {
      final ticket = next.value;
      if (ticket != null &&
          ticket.status == 'matched' &&
          ticket.gameRoomId != null) {
        _expansionTimer?.cancel();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (_) => LobbyScreen(roomId: ticket.gameRoomId!)),
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
                            color: AppColors.neonViolet
                                .withValues(alpha: 0.1 * (4 - index)),
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
                  style: TextStyle(
                      fontSize: 20,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fadeIn(duration: 1.seconds),

                const SizedBox(height: 12),

                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.neonAmber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.neonAmber.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'RANK: ${user?.rank.toUpperCase() ?? 'BRONZE'}',
                    style: const TextStyle(
                        color: AppColors.neonAmber,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontSize: 12),
                  ),
                ),

                const SizedBox(height: 32),

                // TOPIC SECTION
                if (ticket != null || widget.categoryName != null) ...[
                  const SizedBox(
                    width: 160,
                    child: Divider(color: AppColors.divider, thickness: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'MATCH TOPIC',
                    style: AppTextStyles.label.copyWith(
                      fontSize: 9,
                      color: AppColors.neonCyan.withValues(alpha: 0.6),
                      letterSpacing: 4,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getCategoryIcon(displayCategory),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        displayCategory.toUpperCase(),
                        style: AppTextStyles.headline.copyWith(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(
                    width: 160,
                    child: Divider(color: AppColors.divider, thickness: 0.5),
                  ),
                  const SizedBox(height: 40),
                ],

                // Animated status messages
                const DefaultTextStyle(
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
                    _expansionTimer?.cancel();
                    await ref
                        .read(matchmakingRepositoryProvider)
                        .cancelSearching(user.uid);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.close_rounded,
                    color: AppColors.neonPink, size: 20),
                label: const Text(
                  'CANCEL SEARCH',
                  style: TextStyle(
                      color: AppColors.neonPink,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5),
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
    )
        .animate()
        .fadeIn()
        .slideY(begin: 0.1, end: 0)
        .then(delay: 2.seconds)
        .fadeOut();
  }
}
