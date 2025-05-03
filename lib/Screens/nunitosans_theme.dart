import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Utility class for font-related functions
class FontUtils {
  /// Applies Nunito Sans font to any ThemeData without changing other properties
  static ThemeData applyNunitoSansFont(ThemeData baseTheme) {
    return baseTheme.copyWith(
      textTheme: GoogleFonts.nunitoSansTextTheme(baseTheme.textTheme),
      primaryTextTheme: GoogleFonts.nunitoSansTextTheme(baseTheme.primaryTextTheme),
    );
  }
  
  /// Gets the Nunito Sans TextTheme directly
  static TextTheme nunitoSansTextTheme(TextTheme baseTextTheme) {
    return GoogleFonts.nunitoSansTextTheme(baseTextTheme);
  }
}