import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Space-grade color palette
  static const Color scaffoldBg = Color(0xFF080302);
  static const Color neonOrange = Color(0xFFFF4500);
  static const Color metallicSilver = Color(0xFFCFD8DC);
  static const Color translucentDark = Color(0xCC080302);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scaffoldBg,

      // Color Scheme
      colorScheme: ColorScheme.dark(
        primary: neonOrange,
        onPrimary: scaffoldBg,
        secondary: metallicSilver,
        onSecondary: scaffoldBg,
        surface: translucentDark,
        onSurface: metallicSilver,
        outline: neonOrange,
      ),

      // Typography
      textTheme: GoogleFonts.rajdhaniTextTheme(
        ThemeData.dark().textTheme.apply(
          bodyColor: metallicSilver,
          displayColor: metallicSilver,
        ),
      ).copyWith(
        displayLarge: GoogleFonts.orbitron(
          textStyle: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: metallicSilver,
          ),
        ),
        displayMedium: GoogleFonts.orbitron(
          textStyle: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: metallicSilver,
          ),
        ),
        headlineLarge: GoogleFonts.orbitron(
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: metallicSilver,
          ),
        ),
        titleLarge: GoogleFonts.orbitron(
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: metallicSilver,
          ),
        ),
      ),

      // Card Theme: Translucent dark with thin orange borders
      cardTheme: CardThemeData(
        color: translucentDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: neonOrange, width: 0.5),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scaffoldBg,
        indicatorColor: neonOrange.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.rajdhani(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: metallicSilver,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: neonOrange);
          }
          return IconThemeData(color: metallicSilver.withValues(alpha: 0.7));
        }),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: neonOrange,
          side: const BorderSide(color: neonOrange),
          textStyle: GoogleFonts.rajdhani(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
