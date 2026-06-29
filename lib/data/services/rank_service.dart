import '../models/user_model.dart';
import '../../core/utils/rank_system.dart';

class RankUpdateResult {
  final String oldRank;
  final int? oldSubRank;
  final int oldPoints;
  final String newRank;
  final int? newSubRank;
  final int newPoints;
  final int pointsGained;
  final bool promoted;
  final bool demoted;

  RankUpdateResult({
    required this.oldRank,
    this.oldSubRank,
    required this.oldPoints,
    required this.newRank,
    this.newSubRank,
    required this.newPoints,
    required this.pointsGained,
    this.promoted = false,
    this.demoted = false,
  });
}

class RankService {
  static RankUpdateResult calculateRankUpdate({
    required UserModel user,
    required int correctAnswers,
    required int wrongAnswers,
  }) {
    final int pointsGained = correctAnswers - wrongAnswers;
    
    // Legend has no progression
    if (user.rank == 'Legend') {
      return RankUpdateResult(
        oldRank: user.rank,
        oldSubRank: user.subRank,
        oldPoints: user.rankPoints,
        newRank: user.rank,
        newSubRank: user.subRank,
        newPoints: user.rankPoints,
        pointsGained: pointsGained,
      );
    }

    int currentPoints = user.rankPoints + pointsGained;
    String currentRank = user.rank;
    int? currentSubRank = user.subRank;
    bool promoted = false;
    bool demoted = false;

    // Handle Promotion
    while (currentPoints >= 100 && currentRank != 'Legend') {
      final next = RankSystem.promote(currentRank, currentSubRank);
      currentRank = next['rank'];
      currentSubRank = next['subRank'];
      currentPoints -= 100;
      promoted = true;
      if (currentRank == 'Legend') {
        currentPoints = 0;
        break;
      }
    }

    // Handle Demotion
    while (currentPoints < 0 && currentRank != 'Unranked') {
      final prev = RankSystem.demote(currentRank, currentSubRank);
      currentRank = prev['rank'];
      currentSubRank = prev['subRank'];
      currentPoints += 100;
      demoted = true;
    }

    // Prevent negative points for Unranked
    if (currentRank == 'Unranked' && currentPoints < 0) {
      currentPoints = 0;
    }

    return RankUpdateResult(
      oldRank: user.rank,
      oldSubRank: user.subRank,
      oldPoints: user.rankPoints,
      newRank: currentRank,
      newSubRank: currentSubRank,
      newPoints: currentPoints,
      pointsGained: pointsGained,
      promoted: promoted,
      demoted: demoted,
    );
  }
}
