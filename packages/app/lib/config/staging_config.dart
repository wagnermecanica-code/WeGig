/// Configuração do ambiente STAGING
///
/// - API de homologação
/// - Logs habilitados
/// - Firebase: to-sem-banda-staging
/// - Crashlytics habilitado para testes
class StagingConfig {
  static const String appEnv = 'staging';
  static const String appFlavor = 'staging';
  static const String appName = 'WeGig STAGING';

  // API Configuration
  static const String apiBaseUrl = 'https://staging-api.tosembanda.com';

  // Firebase Configuration
  static const String firebaseProjectId = 'to-sem-banda-staging';

  // Feature Flags
  static const bool enableLogs = true;
  static const bool enableCrashlytics = true;
  static const bool enableAnalytics = true;
  static const bool enablePerformanceMonitoring = true;

  // Debug Settings
  static const bool showDebugBanner = true;
  static const bool verboseLogging = false; // Logs mais limpos em staging
  static const bool enableNetworkInspector = true;

  // App Behavior
  static const int apiTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;
  static const bool skipOnboarding = false;

  // Bundle IDs
  static const String androidApplicationId = 'com.wegig.wegig.staging';
  static const String iosBundleId = 'com.wegig.wegig.staging';

  /// Verifica se está em ambiente de staging
  static bool get isDevelopment => false;
  static bool get isStaging => true;
  static bool get isProduction => false;
}
