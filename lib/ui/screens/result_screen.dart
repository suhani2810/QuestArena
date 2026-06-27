// WHAT THIS FILE DOES:
// Displays the final scores, the winner, and rewards (XP/Coins).
//
// KEY CONCEPTS IN THIS FILE:
// • Lottie: Using high-quality vector animations for "Victory" or "Defeat".
// • Conditional Layouts: Different colors and text based on whether the user won or lost.
// • Navigation: Returning the user back to the main Hub (HomeScreen).


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../providers/user_providers.dart';
import '../../providers/game_providers.dart';
import '../../data/models/game_room_model.dart';
import '../../data/models/match_history_model.dart';
import '../../data/models/user_model.dart';
import '../widgets/victory_card.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final GameRoomModel room;
  const ResultScreen({super.key, required this.room});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  bool _rewardsClaimed = false;
  final ScrollController _scrollController = ScrollController();
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _showVictoryCard = false;
  bool _isSharing = false;
  bool _hasPoppedOff = false;

  @override
  void initState() {
    super.initState();
    _handleRewards();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels > 100 && !_showVictoryCard) {
      setState(() => _showVictoryCard = true);
    }
    
    // Check for "pop-off" effect when reaching near the bottom
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 20 && !_hasPoppedOff) {
      setState(() => _hasPoppedOff = true);
    }
  }

  void _handleRewards() async {
    // Avoid double processing if already handled in this session
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

      // 1. Calculate History first so it's ready
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

      // 2. Perform all updates in parallel for speed
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

  void _onShareVictoryPressed() {
    setState(() => _isSharing = true);
    // Scroll to the top of the shared view to make sure they see the card and panel
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: 600.ms,
      curve: Curves.easeOutCubic
    );
  }

  Future<void> _captureAndShare(UserModel user) async {
    try {
      final directory = await getTemporaryDirectory();
      final imagePath = await _screenshotController.captureAndSave(
        directory.path,
        fileName: "victory_card_${DateTime.now().millisecondsSinceEpoch}.png"
      );

      if (imagePath != null) {
        await Share.shareXFiles(
          [XFile(imagePath)],
          text: 'Check out my victory on QuestArena! Challenge me!',
        );
      }
    } catch (e) {
      debugPrint('Share Error: $e');
    }
  }

  Future<void> _saveToGallery() async {
    try {
      final image = await _screenshotController.capture();
      if (image != null) {
        // In a real app, you'd use a package like image_gallery_saver
        // For now, we'll just show a success message as a mock
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Victory Card saved to gallery!')),
        );
      }
    } catch (e) {
      debugPrint('Save Error: $e');
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

    final opponentName = currentUser.uid == widget.room.player1['uid']
        ? (widget.room.player2?['username'] ?? 'Opponent')
        : widget.room.player1['username'];

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
                      ? AppColors.teal.withValues(alpha: 0.2) 
                      : (isDraw ? AppColors.gold.withValues(alpha: 0.2) : AppColors.red.withValues(alpha: 0.2)),
                  AppColors.primaryBg,
                ],
                radius: 1.0,
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                children: [
                  // --- STEP 1: EXISTING VICTORY SCREEN CONTENT ---
                  if (!_isSharing)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 140,
                          child: isWinner 
                            ? const Icon(Icons.emoji_events_rounded, size: 100, color: AppColors.gold)
                            : (isDraw 
                                ? const Icon(Icons.handshake_rounded, size: 100, color: AppColors.gold)
                                : const Icon(Icons.sentiment_very_dissatisfied_rounded, size: 100, color: AppColors.red)),
                        ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),

                        const SizedBox(height: 16),

                        Text(
                          isDraw ? "IT'S A DRAW!" : (isWinner ? 'VICTORY!' : 'DEFEAT'),
                          style: AppTextStyles.display.copyWith(
                            fontSize: 36,
                            color: isWinner ? AppColors.teal : (isDraw ? AppColors.gold : AppColors.red),
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
                              _ResultRow(label: 'OPPONENT', value: '$opponentScore', color: AppColors.textSecondary),
                            ],
                          ),
                        ).animate().fadeIn(delay: 400.ms),

                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _RewardItem(
                              label: 'XP GAINED', 
                              value: isWinner ? '+50' : (isDraw ? '+25' : '+15'), 
                              icon: Icons.trending_up_rounded, 
                              color: AppColors.purple,
                              isProcessing: !_rewardsClaimed,
                            ),
                            _RewardItem(
                              label: 'COINS', 
                              value: isWinner ? '+20' : (isDraw ? '+10' : '+5'),
                              icon: Icons.monetization_on_rounded, 
                              color: AppColors.gold,
                              isProcessing: !_rewardsClaimed,
                            ),
                          ],
                        ).animate().fadeIn(delay: 600.ms),

                        const SizedBox(height: 40),

                        // Scroll Prompt (Step 1)
                        if (isWinner)
                          Column(
                            children: [
                              Text(
                                '👇 Scroll down to reveal your Victory Card',
                                style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 8),
                              const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.gold)
                                .animate(onPlay: (controller) => controller.repeat())
                                .moveY(begin: 0, end: 10, duration: 1000.ms, curve: Curves.easeInOut)
                                .then()
                                .moveY(begin: 10, end: 0, duration: 1000.ms, curve: Curves.easeInOut),
                            ],
                          ).animate().fadeIn(delay: 1000.ms),
                        
                        const SizedBox(height: 100), // Gap to allow scrolling
                      ],
                    ),

                  // --- STEP 2: SCROLL REVEAL VICTORY CARD ---
                  if (isWinner)
                    Column(
                      children: [
                        if (!_isSharing)
                          Screenshot(
                            controller: _screenshotController,
                            child: VictoryCard(
                              username: currentUser.username,
                              avatarUrl: currentUser.avatarUrl,
                              rank: currentUser.rank,
                              opponentName: opponentName,
                              playerScore: myScore,
                              opponentScore: opponentScore,
                              xpEarned: isWinner ? 50 : 15,
                              coinsEarned: isWinner ? 20 : 5,
                              timestamp: DateTime.now(),
                            ),
                          )
                          .animate(target: _showVictoryCard ? 1 : 0)
                          .fadeIn(duration: 600.ms)
                          .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic)
                          .scale(
                            begin: const Offset(0.95, 0.95), 
                            end: const Offset(1.0, 1.0),
                            duration: 600.ms
                          )
                          .then()
                          .scale(
                            begin: const Offset(1.0, 1.0),
                            end: _hasPoppedOff ? const Offset(1.05, 1.05) : const Offset(1.0, 1.0),
                            duration: 300.ms,
                            curve: Curves.elasticOut
                          ),
                        
                        if (_isSharing)
                          Column(
                            children: [
                              const SizedBox(height: 40),
                              VictoryCard(
                                isCompact: true,
                                username: currentUser.username,
                                avatarUrl: currentUser.avatarUrl,
                                rank: currentUser.rank,
                                opponentName: opponentName,
                                playerScore: myScore,
                                opponentScore: opponentScore,
                                xpEarned: isWinner ? 50 : 15,
                                coinsEarned: isWinner ? 20 : 5,
                                timestamp: DateTime.now(),
                              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                              
                              const SizedBox(height: 32),
                              
                              ShareOptionsPanel(
                                onSharePressed: () => _captureAndShare(currentUser),
                                onSavePressed: _saveToGallery,
                              ).animate().slideY(begin: 0.5, end: 0).fadeIn(),
                              
                              const SizedBox(height: 32),
                              
                              TextButton(
                                onPressed: () => setState(() => _isSharing = false),
                                child: Text('CANCEL', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                              ),
                            ],
                          ),

                        const SizedBox(height: 48),

                        // Actions
                        if (!_isSharing)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.surface),
                                    minimumSize: const Size(0, 56),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: const Text('CONTINUE', style: TextStyle(color: Colors.white)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _onShareVictoryPressed,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.gold,
                                    foregroundColor: Colors.black,
                                    minimumSize: const Size(0, 56),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: const Text('SHARE VICTORY', style: TextStyle(fontWeight: FontWeight.w900)),
                                ),
                              ),
                            ],
                          ).animate(target: _showVictoryCard ? 1 : 0).fadeIn(delay: 400.ms),
                      ],
                    ),

                  const SizedBox(height: 100),

                  // Original Continue Button for Non-winners
                  if (!isWinner)
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
}

class ShareOptionsPanel extends StatelessWidget {
  final VoidCallback onSharePressed;
  final VoidCallback onSavePressed;
  
  const ShareOptionsPanel({
    super.key,
    required this.onSharePressed,
    required this.onSavePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.surface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SHARE TO SOCIALS',
            style: AppTextStyles.label.copyWith(color: AppColors.textSecondary, letterSpacing: 2),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            children: [
              _ShareItem(icon: Icons.whatshot, label: 'WhatsApp', color: Colors.green, onTap: onSharePressed),
              _ShareItem(icon: Icons.camera_alt, label: 'Instagram', color: Colors.pink, onTap: onSharePressed),
              _ShareItem(icon: Icons.send, label: 'Telegram', color: Colors.blue, onTap: onSharePressed),
              _ShareItem(icon: Icons.alternate_email, label: 'X / Twitter', color: Colors.white, onTap: onSharePressed),
              _ShareItem(icon: Icons.link, label: 'Copy Link', color: Colors.grey, onTap: () {}),
              _ShareItem(icon: Icons.save_alt, label: 'Save Image', color: AppColors.gold, onTap: onSavePressed),
              _ShareItem(icon: Icons.more_horiz, label: 'More', color: AppColors.purple, onTap: onSharePressed),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShareItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareItem({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.label.copyWith(fontSize: 8, color: AppColors.textMuted),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
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
