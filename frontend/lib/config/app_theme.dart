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

  // Input Field Colors
  static const Color inputFillColor = Color(0xFFF0F5F3);    // Light mint tint
  static const Color inputIconColor = Color(0xFF90BEB3);     // Soft teal for icons

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
          minimumSize: const Size(0, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          elevation: buttonElevation,
          textStyle: buttonTextStyle,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: outlineButton(),
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
        fillColor: inputFillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: primaryTeal, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: const TextStyle(
          color: textHint,
          fontSize: 14,
        ),
        prefixIconColor: inputIconColor,
      ),

      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTeal,
        primary: primaryTeal,
        secondary: darkBlue,
      ),
    );
  }

  // ── Standard Button Dimensions ──
  static const double buttonHeight = 52;
  static const double buttonRadius = 30;
  static const double buttonFontSize = 16;
  static const FontWeight buttonFontWeight = FontWeight.w600;
  static const double buttonElevation = 2;

  // ── Button Text Style ──
  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: buttonFontSize,
    fontWeight: buttonFontWeight,
  );

  // ── Primary Action (Save, Submit, Confirm, Login, Continue) — Dark Blue ──
  static ButtonStyle primaryButton() {
    return ElevatedButton.styleFrom(
      backgroundColor: darkBlue,
      foregroundColor: Colors.white,
      minimumSize: const Size(0, buttonHeight),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(buttonRadius),
      ),
      elevation: buttonElevation,
      textStyle: buttonTextStyle,
    );
  }

  // ── Secondary Action (Yes, No, Back, Guidance, View, navigation) — Teal ──
  static ButtonStyle secondaryButton() {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryTeal,
      foregroundColor: Colors.white,
      minimumSize: const Size(0, buttonHeight),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(buttonRadius),
      ),
      elevation: buttonElevation,
      textStyle: buttonTextStyle,
    );
  }

  // ── Danger Action (Disconnect, Remove) — Red ──
  static ButtonStyle dangerButton() {
    return ElevatedButton.styleFrom(
      backgroundColor: criticalRed,
      foregroundColor: Colors.white,
      minimumSize: const Size(0, buttonHeight),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(buttonRadius),
      ),
      elevation: buttonElevation,
      textStyle: buttonTextStyle,
    );
  }

  // ── Outline / Tertiary (Go to Login, Cancel) ──
  static ButtonStyle outlineButton() {
    return OutlinedButton.styleFrom(
      foregroundColor: primaryTeal,
      side: const BorderSide(color: primaryTeal, width: 2),
      minimumSize: const Size(0, buttonHeight),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(buttonRadius),
      ),
      textStyle: buttonTextStyle,
    );
  }

  // ── Menu / Profile buttons (full-width teal) ──
  static ButtonStyle menuButton() {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryTeal,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, buttonHeight),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(buttonRadius),
      ),
      elevation: 0,
      textStyle: buttonTextStyle,
    );
  }

  // Legacy alias
  static ButtonStyle darkButton() => primaryButton();

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
