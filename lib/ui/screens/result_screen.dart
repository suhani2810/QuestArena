// WHAT THIS FILE DOES:
// Displays the final scores, the winner, and rewards (XP/Coins).
// Handles the 3-step victory experience: Victory Screen -> Victory Card Pop-up -> Share Options.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../providers/user_providers.dart';
import '../../providers/game_providers.dart';
import '../../providers/leaderboard_providers.dart';
import '../../data/models/game_room_model.dart';
import '../../data/models/match_history_model.dart';
import '../../data/models/user_model.dart';
import '../widgets/victory_card.dart';
import 'home_screen.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final GameRoomModel room;
  const ResultScreen({super.key, required this.room});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  bool _rewardsClaimed = false;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _handleRewards();
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
      final isDraw = widget.room.winnerId == 'draw';

      final myScore = currentUser.uid == widget.room.player1['uid'] 
          ? widget.room.player1['score'] 
          : (widget.room.player2?['score'] ?? 0);
          
      final opponentScore = currentUser.uid == widget.room.player1['uid'] 
          ? (widget.room.player2?['score'] ?? 0)
          : widget.room.player1['score'];
          
      final opponentName = currentUser.uid == widget.room.player1['uid']
          ? (widget.room.player2?['username'] ?? 'Opponent')
          : widget.room.player1['username'];

      final history = MatchModel(
        id: widget.room.roomId,
        opponentName: opponentName,
        playerScore: myScore,
        opponentScore: opponentScore,
        xpEarned: isWinner ? 50 : (isDraw ? 25 : 15),
        timestamp: DateTime.now(),
      );

      await Future.wait([
        ref.read(userRepositoryProvider).updateUserStats(
          uid: currentUser.uid,
          xpGained: isWinner ? 50 : (isDraw ? 25 : 15),
          coinsGained: isWinner ? 20 : (isDraw ? 10 : 5),
          isWin: isWinner,
          isDraw: isDraw,
        ),
        ref.read(gameRepositoryProvider).claimRewards(
          widget.room.roomId,
          currentUser.uid,
          isWinner,
        ),
        ref.read(userRepositoryProvider).saveMatchHistory(currentUser.uid, history),
      ]);
      
      debugPrint('All rewards and history saved successfully!');
    } catch (e) {
      debugPrint('Error claiming rewards: $e');
    } finally {
      if (mounted) {
        setState(() => _rewardsClaimed = true);
      }
    }
  }

  void _showVictoryCardPopUp(UserModel user, String opponentName, int myScore, int opponentScore, int xp, int coins, bool isMvp) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) => _VictoryCardModal(
        user: user,
        opponentName: opponentName,
        myScore: myScore,
        opponentScore: opponentScore,
        xpEarned: xp,
        coinsEarned: coins,
        isMvp: isMvp,
        screenshotController: _screenshotController,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;
    if (currentUser == null) return const Scaffold();

    final weeklyMvp = ref.watch(weeklyMvpProvider);
    final isMvp = weeklyMvp?.uid == currentUser.uid;

    final isWinner = widget.room.winnerId == currentUser.uid;
    final isDraw = widget.room.winnerId == 'draw';
    
    final myScore = currentUser.uid == widget.room.player1['uid'] 
        ? widget.room.player1['score'] 
        : (widget.room.player2?['score'] ?? 0);
        
    final opponentScore = currentUser.uid == widget.room.player1['uid'] 
        ? (widget.room.player2?['score'] ?? 0)
        : widget.room.player1['score'];

    final opponentName = currentUser.uid == widget.room.player1['uid']
        ? (widget.room.player2?['username'] ?? 'Opponent')
        : widget.room.player1['username'];

    final opponentAvatar = currentUser.uid == widget.room.player1['uid']
        ? (widget.room.player2?['avatarUrl'])
        : widget.room.player1['avatarUrl'];

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      body: Stack(
        children: [
          // Background Glow
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  isWinner 
                      ? AppColors.teal.withValues(alpha: 0.15) 
                      : (isDraw ? AppColors.gold.withValues(alpha: 0.15) : AppColors.red.withValues(alpha: 0.15)),
                  AppColors.primaryBg,
                ],
                radius: 1.2,
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shield_rounded, color: AppColors.gold, size: 18),
                      const SizedBox(width: 8),
                      Text('QUESTARENA', style: AppTextStyles.label.copyWith(color: AppColors.gold, letterSpacing: 2, fontSize: 10)),
                    ],
                  ).animate().fadeIn(),

                  const Spacer(flex: 1),

                  // Headline
                  Text(
                    isDraw ? "IT'S A DRAW!" : (isWinner ? 'YOU WON!' : 'YOU LOST!'),
                    style: AppTextStyles.display.copyWith(
                      fontSize: 38,
                      color: isWinner ? AppColors.teal : (isDraw ? AppColors.gold : AppColors.red),
                      shadows: [
                        Shadow(
                          color: (isWinner ? AppColors.teal : (isDraw ? AppColors.gold : AppColors.red)).withValues(alpha: 0.5),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

                  Text(
                    isWinner ? "Awesome battle!" : (isDraw ? "Well played!" : "Keep practicing!"),
                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary, fontSize: 14),
                  ).animate().fadeIn(delay: 400.ms),

                  const Spacer(flex: 1),

                  // Illustration
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isWinner ? AppColors.gold : (isDraw ? AppColors.gold : AppColors.red)).withValues(alpha: 0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      isWinner ? Icons.emoji_events_rounded : (isDraw ? Icons.handshake_rounded : Icons.sentiment_very_dissatisfied_rounded),
                      size: 80,
                      color: isWinner ? AppColors.gold : (isDraw ? AppColors.gold : AppColors.red),
                    ),
                  ).animate().scale(delay: 200.ms, duration: 800.ms, curve: Curves.bounceOut),

                  const Spacer(flex: 1),

                  // Match Summary: Avatars and Scores
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Player
                        _PlayerSummary(
                          username: currentUser.username,
                          avatarUrl: currentUser.avatarUrl,
                          rank: currentUser.rank,
                          isWinner: isWinner,
                        ),
                        
                        // Score
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Text('$myScore', style: AppTextStyles.display.copyWith(color: AppColors.teal, fontSize: 26)),
                              const SizedBox(width: 8),
                              Text('-', style: AppTextStyles.display.copyWith(color: AppColors.textMuted, fontSize: 18)),
                              const SizedBox(width: 8),
                              Text('$opponentScore', style: AppTextStyles.display.copyWith(color: AppColors.red, fontSize: 26)),
                            ],
                          ),
                        ),

                        // Opponent
                        _PlayerSummary(
                          username: opponentName,
                          avatarUrl: opponentAvatar,
                          rank: 'Silver I', // Placeholder
                          isWinner: !isWinner && !isDraw,
                        ),
                      ],
                    ),
                  ).animate().slideY(begin: 0.2, end: 0).fadeIn(delay: 600.ms),

                  const Spacer(flex: 1),

                  // Rewards Row
                  Row(
                    children: [
                      Expanded(
                        child: _RewardCard(
                          label: 'XP EARNED',
                          value: isWinner ? '+50 XP' : (isDraw ? '+25 XP' : '+15 XP'),
                          icon: Icons.stars_rounded,
                          color: AppColors.purple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _RewardCard(
                          label: 'COINS EARNED',
                          value: isWinner ? '+20' : (isDraw ? '+10' : '+5'),
                          icon: Icons.monetization_on_rounded,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 800.ms),

                  const SizedBox(height: 10),

                  // Win Streak
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surface),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.whatshot_rounded, color: AppColors.red, size: 16),
                        const SizedBox(width: 8),
                        Text('WIN STREAK', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary, letterSpacing: 1.5, fontSize: 10)),
                        const SizedBox(width: 8),
                        Text('4', style: AppTextStyles.headline.copyWith(color: AppColors.red, fontSize: 14)),
                      ],
                    ),
                  ).animate().fadeIn(delay: 1000.ms),

                  const Spacer(flex: 2),

                  if (isWinner)
                    ElevatedButton(
                      onPressed: () => _showVictoryCardPopUp(
                        currentUser, 
                        opponentName, 
                        myScore, 
                        opponentScore,
                        50, // XP
                        20, // Coins
                        isMvp,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.share_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 12),
                          Text('SHARE YOUR VICTORY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                        ],
                      ),
                    ).animate().fadeIn(delay: 1200.ms).scale(),

                  const SizedBox(height: 8),

                  TextButton(
                    onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                      (route) => false,
                    ),
                    child: Text(
                      'Continue to dashboard',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.textSecondary, 
                        decoration: TextDecoration.underline,
                        fontSize: 12,
                      ),
                    ),
                  ).animate().fadeIn(delay: 1400.ms),
                  
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerSummary extends StatelessWidget {
  final String username;
  final String? avatarUrl;
  final String rank;
  final bool isWinner;

  const _PlayerSummary({required this.username, this.avatarUrl, required this.rank, required this.isWinner});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: isWinner ? AppColors.gold.withValues(alpha: 0.3) : AppColors.surface,
              child: ClipOval(
                child: avatarUrl != null && avatarUrl!.isNotEmpty
                    ? CachedNetworkImage(imageUrl: avatarUrl!, width: 64, height: 64, fit: BoxFit.cover)
                    : const Icon(Icons.person, color: AppColors.textMuted),
              ),
            ),
            if (isWinner)
              const Positioned(
                top: -10,
                child: Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 20),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(username, style: AppTextStyles.headline.copyWith(fontSize: 14)),
        Text(rank, style: AppTextStyles.label.copyWith(color: AppColors.gold, fontSize: 10)),
      ],
    );
  }
}

class _RewardCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _RewardCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(label, style: AppTextStyles.label.copyWith(fontSize: 8, color: AppColors.textSecondary)),
          Text(value, style: AppTextStyles.headline.copyWith(fontSize: 16, color: color)),
        ],
      ),
    );
  }
}

class _VictoryCardModal extends StatefulWidget {
  final UserModel user;
  final String opponentName;
  final int myScore;
  final int opponentScore;
  final int xpEarned;
  final int coinsEarned;
  final bool isMvp;
  final ScreenshotController screenshotController;

  const _VictoryCardModal({
    required this.user,
    required this.opponentName,
    required this.myScore,
    required this.opponentScore,
    required this.xpEarned,
    required this.coinsEarned,
    required this.isMvp,
    required this.screenshotController,
  });

  @override
  State<_VictoryCardModal> createState() => _VictoryCardModalState();
}

class _VictoryCardModalState extends State<_VictoryCardModal> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _captureAndShare() async {
    try {
      final image = await widget.screenshotController.captureFromWidget(
        Material(
          color: Colors.transparent,
          child: VictoryCard(
            username: widget.user.username,
            avatarUrl: widget.user.avatarUrl,
            rank: widget.user.rank,
            opponentName: widget.opponentName,
            playerScore: widget.myScore,
            opponentScore: widget.opponentScore,
            xpEarned: widget.xpEarned,
            coinsEarned: widget.coinsEarned,
            isMvp: widget.isMvp,
          ),
        ),
        delay: const Duration(milliseconds: 100),
        context: context,
      );

      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/victory_card.png').create();
      await imagePath.writeAsBytes(image);

      const shareMessage = "I just won a battle on QuestArena!🏆\n\nThink you can beat me? 🧠\nChallenge me and prove it.\n\n🎮 Play now:\nhttps://quest-arena-self.vercel.app/";

      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text: shareMessage,
      );
    } catch (e) {
      debugPrint('Share Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti background
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: true,
            colors: const [AppColors.gold, AppColors.purple, AppColors.teal, Colors.white],
            numberOfParticles: 20,
            gravity: 0.1,
          ),
          
          SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topRight,
                  children: [
                    // The Card
                    Screenshot(
                      controller: widget.screenshotController,
                      child: VictoryCard(
                        username: widget.user.username,
                        avatarUrl: widget.user.avatarUrl,
                        rank: widget.user.rank,
                        opponentName: widget.opponentName,
                        playerScore: widget.myScore,
                        opponentScore: widget.opponentScore,
                        xpEarned: widget.xpEarned,
                        coinsEarned: widget.coinsEarned,
                        isMvp: widget.isMvp,
                      ),
                    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),
                    
                    // Close X button
                    Positioned(
                      top: 10,
                      right: 10,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 24),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          minimumSize: const Size(0, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('CLOSE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _captureAndShare,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(0, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.share_rounded, size: 20),
                            SizedBox(width: 8),
                            Text('SHARE', style: TextStyle(fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5, end: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
