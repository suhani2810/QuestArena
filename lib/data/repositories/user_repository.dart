import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/errors/app_error.dart';
import '../../core/errors/result.dart';
import '../models/user_model.dart';
import '../models/match_history_model.dart';
import '../models/match_end_result.dart';
import '../services/firestore_service.dart';
import '../services/xp_service.dart';
import '../services/rank_service.dart';
import '../../core/utils/level_system.dart';

class UserRepository {
  final FirestoreService _service;

  UserRepository(this._service);

  Future<Result<void>> createUserProfile(UserModel user) async {
    try {
      final isAvailable = await _service.isUsernameAvailable(user.username);
      if (!isAvailable) {
        return const Failure(DatabaseError("Username already taken."));
      }

      await _service.setData(
        path: 'users/${user.uid}',
        data: user.toJson(),
      );

      return const Success(null);
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  Future<Result<UserModel>> getUserProfile(String uid) async {
    try {
      final doc = await _service.getDocument('users/$uid');
      if (doc.exists) {
        return Success(UserModel.fromJson(doc.data() as Map<String, dynamic>));
      }
      return const Failure(DatabaseError("User profile not found."));
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  Future<Result<void>> updateUserProfile(UserModel user) async {
    try {
      await _service.setData(
        path: 'users/${user.uid}',
        data: user.toJson(),
      );
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  Stream<UserModel?> watchUserProfile(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromJson(doc.data()!);
    });
  }

  Future<void> updateAvatarUrl(String uid, String avatarUrl) async {
    await _service.setData(
      path: 'users/$uid',
      data: {'avatarUrl': avatarUrl},
    );
  }

  Future<MatchEndResult?> processMatchEnd({
    required String uid,
    required bool isWin,
    bool isDraw = false,
    bool isArenaBreakerWin = false,
    required int correctAnswers,
    required int totalQuestions,
    required int coinsGained,
  }) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    MatchEndResult? result;

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;

      final userData = snapshot.data()!;
      final user = UserModel.fromJson(userData);

      final xpRewards = XpService.calculateMatchRewards(
        user: user,
        isWin: isWin,
        isDraw: isDraw,
        correctAnswers: correctAnswers,
        totalQuestions: totalQuestions,
      );

      final wrongAnswers = totalQuestions - correctAnswers;
      final rankUpdate = RankService.calculateRankUpdate(
        user: user,
        correctAnswers: correctAnswers,
        wrongAnswers: wrongAnswers,
      );

      final totalXp = user.xp + xpRewards.total;
      final newLevel = LevelSystem.getCurrentLevel(totalXp);
      
      final currentWinStreak = isWin ? user.currentWinStreak + 1 : 0;
      final highestWinStreak = currentWinStreak > user.highestWinStreak 
          ? currentWinStreak 
          : user.highestWinStreak;

      final lastDailyBonusDate = xpRewards.dailyBonusXp > 0 
          ? DateTime.now() 
          : user.lastDailyBonusDate;

      // Achievements
      final achievements = List<String>.from(user.achievements);
      if (isWin && !achievements.contains('first_win')) {
        achievements.add('first_win');
      }
      final totalWins = user.wins + (isWin ? 1 : 0);
      if (totalWins >= 10 && !achievements.contains('veteran')) {
        achievements.add('veteran');
      }

      final abWins = user.arenaBreakerWins + (isArenaBreakerWin && isWin ? 1 : 0);
      final abLosses = user.arenaBreakerLosses + (isArenaBreakerWin && !isWin && !isDraw ? 1 : 0);

      if (isArenaBreakerWin && isWin && !achievements.contains('arena_breaker')) {
        achievements.add('arena_breaker');
      }

      transaction.update(userRef, {
        'xp': totalXp,
        'level': newLevel,
        'coins': user.coins + coinsGained,
        'wins': totalWins,
        'losses': user.losses + (!isWin && !isDraw ? 1 : 0),
        'draws': user.draws + (isDraw ? 1 : 0),
        'matchesPlayed': user.matchesPlayed + 1,
        'currentWinStreak': currentWinStreak,
        'highestWinStreak': highestWinStreak,
        'lastDailyBonusDate': lastDailyBonusDate != null ? Timestamp.fromDate(lastDailyBonusDate) : null,
        'rank': rankUpdate.newRank,
        'subRank': rankUpdate.newSubRank,
        'rankPoints': rankUpdate.newPoints,
        'achievements': achievements,
        'arenaBreakerWins': abWins,
        'arenaBreakerLosses': abLosses,
      });

      result = MatchEndResult(
        xpRewards: xpRewards,
        rankUpdate: rankUpdate,
      );
    });

    return result;
  }

  // Backward compatibility
  Future<void> updateUserStats({
    required String uid,
    required int xpGained,
    required int coinsGained,
    required bool isWin,
  }) async {
    await processMatchEnd(
      uid: uid,
      isWin: isWin,
      isDraw: false,
      correctAnswers: 0,
      totalQuestions: 0,
      coinsGained: coinsGained,
    );
  }

  Future<void> saveMatchHistory(String uid, MatchModel history) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('matchHistory')
        .doc(history.id)
        .set(history.toJson());
  }

  Stream<List<MatchModel>> watchMatchHistory(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('matchHistory')
        .limit(20)
        .snapshots()
        .map((snapshot) {
      final history = snapshot.docs
          .map((doc) => MatchModel.fromJson(doc.data()))
          .toList();
      history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return history;
    });
  }
}
