class LevelSystem {
  /// Returns the XP required to go from level [level] to [level + 1].
  static int xpForNextLevel(int currentLevel) {
    final targetLevel = currentLevel + 1;
    if (currentLevel == 1) {
      return 30;
    } else if (targetLevel <= 201) {
      return 50 * (targetLevel - 1);
    } else if (targetLevel <= 300) {
      return 500 * (targetLevel - 200) + 9500;
    } else {
      return 1000 * (targetLevel - 300) + 60000;
    }
  }

  /// Calculates the current level based on total cumulative XP.
  static int getCurrentLevel(int totalXp) {
    int level = 1;
    int remainingXp = totalXp;
    while (true) {
      int needed = xpForNextLevel(level);
      if (remainingXp >= needed) {
        remainingXp -= needed;
        level++;
      } else {
        break;
      }
    }
    return level;
  }

  /// Returns the cumulative XP required to reach the start of [level].
  static int totalXpToReachLevel(int level) {
    int total = 0;
    for (int i = 1; i < level; i++) {
      total += xpForNextLevel(i);
    }
    return total;
  }

  /// Returns progress within the current level (0.0 to 1.0).
  static double getProgress(int totalXp) {
    final level = getCurrentLevel(totalXp);
    final currentLevelStartTotalXp = totalXpToReachLevel(level);
    final xpInLevel = totalXp - currentLevelStartTotalXp;
    final xpNeededForNext = xpForNextLevel(level);
    return (xpInLevel / xpNeededForNext).clamp(0.0, 1.0);
  }

  /// Returns how much XP has been earned since the start of the current level.
  static int getXpInCurrentLevel(int totalXp) {
    final level = getCurrentLevel(totalXp);
    return totalXp - totalXpToReachLevel(level);
  }
}
