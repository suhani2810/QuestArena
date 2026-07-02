import '../services/xp_service.dart';
import '../services/rank_service.dart';

class MatchEndResult {
  final XpRewardBreakdown xpRewards;
  final RankUpdateResult rankUpdate;
  final bool rankProtectionUsed;

  MatchEndResult({
    required this.xpRewards,
    required this.rankUpdate,
    this.rankProtectionUsed = false,
  });
}
