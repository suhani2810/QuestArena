// WHAT THIS FILE DOES:
// Represents the Player's profile data.
//
// KEY CONCEPTS IN THIS FILE:
// • Data Modeling: Translating a JSON/Firestore document into a safe Dart object.
// • Immutability: Using 'final' ensures that once a user object is created, it cannot be accidentally changed.

class UserModel {
  final String uid;
  final String username;
  final String email;
  final String? avatarUrl;
  final int level;
  final int xp;
  final int xpToNextLevel;
  final int coins;
  final int totalWins;
  final int totalLosses;
  final int totalDraws;
  final int currentStreak;
  final double averageAccuracy;
  final String rank;
  final List<String> achievements;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.level = 1,
    this.xp = 0,
    this.xpToNextLevel = 100,
    this.coins = 0,
    this.totalWins = 0,
    this.totalLosses = 0,
    this.totalDraws = 0,
    this.currentStreak = 0,
    this.averageAccuracy = 0.0,
    this.rank = 'Bronze',
    this.achievements = const [],
  });

  // Manual JSON conversion for Day 1 (to avoid code-gen errors)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'],
      level: json['level'] ?? 1,
      xp: json['xp'] ?? 0,
      xpToNextLevel: json['xpToNextLevel'] ?? 100,
      coins: json['coins'] ?? 0,
      totalWins: json['totalWins'] ?? 0,
      totalLosses: json['totalLosses'] ?? 0,
      totalDraws: json['totalDraws'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      averageAccuracy: (json['averageAccuracy'] ?? 0).toDouble(),
      rank: json['rank'] ?? 'Bronze',
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
        'xpToNextLevel': xpToNextLevel,
        'coins': coins,
        'totalWins': totalWins,
        'totalLosses': totalLosses,
        'totalDraws': totalDraws,
        'currentStreak': currentStreak,
        'averageAccuracy': averageAccuracy,
        'rank': rank,
        'achievements': achievements,
      };

  UserModel copyWith({
    String? username,
    String? avatarUrl,
    int? xp,
    int? coins,
    String? rank,
    int? totalWins,
    int? totalLosses,
    int? totalDraws,
    int? currentStreak,
    double? averageAccuracy,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      rank: rank ?? this.rank,
      level: level,
      totalWins: totalWins ?? this.totalWins,
      totalLosses: totalLosses ?? this.totalLosses,
      totalDraws: totalDraws ?? this.totalDraws,
      currentStreak: currentStreak ?? this.currentStreak,
      averageAccuracy: averageAccuracy ?? this.averageAccuracy,
      achievements: achievements,
    );
  }
}
