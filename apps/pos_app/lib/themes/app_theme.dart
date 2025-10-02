import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color primaryOrange = Color(0xFFFF9800);
  static const Color primaryRed = Color(0xFFF44336);

  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color lightBlue = Color(0xFFE3F2FD);

  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFBDBDBD);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryBlue,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
      ),
      // fontFamily: 'Cairo', // Temporarily disabled

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          // fontFamily: 'Cairo', // Temporarily disabled
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.white,
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            // fontFamily: 'Cairo', // Temporarily disabled
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            // fontFamily: 'Cairo', // Temporarily disabled
          ),
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          // fontFamily: 'Cairo', // Temporarily disabled
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          // fontFamily: 'Cairo', // Temporarily disabled
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          // fontFamily: 'Cairo', // Temporarily disabled
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          // fontFamily: 'Cairo', // Temporarily disabled
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          // fontFamily: 'Cairo', // Temporarily disabled
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          // fontFamily: 'Cairo', // Temporarily disabled
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          // fontFamily: 'Cairo', // Temporarily disabled
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          // fontFamily: 'Cairo', // Temporarily disabled
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          // fontFamily: 'Cairo', // Temporarily disabled
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimary,
          // fontFamily: 'Cairo', // Temporarily disabled
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textPrimary,
          // fontFamily: 'Cairo', // Temporarily disabled
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: textSecondary,
          // fontFamily: 'Cairo', // Temporarily disabled
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          // fontFamily: 'Cairo', // Temporarily disabled
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          // fontFamily: 'Cairo', // Temporarily disabled
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textSecondary,
          // fontFamily: 'Cairo', // Temporarily disabled
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryRed, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(
          color: textSecondary,
          // fontFamily: 'Cairo', // Temporarily disabled
        ),
        hintStyle: const TextStyle(
          color: textLight,
          // fontFamily: 'Cairo', // Temporarily disabled
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryBlue,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          // fontFamily: 'Cairo', // Temporarily disabled
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
            // fontFamily: 'Cairo', // Temporarily disabled
            ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: Colors.grey,
        thickness: 1,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: primaryBlue,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.dark,
      ),
      // fontFamily: 'Cairo', // Temporarily disabled

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          // fontFamily: 'Cairo', // Temporarily disabled
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: const Color(0xFF2E2E2E),
      ),

      // Scaffold Background
      scaffoldBackgroundColor: const Color(0xFF121212),
    );
  }

  // Custom colors for specific use cases
  static const Color successColor = primaryGreen;
  static const Color warningColor = primaryOrange;
  static const Color errorColor = primaryRed;
  static const Color infoColor = primaryBlue;

  // Status colors for orders
  static const Color pendingColor = primaryOrange;
  static const Color preparingColor = primaryBlue;
  static const Color readyColor = primaryGreen;
  static const Color cancelledColor = primaryRed;

  // Payment method colors
  static const Color cashColor = primaryGreen;
  static const Color cardColor = primaryBlue;
  static const Color digitalColor = primaryOrange;
}
