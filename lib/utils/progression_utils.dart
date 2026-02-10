import 'dart:math';
import '../constants/progression.dart';

class ProgressionUtils {
  /// Calculates the XP required to grow from [level] to [level + 1]
  static int getXPRequiredForNextLevel(int level) {
    if (level >= ProgressionConstants.maxLevel) return 0;
    return (ProgressionConstants.baseXP * pow(level, ProgressionConstants.growthRate)).round();
  }

  /// Calculates the total cumulative XP required to reach a specific [level]
  static int getTotalXPForLevel(int level) {
    int total = 0;
    for (int i = 1; i < level; i++) {
      total += getXPRequiredForNextLevel(i);
    }
    return total;
  }

  /// Evaluates current level based on [totalXP]
  static int getLevelFromTotalXP(int totalXP) {
    int level = 1;
    while (level < ProgressionConstants.maxLevel) {
      int nextLevelXP = getTotalXPForLevel(level + 1);
      if (totalXP < nextLevelXP) break;
      level++;
    }
    return level;
  }

  /// Calculates progress (0.0 to 1.0) through the current level
  static double getLevelProgress(int totalXP) {
    int currentLevel = getLevelFromTotalXP(totalXP);
    if (currentLevel >= ProgressionConstants.maxLevel) return 1.0;

    int xpAtStartOfLevel = getTotalXPForLevel(currentLevel);
    int xpAtEndOfLevel = getTotalXPForLevel(currentLevel + 1);
    
    int xpInCurrentLevel = totalXP - xpAtStartOfLevel;
    int totalRequiredInLevel = xpAtEndOfLevel - xpAtStartOfLevel;
    
    return (xpInCurrentLevel / totalRequiredInLevel).clamp(0.0, 1.0);
  }
  
  /// Gets the XP remaining until next level
  static int getXPToNextLevel(int totalXP) {
    int currentLevel = getLevelFromTotalXP(totalXP);
    if (currentLevel >= ProgressionConstants.maxLevel) return 0;
    
    int xpAtEndOfLevel = getTotalXPForLevel(currentLevel + 1);
    return xpAtEndOfLevel - totalXP;
  }
}
