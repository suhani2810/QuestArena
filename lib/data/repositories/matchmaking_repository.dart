// WHAT THIS FILE DOES:
// Manages the player's presence in the matchmaking queue with robust
// transaction logic, category matching, and ELO-based search expansion.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/game_utils.dart';
import '../models/matchmaking_model.dart';

class MatchmakingRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Dio _dio;

  MatchmakingRepository(this._dio);

  // Start searching for a match.
  Future<void> startSearching(MatchmakingModel ticket) async {
    final myTicketRef = _db.collection('matchmaking').doc(ticket.uid);

    // Cleanup any old ticket for this user, then save the fresh ticket.
    await myTicketRef.delete();
    await myTicketRef.set({
      ...ticket.toJson(),
      'status': 'searching',
      'lastSeen': FieldValue.serverTimestamp(),
    });

    await _tryMatch(ticket);
  }

  // Expansion method to be called periodically by the client.
  Future<void> expandSearch(String uid) async {
    final doc = await _db.collection('matchmaking').doc(uid).get();
    if (!doc.exists || doc.data() == null) return;

    final data = doc.data()!;
    if (data['status'] != 'searching') return;

    final currentRange = (data['searchRange'] as num? ?? 100).toInt();
    final newRange = currentRange + 100;

    await _db.collection('matchmaking').doc(uid).update({
      'searchRange': newRange,
      'lastSeen': FieldValue.serverTimestamp(),
    });

    final updatedTicket = MatchmakingModel.fromJson({
      ...data,
      'searchRange': newRange,
    });
    await _tryMatch(updatedTicket);
  }

  Future<void> _tryMatch(MatchmakingModel ticket) async {
    final myTicketRef = _db.collection('matchmaking').doc(ticket.uid);

    final potentialMatches = await _db
        .collection('matchmaking')
        .where('status', isEqualTo: 'searching')
        .where('categoryId', isEqualTo: ticket.categoryId)
        .limit(20)
        .get();

    QueryDocumentSnapshot<Map<String, dynamic>>? bestMatchDoc;
    var bestEloDiff = 999999;
    final thirtySecondsAgo = DateTime.now().subtract(
      const Duration(seconds: 30),
    );

    for (final doc in potentialMatches.docs) {
      if (doc.id == ticket.uid) continue;

      final data = doc.data();

      final startedAt = _parseDate(data['searchStartedAt']);
      if (startedAt == null || startedAt.isBefore(thirtySecondsAgo)) {
        continue;
      }

      final opponentElo = (data['eloRating'] as num? ?? 1200).toInt();
      final eloDiff = (ticket.eloRating - opponentElo).abs();
      final opponentRange = (data['searchRange'] as num? ?? 100).toInt();
      final maxAllowedDiff = ticket.searchRange > opponentRange
          ? ticket.searchRange
          : opponentRange;

      if (eloDiff <= maxAllowedDiff && eloDiff < bestEloDiff) {
        bestEloDiff = eloDiff;
        bestMatchDoc = doc;
      }
    }

    if (bestMatchDoc == null) return;

    final opponentUid = bestMatchDoc.id;
    final opponentRef = _db.collection('matchmaking').doc(opponentUid);

    final success = await _db.runTransaction((transaction) async {
      final oppSnap = await transaction.get(opponentRef);
      final mySnap = await transaction.get(myTicketRef);

      if (!oppSnap.exists || !mySnap.exists) return false;

      final oppData = oppSnap.data()!;
      final myData = mySnap.data()!;

      if (oppData['status'] != 'searching' ||
          myData['status'] != 'searching' ||
          oppData['categoryId'] != ticket.categoryId ||
          myData['categoryId'] != ticket.categoryId) {
        return false;
      }

      transaction.update(opponentRef, {
        'status': 'matched_pending',
        'matchedWith': ticket.uid,
      });
      transaction.update(myTicketRef, {
        'status': 'creating',
        'matchedWith': opponentUid,
      });

      return true;
    });

    if (success) {
      await _createGameRoomAndFinalize(
        ticket.uid,
        opponentUid,
        ticket.categoryId,
        ticket.categoryName,
      );
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  Future<void> _createGameRoomAndFinalize(
    String hostUid,
    String guestUid,
    int? categoryId,
    String categoryName,
  ) async {
    final roomId = _db.collection('gameRooms').doc().id;

    List<Map<String, dynamic>> questions = [];
    try {
      final response = await _dio.get(
        ApiConstants.triviaUrlForCategory(categoryId),
      );
      questions = (response.data['results'] as List)
          .map(
            (q) => {
              'question': GameUtils.decodeHtmlEntities(q['question']),
              'correct_answer':
                  GameUtils.decodeHtmlEntities(q['correct_answer']),
              'incorrect_answers': (q['incorrect_answers'] as List)
                  .map((a) => GameUtils.decodeHtmlEntities(a))
                  .toList(),
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Trivia API Error: $e');
      questions = GameUtils.getFallbackQuestions();
    }

    final hostSnap = await _db.collection('matchmaking').doc(hostUid).get();
    final guestSnap = await _db.collection('matchmaking').doc(guestUid).get();

    if (!hostSnap.exists || !guestSnap.exists) return;

    await _db.collection('gameRooms').doc(roomId).set({
      'roomId': roomId,
      'roomCode': '',
      'categoryId': categoryId,
      'categoryName': categoryName,
      'status': 'waiting',
      'isRanked': true,
      'player1': {
        ...hostSnap.data()!,
        'isReady': false,
        'score': 0,
        'answers': [],
      },
      'player2': {
        ...guestSnap.data()!,
        'isReady': false,
        'score': 0,
        'answers': [],
      },
      'createdAt': FieldValue.serverTimestamp(),
      'questions': questions,
    });

    final batch = _db.batch();
    batch.update(_db.collection('matchmaking').doc(hostUid), {
      'status': 'matched',
      'matchedWith': guestUid,
      'gameRoomId': roomId,
    });
    batch.update(_db.collection('matchmaking').doc(guestUid), {
      'status': 'matched',
      'matchedWith': hostUid,
      'gameRoomId': roomId,
    });
    await batch.commit();
  }

  // Cancel searching.
  Future<void> cancelSearching(String uid) async {
    await _db.collection('matchmaking').doc(uid).delete();
  }

  // Listen to the matchmaking ticket.
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

    await ticketRef.update({'lastSeen': FieldValue.serverTimestamp()});

    final ticket = MatchmakingModel.fromJson(data);
    await _tryMatch(ticket);
  }
}
