import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';

// ─── QuestArena Dark Arena Theme ───────────────────────────────────────────
// Inspired by: Blade Runner 2049, TRON Legacy, Star Wars, Alita Battle Angel

class AppTheme {
  static ThemeData get darkArena => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgBase,
    fontFamily: GoogleFonts.chakraPetch().fontFamily,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.neonCyan,
      secondary: AppColors.neonViolet,
      surface: AppColors.bgCard,
      error: AppColors.neonPink,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bgBase,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.orbitron(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.0,
      ),
      iconTheme: const IconThemeData(color: AppColors.neonCyan),
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
        side: const BorderSide(color: AppColors.divider, width: 0.5),
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
        color: borderColor.withValues(alpha: borderOpacity),
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: borderColor.withValues(alpha: 0.08),
          blurRadius: glowSpread,
          spreadRadius: 0,
        ),
      ],
    );

BoxDecoration neonBorderGlow(Color color, {double radius = 16}) =>
    BoxDecoration(
      color: AppColors.bgCard,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: 0.20), blurRadius: 12, spreadRadius: 2),
        BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 30, spreadRadius: 4),
      ],
    );
