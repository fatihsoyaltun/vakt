import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Dark variants
  static TextStyle headline = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  static TextStyle title = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  static TextStyle body = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.white,
  );

  static TextStyle caption = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static TextStyle countdown = GoogleFonts.poppins(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  // Light variants
  static TextStyle headlineLight = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.darkBackground,
  );

  static TextStyle titleLight = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.darkBackground,
  );

  static TextStyle bodyLight = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.darkBackground,
  );

  static TextStyle captionLight = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static TextStyle countdownLight = GoogleFonts.poppins(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: AppColors.darkBackground,
  );

  // Theme-aware resolvers
  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static TextStyle headlineOf(BuildContext context) =>
      _isDark(context) ? headline : headlineLight;

  static TextStyle titleOf(BuildContext context) =>
      _isDark(context) ? title : titleLight;

  static TextStyle bodyOf(BuildContext context) =>
      _isDark(context) ? body : bodyLight;

  static TextStyle captionOf(BuildContext context) =>
      _isDark(context) ? caption : captionLight;

  static TextStyle countdownOf(BuildContext context) =>
      _isDark(context) ? countdown : countdownLight;
}
