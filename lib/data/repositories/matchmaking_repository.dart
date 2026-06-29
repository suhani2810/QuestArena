// WHAT THIS FILE DOES:
// Manages the player's presence in the matchmaking queue with robust transaction logic.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/game_utils.dart';
import '../models/matchmaking_model.dart';

class MatchmakingRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Dio _dio;

  MatchmakingRepository(this._dio);

  // Start searching for a match
  Future<void> startSearching(MatchmakingModel ticket) async {
    // 0. Initial Cleanup: Delete any old ticket for this user
    await _db.collection('matchmaking').doc(ticket.uid).delete();

    // 1. Create our searching ticket
    final myTicketRef = _db.collection('matchmaking').doc(ticket.uid);
    await myTicketRef.set({
      ...ticket.toJson(),
      'status': 'searching',
      'lastSeen': FieldValue.serverTimestamp(),
    });

    // 2. Look for potential opponents
    // We filter by status and category in Firestore. This is more efficient.
    final thirtySecondsAgo = DateTime.now().subtract(const Duration(seconds: 30));
    
    final potentialMatches = await _db.collection('matchmaking')
        .where('status', isEqualTo: 'searching')
        .where('categoryId', isEqualTo: ticket.categoryId)
        .limit(20)
        .get();

    for (final doc in potentialMatches.docs) {
      if (doc.id == ticket.uid) continue;

      final data = doc.data();
      
      // Filter staleness in Dart to avoid needing a 3-field composite index
      final DateTime startedAt;
      final startedAtRaw = data['searchStartedAt'];
      if (startedAtRaw == null) continue;
      
      if (startedAtRaw is Timestamp) {
        startedAt = startedAtRaw.toDate();
      } else {
        startedAt = DateTime.parse(startedAtRaw.toString());
      }

      if (startedAt.isBefore(thirtySecondsAgo)) continue;

      // 3. Attempt to "Claim" this opponent via Transaction
      final opponentUid = doc.id;
      final opponentRef = _db.collection('matchmaking').doc(opponentUid);

      final success = await _db.runTransaction((transaction) async {
        final oppSnap = await transaction.get(opponentRef);
        final mySnap = await transaction.get(myTicketRef);

        if (!oppSnap.exists || !mySnap.exists) return false;
        
        final oppData = oppSnap.data()!;
        final myData = mySnap.data()!;

        // Check if both are still searching
        if (oppData['status'] != 'searching' || myData['status'] != 'searching') {
          return false;
        }

        // Lock both tickets to 'creating' status so no one else picks them up
        transaction.update(opponentRef, {'status': 'matched_pending', 'matchedWith': ticket.uid});
        transaction.update(myTicketRef, {'status': 'creating', 'matchedWith': opponentUid});
        
        return true;
      });

      if (success) {
        // I am the "Host" - I will create the game room
        await _createGameRoomAndFinalize(ticket.uid, opponentUid, ticket.categoryId, ticket.categoryName);
        return;
      }
      
      // If transaction failed, continue to next potential match
    }
  }

  Future<void> _createGameRoomAndFinalize(
    String hostUid, 
    String guestUid, 
    int? categoryId,
    String categoryName,
  ) async {
    final roomId = _db.collection('gameRooms').doc().id;

    // 1. Fetch questions
    List<Map<String, dynamic>> questions = [];
    try {
      final response = await _dio.get(ApiConstants.triviaUrlForCategory(categoryId));
      questions = (response.data['results'] as List).map((q) => {
        'question': GameUtils.decodeHtmlEntities(q['question']),
        'correct_answer': GameUtils.decodeHtmlEntities(q['correct_answer']),
        'incorrect_answers': (q['incorrect_answers'] as List)
            .map((a) => GameUtils.decodeHtmlEntities(a))
            .toList(),
      }).toList();
    } catch (e) {
      print("Trivia API Error: $e");
      questions = GameUtils.getFallbackQuestions();
    }

    // 2. Get both tickets to build room data
    final hostSnap = await _db.collection('matchmaking').doc(hostUid).get();
    final guestSnap = await _db.collection('matchmaking').doc(guestUid).get();

    if (!hostSnap.exists || !guestSnap.exists) return;

    // 3. Create the room
    await _db.collection('gameRooms').doc(roomId).set({
      'roomId': roomId,
      'roomCode': '',
      'categoryId': categoryId,
      'categoryName': categoryName,
      'status': 'waiting',
      'player1': {...hostSnap.data()!, 'isReady': false, 'score': 0, 'answers': []},
      'player2': {...guestSnap.data()!, 'isReady': false, 'score': 0, 'answers': []},
      'createdAt': FieldValue.serverTimestamp(),
      'questions': questions,
    });

    // 4. Update both tickets to 'matched' with the real roomId
    final batch = _db.batch();
    batch.update(_db.collection('matchmaking').doc(hostUid), {
      'status': 'matched',
      'gameRoomId': roomId,
    });
    batch.update(_db.collection('matchmaking').doc(guestUid), {
      'status': 'matched',
      'gameRoomId': roomId,
    });
    await batch.commit();
  }

  // Cancel searching
  Future<void> cancelSearching(String uid) async {
    await _db.collection('matchmaking').doc(uid).delete();
  }

  // Listen to the matchmaking ticket
  Stream<MatchmakingModel?> watchTicket(String uid) {
    return _db.collection('matchmaking').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return MatchmakingModel.fromJson(doc.data()!);
    });
  }

  /// Updates the ticket's lastSeen and periodically attempts to find a match 
  /// if the ticket hasn't been matched yet.
  Future<void> pingMatchmaking(String uid) async {
    final ticketRef = _db.collection('matchmaking').doc(uid);
    final snap = await ticketRef.get();
    
    if (!snap.exists) return;
    
    final data = snap.data()!;
    if (data['status'] != 'searching') return;

    // Update lastSeen
    await ticketRef.update({'lastSeen': FieldValue.serverTimestamp()});

    // Re-trigger searching logic
    final ticket = MatchmakingModel.fromJson(data);
    await startSearching(ticket);
  }
}
