import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service to track TikTok App Events via native SDK (Android).
/// iOS: TikTok events are handled natively via the TikTok iOS SDK.
class TikTokService {
  TikTokService._();
  static final TikTokService instance = TikTokService._();
  static const bool _isEnabled = false;

  static const _channel = MethodChannel('com.wegig.wegig/tiktok');

  /// Track a standard TikTok event by name.
  Future<void> trackEvent(String eventName) async {
    if (!_isEnabled || !Platform.isAndroid) {
      debugPrint('⚠️ TikTok trackEvent skipped: SDK disabled');
      return;
    }
    try {
      await _channel.invokeMethod('trackEvent', {'eventName': eventName});
    } on PlatformException catch (e) {
      debugPrint('⚠️ TikTok trackEvent error: ${e.message}');
    }
  }

  /// Identify the current user for TikTok attribution.
  Future<void> identify({
    required String externalId,
    String userName = '',
    String phone = '',
    String email = '',
  }) async {
    if (!_isEnabled || !Platform.isAndroid) {
      debugPrint('⚠️ TikTok identify skipped: SDK disabled');
      return;
    }
    try {
      await _channel.invokeMethod('identify', {
        'externalId': externalId,
        'userName': userName,
        'phone': phone,
        'email': email,
      });
    } on PlatformException catch (e) {
      debugPrint('⚠️ TikTok identify error: ${e.message}');
    }
  }

  // Standard event helpers
  Future<void> trackLaunchApp() => trackEvent('LaunchAPP');
  Future<void> trackRegistration() => trackEvent('Registration');
  Future<void> trackLogin() => trackEvent('Login');
  Future<void> trackSearch() => trackEvent('Search');
  Future<void> trackViewContent() => trackEvent('ViewContent');
  Future<void> trackJoinGroup() => trackEvent('JoinGroup');
  Future<void> trackCreateGroup() => trackEvent('CreateGroup');
  Future<void> trackGenerateLead() => trackEvent('GenerateLead');
  Future<void> trackCompleteTutorial() => trackEvent('CompleteTutorial');
  Future<void> trackRate() => trackEvent('Rate');
}
