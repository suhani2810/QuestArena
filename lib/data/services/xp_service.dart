import '../models/user_model.dart';

class XpRewardBreakdown {
  final int matchCompleted;
  final int outcomeXp;
  final int correctAnswersXp;
  final int perfectScoreXp;
  final int dailyBonusXp;
  final int streakBonusXp;

  XpRewardBreakdown({
    this.matchCompleted = 0,
    this.outcomeXp = 0,
    this.correctAnswersXp = 0,
    this.perfectScoreXp = 0,
    this.dailyBonusXp = 0,
    this.streakBonusXp = 0,
  });

  int get total =>
      matchCompleted +
      outcomeXp +
      correctAnswersXp +
      perfectScoreXp +
      dailyBonusXp +
      streakBonusXp;
}

class XpService {
  static XpRewardBreakdown calculateMatchRewards({
    required UserModel user,
    required bool isWin,
    required bool isDraw,
    required int correctAnswers,
    required int totalQuestions,
  }) {
    int matchCompleted = 20;
    int outcomeXp = isWin ? 15 : (isDraw ? 10 : 5);
    int correctAnswersXp = correctAnswers * 2;
    int perfectScoreXp = (correctAnswers == totalQuestions && totalQuestions > 0) ? 10 : 0;

    int dailyBonusXp = 0;
    final now = DateTime.now();
    final lastDaily = user.lastDailyBonusDate;
    if (lastDaily == null ||
        lastDaily.year != now.year ||
        lastDaily.month != now.month ||
        lastDaily.day != now.day) {
      dailyBonusXp = 20;
    }

    int streakBonusXp = 0;
    // 5-win streak: +25 XP (Awarded every 5 wins)
    if (isWin && (user.currentWinStreak + 1) % 5 == 0) {
      streakBonusXp = 25;
    }

    return XpRewardBreakdown(
      matchCompleted: matchCompleted,
      outcomeXp: outcomeXp,
      correctAnswersXp: correctAnswersXp,
      perfectScoreXp: perfectScoreXp,
      dailyBonusXp: dailyBonusXp,
      streakBonusXp: streakBonusXp,
    );
  }
}
