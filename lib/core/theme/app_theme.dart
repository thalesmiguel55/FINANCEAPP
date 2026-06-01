import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// removed unused google_fonts import
import 'package:shared_preferences/shared_preferences.dart';
import 'package:financeapp/core/constants/app_constants.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(AppConstants.themeKey) ?? true;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() async {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.themeKey, state == ThemeMode.dark);
  }
}

class AppTheme {
  AppTheme._();

  // Color Palette
  static const Color primaryGreen = Color(0xFF14B8A6);
  static const Color primaryGreenDark = Color(0xFF0F766E);
  static const Color secondaryBlue = Color(0xFF2563EB);
  static const Color accentPurple = Color(0xFF7C3AED);
  static const Color dangerRed = Color(0xFFE11D48);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color accentCoral = Color(0xFFF97316);

  // Dark theme colors
  static const Color darkBg = Color(0xFF101418);
  static const Color darkSurface = Color(0xFF171D22);
  static const Color darkCard = Color(0xFF1E252B);
  static const Color darkBorder = Color(0xFF303941);
  static const Color darkTextPrimary = Color(0xFFF5F7FA);
  static const Color darkTextSecondary = Color(0xFFA8B3BD);

  // Light theme colors
  static const Color lightBg = Color(0xFFF4F7F6);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFD8E2E0);
  static const Color lightTextPrimary = Color(0xFF16201D);
  static const Color lightTextSecondary = Color(0xFF62716D);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        secondary: secondaryBlue,
        tertiary: accentPurple,
        error: dangerRed,
        surface: darkSurface,
        onPrimary: Color(0xFFFFFFFF),
        onSurface: darkTextPrimary,
      ),
      textTheme: _buildTextTheme(darkTextPrimary, darkTextSecondary),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          fontFamily: 'Poppins',
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        hintStyle: const TextStyle(color: darkTextSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: dangerRed),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkCard,
        selectedItemColor: primaryGreen,
        unselectedItemColor: darkTextSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: darkCard,
        selectedColor: primaryGreen.withAlpha((0.2 * 255).round()),
        labelStyle: const TextStyle(color: darkTextPrimary, fontFamily: 'Poppins'),
        side: const BorderSide(color: darkBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkCard,
        contentTextStyle: const TextStyle(color: darkTextPrimary, fontFamily: 'Poppins'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        secondary: secondaryBlue,
        tertiary: accentPurple,
        error: dangerRed,
        surface: lightSurface,
        onPrimary: Color(0xFFFFFFFF),
        onSurface: lightTextPrimary,
      ),
      textTheme: _buildTextTheme(lightTextPrimary, lightTextSecondary),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBg,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          fontFamily: 'Poppins',
        ),
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        hintStyle: const TextStyle(color: lightTextSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: dangerRed),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: primaryGreen,
        unselectedItemColor: lightTextSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: TextStyle(color: primary, fontSize: 32, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
      displayMedium: TextStyle(color: primary, fontSize: 28, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
      displaySmall: TextStyle(color: primary, fontSize: 24, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
      headlineLarge: TextStyle(color: primary, fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
      headlineMedium: TextStyle(color: primary, fontSize: 20, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
      headlineSmall: TextStyle(color: primary, fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
      titleLarge: TextStyle(color: primary, fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
      titleMedium: TextStyle(color: primary, fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'Poppins'),
      titleSmall: TextStyle(color: secondary, fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'Poppins'),
      bodyLarge: TextStyle(color: primary, fontSize: 16, fontFamily: 'Poppins'),
      bodyMedium: TextStyle(color: secondary, fontSize: 14, fontFamily: 'Poppins'),
      bodySmall: TextStyle(color: secondary, fontSize: 12, fontFamily: 'Poppins'),
      labelLarge: TextStyle(color: primary, fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
      labelMedium: TextStyle(color: secondary, fontSize: 12, fontFamily: 'Poppins'),
    );
  }
}
