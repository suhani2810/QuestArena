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
    required int correctAnswers,
    required int totalQuestions,
    required int coinsGained,
    bool isArenaBreakerWin = false,
    bool isRanked = true,
    bool rankProtectionActive = false,
  }) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    MatchEndResult? result;

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;

      final userData = snapshot.data()!;
      final user = UserModel.fromJson(userData);

      // 1. Calculate XP Rewards
      final xpRewards = XpService.calculateMatchRewards(
        user: user,
        isWin: isWin,
        isDraw: isDraw,
        correctAnswers: correctAnswers,
        totalQuestions: totalQuestions,
      );

      // 2. Handle ELO and Rank (Only for Ranked Matches)
      int newElo = user.eloRating;
      String newRank = user.rank;
      int? newSubRank = user.subRank;
      int newRankPoints = user.rankPoints;
      bool promoted = false;
      bool demoted = false;
      int pointsGained = 0;

      if (isRanked) {
        if (!isDraw) {
          final eloChange = isWin ? 20 : -20;
          newElo = (user.eloRating + eloChange).clamp(0, 5000);
          newRank = RankSystem.getRankFromElo(newElo);
          promoted = RankSystem.ranks.indexOf(newRank) > RankSystem.ranks.indexOf(user.rank);
          demoted = RankSystem.ranks.indexOf(newRank) < RankSystem.ranks.indexOf(user.rank);
          
          // Clear subrank if we move to the new system, or keep it for legacy UI?
          // User said "Preserve existing UI", but the new system doesn't mention subranks.
          // I'll keep subrank null for the new ELO system to indicate it's simplified.
          newSubRank = null; 
        }
      } else {
        // Legacy/Existing Rank System for non-ranked modes (like Private Duel if it was allowed)
        // But user said: "Private Duel and Practice Mode: Do not use ELO. Do not update ELO after these matches."
        // And "Ranked Match only: Winner gains +20 ELO..."
        
        final wrongAnswers = totalQuestions - correctAnswers;
        final rankUpdate = RankService.calculateRankUpdate(
          user: user,
          correctAnswers: correctAnswers,
          wrongAnswers: wrongAnswers,
        );
        newRank = rankUpdate.newRank;
        newSubRank = rankUpdate.newSubRank;
        newRankPoints = rankUpdate.newPoints;
        promoted = rankUpdate.promoted;
        demoted = rankUpdate.demoted;
        pointsGained = rankUpdate.pointsGained;
      }
      final wrongAnswers = totalQuestions - correctAnswers;
      var rankUpdate = RankService.calculateRankUpdate(
        user: user,
        correctAnswers: correctAnswers,
        wrongAnswers: wrongAnswers,
      );

      bool rankProtectionUsed = false;
      int remainingRankProtection = user.rankProtectionMatches;

      // If protection is active, we consume a match regardless of the outcome
      // but only apply the "protection" effect if they would have lost points.
      if (rankProtectionActive && remainingRankProtection > 0) {
        remainingRankProtection--;
        
        if (rankUpdate.pointsGained < 0 || rankUpdate.demoted) {
          rankProtectionUsed = true;
          // Reset rank update to original state (prevent loss)
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

      final totalXp = user.xp + xpRewards.total;
      final newLevel = LevelSystem.getCurrentLevel(totalXp);
      
      final currentWinStreak = isWin ? user.currentWinStreak + 1 : 0;
      final highestWinStreak = currentWinStreak > user.highestWinStreak 
          ? currentWinStreak 
          : user.highestWinStreak;

      final lastDailyBonusDate = xpRewards.dailyBonusXp > 0 
          ? DateTime.now() 
          : user.lastDailyBonusDate;

      // Achievements Logic
      final achievements = List<String>.from(userData['achievements'] ?? []);
      if (isWin && !achievements.contains('first_win')) {
        achievements.add('first_win');
      }
      final totalWins = user.wins + (isWin ? 1 : 0);
      if (totalWins >= 10 && !achievements.contains('veteran')) {
        achievements.add('veteran');
      }

      int abWins = user.arenaBreakerWins;
      int abLosses = user.arenaBreakerLosses;
      if (isArenaBreakerWin) {
        if (isWin) {
          abWins++;
          if (!achievements.contains('arena_breaker')) {
            achievements.add('arena_breaker');
          }
        } else {
          abLosses++;
        }
      }

      transaction.update(userRef, {
        'xp': totalXp,
        'level': newLevel,
        'coins': user.coins + coinsGained,
        'wins': totalWins,
        'losses': user.losses + (!isWin && !isDraw ? 1 : 0),
        'draws': user.draws + (isDraw ? 1 : 0),
        'matchesPlayed': user.matchesPlayed + 1,
        'eloRating': newElo,
        'currentWinStreak': currentWinStreak,
        'highestWinStreak': highestWinStreak,
        'lastDailyBonusDate': lastDailyBonusDate != null ? Timestamp.fromDate(lastDailyBonusDate) : null,
        'rank': newRank,
        'subRank': newSubRank,
        'rankPoints': newRankPoints,
        'achievements': achievements,
        'arenaBreakerWins': abWins,
        'arenaBreakerLosses': abLosses,
        'rankProtectionMatches': remainingRankProtection,
        'rankProtectionActive': false,
        'ownedShieldPackage': remainingRankProtection > 0 ? user.ownedShieldPackage : 0,
      });

      result = MatchEndResult(
        xpRewards: xpRewards,
        rankUpdate: RankUpdateResult(
          oldRank: user.rank,
          oldSubRank: user.subRank,
          oldPoints: user.rankPoints,
          newRank: newRank,
          newSubRank: newSubRank,
          newPoints: newRankPoints,
          pointsGained: isRanked ? (isWin ? 20 : (isDraw ? 0 : -20)) : pointsGained,
          promoted: promoted,
          demoted: demoted,
        ),
        rankUpdate: rankUpdate,
        rankProtectionUsed: rankProtectionUsed,
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
    bool isArenaBreakerWin = false,
    bool rankProtectionActive = false,
  }) async {
    await processMatchEnd(
      uid: uid,
      isWin: isWin,
      isDraw: false,
      correctAnswers: 0,
      totalQuestions: 0,
      coinsGained: coinsGained,
      isArenaBreakerWin: isArenaBreakerWin,
      rankProtectionActive: rankProtectionActive,
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
