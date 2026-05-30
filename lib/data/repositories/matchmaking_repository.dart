// WHAT THIS FILE DOES:
// Manages the player's presence in the matchmaking queue.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/matchmaking_model.dart';
import '../services/firestore_service.dart';

class MatchmakingRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Start searching for a match
  Future<void> startSearching(MatchmakingModel ticket) async {
    await _db.collection('matchmaking').doc(ticket.uid).set(ticket.toJson());
  }

  // Cancel searching
  Future<void> cancelSearching(String uid) async {
    await _db.collection('matchmaking').doc(uid).delete();
  }

  // Listen to the matchmaking ticket for updates (e.g., when status becomes 'matched')
  Stream<MatchmakingModel?> watchTicket(String uid) {
    return _db.collection('matchmaking').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return MatchmakingModel.fromJson(doc.data()!);
    });
  }
}
