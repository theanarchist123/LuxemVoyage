import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Core Palette: "Midnight Aurora" ──
  static const Color primaryBlack = Color(0xFF080E1A);
  static const Color surfaceDark = Color(0xFF111827);
  static const Color surfaceLight = Color(0xFF1E293B);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentTeal = Color(0xFF14B8A6);
  static const Color accentViolet = Color(0xFF8B5CF6);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color glassWhite = Color(0x0FFFFFFF); // ~6% white

  // ── Legacy aliases (so existing code doesn't break instantly) ──
  static const Color midnightBlue = primaryBlack;
  static const Color softGold = accentAmber;
  static const Color deepNavy = surfaceDark;
  static const Color offWhite = textPrimary;

  // ── Gradients ──
  static const LinearGradient auroraGradient = LinearGradient(
    colors: [Color(0xFF14B8A6), Color(0xFF8B5CF6), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amberGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF111827), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient screenGradient = LinearGradient(
    colors: [Color(0xFF080E1A), Color(0xFF0F172A), Color(0xFF111827)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Glass decoration factory ──
  static BoxDecoration glassDecoration({
    double borderRadius = 20,
    Color? borderColor,
    double opacity = 0.06,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? Colors.white.withValues(alpha: 0.08),
      ),
    );
  }

  static BoxDecoration glassCardDecoration({
    double borderRadius = 22,
    bool withShadow = true,
  }) {
    return BoxDecoration(
      color: surfaceDark.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      boxShadow: withShadow
          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8))]
          : null,
    );
  }

  // ── Theme Data ──
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryBlack,
      primaryColor: accentAmber,
      colorScheme: const ColorScheme.dark(
        primary: accentAmber,
        secondary: accentTeal,
        tertiary: accentViolet,
        surface: surfaceDark,
        onSurface: textPrimary,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(color: textPrimary, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        displayMedium: GoogleFonts.inter(color: textPrimary, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        titleLarge: GoogleFonts.inter(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
        titleMedium: GoogleFonts.inter(color: textPrimary, fontSize: 17, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.inter(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
        bodyMedium: GoogleFonts.inter(color: textSecondary, fontSize: 14, fontWeight: FontWeight.w400, height: 1.5),
        labelLarge: GoogleFonts.inter(color: accentAmber, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        labelSmall: GoogleFonts.inter(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentAmber,
          foregroundColor: primaryBlack,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          elevation: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accentAmber, width: 1.5),
        ),
      ),
    );
  }
}
