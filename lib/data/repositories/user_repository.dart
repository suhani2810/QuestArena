// WHAT THIS FILE DOES:
// Manages player profile data logic with detailed error reporting.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/errors/app_error.dart';
import '../../core/errors/result.dart';
import '../models/user_model.dart';
import '../models/match_history_model.dart';
import '../models/match_end_result.dart';
import '../services/firestore_service.dart';
import '../services/xp_service.dart';
import '../services/rank_service.dart';
import '../../core/utils/level_system.dart';
import '../../core/utils/rank_system.dart';

class UserRepository {
  final FirestoreService _service;

  UserRepository(this._service);

  Future<Result<void>> createUserProfile(UserModel user) async {
    try {
      // 1. Check if the username is taken
      final isAvailable = await _service.isUsernameAvailable(user.username);
      if (!isAvailable) {
        return const Failure(DatabaseError("Username already taken."));
      }

      // 2. Try to save the document
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

  Future<void> deleteUserProfile(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).delete();
  }

  /// Processes match rewards and updates user stats transactionally.
  Future<MatchEndResult?> processMatchEnd({
    required String uid,
    required bool isWin,
    required bool isDraw,
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

      final xpGained = xpRewards.total;
      final totalXp = user.xp + xpGained;
      final newLevel = LevelSystem.getCurrentLevel(totalXp);
      
      final wins = user.wins + (isWin ? 1 : 0);
      final losses = user.losses + (!isWin && !isDraw ? 1 : 0);
      final draws = user.draws + (isDraw ? 1 : 0);
      final matchesPlayed = user.matchesPlayed + 1;
      
      final currentWinStreak = isWin ? user.currentWinStreak + 1 : 0;
      final highestWinStreak = currentWinStreak > user.highestWinStreak 
          ? currentWinStreak 
          : user.highestWinStreak;

      final lastDailyBonusDate = xpRewards.dailyBonusXp > 0 
          ? DateTime.now() 
          : user.lastDailyBonusDate;

      // Achievements Logic (Keeping original logic)
      final achievements = List<String>.from(userData['achievements'] ?? []);
      if (isWin && !achievements.contains('first_win')) {
        achievements.add('first_win');
      }
      if (wins >= 10 && !achievements.contains('veteran')) {
        achievements.add('veteran');
      }

      transaction.update(userRef, {
        'xp': totalXp,
        'level': newLevel,
        'coins': user.coins + coinsGained,
        'wins': wins,
        'losses': losses,
        'draws': draws,
        'matchesPlayed': matchesPlayed,
        'currentWinStreak': currentWinStreak,
        'highestWinStreak': highestWinStreak,
        'lastDailyBonusDate': lastDailyBonusDate != null ? Timestamp.fromDate(lastDailyBonusDate) : null,
        'rank': rankUpdate.newRank,
        'subRank': rankUpdate.newSubRank,
        'rankPoints': rankUpdate.newPoints,
        'achievements': achievements,
      });

      result = MatchEndResult(
        xpRewards: xpRewards,
        rankUpdate: rankUpdate,
      );
    });

    return result;
  }

  // Deprecated: use processMatchEnd instead
  Future<void> updateUserStats({
    required String uid,
    required int xpGained,
    required int coinsGained,
    required bool isWin,
  }) async {
    // Forwarding to processMatchEnd with defaults for backward compatibility
    await processMatchEnd(
      uid: uid,
      isWin: isWin,
      isDraw: false, // Assume not a draw for old calls
      correctAnswers: 0,
      totalQuestions: 0,
      coinsGained: coinsGained,
    );
  }

  Future<void> saveMatchHistory(String uid, MatchHistoryModel history) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('matchHistory')
        .doc(history.matchId)
        .set(history.toJson());
  }

  Stream<List<MatchHistoryModel>> watchMatchHistory(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('matchHistory')
        // Temporarily removed orderBy to check if it's an index issue
        .limit(10)
        .snapshots()
        .map((snapshot) {
      final history = snapshot.docs
          .map((doc) => MatchHistoryModel.fromJson(doc.data()))
          .toList();
      // Sort manually in Dart to avoid index requirements during debug
      history.sort((a, b) => b.playedAt.compareTo(a.playedAt));
      return history;
    });
  }
}
