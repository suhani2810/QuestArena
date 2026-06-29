import '../../../core/models/quiz_category.dart';

enum PracticeDifficulty {
  easy,
  medium,
  hard;

  String get label {
    switch (this) {
      case PracticeDifficulty.easy: return 'Easy';
      case PracticeDifficulty.medium: return 'Medium';
      case PracticeDifficulty.hard: return 'Hard';
    }
  }
}

class PracticeSession {
  final QuizCategory category;
  final PracticeDifficulty difficulty;
  final BotProfile bot;

  PracticeSession({
    required this.category,
    required this.difficulty,
    required this.bot,
  });
}

class BotProfile {
  final String name;
  final String avatarUrl;

  BotProfile({required this.name, required this.avatarUrl});

  static BotProfile random() {
    final names = ['BrainBot', 'QuizMaster', 'LogicKing', 'AlphaAI', 'SmartBot'];
    final name = names[DateTime.now().millisecondsSinceEpoch % names.length];
    // Reusing a known avatar URL style or placeholder
    final avatarId = DateTime.now().millisecondsSinceEpoch % 100;
    return BotProfile(
      name: name,
      avatarUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=$avatarId',
    );
  }
}
