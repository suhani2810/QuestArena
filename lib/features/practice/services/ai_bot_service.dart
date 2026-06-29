import 'dart:math';
import '../models/practice_models.dart';

class AIBotService {
  final Random _random = Random();

  /// Simulates an AI decision. Returns true if correct, and the duration in ms.
  Future<Map<String, dynamic>> simulateAnswer(PracticeDifficulty difficulty) async {
    double correctProbability;
    int minDelay;
    int maxDelay;

    switch (difficulty) {
      case PracticeDifficulty.easy:
        correctProbability = 0.45;
        minDelay = 8000;
        maxDelay = 14000;
        break;
      case PracticeDifficulty.medium:
        correctProbability = 0.70;
        minDelay = 4000;
        maxDelay = 9000;
        break;
      case PracticeDifficulty.hard:
        correctProbability = 0.90;
        minDelay = 1000;
        maxDelay = 5000;
        break;
    }

    final delay = minDelay + _random.nextInt(maxDelay - minDelay);
    final isCorrect = _random.nextDouble() < correctProbability;

    await Future.delayed(Duration(milliseconds: delay));

    return {
      'isCorrect': isCorrect,
      'delayMs': delay,
    };
  }
}
