import 'package:wegig_app/config/dev_config.dart';
import 'package:wegig_app/config/prod_config.dart';
import 'package:wegig_app/config/staging_config.dart';

/// Configuração centralizada de ambiente baseada em flavors
///
/// Uso:
/// ```dart
/// if (AppConfig.isDevelopment) {
///   debugPrint('Running in DEV mode');
/// }
///
/// final apiUrl = AppConfig.apiBaseUrl;
/// ```
class AppConfig {
  // Flavor atual (definido em tempo de compilação)
  // Será sobrescrito pelo flutter_flavorizr
  static const String _flavor =
      String.fromEnvironment('FLAVOR', defaultValue: 'dev');

  /// Nome do app atual (com sufixo do flavor)
  static String get appName {
    switch (_flavor) {
      case 'prod':
        return ProdConfig.appName;
      case 'staging':
        return StagingConfig.appName;
      case 'dev':
      default:
        return DevConfig.appName;
    }
  }

  /// Ambiente atual (development/staging/production)
  static String get appEnv {
    switch (_flavor) {
      case 'prod':
        return ProdConfig.appEnv;
      case 'staging':
        return StagingConfig.appEnv;
      case 'dev':
      default:
        return DevConfig.appEnv;
    }
  }

  /// Flavor atual (dev/staging/prod)
  static String get appFlavor => _flavor;

  // ========== API Configuration ==========

  static String get apiBaseUrl {
    switch (_flavor) {
      case 'prod':
        return ProdConfig.apiBaseUrl;
      case 'staging':
        return StagingConfig.apiBaseUrl;
      case 'dev':
      default:
        return DevConfig.apiBaseUrl;
    }
  }

  static int get apiTimeoutSeconds {
    switch (_flavor) {
      case 'prod':
        return ProdConfig.apiTimeoutSeconds;
      case 'staging':
        return StagingConfig.apiTimeoutSeconds;
      case 'dev':
      default:
        return DevConfig.apiTimeoutSeconds;
    }
  }

  // ========== Firebase Configuration ==========

  static String get firebaseProjectId {
    switch (_flavor) {
      case 'prod':
        return ProdConfig.firebaseProjectId;
      case 'staging':
        return StagingConfig.firebaseProjectId;
      case 'dev':
      default:
        return DevConfig.firebaseProjectId;
    }
  }

  // ========== Feature Flags ==========

  static bool get enableLogs {
    switch (_flavor) {
      case 'prod':
        return ProdConfig.enableLogs;
      case 'staging':
        return StagingConfig.enableLogs;
      case 'dev':
      default:
        return DevConfig.enableLogs;
    }
  }

  static bool get enableCrashlytics {
    switch (_flavor) {
      case 'prod':
        return ProdConfig.enableCrashlytics;
      case 'staging':
        return StagingConfig.enableCrashlytics;
      case 'dev':
      default:
        return DevConfig.enableCrashlytics;
    }
  }

  static bool get enableAnalytics {
    switch (_flavor) {
      case 'prod':
        return ProdConfig.enableAnalytics;
      case 'staging':
        return StagingConfig.enableAnalytics;
      case 'dev':
      default:
        return DevConfig.enableAnalytics;
    }
  }

  static bool get showDebugBanner {
    switch (_flavor) {
      case 'prod':
        return ProdConfig.showDebugBanner;
      case 'staging':
        return StagingConfig.showDebugBanner;
      case 'dev':
      default:
        return DevConfig.showDebugBanner;
    }
  }

  // ========== Environment Checks ==========

  static bool get isDevelopment => _flavor == 'dev';
  static bool get isStaging => _flavor == 'staging';
  static bool get isProduction => _flavor == 'prod';

  // ========== Google Maps Configuration ==========

  /// Google Maps Cloud Map ID para Android
  static String get googleMapIdAndroid {
    switch (_flavor) {
      case 'prod':
        return ProdConfig.googleMapIdAndroid;
      case 'staging':
        return StagingConfig.googleMapIdAndroid;
      case 'dev':
      default:
        return DevConfig.googleMapIdAndroid;
    }
  }

  /// Google Maps Cloud Map ID para iOS
  static String get googleMapIdIOS {
    switch (_flavor) {
      case 'prod':
        return ProdConfig.googleMapIdIOS;
      case 'staging':
        return StagingConfig.googleMapIdIOS;
      case 'dev':
      default:
        return DevConfig.googleMapIdIOS;
    }
  }
}
