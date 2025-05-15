import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Utility class for font-related functions
class FontUtils {
  /// Applies Inter font to any ThemeData without changing other properties
  static ThemeData applyInterFont(ThemeData baseTheme) {
    return baseTheme.copyWith(
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
      primaryTextTheme: GoogleFonts.interTextTheme(baseTheme.primaryTextTheme),
    );
  }

  /// Gets the Inter TextTheme directly
  static TextTheme interTextTheme(TextTheme baseTextTheme) {
    return GoogleFonts.interTextTheme(baseTextTheme);
  }
}

