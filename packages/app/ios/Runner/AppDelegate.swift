import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let googleMapsApiKey = getGoogleMapsApiKey()
    GMSServices.provideAPIKey(googleMapsApiKey)
    
    #if DEBUG
    print("🗺️ Google Maps API Key loaded for bundle: \(Bundle.main.bundleIdentifier ?? "unknown")")
    #endif
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func getGoogleMapsApiKey() -> String {
    let bundleId = Bundle.main.bundleIdentifier ?? ""
    
    switch bundleId {
    case "com.wegig.wegig.dev":
      return "AIzaSyADjXo-1miAGtoCVRR1702AjtiyoeSdsMA"
    case "com.wegig.wegig.staging":
      return "AIzaSyBcR84Clf81XicGgxCM77mO7qqt1Np87cg"
    case "com.wegig.wegig":
      return "AIzaSyAe_WwvD3nN-VJlMZf2L_BRpIx-ne3P_-0"
    default:
      #if DEBUG
      print("⚠️ Unknown bundle ID: \(bundleId), using production API key")
      #endif
      return "AIzaSyAe_WwvD3nN-VJlMZf2L_BRpIx-ne3P_-0"
    }
  }
}
