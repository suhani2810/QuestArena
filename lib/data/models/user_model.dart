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
  final List<String> achievements;
  final Map<String, int> powerUps;

  // Coin & Streak System Fields
  final int todayCoinsEarned;
  final DateTime lastCoinResetDate;
  final DateTime lastDailyLoginRewardDate;
  final int loginStreak;
  final DateTime lastLoginDate;
  final String? lastRewardedMatchId;
  final String? lastLeagueRewardClaimed; // e.g., 'Gold_Season_1'

  // Additional stats
  final int arenaBreakerWins;
  final int arenaBreakerLosses;
  final double averageAccuracy;
  final int oneOptionLifelines;
  final int twoOptionLifelines;
  final int rankProtectionMatches;
  final DateTime? lastDailyBonusDate;

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
    this.achievements = const [],
    this.powerUps = const {'fiftyFifty': 5, 'timeFreeze': 5},
    this.todayCoinsEarned = 0,
    DateTime? lastCoinResetDate,
    DateTime? lastDailyLoginRewardDate,
    this.loginStreak = 0,
    DateTime? lastLoginDate,
    this.lastRewardedMatchId,
    this.lastLeagueRewardClaimed,
    this.arenaBreakerWins = 0,
    this.arenaBreakerLosses = 0,
    this.averageAccuracy = 0.0,
    this.oneOptionLifelines = 0,
    this.twoOptionLifelines = 0,
    this.rankProtectionMatches = 0,
    this.lastDailyBonusDate,
  })  : lastCoinResetDate = lastCoinResetDate ?? DateTime(2000),
        lastDailyLoginRewardDate = lastDailyLoginRewardDate ?? DateTime(2000),
        lastLoginDate = lastLoginDate ?? DateTime(2000);

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
      achievements: List<String>.from(json['achievements'] ?? []),
      powerUps: Map<String, int>.from(json['powerUps'] ?? {'fiftyFifty': 5, 'timeFreeze': 5}),
      todayCoinsEarned: json['todayCoinsEarned'] ?? 0,
      lastCoinResetDate: json['lastCoinResetDate'] != null
          ? (json['lastCoinResetDate'] as Timestamp).toDate()
          : DateTime(2000),
      lastDailyLoginRewardDate: json['lastDailyLoginRewardDate'] != null
          ? (json['lastDailyLoginRewardDate'] as Timestamp).toDate()
          : DateTime(2000),
      loginStreak: json['loginStreak'] ?? 0,
      lastLoginDate: json['lastLoginDate'] != null
          ? (json['lastLoginDate'] as Timestamp).toDate()
          : DateTime(2000),
      lastRewardedMatchId: json['lastRewardedMatchId'],
      lastLeagueRewardClaimed: json['lastLeagueRewardClaimed'],
      arenaBreakerWins: json['arenaBreakerWins'] ?? 0,
      arenaBreakerLosses: json['arenaBreakerLosses'] ?? 0,
      averageAccuracy: (json['averageAccuracy'] ?? 0.0).toDouble(),
      oneOptionLifelines: json['oneOptionLifelines'] ?? 0,
      twoOptionLifelines: json['twoOptionLifelines'] ?? 0,
      rankProtectionMatches: json['rankProtectionMatches'] ?? 0,
      lastDailyBonusDate: json['lastDailyBonusDate'] != null
          ? (json['lastDailyBonusDate'] as Timestamp).toDate()
          : null,
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
        'achievements': achievements,
        'powerUps': powerUps,
        'todayCoinsEarned': todayCoinsEarned,
        'lastCoinResetDate': lastCoinResetDate,
        'lastDailyLoginRewardDate': lastDailyLoginRewardDate,
        'loginStreak': loginStreak,
        'lastLoginDate': lastLoginDate,
        'lastRewardedMatchId': lastRewardedMatchId,
        'lastLeagueRewardClaimed': lastLeagueRewardClaimed,
        'arenaBreakerWins': arenaBreakerWins,
        'arenaBreakerLosses': arenaBreakerLosses,
        'averageAccuracy': averageAccuracy,
        'oneOptionLifelines': oneOptionLifelines,
        'twoOptionLifelines': twoOptionLifelines,
        'rankProtectionMatches': rankProtectionMatches,
        'lastDailyBonusDate': lastDailyBonusDate != null ? Timestamp.fromDate(lastDailyBonusDate!) : null,
      };

  UserModel copyWith({
    String? username,
    String? avatarUrl,
    int? level,
    int? xp,
    int? coins,
    int? todayCoinsEarned,
    DateTime? lastCoinResetDate,
    DateTime? lastDailyLoginRewardDate,
    int? loginStreak,
    DateTime? lastLoginDate,
    int? currentWinStreak,
    int? highestWinStreak,
    String? lastRewardedMatchId,
    String? lastLeagueRewardClaimed,
    String? rank,
    int? subRank,
    int? rankPoints,
    int? wins,
    int? losses,
    int? draws,
    int? matchesPlayed,
    DateTime? lastDailyBonusDate,
    List<String>? achievements,
    Map<String, int>? powerUps,
    int? arenaBreakerWins,
    int? arenaBreakerLosses,
    double? averageAccuracy,
    int? oneOptionLifelines,
    int? twoOptionLifelines,
    int? rankProtectionMatches,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      todayCoinsEarned: todayCoinsEarned ?? this.todayCoinsEarned,
      lastCoinResetDate: lastCoinResetDate ?? this.lastCoinResetDate,
      lastDailyLoginRewardDate: lastDailyLoginRewardDate ?? this.lastDailyLoginRewardDate,
      loginStreak: loginStreak ?? this.loginStreak,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      currentWinStreak: currentWinStreak ?? this.currentWinStreak,
      highestWinStreak: highestWinStreak ?? this.highestWinStreak,
      lastRewardedMatchId: lastRewardedMatchId ?? this.lastRewardedMatchId,
      lastLeagueRewardClaimed: lastLeagueRewardClaimed ?? this.lastLeagueRewardClaimed,
      rank: rank ?? this.rank,
      subRank: subRank ?? this.subRank,
      rankPoints: rankPoints ?? this.rankPoints,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      lastDailyBonusDate: lastDailyBonusDate ?? this.lastDailyBonusDate,
      achievements: achievements ?? this.achievements,
      powerUps: powerUps ?? this.powerUps,
      arenaBreakerWins: arenaBreakerWins ?? this.arenaBreakerWins,
      arenaBreakerLosses: arenaBreakerLosses ?? this.arenaBreakerLosses,
      averageAccuracy: averageAccuracy ?? this.averageAccuracy,
      oneOptionLifelines: oneOptionLifelines ?? this.oneOptionLifelines,
      twoOptionLifelines: twoOptionLifelines ?? this.twoOptionLifelines,
      rankProtectionMatches: rankProtectionMatches ?? this.rankProtectionMatches,
    );
  }
}
