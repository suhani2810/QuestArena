// WHAT THIS FILE DOES:
// Manages the real-time state of a specific game session.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/models/quiz_category.dart';
import '../../core/utils/game_utils.dart';
import '../models/game_room_model.dart';

class GameRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Dio _dio;

  GameRepository(this._dio);

  // Create a private room
  Future<String> createPrivateRoom(
    Map<String, dynamic> player1Data,
    String code,
    QuizCategory category,
  ) async {
    final roomId = _db.collection('gameRooms').doc().id;
    
    // Fetch questions from client side since Cloud Functions are not available on Spark plan
    List<Map<String, dynamic>> questions = [];
    try {
      final response = await _dio.get(ApiConstants.triviaUrlForCategory(category.id));
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

    await _db.collection('gameRooms').doc(roomId).set({
      'roomId': roomId,
      'roomCode': code,
      'categoryId': category.id,
      'categoryName': category.name,
      'status': 'waiting',
      'player1': {...player1Data, 'isReady': false, 'score': 0, 'answers': []},
      'player2': null,
      'createdAt': FieldValue.serverTimestamp(),
      'questions': questions,
    });
    return roomId;
  }

  // Join a private room using a code
  Future<String?> joinPrivateRoom(Map<String, dynamic> player2Data, String code) async {
    // Look for rooms with this code that are not already active/finished
    final query = await _db
        .collection('gameRooms')
        .where('roomCode', isEqualTo: code)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final doc = query.docs.first;
    final status = doc.get('status');

    // Only allow joining if it's in a 'waiting' or 'fetching_questions' state
    if (status != 'waiting' && status != 'fetching_questions') return null;

    await doc.reference.update({
      'player2': {...player2Data, 'isReady': false, 'score': 0, 'answers': []},
      'status': 'active', // Room is now full
    });

    return doc.id;
  }

  // Watch a specific game room
  Stream<GameRoomModel?> watchRoom(String roomId) {
    return _db.collection('gameRooms').doc(roomId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return GameRoomModel.fromJson(doc.data()!);
    });
  }

  // Set the player as "Ready"
  Future<void> setPlayerReady(String roomId, int playerNumber) async {
    await _db.collection('gameRooms').doc(roomId).update({
      'player$playerNumber.isReady': true,
    });
  }

  // Submit an answer
  Future<void> submitAnswer({
    required String roomId,
    required String userId,
    required int playerNumber,
    required String answer,
    required int scoreIncrement,
  }) async {
    final roomRef = _db.collection('gameRooms').doc(roomId);
    
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final playerKey = 'player$playerNumber';
      
      final player1 = data['player1'] as Map<String, dynamic>;
      final player2 = data['player2'] as Map<String, dynamic>?;

      if (player2 == null) return; // Can't progress without both players

      final currentP1Answers = List<String>.from(player1['answers'] ?? []);
      final currentP2Answers = List<String>.from(player2['answers'] ?? []);
      
      final currentIdx = data['currentQuestionIndex'] ?? 0;
      final questions = List<dynamic>.from(data['questions'] ?? []);

      // 1. Update current player's answers and score
      final updatedAnswers = playerNumber == 1 ? currentP1Answers : currentP2Answers;
      
      // Safety: Don't answer if already answered this index or beyond
      if (updatedAnswers.length > currentIdx) return; 

      // Padding for missed questions due to disconnect
      while (updatedAnswers.length < currentIdx) {
        updatedAnswers.add("TIMEOUT");
      }
      
      updatedAnswers.add(answer);
      final oldScore = (playerNumber == 1 ? player1['score'] : player2['score']) ?? 0;
      final newScore = oldScore + scoreIncrement;

      transaction.update(roomRef, {
        '$playerKey.answers': updatedAnswers,
        '$playerKey.score': newScore,
      });

      // 2. Check if we should move to the next question
      final p1Len = playerNumber == 1 ? updatedAnswers.length : currentP1Answers.length;
      final p2Len = playerNumber == 2 ? updatedAnswers.length : currentP2Answers.length;

      final opponentId = playerNumber == 1 ? (player2?['uid']) : player1['uid'];
      final opponentPresence = data['presence']?[opponentId];
      final isOpponentOnline = opponentPresence?['isOnline'] ?? true;

      // Advance if BOTH answered OR if current player answered and opponent is offline
      bool shouldAdvance = false;
      if (p1Len > currentIdx && p2Len > currentIdx) {
        shouldAdvance = true;
      } else if (playerNumber == 1 && p1Len > currentIdx && !isOpponentOnline) {
        shouldAdvance = true;
      } else if (playerNumber == 2 && p2Len > currentIdx && !isOpponentOnline) {
        shouldAdvance = true;
      }

      if (shouldAdvance) {
        if (currentIdx + 1 < questions.length) {
          transaction.update(roomRef, {'currentQuestionIndex': currentIdx + 1});
        } else {
          // Game Finished
          final p1Score = playerNumber == 1 ? newScore : (player1['score'] ?? 0);
          final p2Score = playerNumber == 2 ? newScore : (player2['score'] ?? 0);
          
          if (p1Score == p2Score) {
            // TIE DETECTED -> Trigger Arena Breaker
            transaction.update(roomRef, {
              'status': 'arena_breaker',
              'isArenaBreaker': true,
            });
            // Fetch the first tie-breaker question
            _fetchArenaBreakerQuestion(roomId);
          } else {
            String winnerId = 'draw';
            if (p1Score > p2Score) winnerId = player1['uid'];
            if (p2Score > p1Score) winnerId = player2['uid'];

            transaction.update(roomRef, {
              'status': 'finished',
              'winnerId': winnerId,
            });
          }
        }
      }
    });
  }

  // --- ARENA BREAKER LOGIC ---

  /// Internal helper to fetch a single fresh question for the Arena Breaker round.
  Future<void> _fetchArenaBreakerQuestion(String roomId) async {
    try {
      final response = await _dio.get(ApiConstants.triviaUrl, queryParameters: {'amount': 1});
      final q = (response.data['results'] as List).first;
      final questionMap = {
        'question': GameUtils.decodeHtmlEntities(q['question']),
        'correct_answer': GameUtils.decodeHtmlEntities(q['correct_answer']),
        'incorrect_answers': (q['incorrect_answers'] as List)
            .map((a) => GameUtils.decodeHtmlEntities(a))
            .toList(),
      };

      await _db.collection('gameRooms').doc(roomId).update({
        'arenaBreakerQuestion': questionMap,
        'arenaBreakerSubmissions': {}, // Reset submissions for the new round
        'arenaBreakerStartTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Arena Breaker API Error: $e");
      // Fallback
      await _db.collection('gameRooms').doc(roomId).update({
        'arenaBreakerQuestion': GameUtils.getFallbackQuestions().first,
        'arenaBreakerSubmissions': {},
        'arenaBreakerStartTime': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Submits an answer during the Arena Breaker phase.
  Future<void> submitArenaBreakerAnswer({
    required String roomId,
    required String userId,
    required String answer,
  }) async {
    final roomRef = _db.collection('gameRooms').doc(roomId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final question = data['arenaBreakerQuestion'];
      if (question == null) return;

      final isCorrect = answer == question['correct_answer'];
      final submissions = Map<String, dynamic>.from(data['arenaBreakerSubmissions'] ?? {});

      if (submissions.containsKey(userId)) return; // Already answered this round

      submissions[userId] = {
        'answer': answer,
        'isCorrect': isCorrect,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      transaction.update(roomRef, {'arenaBreakerSubmissions': submissions});

      final player1 = data['player1'];
      final player2 = data['player2'];

      final opponentId = userId == player1['uid'] ? player2['uid'] : player1['uid'];
      final opponentPresence = data['presence']?[opponentId];
      final isOpponentOnline = opponentPresence?['isOnline'] ?? true;

      // Check if both have submitted OR if one answered correctly (instant win) OR if opponent is offline
      if (submissions.length == 2 || isOpponentOnline == false || isCorrect == true) {
        final s1 = submissions[player1['uid']];
        final s2 = submissions[player2['uid']];

        String? winnerId;

        // Instant win if current player is correct and opponent is offline or hasn't answered yet
        if (isCorrect && (submissions.length == 1)) {
           winnerId = userId;
        } else if (s1 != null && s2 != null) {
          if (s1['isCorrect'] && !s2['isCorrect']) {
            winnerId = player1['uid'];
          } else if (!s1['isCorrect'] && s2['isCorrect']) {
            winnerId = player2['uid'];
          } else if (s1['isCorrect'] && s2['isCorrect']) {
            // Both correct -> Compare response times
            if (s1['timestamp'] < s2['timestamp']) {
              winnerId = player1['uid'];
            } else if (s2['timestamp'] < s1['timestamp']) {
              winnerId = player2['uid'];
            } else {
              // CASE 4: PERFECT TIE (Identical times)
              transaction.update(roomRef, {
                'arenaBreakerStatusMessage': 'Perfect Tie! Launching another Arena Breaker round...',
              });
              _scheduleNextABRound(roomId);
              return;
            }
          } else {
            // CASE 2: BOTH INCORRECT
            transaction.update(roomRef, {
              'arenaBreakerStatusMessage': 'Both players answered incorrectly. Next question loading...',
            });
            _scheduleNextABRound(roomId);
            return;
          }
        } else if (submissions.length == 1 && !isCorrect && !isOpponentOnline) {
            // Current player wrong and opponent offline -> New round
            _scheduleNextABRound(roomId);
            return;
        }

        if (winnerId != null) {
          transaction.update(roomRef, {
            'status': 'finished',
            'winnerId': winnerId,
            'isArenaBreakerWin': true,
            'arenaBreakerStatusMessage': null,
          });
        }
      }
    });
  }

  /// Helper to delay the transition between Arena Breaker rounds
  void _scheduleNextABRound(String roomId) {
    Future.delayed(const Duration(seconds: 3), () {
      _fetchArenaBreakerQuestion(roomId);
    });
  }

  // Emergency Fallback: If Cloud Function fails, the client will push mock questions
  Future<void> triggerQuestionsFallback(String roomId) async {
    await _db.collection('gameRooms').doc(roomId).update({
      'questions': GameUtils.getFallbackQuestions(),
      'status': 'waiting',
    });
  }

  // Claim match rewards
  Future<void> claimRewards(String roomId, String userId, bool isWin) async {
    final roomRef = _db.collection('gameRooms').doc(roomId);
    
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) return;

      final claimed = List<String>.from(snapshot.get('claimedRewards') ?? []);
      if (claimed.contains(userId)) return; // Already claimed

      claimed.add(userId);
      transaction.update(roomRef, {'claimedRewards': claimed});
    });
  }

  // --- REMATCH LOGIC ---

  /// Adds the user's ID to the rematchRequests list in Firestore.
  Future<void> requestRematch(String roomId, String userId) async {
    await _db.collection('gameRooms').doc(roomId).update({
      'rematchRequests': FieldValue.arrayUnion([userId]),
    });
  }

  /// Creates a completely fresh match using the same players from the old room.
  Future<void> createRematchGame({
    required String oldRoomId,
    required Map<String, dynamic> player1,
    required Map<String, dynamic> player2,
    required int? categoryId,
    required String categoryName,
  }) async {
    final newRoomId = _db.collection('gameRooms').doc().id;

    // Fetch fresh questions
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

    // Reset dynamic fields for both players
    Map<String, dynamic> resetPlayer(Map<String, dynamic> p) {
      final newP = Map<String, dynamic>.from(p);
      newP['score'] = 0;
      newP['answers'] = [];
      newP['isReady'] = false;
      return newP;
    }

    final batch = _db.batch();

    // 1. Set up the new room
    batch.set(_db.collection('gameRooms').doc(newRoomId), {
      'roomId': newRoomId,
      'roomCode': '',
      'categoryId': categoryId,
      'categoryName': categoryName,
      'status': 'waiting',
      'player1': resetPlayer(player1),
      'player2': resetPlayer(player2),
      'createdAt': FieldValue.serverTimestamp(),
      'questions': questions,
    });

    // 2. Link the old room to the new one
    batch.update(_db.collection('gameRooms').doc(oldRoomId), {
      'nextMatchId': newRoomId,
    });

    await batch.commit();
  }

  // --- DISCONNECT & FORFEIT LOGIC ---

  /// Updates the user's presence status in the game room.
  Future<void> updatePresence(String roomId, String userId, bool isOnline) async {
    await _db.collection('gameRooms').doc(roomId).update({
      'presence.$userId': {
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      },
    });
  }

  /// Declares a winner by forfeit if the opponent fails to reconnect.
  Future<void> handleForfeit(String roomId, String winnerId) async {
    final roomRef = _db.collection('gameRooms').doc(roomId);
    
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) return;
      
      final data = snapshot.data() as Map<String, dynamic>;
      if (data['status'] == 'finished') return; // Match already finished

      transaction.update(roomRef, {
        'status': 'finished',
        'winnerId': winnerId,
        'forfeitWinnerId': winnerId,
      });
    });
  }

  /// Immediately forfeits the match for the user.
  Future<void> leaveMatch(String roomId, String userId, String opponentId) async {
    await _db.collection('gameRooms').doc(roomId).update({
      'status': 'finished',
      'winnerId': opponentId,
      'forfeitWinnerId': opponentId,
    });
  }

  /// Finds an active match for the given user that started recently (within 10 mins).
  Future<GameRoomModel?> findActiveMatch(String uid) async {
    final tenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 10));
    
    final query = await _db.collection('gameRooms')
        .where('status', whereIn: ['active', 'arena_breaker'])
        .where('createdAt', isGreaterThan: Timestamp.fromDate(tenMinutesAgo))
        .get();

    for (var doc in query.docs) {
      final data = doc.data();
      if (data['player1']['uid'] == uid || data['player2']?['uid'] == uid) {
        return GameRoomModel.fromJson(data);
      }
    }
    return null;
  }
}
