class QuizCategory {
  final int? id;
  final String name;

  const QuizCategory({required this.id, required this.name});

  static const mixed = QuizCategory(id: null, name: 'Mixed / Random');

  static const all = <QuizCategory>[
    mixed,
    QuizCategory(id: 9, name: 'General Knowledge'),
    QuizCategory(id: 10, name: 'Books'),
    QuizCategory(id: 11, name: 'Film'),
    QuizCategory(id: 12, name: 'Music'),
    QuizCategory(id: 15, name: 'Video Games'),
    QuizCategory(id: 17, name: 'Science & Nature'),
    QuizCategory(id: 18, name: 'Computers'),
    QuizCategory(id: 19, name: 'Mathematics'),
    QuizCategory(id: 21, name: 'Sports'),
    QuizCategory(id: 22, name: 'Geography'),
    QuizCategory(id: 23, name: 'History'),
    QuizCategory(id: 27, name: 'Animals'),
  ];

  factory QuizCategory.fromId(int? id) {
    return all.firstWhere(
      (category) => category.id == id,
      orElse: () => mixed,
    );
  }
}
