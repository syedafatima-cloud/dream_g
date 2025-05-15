import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PastelTheme {
  static const Color primary = Color.fromARGB(255, 197, 157, 216); // Soft purple
  static const Color secondary = Color(0xFFFFC8DD); // Soft pink
  static const Color accent = Color.fromARGB(255, 75, 77, 68); // Dark gray
  static const Color background = Color(0xFFF8EDEB); // Soft cream
  static const Color cardColor = Color(0xFFFFFFFF); // White
  static const Color textPrimary = Color(0xFF445566); // Darker blue-gray
  static const Color textSecondary = Color(0xFF7A8999); // Medium blue-gray
  static const Color success = Color(0xFFABD8C6); // Mint green
  static const Color error = Color(0xFFFFADAD); // Soft red
  static const Color inputBackground = Color(0x25AAAAAA);
  // Light shadow color for cards
  static const Color cardShadow = Color(0x15AAAAAA); // Very light transparent shadow

  // Transparent greyish divider color
  static const Color divider = Color(0x25AAAAAA); // Transparent greyish

  // Create a ThemeData instance using the pastel colors
  static ThemeData get theme => ThemeData(
        // Primary color scheme
        primaryColor: primary,
        colorScheme: ColorScheme.light(
          primary: primary,
          secondary: secondary,
          surface: background,
          error: error,
          onPrimary: Colors.white,
          onSecondary: textPrimary,
          onSurface: textPrimary,
          onError: Colors.white,
        ),
        
        // Background colors
        scaffoldBackgroundColor: background,
        cardColor: cardColor,
        
        // Text themes with Nunito Sans font
        textTheme: GoogleFonts.interTextTheme(
          TextTheme(
            displayLarge: TextStyle(color: const Color.fromARGB(255, 24, 31, 37), fontWeight: FontWeight.w700),
            displayMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
            displaySmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
            headlineLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
            headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
            headlineSmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
            titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
            titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
            titleSmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
            bodyLarge: TextStyle(color: textPrimary),
            bodyMedium: TextStyle(color: textPrimary),
            bodySmall: TextStyle(color: textSecondary),
            labelLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
            labelMedium: TextStyle(color: textPrimary),
            labelSmall: TextStyle(color: textSecondary),
          ),
        ),
        
        // Button themes
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(1000),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: BorderSide(color: primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(1000),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        
        // Input decoration theme - Modified to remove black borders and make fields transparent grey
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: inputBackground, // Transparent greyish background
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(1000),
            borderSide: BorderSide.none, // No border outline
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(1000),
            borderSide: BorderSide.none, // No border when enabled
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(1000),
            borderSide: BorderSide(color: primary), // Colored line when focused
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(1000),
            borderSide: BorderSide(color: error), // Only error has visible border
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        
        // App bar theme
        appBarTheme: AppBarTheme(
          backgroundColor: background,
          elevation: 0,
          iconTheme: IconThemeData(color: textPrimary),
          titleTextStyle: GoogleFonts.inter(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        // Tab bar theme
        tabBarTheme: TabBarTheme(
          labelColor: primary,
          unselectedLabelColor: textSecondary,
          indicatorColor: primary,
          labelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w400,
          ),
        ),
        
        // Card theme with light shadow
        cardTheme: CardTheme(
          color: cardColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: cardShadow, // Using the very light shadow color
        ),
        
        // Floating action button theme
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.white, // Changed to white for better contrast
        ),

        // Ensure no default black outlines on buttons or other widgets
        buttonTheme: ButtonThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(1000),
          ),
          buttonColor: primary,
          textTheme: ButtonTextTheme.primary,
        ),
        
        // Add divider theme to match the overall aesthetic
        dividerTheme: DividerThemeData(
          color: divider,
          thickness: 1.0,
          space: 16.0,
        ),

        // Remove focus highlight color that can create black borders
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent.withOpacity(0.1),
        highlightColor: Colors.transparent.withOpacity(0.1),
        splashColor: primary.withOpacity(0.1),
      );
}