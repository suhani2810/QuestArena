import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:questarena/core/errors/result.dart';
import 'package:questarena/core/errors/app_error.dart';
import 'package:questarena/data/models/user_model.dart';
import 'package:questarena/data/models/match_history_model.dart';
import 'package:questarena/data/models/match_end_result.dart';
import 'package:questarena/data/services/firestore_service.dart';
import 'package:questarena/data/services/xp_service.dart';
import 'package:questarena/data/services/rank_service.dart';
import 'package:questarena/core/utils/level_system.dart';

/// Repository responsible for user profile management and post-match data processing.
class UserRepository {
  final FirestoreService _service;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  UserRepository(this._service);

  /// Fetches the user profile from Firestore.
  /// Returns a [Result] containing [UserModel] on success or [AppError] on failure.
  Future<Result<UserModel>> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return Success(UserModel.fromJson(doc.data()!));
      } else {
        return const Failure(DatabaseError('User profile not found.'));
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return Failure(UnknownError(e.toString()));
    }
  }

  /// Provides a real-time stream of the user profile for a given [uid].
  Stream<UserModel?> watchUserProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (snapshot.exists && data != null) {
        return UserModel.fromJson(data);
      }
      return null;
    });
  }

  /// Creates a new user profile document.
  Future<Result<void>> createUserProfile(UserModel user) async {
    try {
      await _service.setData(
        path: 'users/${user.uid}',
        data: user.toJson(),
        merge: false,
      );
      return const Success(null);
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      return Failure(DatabaseError(e.toString()));
    }
  }

  /// Updates specific fields in the user profile.
  Future<Result<void>> updateUserProfile(UserModel user) async {
    try {
      await _service.setData(
        path: 'users/${user.uid}',
        data: user.toJson(),
      );
      return const Success(null);
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      return Failure(DatabaseError(e.toString()));
    }
  }

  /// Deletes the user profile.
  Future<Result<void>> deleteUserProfile(String uid) async {
    try {
      await _service.deleteData('users/$uid');
      return const Success(null);
    } catch (e) {
      debugPrint('Error deleting user profile: $e');
      return Failure(DatabaseError(e.toString()));
    }
  }

  /// Streams the match history for a user, sorted by newest first.
  Stream<List<MatchModel>> watchMatchHistory(String uid, {int limit = 20}) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('matchHistory')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id; // Ensure the ID is present for the model
              return MatchModel.fromJson(data);
            }).toList());
  }

  /// Processes all updates related to a match ending (XP, Rank, Coins, Stats).
  /// This operation is performed in a transaction to ensure atomicity.
  Future<MatchEndResult?> processMatchEnd({
    required String uid,
    required bool isWin,
    required bool isDraw,
    required int correctAnswers,
    required int totalQuestions,
    required int coinsGained,
    required bool isRanked,
    required bool rankProtectionActive,
    bool isArenaBreakerWin = false,
    int? playerScore,
    int? opponentScore,
    String? opponentId,
    String? opponentName,
    String? opponentAvatar,
    int? opponentElo,
    bool? isArenaBreaker,
  }) async {
    try {
      final userRef = _db.collection('users').doc(uid);
      MatchEndResult? matchResult;

      await _db.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        final userData = userDoc.data();
        if (userData == null) return;

        final user = UserModel.fromJson(userData);
        final xpRewards = XpService.calculateMatchRewards(
          user: user,
          isWin: isWin,
          isDraw: isDraw,
          correctAnswers: correctAnswers,
          totalQuestions: totalQuestions,
        );

        final wrongAnswers = totalQuestions - correctAnswers;
        var rankUpdate = isRanked
            ? RankService.calculateRankUpdate(
                user: user,
                correctAnswers: correctAnswers,
                wrongAnswers: wrongAnswers,
              )
            : RankUpdateResult(
                oldRank: user.rank,
                oldSubRank: user.subRank,
                oldPoints: user.rankPoints,
                newRank: user.rank,
                newSubRank: user.subRank,
                newPoints: user.rankPoints,
                pointsGained: 0,
              );

        bool rankProtectionUsed = false;
        int remainingRankProtection = user.rankProtectionMatches;

        if (rankProtectionActive && remainingRankProtection > 0) {
          remainingRankProtection--;
          if (rankUpdate.pointsGained < 0 || rankUpdate.demoted) {
            rankProtectionUsed = true;
            rankUpdate = RankUpdateResult(
              oldRank: user.rank,
              oldSubRank: user.subRank,
              oldPoints: user.rankPoints,
              newRank: user.rank,
              newSubRank: user.subRank,
              newPoints: user.rankPoints,
              pointsGained: 0,
              promoted: false,
              demoted: false,
            );
          }
        }

        int newElo = user.eloRating;
        if (isRanked) {
          newElo = _calculateElo(
            user.eloRating,
            opponentElo ?? 1200,
            isWin,
            isDraw,
          ).clamp(0, 5000);
        }

        final totalXp = user.xp + xpRewards.total;
        final newLevel = LevelSystem.getCurrentLevel(totalXp);
        final newWins = user.wins + (isWin ? 1 : 0);
        final newLosses = user.losses + (!isWin && !isDraw ? 1 : 0);
        final newDraws = user.draws + (isDraw ? 1 : 0);
        final currentWinStreak = isWin ? user.currentWinStreak + 1 : 0;
        final highestWinStreak = math.max(
          currentWinStreak,
          user.highestWinStreak,
        );
        final lastDailyBonusDate = xpRewards.dailyBonusXp > 0
            ? DateTime.now()
            : user.lastDailyBonusDate;

        final achievements = List<String>.from(userData['achievements'] ?? []);
        if (isWin && !achievements.contains('first_win')) {
          achievements.add('first_win');
        }
        if (newWins >= 10 && !achievements.contains('veteran')) {
          achievements.add('veteran');
        }

        int abWins = user.arenaBreakerWins;
        int abLosses = user.arenaBreakerLosses;
        final arenaBreakerResult =
            isArenaBreakerWin || (isArenaBreaker ?? false);
        if (arenaBreakerResult) {
          if (isWin) {
            abWins++;
            if (!achievements.contains('arena_breaker')) {
              achievements.add('arena_breaker');
            }
          } else if (!isDraw) {
            abLosses++;
          }
        }
        if (abWins >= 5 && !achievements.contains('clutch_master')) {
          achievements.add('clutch_master');
        }
        if (abWins >= 10 && !achievements.contains('unbreakable')) {
          achievements.add('unbreakable');
        }

        final now = DateTime.now();
        final lastReset = user.lastCoinResetDate;
        final isNewDay = now.year != lastReset.year ||
            now.month != lastReset.month ||
            now.day != lastReset.day;
        final todayCoins = isNewDay ? 0 : user.todayCoinsEarned;
        var coinReward = coinsGained;
        const dailyCoinCap = 500;
        if (todayCoins + coinReward > dailyCoinCap) {
          coinReward = math.max(0, dailyCoinCap - todayCoins);
        }

        transaction.update(userRef, {
          'xp': totalXp,
          'level': newLevel,
          'coins': user.coins + coinReward,
          'todayCoinsEarned': todayCoins + coinReward,
          'lastCoinResetDate': Timestamp.fromDate(now),
          'wins': newWins,
          'losses': newLosses,
          'draws': newDraws,
          'matchesPlayed': user.matchesPlayed + 1,
          'eloRating': newElo,
          'currentWinStreak': currentWinStreak,
          'highestWinStreak': highestWinStreak,
          'lastDailyBonusDate': lastDailyBonusDate != null
              ? Timestamp.fromDate(lastDailyBonusDate)
              : null,
          'rank': rankUpdate.newRank,
          'subRank': rankUpdate.newSubRank,
          'rankPoints': rankUpdate.newPoints,
          'achievements': achievements,
          'weeklyWins': user.weeklyWins + (isWin ? 1 : 0),
          'weeklyXp': user.weeklyXp + xpRewards.total,
          'weeklyMatchesPlayed': user.weeklyMatchesPlayed + 1,
          'arenaBreakerWins': abWins,
          'arenaBreakerLosses': abLosses,
          'rankProtectionMatches': remainingRankProtection,
          'rankProtectionActive': false,
          'ownedShieldPackage':
              remainingRankProtection > 0 ? user.ownedShieldPackage : 0,
          'totalQuestionsCorrect': user.totalQuestionsCorrect + correctAnswers,
          'totalPerfectScores': user.totalPerfectScores +
              (correctAnswers >= totalQuestions ? 1 : 0),
        });

        matchResult = MatchEndResult(
          xpRewards: xpRewards,
          rankUpdate: rankUpdate,
          rankProtectionUsed: rankProtectionUsed,
        );
      });

      return matchResult;
    } catch (e, stack) {
      debugPrint('processMatchEnd fatal error: $e\n$stack');
      return null;
    }
  }

  Future<void> saveMatchHistory(String uid, MatchModel history) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('matchHistory')
        .doc(history.id)
        .set(history.toJson());
  }

  /// Standard Elo calculation.
  int _calculateElo(int currentElo, int opponentElo, bool isWin, bool isDraw) {
    const kFactor = 32;
    final expectedScore =
        1 / (1 + math.pow(10, (opponentElo - currentElo) / 400));
    final actualScore = isWin ? 1.0 : (isDraw ? 0.5 : 0.0);
    return currentElo + (kFactor * (actualScore - expectedScore)).round();
  }
}
