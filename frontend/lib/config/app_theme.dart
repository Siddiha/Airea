import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryTeal = Color(0xFF5EBAA8);
  static const Color darkBlue = Color(0xFF1E3A5F);
  static const Color lightTeal = Color(0xFF6EC9B7);

  // Status Colors
  static const Color normalGreen = Color(0xFF4CAF50);
  static const Color highOrange = Color(0xFFFF9800);
  static const Color criticalRed = Color(0xFFE53935);

  // Background Colors
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardBackground = Colors.white;

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // Create theme data
  static ThemeData lightTheme() {
    return ThemeData(
      primaryColor: primaryTeal,
      scaffoldBackgroundColor: backgroundColor,
      useMaterial3: true,
      fontFamily: 'Roboto',

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 2,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 2,
        color: cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFE8E8E8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: const TextStyle(
          color: textHint,
          fontSize: 14,
        ),
      ),

      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTeal,
        primary: primaryTeal,
        secondary: darkBlue,
      ),
    );
  }

  // Button Styles
  static ButtonStyle primaryButton() {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryTeal,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      elevation: 2,
    );
  }

  static ButtonStyle darkButton() {
    return ElevatedButton.styleFrom(
      backgroundColor: darkBlue,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      elevation: 2,
    );
  }

  static ButtonStyle outlineButton() {
    return OutlinedButton.styleFrom(
      foregroundColor: primaryTeal,
      side: const BorderSide(color: primaryTeal, width: 2),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }

  // Text Styles
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    color: textPrimary,
  );

  static const TextStyle bodyTextSecondary = TextStyle(
    fontSize: 14,
    color: textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: textSecondary,
  );
}
