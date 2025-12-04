import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wegig_app/bootstrap/bootstrap_core.dart';
import 'package:wegig_app/firebase_options_staging.dart';
import 'package:wegig_app/main.dart' show WeGigApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrapCoreServices(
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    flavorLabel: 'staging',
    expectedProjectId: 'to-sem-banda-staging',
    backgroundHandler: _firebaseMessagingBackgroundHandler,
    enableCrashlytics: true,
    printEnvOnDebug: false,
  );

  runApp(const ProviderScope(child: WeGigApp()));
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  debugPrint('📩 [staging] Background Message: ${message.messageId}');
  debugPrint('   Title: ${message.notification?.title}');
  debugPrint('   Body: ${message.notification?.body}');
  debugPrint('   Data: ${message.data}');
}
