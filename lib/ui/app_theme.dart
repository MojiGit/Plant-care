import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const cream      = Color(0xFFF5EAD8);
  static const dark       = Color(0xFF201E1D);
  static const muted      = Color(0xFF645C50);
  static const terracotta = Color(0xFFC67139);
  static const sage       = Color(0xFF7A8A5E);
  static const sageTint   = Color(0xFFEAEDE5);
  static const amber      = Color(0xFFD4920F);
  static const warning    = Color(0xFFC67139);

  static ThemeData get theme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: cream,
      colorScheme: const ColorScheme.light(
        primary: sage,
        secondary: terracotta,
        surface: cream,
        onPrimary: cream,
        onSecondary: cream,
        onSurface: dark,
      ),
      textTheme: GoogleFonts.figtreeTextTheme(base.textTheme).apply(
        bodyColor: dark,
        displayColor: dark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cream,
        foregroundColor: dark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.caprasimo(
          color: dark,
          fontSize: 22,
          fontWeight: FontWeight.w400,
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: cream,
        indicatorColor: amber,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: sage,
        foregroundColor: cream,
        elevation: 3,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: sage,
          foregroundColor: cream,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          textStyle: GoogleFonts.figtree(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
