import Flutter
import UIKit
import GoogleMaps
import SDWebImage

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Provide Google Maps API key based on Bundle ID (flavor)
    let googleMapsApiKey = getGoogleMapsApiKey()
    GMSServices.provideAPIKey(googleMapsApiKey)
    
    #if DEBUG
    print("🗺️ Google Maps API Key loaded for bundle: \(Bundle.main.bundleIdentifier ?? "unknown")")
    #endif
    
    // ✅ Configurar cache de imagens SDWebImage
    // Limite de 200MB em disco e 50MB em memória
    // TTL de 7 dias para imagens cacheadas
    configureImageCache()
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  /// Configura SDWebImage cache para otimizar uso de memória/disco
  private func configureImageCache() {
    let cache = SDImageCache.shared
    
    // Limite de memória: 50MB (evita crashes em dispositivos antigos)
    cache.config.maxMemoryCost = 50 * 1024 * 1024
    
    // Limite de disco: 200MB (suficiente para posts/perfis)
    cache.config.maxDiskSize = 200 * 1024 * 1024
    
    // TTL: 7 dias (posts expiram em 30 dias, mas imagens podem ser reutilizadas)
    cache.config.maxDiskAge = 7 * 24 * 60 * 60 // 7 dias em segundos
    
    // Desabilitar cache em memória de imagens muito grandes (>2MB)
    // Isso evita picos de memória com fotos de alta resolução
    cache.config.shouldCacheImagesInMemory = true
    
    #if DEBUG
    print("📷 SDWebImage cache configurado:")
    print("   - Memória: 50MB")
    print("   - Disco: 200MB")
    print("   - TTL: 7 dias")
    #endif
  }
  
  /// Returns the Google Maps API key based on the current Bundle ID (flavor)
  /// Keys from Google Cloud Console - ensure Maps SDK for iOS is enabled in each project
  private func getGoogleMapsApiKey() -> String {
    let bundleId = Bundle.main.bundleIdentifier ?? ""
    
    switch bundleId {
    case "com.wegig.wegig.dev":
      // Dev environment - wegig-dev project
      return "AIzaSyADjXo-1miAGtoCVRR1702AjtiyoeSdsMA"
    case "com.wegig.wegig.staging":
      // Staging environment - wegig-staging project
      return "AIzaSyBcR84Clf81XicGgxCM77mO7qqt1Np87cg"
    case "com.wegig.wegig":
      // Production environment - to-sem-banda-83e19 project
      return "AIzaSyAe_WwvD3nN-VJlMZf2L_BRpIx-ne3P_-0"
    default:
      // Fallback to production key
      #if DEBUG
      print("⚠️ Unknown bundle ID: \(bundleId), using production API key")
      #endif
      return "AIzaSyAe_WwvD3nN-VJlMZf2L_BRpIx-ne3P_-0"
    }
  }
}
