import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Premium Teal-Emerald palette
  static const Color primary = Color(0xFF0D9488);       // teal-600
  static const Color primaryLight = Color(0xFF2DD4BF);  // teal-400
  static const Color primaryDark = Color(0xFF0F766E);   // teal-700
  static const Color accent = Color(0xFFF97316);        // orange-500 (warm coral)
  static const Color accentGreen = Color(0xFF10B981);   // emerald-500
  static const Color accentOrange = Color(0xFFFBBF24);  // amber-400

  static const List<Color> habitColors = [
    Color(0xFF0D9488), // Teal
    Color(0xFFF97316), // Coral
    Color(0xFF10B981), // Emerald
    Color(0xFFFBBF24), // Amber
    Color(0xFF38BDF8), // Sky Blue
    Color(0xFFF43F5E), // Rose
    Color(0xFF8B5CF6), // Violet
    Color(0xFF06B6D4), // Cyan
    Color(0xFF84CC16), // Lime
    Color(0xFF6366F1), // Indigo
  ];

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0D9488), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Light theme
  static const Color background = Color(0xFFF0FDFA);   // teal-50
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color inputFill = Color(0xFFCCFBF1);    // teal-100

  // Dark theme
  static const Color backgroundDark = Color(0xFF030F0E); // near-black teal
  static const Color surfaceDark = Color(0xFF0F2421);    // very dark teal
  static const Color cardDark = Color(0xFF0F2421);
  static const Color inputFillDark = Color(0xFF134E4A);  // teal-900

  // Text
  static const Color textPrimary = Color(0xFF0F172A);    // slate-900
  static const Color textSecondary = Color(0xFF64748B);  // slate-500
  static const Color textLight = Color(0xFF94A3B8);      // slate-400

  // Status
  static const Color success = Color(0xFF10B981);  // emerald-500
  static const Color error = Color(0xFFF43F5E);    // rose-500
  static const Color warning = Color(0xFFF59E0B);  // amber-500
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: _buildTextTheme(false),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardLight,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      labelStyle: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.w500),
      hintStyle: GoogleFonts.outfit(color: AppColors.textLight, fontSize: 15),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.2),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return Colors.white;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        return AppColors.textLight;
      }),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primaryLight,
      secondary: AppColors.accent,
      surface: AppColors.surfaceDark,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.backgroundDark,
    textTheme: _buildTextTheme(true),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: -0.3,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputFillDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      labelStyle: GoogleFonts.outfit(color: Colors.white60, fontSize: 15, fontWeight: FontWeight.w500),
      hintStyle: GoogleFonts.outfit(color: Colors.white38, fontSize: 15),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.2),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryLight,
      foregroundColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return Colors.white54;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        return AppColors.inputFillDark;
      }),
    ),
  );

  static TextTheme _buildTextTheme(bool isDark) {
    final color = isDark ? Colors.white : AppColors.textPrimary;
    final secondaryColor = isDark ? Colors.white70 : AppColors.textSecondary;
    return TextTheme(
      displayLarge: GoogleFonts.outfit(fontSize: 57, fontWeight: FontWeight.w700, color: color, letterSpacing: -1.5),
      displayMedium: GoogleFonts.outfit(fontSize: 45, fontWeight: FontWeight.w700, color: color, letterSpacing: -1.0),
      displaySmall: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w700, color: color, letterSpacing: -0.5),
      headlineLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w700, color: color, letterSpacing: -0.5),
      headlineMedium: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700, color: color, letterSpacing: -0.3),
      headlineSmall: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: color, letterSpacing: -0.2),
      titleLarge: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w600, color: color),
      titleMedium: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: color),
      titleSmall: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: color),
      bodyLarge: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w400, color: color),
      bodyMedium: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w400, color: secondaryColor),
      bodySmall: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w400, color: secondaryColor),
      labelLarge: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: color),
      labelMedium: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      labelSmall: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500, color: secondaryColor),
    );
  }
}