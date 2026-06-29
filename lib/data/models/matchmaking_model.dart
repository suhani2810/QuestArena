// WHAT THIS FILE DOES:
// Represents a player waiting in the queue to find an opponent.

import 'package:cloud_firestore/cloud_firestore.dart';

class MatchmakingModel {
  final String uid;
  final String username;
  final String? avatarUrl;
  final String rank;
  final String status;
  final String? matchedWith;
  final String? gameRoomId;
  final int? categoryId;
  final String categoryName;
  final DateTime searchStartedAt;
  final DateTime? lastSeen;

  MatchmakingModel({
    required this.uid,
    required this.username,
    this.avatarUrl,
    required this.rank,
    this.status = 'searching',
    this.matchedWith,
    this.gameRoomId,
    this.categoryId,
    this.categoryName = 'Mixed / Random',
    required this.searchStartedAt,
    this.lastSeen,
  });

  factory MatchmakingModel.fromJson(Map<String, dynamic> json) {
    return MatchmakingModel(
      uid: json['uid'] ?? '',
      username: json['username'] ?? '',
      avatarUrl: json['avatarUrl'],
      rank: json['rank'] ?? 'Bronze',
      status: json['status'] ?? 'searching',
      matchedWith: json['matchedWith'],
      gameRoomId: json['gameRoomId'],
      categoryId: json['categoryId'],
      categoryName: json['categoryName'] ?? 'Mixed / Random',
      searchStartedAt: json['searchStartedAt'] != null 
          ? (json['searchStartedAt'] is Timestamp 
              ? (json['searchStartedAt'] as Timestamp).toDate() 
              : DateTime.parse(json['searchStartedAt'].toString()))
          : DateTime.now(),
      lastSeen: json['lastSeen'] != null 
          ? (json['lastSeen'] is Timestamp 
              ? (json['lastSeen'] as Timestamp).toDate() 
              : DateTime.parse(json['lastSeen']))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'username': username,
    'avatarUrl': avatarUrl,
    'rank': rank,
    'status': status,
    'matchedWith': matchedWith,
    'gameRoomId': gameRoomId,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'searchStartedAt': searchStartedAt.toIso8601String(),
    'lastSeen': lastSeen?.toIso8601String(),
  };
}
