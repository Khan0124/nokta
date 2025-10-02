// packages/core/lib/config/app_config.dart
class AppConfig {
  static const String appName = 'Nokta';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000',
  );

  // Feature Flags
  static const bool enableOfflineMode = !bool.fromEnvironment('WEB');
  static const bool enableAnalytics = bool.fromEnvironment('ENABLE_ANALYTICS', defaultValue: true);

  // Default Values
  static const double defaultTaxRate = 15.0; // 15% VAT in Saudi Arabia
  static const String defaultCurrency = 'SAR';
  static const String defaultLanguage = 'ar';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}

// Environment Configuration
enum Environment {
  development,
  staging,
  production,
}

class EnvironmentConfig {
  static Environment get current {
    const env = String.fromEnvironment('ENV', defaultValue: 'development');
    switch (env) {
      case 'production':
        return Environment.production;
      case 'staging':
        return Environment.staging;
      default:
        return Environment.development;
    }
  }

  static String get apiUrl {
    switch (current) {
      case Environment.production:
        return 'https://api.nokta.com';
      case Environment.staging:
        return 'https://staging-api.nokta.com';
      case Environment.development:
        return 'http://62.77.155.129:3000'; // Your current dev server
    }
  }

  static bool get enableLogging => current != Environment.production;
  static bool get enableDebugTools => current == Environment.development;
}