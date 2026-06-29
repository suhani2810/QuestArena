import 'package:flutter/material.dart';

// ─── QuestArena Dark Arena Theme ───────────────────────────────────────────
// Inspired by: Blade Runner 2049, TRON Legacy, Star Wars, Alita Battle Angel
// Palette: near-black backgrounds, cyan/violet neon accents, amber gold for XP

class AppColors {
  // Backgrounds — layered depth like TRON grid darkness
  static const Color bgDeep       = Color(0xFF0A0A0F);  // deepest void
  static const Color bgBase       = Color(0xFF0F0F18);  // main scaffold bg
  static const Color bgCard       = Color(0xFF161625);  // card surface
  static const Color bgCardHover  = Color(0xFF1E1E30);  // card on press/hover
  static const Color bgInputField = Color(0xFF12121E);  // input fields

  // Neon accents — Blade Runner / TRON energy
  static const Color neonCyan     = Color(0xFF00E5FF);  // primary neon (TRON blue)
  static const Color neonViolet   = Color(0xFF7C4DFF);  // secondary (Blade Runner purple)
  static const Color neonPink     = Color(0xFFFF006E);  // danger / loss
  static const Color neonAmber    = Color(0xFFFFAB00);  // XP gold / ranked

  // Glow variants (same hue, lower opacity — for BoxShadow)
  static const Color glowCyan     = Color(0x4000E5FF);
  static const Color glowViolet   = Color(0x407C4DFF);
  static const Color glowAmber    = Color(0x40FFAB00);
  static const Color glowPink     = Color(0x40FF006E);

  // Text hierarchy
  static const Color textPrimary   = Color(0xFFE8E8F0);
  static const Color textSecondary = Color(0xFF8888AA);
  static const Color textMuted     = Color(0xFF44445A);

  // Rank tier colors
  static const Color rankBronze   = Color(0xFFCD7F32);
  static const Color rankSilver   = Color(0xFFC0C0C0);
  static const Color rankGold     = Color(0xFFFFD700);
  static const Color rankPlatinum = Color(0xFF00E5FF);

  // Divider
  static const Color divider = Color(0xFF1E1E30);
}

class AppTheme {
  static ThemeData get darkArena => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgBase,
    fontFamily: 'Rajdhani', // fallback to default if not added
    colorScheme: const ColorScheme.dark(
      primary:   AppColors.neonCyan,
      secondary: AppColors.neonViolet,
      surface:   AppColors.bgCard,
      error:     AppColors.neonPink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgBase,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: 3.0,
      ),
      iconTheme: IconThemeData(color: AppColors.neonCyan),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.bgCard,
      indicatorColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final active = states.contains(WidgetState.selected);
        return TextStyle(
          color: active ? AppColors.neonCyan : AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final active = states.contains(WidgetState.selected);
        return IconThemeData(
          color: active ? AppColors.neonCyan : AppColors.textMuted,
          size: 22,
        );
      }),
    ),
    cardTheme: CardThemeData(
      color: AppColors.bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF1E1E30), width: 0.5),
      ),
    ),
    dividerColor: AppColors.divider,
  );
}

// ─── Reusable decoration helpers ───────────────────────────────────────────

BoxDecoration neonCardDecoration({
  Color borderColor = AppColors.neonCyan,
  double borderWidth = 0.8,
  double borderOpacity = 0.3,
  double glowSpread = 6,
  double radius = 16,
}) =>
    BoxDecoration(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor.withOpacity(borderOpacity),
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: borderColor.withOpacity(0.08),
          blurRadius: glowSpread,
          spreadRadius: 0,
        ),
      ],
    );

BoxDecoration neonBorderGlow(Color color, {double radius = 16}) =>
    BoxDecoration(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: color.withOpacity(0.5), width: 1),
      boxShadow: [
        BoxShadow(color: color.withOpacity(0.20), blurRadius: 12, spreadRadius: 2),
        BoxShadow(color: color.withOpacity(0.08), blurRadius: 30, spreadRadius: 4),
      ],
    );