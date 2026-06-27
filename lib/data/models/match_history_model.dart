import 'package:flutter/foundation.dart';

enum MatchResult { win, loss, draw }

class MatchModel {
  final String id;
  final String opponentName;
  final int playerScore;
  final int opponentScore;
  final int xpEarned;
  final DateTime timestamp;

  MatchModel({
    required this.id,
    required this.opponentName,
    required this.playerScore,
    required this.opponentScore,
    required this.xpEarned,
    required this.timestamp,
  });

  MatchResult get result {
    if (playerScore > opponentScore) return MatchResult.win;
    if (playerScore < opponentScore) return MatchResult.loss;
    return MatchResult.draw;
  }

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate = DateTime.now();
    try {
      if (json['playedAt'] != null || json['timestamp'] != null) {
        final val = json['playedAt'] ?? json['timestamp'];
        if (val is DateTime) {
          parsedDate = val;
        } else if (val is String) {
          parsedDate = DateTime.parse(val);
        } else {
          parsedDate = (val as dynamic).toDate();
        }
      }
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }

    return MatchModel(
      id: json['matchId'] ?? json['id'] ?? '',
      opponentName: json['opponentName'] ?? 'Unknown',
      playerScore: json['myScore'] ?? json['playerScore'] ?? 0,
      opponentScore: json['opponentScore'] ?? 0,
      xpEarned: json['xpGained'] ?? json['xpEarned'] ?? 0,
      timestamp: parsedDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'opponentName': opponentName,
    'playerScore': playerScore,
    'opponentScore': opponentScore,
    'xpEarned': xpEarned,
    'timestamp': timestamp,
    // Keep legacy fields for Firestore compatibility if needed
    'matchId': id,
    'myScore': playerScore,
    'xpGained': xpEarned,
    'playedAt': timestamp,
  };
}
