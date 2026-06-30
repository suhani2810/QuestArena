import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;
  final String email;
  final String? avatarUrl;
  final int level;
  final int xp;
  final int coins;
  final String rank;
  final int? subRank;
  final int rankPoints;
  final int wins;
  final int losses;
  final int draws;
  final int matchesPlayed;
  final int currentWinStreak;
  final int highestWinStreak;
  final DateTime? lastDailyBonusDate;
  final List<String> achievements;
  final int arenaBreakerWins;
  final int arenaBreakerLosses;
  final double averageAccuracy;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.level = 1,
    this.xp = 0,
    this.coins = 0,
    this.rank = 'Bronze',
    this.subRank,
    this.rankPoints = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.matchesPlayed = 0,
    this.currentWinStreak = 0,
    this.highestWinStreak = 0,
    this.lastDailyBonusDate,
    this.achievements = const [],
    this.arenaBreakerWins = 0,
    this.arenaBreakerLosses = 0,
    this.averageAccuracy = 0.0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'],
      level: json['level'] ?? 1,
      xp: json['xp'] ?? 0,
      coins: json['coins'] ?? 0,
      rank: json['rank'] ?? 'Bronze',
      subRank: json['subRank'],
      rankPoints: json['rankPoints'] ?? 0,
      wins: json['wins'] ?? json['totalWins'] ?? 0,
      losses: json['losses'] ?? json['totalLosses'] ?? 0,
      draws: json['draws'] ?? json['totalDraws'] ?? 0,
      matchesPlayed: json['matchesPlayed'] ?? 0,
      currentWinStreak: json['currentWinStreak'] ?? json['currentStreak'] ?? 0,
      highestWinStreak: json['highestWinStreak'] ?? 0,
      lastDailyBonusDate: json['lastDailyBonusDate'] != null
          ? (json['lastDailyBonusDate'] as Timestamp).toDate()
          : null,
      achievements: List<String>.from(json['achievements'] ?? []),
      arenaBreakerWins: json['arenaBreakerWins'] ?? 0,
      arenaBreakerLosses: json['arenaBreakerLosses'] ?? 0,
      averageAccuracy: (json['averageAccuracy'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'username': username,
        'email': email,
        'avatarUrl': avatarUrl,
        'level': level,
        'xp': xp,
        'coins': coins,
        'rank': rank,
        'subRank': subRank,
        'rankPoints': rankPoints,
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
        'arenaBreakerWins': arenaBreakerWins,
        'arenaBreakerLosses': arenaBreakerLosses,
        'averageAccuracy': averageAccuracy,
      };

  UserModel copyWith({
    String? username,
    String? avatarUrl,
    int? level,
    int? xp,
    int? coins,
    String? rank,
    int? subRank,
    int? rankPoints,
    int? wins,
    int? losses,
    int? draws,
    int? matchesPlayed,
    int? currentWinStreak,
    int? highestWinStreak,
    DateTime? lastDailyBonusDate,
    List<String>? achievements,
    int? arenaBreakerWins,
    int? arenaBreakerLosses,
    double? averageAccuracy,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      rank: rank ?? this.rank,
      subRank: subRank ?? this.subRank,
      rankPoints: rankPoints ?? this.rankPoints,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      currentWinStreak: currentWinStreak ?? this.currentWinStreak,
      highestWinStreak: highestWinStreak ?? this.highestWinStreak,
      lastDailyBonusDate: lastDailyBonusDate ?? this.lastDailyBonusDate,
      achievements: achievements ?? this.achievements,
      arenaBreakerWins: arenaBreakerWins ?? this.arenaBreakerWins,
      arenaBreakerLosses: arenaBreakerLosses ?? this.arenaBreakerLosses,
      averageAccuracy: averageAccuracy ?? this.averageAccuracy,
    );
  }
}
