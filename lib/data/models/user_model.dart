// WHAT THIS FILE DOES:
// Represents the Player's profile data.
//
// KEY CONCEPTS IN THIS FILE:
// • Data Modeling: Translating a JSON/Firestore document into a safe Dart object.
// • Immutability: Using 'final' ensures that once a user object is created, it cannot be accidentally changed.

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;
  final String email;
  final String? avatarUrl;
  final int level;
  final int xp;
  final String rank;
  final int? subRank;
  final int rankPoints;
  final int coins;
  final int wins;
  final int losses;
  final int draws;
  final int matchesPlayed;
  final int currentWinStreak;
  final int highestWinStreak;
  final DateTime? lastDailyBonusDate;
  final List<String> achievements;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.level = 1,
    this.xp = 0,
    this.rank = 'Unranked',
    this.subRank,
    this.rankPoints = 0,
    this.coins = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.matchesPlayed = 0,
    this.currentWinStreak = 0,
    this.highestWinStreak = 0,
    this.lastDailyBonusDate,
    this.achievements = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rank = json['rank'] ?? 'Unranked';
    int? subRank = json['subRank'];

    // Migration logic: If the user has a rank but no subRank, default to 3
    if (subRank == null && rank != 'Unranked' && rank != 'Legend') {
      subRank = 3;
    }

    return UserModel(
      uid: json['uid'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'],
      level: json['level'] ?? 1,
      xp: json['xp'] ?? 0,
      rank: rank,
      subRank: subRank,
      rankPoints: json['rankPoints'] ?? 0,
      coins: json['coins'] ?? 0,
      wins: json['wins'] ?? json['totalWins'] ?? 0,
      losses: json['losses'] ?? json['totalLosses'] ?? 0,
      draws: json['draws'] ?? 0,
      matchesPlayed: json['matchesPlayed'] ?? 0,
      currentWinStreak: json['currentWinStreak'] ?? 0,
      highestWinStreak: json['highestWinStreak'] ?? 0,
      lastDailyBonusDate: json['lastDailyBonusDate'] != null
          ? (json['lastDailyBonusDate'] as Timestamp).toDate()
          : null,
      achievements: List<String>.from(json['achievements'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'username': username,
        'email': email,
        'avatarUrl': avatarUrl,
        'level': level,
        'xp': xp,
        'rank': rank,
        'subRank': subRank,
        'rankPoints': rankPoints,
        'coins': coins,
        'wins': wins,
        'losses': losses,
        'draws': draws,
        'matchesPlayed': matchesPlayed,
        'currentWinStreak': currentWinStreak,
        'highestWinStreak': highestWinStreak,
        'lastDailyBonusDate': lastDailyBonusDate != null
            ? Timestamp.fromDate(lastDailyBonusDate!)
            : null,
        'achievements': achievements,
      };

  UserModel copyWith({
    String? username,
    String? avatarUrl,
    int? xp,
    int? level,
    String? rank,
    int? subRank,
    int? rankPoints,
    int? coins,
    int? wins,
    int? losses,
    int? draws,
    int? matchesPlayed,
    int? currentWinStreak,
    int? highestWinStreak,
    DateTime? lastDailyBonusDate,
    List<String>? achievements,
    bool clearSubRank = false,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      rank: rank ?? this.rank,
      subRank: clearSubRank ? null : (subRank ?? this.subRank),
      rankPoints: rankPoints ?? this.rankPoints,
      coins: coins ?? this.coins,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      currentWinStreak: currentWinStreak ?? this.currentWinStreak,
      highestWinStreak: highestWinStreak ?? this.highestWinStreak,
      lastDailyBonusDate: lastDailyBonusDate ?? this.lastDailyBonusDate,
      achievements: achievements ?? this.achievements,
    );
  }
}
