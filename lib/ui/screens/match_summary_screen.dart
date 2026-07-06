import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../data/models/match_history_model.dart';
import '../../core/utils/game_utils.dart';
import '../widgets/smart_avatar.dart';
import '../widgets/neon_swirl_background.dart';

class MatchSummaryScreen extends StatelessWidget {
  final MatchModel match;
  const MatchSummaryScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final isWin = match.result == MatchResult.win;
    final isDraw = match.result == MatchResult.draw;

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        title: Text('MATCH SUMMARY', style: AppTextStyles.display.copyWith(fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: NeonSwirlBackground(
        colors: isWin 
            ? const [AppColors.teal, AppColors.neonViolet] 
            : (isDraw ? const [AppColors.gold, AppColors.purple] : const [AppColors.red, AppColors.purple]),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Result Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: (isWin ? AppColors.teal : (isDraw ? AppColors.gold : AppColors.red)).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isWin ? AppColors.teal : (isDraw ? AppColors.gold : AppColors.red),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  isWin ? 'VICTORY' : (isDraw ? 'DRAW' : 'DEFEAT'),
                  style: AppTextStyles.display.copyWith(
                    fontSize: 24,
                    color: isWin ? AppColors.teal : (isDraw ? AppColors.gold : AppColors.red),
                  ),
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

              const SizedBox(height: 40),

              // Score Comparison
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PlayerScore(
                    name: 'YOU',
                    score: match.playerScore,
                    isMe: true,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('VS', style: AppTextStyles.display.copyWith(color: AppColors.textMuted, fontSize: 20)),
                  ),
                  _PlayerScore(
                    name: match.opponentName,
                    avatarUrl: match.opponentAvatarUrl,
                    score: match.opponentScore,
                    isMe: false,
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 48),

              // Details Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cardBg.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.surface),
                ),
                child: Column(
                  children: [
                    _SummaryRow(label: 'TOPIC', value: match.categoryName, icon: Icons.category_rounded),
                    const Divider(color: AppColors.surface, height: 32),
                    _SummaryRow(label: 'MODE', value: match.matchTypeLabel, icon: Icons.sports_esports_rounded),
                    const Divider(color: AppColors.surface, height: 32),
                    _SummaryRow(label: 'XP EARNED', value: '+${match.xpEarned} XP', valueColor: AppColors.gold, icon: Icons.stars_rounded),
                    const Divider(color: AppColors.surface, height: 32),
                    _SummaryRow(label: 'PLAYED', value: GameUtils.getRelativeTime(match.timestamp), icon: Icons.calendar_today_rounded),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('BACK TO HISTORY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '--';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes == 0) return '${seconds}s';
    return '${minutes}m ${remainingSeconds}s';
  }
}

class _PlayerScore extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final int score;
  final bool isMe;

  const _PlayerScore({required this.name, this.avatarUrl, required this.score, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SmartAvatar(
          avatarUrl: avatarUrl,
          size: 80,
          showGlow: isMe,
          showBorder: true,
        ),
        const SizedBox(height: 12),
        Text(
          name.toUpperCase(),
          style: AppTextStyles.label.copyWith(fontSize: 10, letterSpacing: 1),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '$score',
          style: AppTextStyles.display.copyWith(fontSize: 32, color: isMe ? AppColors.gold : Colors.white),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _SummaryRow({required this.label, required this.value, required this.icon, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 20),
        const SizedBox(width: 12),
        Text(label, style: AppTextStyles.label.copyWith(fontSize: 11, color: AppColors.textSecondary)),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.headline.copyWith(
            fontSize: 16, 
            color: valueColor ?? Colors.white,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
