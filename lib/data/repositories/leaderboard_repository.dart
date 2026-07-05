// WHAT THIS FILE DOES:
// Fetches the global rankings from Firestore.
//
// KEY CONCEPTS IN THIS FILE:
// • Querying: Using .orderBy() and .limit() to get specific data.
// • Mapping: Converting a list of Firestore documents into a list of Models.

import '../models/leaderboard_model.dart';
import '../../core/errors/result.dart';
import '../../core/errors/app_error.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Result<List<LeaderboardModel>>> getTopPlayers() async {
    try {
      final snapshot = await _db.collection('users').limit(100).get();

      final players = snapshot.docs
          .map((doc) => LeaderboardModel.fromJson(doc.data()))
          .toList();
      players.sort(_compareByPlayerStanding);

      return Success(players);
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  Stream<List<LeaderboardModel>> watchTopPlayers() {
    return _db.collection('users').limit(100).snapshots().map((snapshot) {
      final players = snapshot.docs
          .map((doc) => LeaderboardModel.fromJson(doc.data()))
          .toList();
      players.sort(_compareByPlayerStanding);
      return players;
    });
  }

  int _compareByPlayerStanding(LeaderboardModel a, LeaderboardModel b) {
    final levelCompare = b.level.compareTo(a.level);
    if (levelCompare != 0) return levelCompare;

    final rankCompare = b.rankStrength.compareTo(a.rankStrength);
    if (rankCompare != 0) return rankCompare;

    final winsCompare = b.wins.compareTo(a.wins);
    if (winsCompare != 0) return winsCompare;

    final eloCompare = b.eloRating.compareTo(a.eloRating);
    if (eloCompare != 0) return eloCompare;

    return b.xp.compareTo(a.xp);
  }
}
