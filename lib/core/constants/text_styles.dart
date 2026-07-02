import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // "Orbitron" is perfect for high-tech, futuristic gaming titles
  static TextStyle display = GoogleFonts.orbitron(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
    letterSpacing: 2.0,
  );

  static TextStyle headline = GoogleFonts.orbitron(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 1.5,
  );

  // "Chakra Petch" has a technical, semi-robotic look for body text
  static TextStyle bodyLg = GoogleFonts.chakraPetch(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMd = GoogleFonts.chakraPetch(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  // "Space Mono" for stats and numbers
  static TextStyle label = GoogleFonts.spaceMono(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    color: AppColors.textSecondary,
  );
}
