import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/game_utils.dart';
import '../../../data/models/game_room_model.dart';
import '../../../providers/user_providers.dart';
import '../models/practice_models.dart';
import '../services/ai_bot_service.dart';

final practiceControllerProvider = StateNotifierProvider.family<PracticeController, GameRoomModel?, PracticeSession>((ref, session) {
  final dio = ref.watch(dioProvider);
  return PracticeController(dio, session, ref);
});

class PracticeController extends StateNotifier<GameRoomModel?> {
  final Dio _dio;
  final PracticeSession _session;
  final Ref _ref;
  final AIBotService _aiService = AIBotService();
  Timer? _aiTimer;

  PracticeController(this._dio, this._session, this._ref) : super(null) {
    _initMatch();
  }

  @override
  void dispose() {
    _aiTimer?.cancel();
    super.dispose();
  }

  Future<void> _initMatch() async {
    List<Map<String, dynamic>> questions = [];
    try {
      final response = await _dio.get(ApiConstants.triviaUrlForCategory(_session.category.id));
      questions = (response.data['results'] as List).map((q) => {
        'question': GameUtils.decodeHtmlEntities(q['question']),
        'correct_answer': GameUtils.decodeHtmlEntities(q['correct_answer']),
        'incorrect_answers': (q['incorrect_answers'] as List)
            .map((a) => GameUtils.decodeHtmlEntities(a))
            .toList(),
      }).toList();
    } catch (e) {
      questions = GameUtils.getFallbackQuestions();
    }

    final user = _ref.read(currentUserProvider).value;
    
    state = GameRoomModel(
      roomId: 'practice_${DateTime.now().millisecondsSinceEpoch}',
      status: 'active',
      player1: {
        'uid': user?.uid ?? 'local_user',
        'username': user?.username ?? 'Player',
        'avatarUrl': user?.avatarUrl,
        'score': 0,
        'answers': [],
      },
      player2: {
        'uid': 'bot_id',
        'username': _session.bot.name,
        'avatarUrl': _session.bot.avatarUrl,
        'score': 0,
        'answers': [],
        'isBot': true,
      },
      questions: questions,
      currentQuestionIndex: 0,
      questionStartedAt: DateTime.now(),
      categoryName: _session.category.name,
    );

    _startAIRound();
  }

  void _startAIRound() {
    _aiTimer?.cancel();
    
    final currentRoom = state;
    if (currentRoom == null || currentRoom.status == 'finished') return;

    // Simulate AI answer
    _aiService.simulateAnswer(_session.difficulty).then((result) {
      if (!mounted || state == null || state!.status == 'finished') return;
      
      final isCorrect = result['isCorrect'] as bool;
      final delayMs = result['delayMs'] as int;
      
      // Calculate bot score
      final remainingMs = 15000 - delayMs;
      int score = 0;
      if (isCorrect && remainingMs > 0) {
        score = 10 + (remainingMs / 3000).floor();
      }

      final question = state!.questions[state!.currentQuestionIndex];
      final answer = isCorrect ? question['correct_answer'] : (question['incorrect_answers'] as List).first;

      submitAnswer('bot_id', answer, score);
    });
  }

  void submitAnswer(String userId, String answer, int score) {
    final currentRoom = state;
    if (currentRoom == null || currentRoom.status == 'finished') return;

    final isP1 = userId == currentRoom.player1['uid'];
    
    final playerMap = Map<String, dynamic>.from(isP1 ? currentRoom.player1 : currentRoom.player2!);
    final currentAnswers = List<String>.from(playerMap['answers'] ?? []);
    
    if (currentAnswers.length > currentRoom.currentQuestionIndex) return;

    while (currentAnswers.length < currentRoom.currentQuestionIndex) {
      currentAnswers.add('TIMEOUT');
    }
    currentAnswers.add(answer);

    playerMap['answers'] = currentAnswers;
    playerMap['score'] = (playerMap['score'] ?? 0) + score;

    if (isP1) {
      state = currentRoom.copyWith(player1: playerMap);
    } else {
      state = currentRoom.copyWith(player2: playerMap);
    }
    
    _checkProgression();
  }

  void _checkProgression() {
    final room = state!;
    final p1Len = (room.player1['answers'] as List).length;
    final p2Len = (room.player2?['answers'] as List).length;
    final currentIdx = room.currentQuestionIndex;

    if (p1Len > currentIdx && p2Len > currentIdx) {
      if (currentIdx + 1 < room.questions.length) {
        state = room.copyWith(
          currentQuestionIndex: currentIdx + 1,
          questionStartedAt: DateTime.now(),
        );
        _startAIRound();
      } else {
        _finishMatch();
      }
    }
  }

  void _finishMatch() {
    final room = state!;
    final p1Score = room.player1['score'] ?? 0;
    final p2Score = room.player2?['score'] ?? 0;

    if (p1Score == p2Score) {
      _triggerArenaBreaker();
    } else {
      state = room.copyWith(
        status: 'finished',
        winnerId: p1Score > p2Score ? room.player1['uid'] : room.player2?['uid'],
      );
    }
  }

  Future<void> _triggerArenaBreaker() async {
    List<Map<String, dynamic>> abQuestions = [];
    try {
      final response = await _dio.get(ApiConstants.triviaUrlForCategory(null, amount: 1));
      abQuestions = (response.data['results'] as List).map((q) => {
        'question': GameUtils.decodeHtmlEntities(q['question']),
        'correct_answer': GameUtils.decodeHtmlEntities(q['correct_answer']),
        'incorrect_answers': (q['incorrect_answers'] as List)
            .map((a) => GameUtils.decodeHtmlEntities(a))
            .toList(),
      }).toList();
    } catch (e) {
      abQuestions = [GameUtils.getFallbackQuestions().first];
    }

    state = state!.copyWith(
      status: 'arena_breaker',
      isArenaBreaker: true,
      arenaBreakerQuestion: abQuestions.first,
      arenaBreakerSubmissions: {},
      questionStartedAt: DateTime.now(),
    );

    _startABAIRound();
  }

  void _startABAIRound() {
    _aiService.simulateAnswer(_session.difficulty).then((result) {
      if (!mounted || state == null || state!.status != 'arena_breaker') return;
      
      final isCorrect = result['isCorrect'] as bool;
      final question = state!.arenaBreakerQuestion!;
      final answer = isCorrect ? question['correct_answer'] : (question['incorrect_answers'] as List).first;

      submitArenaBreakerAnswer('bot_id', answer);
    });
  }

  void submitArenaBreakerAnswer(String userId, String answer) {
    final room = state;
    if (room == null || room.status != 'arena_breaker') return;

    final question = room.arenaBreakerQuestion!;
    final isCorrect = answer == question['correct_answer'];
    final submissions = Map<String, dynamic>.from(room.arenaBreakerSubmissions);
    
    if (submissions.containsKey(userId)) return;

    submissions[userId] = {
      'answer': answer,
      'isCorrect': isCorrect,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    state = room.copyWith(arenaBreakerSubmissions: submissions);

    if (submissions.length == 2 || isCorrect) {
      final s1 = submissions[room.player1['uid']];
      final s2 = submissions['bot_id'];

      String? winnerId;
      if (s1 != null && s1['isCorrect'] && (s2 == null || !s2['isCorrect'])) {
        winnerId = room.player1['uid'];
      } else if (s2 != null && s2['isCorrect'] && (s1 == null || !s1['isCorrect'])) {
        winnerId = 'bot_id';
      } else if (s1 != null && s2 != null && s1['isCorrect'] && s2['isCorrect']) {
        winnerId = (s1['timestamp'] < s2['timestamp']) ? room.player1['uid'] : 'bot_id';
      } else if (submissions.length == 2) {
        _triggerArenaBreaker();
        return;
      }

      if (winnerId != null) {
        state = state!.copyWith(
          status: 'finished',
          winnerId: winnerId,
          isArenaBreakerWin: true,
        );
      }
    }
  }

  void forceAdvance() {
    final user = _ref.read(currentUserProvider).value;
    if (user != null) {
      submitAnswer(user.uid, 'TIMEOUT', 0);
    }
  }
}
