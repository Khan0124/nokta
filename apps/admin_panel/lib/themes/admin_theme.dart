import 'package:flutter/material.dart';

class AdminTheme {
  static const Color primaryIndigo = Color(0xFF3F51B5);
  static const Color primaryPurple = Color(0xFF9C27B0);
  static const Color accentTeal = Color(0xFF009688);
  static const Color accentAmber = Color(0xFFFFC107);

  static const Color darkIndigo = Color(0xFF1A237E);
  static const Color lightIndigo = Color(0xFFE8EAF6);

  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFBDBDBD);

  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryIndigo,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryIndigo,
        brightness: Brightness.light,
      ),
      // fontFamily: 'Cairo', // Temporarily disabled

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryIndigo,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          // fontFamily: 'Cairo', // Temporarily disabled
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
        shadowColor: Colors.black12,
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryIndigo,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Cairo',
          ),
          elevation: 2,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryIndigo,
          side: const BorderSide(color: primaryIndigo, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Cairo',
          ),
        ),
      ),

      // Text Theme - Enhanced for admin interface
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          fontFamily: 'Cairo',
        ),
        displayMedium: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          fontFamily: 'Cairo',
        ),
        displaySmall: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          fontFamily: 'Cairo',
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontFamily: 'Cairo',
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontFamily: 'Cairo',
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontFamily: 'Cairo',
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          fontFamily: 'Cairo',
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          fontFamily: 'Cairo',
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          fontFamily: 'Cairo',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimary,
          fontFamily: 'Cairo',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textPrimary,
          fontFamily: 'Cairo',
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: textSecondary,
          fontFamily: 'Cairo',
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryIndigo, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        labelStyle: const TextStyle(
          color: textSecondary,
          fontFamily: 'Cairo',
        ),
        hintStyle: const TextStyle(
          color: textLight,
          fontFamily: 'Cairo',
        ),
      ),

      // Navigation Rail Theme (for admin panel)
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: lightIndigo,
        selectedIconTheme: IconThemeData(
          color: primaryIndigo,
          size: 24,
        ),
        unselectedIconTheme: IconThemeData(
          color: textSecondary,
          size: 24,
        ),
        selectedLabelTextStyle: TextStyle(
          color: primaryIndigo,
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: textSecondary,
          fontFamily: 'Cairo',
        ),
      ),

      // Data Table Theme
      dataTableTheme: DataTableThemeData(
        headingTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        dataTextStyle: const TextStyle(
          fontFamily: 'Cairo',
          color: textPrimary,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: Colors.grey,
        thickness: 1,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: primaryIndigo,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryIndigo,
        brightness: Brightness.dark,
      ),
      fontFamily: 'Cairo',

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: const Color(0xFF2E2E2E),
      ),

      // Navigation Rail Theme for dark mode
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedIconTheme: IconThemeData(
          color: Colors.white,
          size: 24,
        ),
        unselectedIconTheme: IconThemeData(
          color: Colors.grey,
          size: 24,
        ),
        selectedLabelTextStyle: TextStyle(
          color: Colors.white,
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: Colors.grey,
          fontFamily: 'Cairo',
        ),
      ),

      // Scaffold Background
      scaffoldBackgroundColor: const Color(0xFF121212),
    );
  }

  // Custom colors for admin-specific features
  static const Color statusActive = successGreen;
  static const Color statusInactive = errorRed;
  static const Color statusPending = warningOrange;
  static const Color statusTrial = accentAmber;

  // Plan colors
  static const Color basicPlan = Color(0xFF9E9E9E);
  static const Color standardPlan = accentTeal;
  static const Color premiumPlan = primaryPurple;
  static const Color enterprisePlan = primaryIndigo;

  // Chart colors for analytics
  static final List<Color> chartColors = [
    const Color(0xFF3F51B5), // primaryIndigo
    const Color(0xFF009688), // accentTeal
    const Color(0xFF9C27B0), // primaryPurple
    const Color(0xFFFFC107), // accentAmber
    const Color(0xFF4CAF50), // successGreen
    const Color(0xFFFF9800), // warningOrange
    const Color(0xFFF44336), // errorRed
    const Color(0xFF00BCD4), // cyan
    const Color(0xFFCDDC39), // lime
    const Color(0xFFE91E63), // pink
  ];

  // Method to get color based on tenant status
  static Color getTenantStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return statusActive;
      case 'trial':
        return statusTrial;
      case 'suspended':
        return warningOrange;
      case 'expired':
        return errorRed;
      case 'cancelled':
        return statusInactive;
      default:
        return textSecondary;
    }
  }

  // Method to get color based on subscription plan
  static Color getPlanColor(String plan) {
    switch (plan.toLowerCase()) {
      case 'basic':
        return basicPlan;
      case 'standard':
        return standardPlan;
      case 'premium':
        return premiumPlan;
      case 'enterprise':
        return enterprisePlan;
      default:
        return textSecondary;
    }
  }
}
