/// Configuração do ambiente PRODUCTION
///
/// - API de produção
/// - Logs desabilitados
/// - Firebase: to-sem-banda-83e19
/// - Crashlytics habilitado
/// - Performance monitoring habilitado
class ProdConfig {
  static const String appEnv = 'production';
  static const String appFlavor = 'prod';
  static const String appName = 'WeGig';

  // API Configuration
  static const String apiBaseUrl = 'https://api.tosembanda.com';

  // Firebase Configuration
  static const String firebaseProjectId = 'to-sem-banda-83e19';

  // Feature Flags
  static const bool enableLogs = false; // SEM logs em produção
  static const bool enableCrashlytics = true;
  static const bool enableAnalytics = true;
  static const bool enablePerformanceMonitoring = true;

  // Debug Settings
  static const bool showDebugBanner = false;
  static const bool verboseLogging = false;
  static const bool enableNetworkInspector = false;

  // App Behavior
  static const int apiTimeoutSeconds = 20; // Timeout mais agressivo
  static const int maxRetryAttempts = 2;
  static const bool skipOnboarding = false;

  // Bundle IDs
  static const String androidApplicationId = 'com.wegig.wegig';
  static const String iosBundleId = 'com.wegig.wegig';

  // Google Maps Cloud Map IDs
  static const String googleMapIdAndroid = 'b7134f9dc59c2ad987ffb1bf';
  static const String googleMapIdIOS = 'b7134f9dc59c2ad91b13772c';

  /// Verifica se está em ambiente de produção
  static bool get isDevelopment => false;
  static bool get isStaging => false;
  static bool get isProduction => true;
}
