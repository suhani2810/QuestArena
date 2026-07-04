import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum MatchResult { win, loss, draw }

class MatchModel {
  final String id;
  final String opponentName;
  final String? opponentAvatarUrl;
  final int playerScore;
  final int opponentScore;
  final int xpEarned;
  final int rpChange;
  final String matchType;
  final String categoryName;
  final int durationSeconds;
  final DateTime timestamp;

  MatchModel({
    required this.id,
    required this.opponentName,
    this.opponentAvatarUrl,
    required this.playerScore,
    required this.opponentScore,
    required this.xpEarned,
    required this.rpChange,
    required this.matchType,
    required this.categoryName,
    required this.durationSeconds,
    required this.timestamp,
  });

  MatchResult get result {
    if (playerScore > opponentScore) return MatchResult.win;
    if (playerScore < opponentScore) return MatchResult.loss;
    return MatchResult.draw;
  }

  String get matchTypeLabel {
    switch (matchType.toLowerCase()) {
      case 'ranked':
        return 'Ranked';
      case 'private_duel':
      case 'private duel':
      case 'private':
        return 'Private Duel';
      case 'practice':
        return 'Practice';
      default:
        return 'Ranked';
    }
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
        } else if (val is Timestamp) {
          parsedDate = val.toDate();
        }
      }
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }

    return MatchModel(
      id: json['matchId'] ?? json['id'] ?? '',
      opponentName: json['opponentName'] ?? 'Unknown',
      opponentAvatarUrl: json['opponentAvatarUrl'] ?? json['opponentAvatar'] ?? json['avatarUrl'],
      playerScore: json['myScore'] ?? json['playerScore'] ?? 0,
      opponentScore: json['opponentScore'] ?? 0,
      xpEarned: json['xpGained'] ?? json['xpEarned'] ?? 0,
      rpChange: json['rpChange'] ?? 0,
      matchType: json['matchType'] ?? 'ranked',
      categoryName: json['categoryName'] ?? 'General Knowledge',
      durationSeconds: json['durationSeconds'] ?? 0,
      timestamp: parsedDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'opponentName': opponentName,
    'opponentAvatarUrl': opponentAvatarUrl,
    'playerScore': playerScore,
    'opponentScore': opponentScore,
    'xpEarned': xpEarned,
    'rpChange': rpChange,
    'matchType': matchType,
    'categoryName': categoryName,
    'durationSeconds': durationSeconds,
    'timestamp': timestamp,
    // Keep legacy fields for Firestore compatibility if needed
    'matchId': id,
    'myScore': playerScore,
    'xpGained': xpEarned,
    'playedAt': timestamp,
  };
}
