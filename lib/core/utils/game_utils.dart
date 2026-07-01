// WHAT THIS FILE DOES:
// Utility functions for game logic.

import 'dart:math';

class GameUtils {
  // Decodes common HTML entities from the Open Trivia Database
  static String decodeHtmlEntities(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&rsquo;', "'")
        .replaceAll('&lsquo;', "'")
        .replaceAll('&ldquo;', '"')
        .replaceAll('&rdquo;', '"')
        .replaceAll('&hellip;', '...')
        .replaceAll('&deg;', '°');
  }

  // Generates a random 6-character uppercase alphanumeric code
  static String generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Removed confusing chars like O, 0, I, 1
    return List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  // Emergency Fallback questions in case Cloud Function fails
  static List<Map<String, dynamic>> getFallbackQuestions() {
    final questions = [
      {
        'question': 'Which planet is known as the Red Planet?',
        'correct_answer': 'Mars',
        'incorrect_answers': ['Venus', 'Jupiter', 'Saturn'],
      },
      {
        'question': 'What is the capital of France?',
        'correct_answer': 'Paris',
        'incorrect_answers': ['London', 'Berlin', 'Madrid'],
      },
      {
        'question': 'Which is the largest ocean on Earth?',
        'correct_answer': 'Pacific Ocean',
        'incorrect_answers': ['Atlantic Ocean', 'Indian Ocean', 'Arctic Ocean'],
      },
      {
        'question': 'Who painted the Mona Lisa?',
        'correct_answer': 'Leonardo da Vinci',
        'incorrect_answers': ['Pablo Picasso', 'Vincent van Gogh', 'Claude Monet'],
      },
      {
        'question': 'What is the chemical symbol for gold?',
        'correct_answer': 'Au',
        'incorrect_answers': ['Ag', 'Fe', 'Cu'],
      },
      {
        'question': 'Which country is home to the kangaroo?',
        'correct_answer': 'Australia',
        'incorrect_answers': ['South Africa', 'Brazil', 'India'],
      },
      {
        'question': 'What is the hardest natural substance on Earth?',
        'correct_answer': 'Diamond',
        'incorrect_answers': ['Gold', 'Iron', 'Quartz'],
      },
      {
        'question': 'Which element has the atomic number 1?',
        'correct_answer': 'Hydrogen',
        'incorrect_answers': ['Helium', 'Oxygen', 'Carbon'],
      },
      {
        'question': 'What is the smallest prime number?',
        'correct_answer': '2',
        'incorrect_answers': ['1', '3', '5'],
      },
      {
        'question': 'In which year did the Titanic sink?',
        'correct_answer': '1912',
        'incorrect_answers': ['1905', '1920', '1915'],
      },
      {
        'question': 'Which language is used for Android development?',
        'correct_answer': 'Kotlin',
        'incorrect_answers': ['Swift', 'Ruby', 'PHP'],
      },
      {
        'question': 'What is the capital of Japan?',
        'correct_answer': 'Tokyo',
        'incorrect_answers': ['Kyoto', 'Osaka', 'Seoul'],
      },
    ];
    return (questions..shuffle()).toList();
  }
}
//A private code generated for the game... private room