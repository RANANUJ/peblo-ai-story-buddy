import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PebloTheme {
  // Brand Colors from PRD Section 5.2
  static const Color primaryPurple = Color(0xFF5C2D91);
  static const Color warmOrange = Color(0xFFFF6B35);
  static const Color skyTeal = Color(0xFF00BCD4);
  static const Color goldenYellow = Color(0xFFFFC107);
  static const Color offWhiteBg = Color(0xFFF8F4FF);
  static const Color successGreen = Color(0xFF43A047);
  static const Color errorRed = Color(0xFFE53935);

  // Common Design Spec Values
  static const double borderRadius = 16.0;
  static const double minTouchTarget = 56.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryPurple,
        primary: primaryPurple,
        secondary: warmOrange,
        tertiary: skyTeal,
        error: errorRed,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: offWhiteBg,
      
      // Typography: Rounded, bold and friendly typography using Nunito
      textTheme: GoogleFonts.nunitoTextTheme().copyWith(
        displayLarge: GoogleFonts.nunito(
          fontWeight: FontWeight.bold,
          color: primaryPurple,
        ),
        titleLarge: GoogleFonts.nunito(
          fontWeight: FontWeight.w800,
          color: primaryPurple,
        ),
        bodyLarge: GoogleFonts.nunito(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        bodyMedium: GoogleFonts.nunito(
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),

      // Card Theme: Rounded corners >= 16dp with subtle shadow
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 3,
        shadowColor: primaryPurple.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),

      // Button Themes: Minimum 56dp touch targets
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          elevation: 2,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryPurple,
          side: const BorderSide(color: primaryPurple, width: 2),
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
