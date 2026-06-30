// WHAT THIS FILE DOES:
// A lightweight model for showing players in the global rankings.

class LeaderboardModel {
  final String uid;
  final String username;
  final String? avatarUrl;
  final int level;
  final int xp;
  final String rank;
  final int? subRank;

  LeaderboardModel({
    required this.uid,
    required this.username,
    this.avatarUrl,
    required this.level,
    required this.xp,
    required this.rank,
    this.subRank,
  });

  factory LeaderboardModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardModel(
      uid: json['uid'] ?? '',
      username: json['username'] ?? '',
      avatarUrl: json['avatarUrl'],
      level: json['level'] ?? 1,
      xp: json['xp'] ?? 0,
      rank: json['rank'] ?? 'Unranked',
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
    'subRank': subRank,
  };
}
