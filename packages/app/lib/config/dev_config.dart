/// Configuração do ambiente DEV
///
/// - API de desenvolvimento/teste
/// - Logs habilitados
/// - Firebase: to-sem-banda-dev
/// - Crashlytics desabilitado
class DevConfig {
  static const String appEnv = 'development';
  static const String appFlavor = 'dev';
  static const String appName = 'WeGig DEV';

  // API Configuration
  static const String apiBaseUrl = 'https://dev-api.tosembanda.com';

  // Firebase Configuration
  static const String firebaseProjectId = 'to-sem-banda-dev';

  // Feature Flags
  static const bool enableLogs = true;
  static const bool enableCrashlytics = false;
  static const bool enableAnalytics = false;
  static const bool enablePerformanceMonitoring = false;

  // Debug Settings
  static const bool showDebugBanner = true;
  static const bool verboseLogging = true;
  static const bool enableNetworkInspector = true;

  // App Behavior
  static const int apiTimeoutSeconds = 60; // Timeout maior para debug
  static const int maxRetryAttempts = 3;
  static const bool skipOnboarding = true; // Pula onboarding em dev

  // Bundle IDs
  static const String androidApplicationId = 'com.wegig.wegig.dev';
  static const String iosBundleId = 'com.wegig.wegig.dev';

  // Google Maps Cloud Map IDs (wegig-dev)
  static const String googleMapIdAndroid = 'f4c603fd45b2747ceac6e4b5';
  static const String googleMapIdIOS = 'f4c603fd45b2747cac0905b3';

  /// Verifica se está em ambiente de desenvolvimento
  static bool get isDevelopment => true;
  static bool get isStaging => false;
  static bool get isProduction => false;
}
