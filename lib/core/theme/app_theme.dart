import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Space-grade color palette
  static const Color scaffoldBg = Color(0xFF080302);
  static const Color neonOrange = Color(0xFFFF4500);
  static const Color cyberAmber = Color(0xFFFFA000);
  static const Color metallicSilver = Color(0xFFCFD8DC);
  static const Color metallicMuted = Color(0xFF90A4AE);
  static const Color translucentDark = Color(0xDD0B0403);
  static const Color cardSurface = Color(0xFF110604);
  static const Color elevatedSurface = Color(0xFF180907);
  static const Color cyberCyan = Color(0xFF00E5FF);
  static const Color neonEmerald = Color(0xFF00E676);

  // Gradient tokens
  static const LinearGradient electricFireGradient = LinearGradient(
    colors: [neonOrange, cyberAmber],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF160805), Color(0xFF0D0403)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Box shadow helpers
  static List<BoxShadow> neonGlow({Color color = neonOrange, double opacity = 0.25, double blur = 12}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: blur,
        spreadRadius: 0,
      ),
    ];
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scaffoldBg,

      // Color Scheme
      colorScheme: ColorScheme.dark(
        primary: neonOrange,
        onPrimary: scaffoldBg,
        secondary: cyberAmber,
        onSecondary: scaffoldBg,
        surface: cardSurface,
        onSurface: metallicSilver,
        outline: neonOrange.withValues(alpha: 0.5),
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
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        displayMedium: GoogleFonts.orbitron(
          textStyle: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        headlineLarge: GoogleFonts.orbitron(
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color: metallicSilver,
          ),
        ),
        titleLarge: GoogleFonts.orbitron(
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: metallicSilver,
          ),
        ),
        titleMedium: GoogleFonts.rajdhani(
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: metallicSilver,
          ),
        ),
        bodyLarge: GoogleFonts.rajdhani(
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
            color: metallicSilver,
          ),
        ),
        bodyMedium: GoogleFonts.rajdhani(
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
            color: metallicMuted,
          ),
        ),
      ),

      // Card Theme: Translucent dark with subtle neon borders
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: neonOrange.withValues(alpha: 0.35), width: 0.6),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Grounded Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0B0403),
        elevation: 0,
        indicatorColor: neonOrange.withValues(alpha: 0.18),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.rajdhani(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: neonOrange,
            );
          }
          return GoogleFonts.rajdhani(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            color: metallicMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: neonOrange, size: 24);
          }
          return IconThemeData(color: metallicMuted.withValues(alpha: 0.8), size: 22);
        }),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: neonOrange,
          side: const BorderSide(color: neonOrange, width: 1),
          textStyle: GoogleFonts.rajdhani(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 1.2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonOrange,
          foregroundColor: Colors.black,
          textStyle: GoogleFonts.rajdhani(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 1.2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 4,
          shadowColor: neonOrange.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
