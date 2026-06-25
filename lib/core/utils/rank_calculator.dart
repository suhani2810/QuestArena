// WHAT THIS FILE DOES:
// Mathematical logic for Leveling and Ranking.

import 'dart:ui';
import '../constants/colors.dart';

import 'level_system.dart';

class RankCalculator {
  static String getRank(int xp) {
    if (xp >= 10000) return 'Diamond';
    if (xp >= 4000) return 'Platinum';
    if (xp >= 1500) return 'Gold';
    if (xp >= 500) return 'Silver';
    return 'Bronze';
  }

  static Color getRankColor(String rank) {
    switch (rank) {
      case 'Diamond': return AppColors.rankDiamond;
      case 'Platinum': return AppColors.rankPlatinum;
      case 'Gold': return AppColors.rankGold;
      case 'Silver': return AppColors.rankSilver;
      default: return AppColors.rankBronze;
    }
  }

  /// Returns the XP required to reach the next level from [currentLevel].
  /// Now delegates to the central [LevelSystem].
  static int getXpToNextLevel(int currentLevel) {
    return LevelSystem.xpForNextLevel(currentLevel);
  }
}
