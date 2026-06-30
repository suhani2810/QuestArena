// WHAT THIS FILE DOES:
// Defines the global color palette for QuestArena to ensure visual consistency.
//
// KEY CONCEPTS IN THIS FILE:
// • Static Constants: Using static const ensures these colors are compiled once and shared across the app.
// • Hexadecimal Colors: Standard Flutter way to define colors using ARGB (Alpha, Red, Green, Blue).

import 'package:flutter/material.dart';

class AppColors {
  // Prevent instantiation
  AppColors._();

  // Background Colors
  static const Color primaryBg = Color(0xFF0A0A0F);
  static const Color cardBg = Color(0xFF1A1A24);
  static const Color surface = Color(0xFF252533);

  // Accent Colors
  static const Color gold = Color(0xFFF5C842);
  static const Color purple = Color(0xFF7C5CFC);
  static const Color teal = Color(0xFF00D4B4);
  static const Color red = Color(0xFFFF4757);

  // Text Colors
  static const Color textPrimary = Color(0xFFE8E8F0);
  static const Color textSecondary = Color(0xFF8888A8);
  static const Color textMuted = Color(0xFF63637A);

  // Rank Colors
  static const Color rankBronze = Color(0xFFCD7F32);
  static const Color rankSilver = Color(0xFFC0C0C0);
  static const Color rankGold = Color(0xFFF5C842);
  static const Color rankPlatinum = Color(0xFFE5E4E2);
  static const Color rankDiamond = Color(0xFF00BFFF);
  static const Color rankMaster = Color(0xFF9D50BB);
  static const Color rankChampion = Color(0xFFE91E63);
}
