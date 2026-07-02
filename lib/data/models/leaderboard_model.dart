// WHAT THIS FILE DOES:
// A lightweight model for showing players in the global rankings.

class LeaderboardModel {
  final String uid;
  final String username;
  final String? avatarUrl;
  final int level;
  final int xp;
  final String rank;
  final int totalWins;
  final int currentStreak;
  final double averageAccuracy;
  final int? subRank;

  LeaderboardModel({
    required this.uid,
    required this.username,
    this.avatarUrl,
    required this.level,
    required this.xp,
    required this.rank,
    this.totalWins = 0,
    this.currentStreak = 0,
    this.averageAccuracy = 0.0,
    this.subRank,
  });

  double get mvpScore => (xp / 10) + (totalWins * 10) + (averageAccuracy * 2) + (currentStreak * 5);

  factory LeaderboardModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardModel(
      uid: json['uid'] ?? '',
      username: json['username'] ?? '',
      avatarUrl: json['avatarUrl'],
      level: json['level'] ?? 1,
      xp: json['xp'] ?? 0,
      rank: json['rank'] ?? 'Bronze',
      totalWins: json['totalWins'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      averageAccuracy: (json['averageAccuracy'] ?? 0).toDouble(),
      subRank: json['subRank'],
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'username': username,
    'avatarUrl': avatarUrl,
    'level': level,
    'xp': xp,
    'rank': rank,
    'totalWins': totalWins,
    'currentStreak': currentStreak,
    'averageAccuracy': averageAccuracy,
    'subRank': subRank,
  };
}
