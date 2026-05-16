import Flutter
import UIKit
import GoogleMaps
import FBSDKCoreKit

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
    
    ApplicationDelegate.shared.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )

    application.registerForRemoteNotifications()

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    super.application(
      application,
      didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
    )

    #if DEBUG
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    print("🍎 APNS token received: \(token)")
    #endif
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    super.application(
      application,
      didFailToRegisterForRemoteNotificationsWithError: error
    )

    #if DEBUG
    print("❌ APNS registration failed: \(error.localizedDescription)")
    #endif
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    let facebookHandled = ApplicationDelegate.shared.application(
      app,
      open: url,
      sourceApplication: options[.sourceApplication] as? String,
      annotation: options[.annotation]
    )

    let flutterHandled = super.application(app, open: url, options: options)
    return facebookHandled || flutterHandled
  }

  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    let facebookHandled = ApplicationDelegate.shared.application(
      application,
      continue: userActivity
    )

    let flutterHandled = super.application(
      application,
      continue: userActivity,
      restorationHandler: restorationHandler
    )

    return facebookHandled || flutterHandled
  }

  private func getGoogleMapsApiKey() -> String {
    let bundleId = Bundle.main.bundleIdentifier ?? ""
    
    switch bundleId {
    case "com.tosembanda.wegig.dev", "com.wegig.wegig.dev":
      return "AIzaSyADjXo-1miAGtoCVRR1702AjtiyoeSdsMA"
    case "com.tosembanda.wegig.staging", "com.wegig.wegig.staging":
      return "AIzaSyBcR84Clf81XicGgxCM77mO7qqt1Np87cg"
    case "com.tosembanda.wegig", "com.wegig.wegig":
      return "AIzaSyAe_WwvD3nN-VJlMZf2L_BRpIx-ne3P_-0"
    default:
      #if DEBUG
      print("⚠️ Unknown bundle ID: \(bundleId), using production API key")
      #endif
      return "AIzaSyAe_WwvD3nN-VJlMZf2L_BRpIx-ne3P_-0"
    }
  }
}
