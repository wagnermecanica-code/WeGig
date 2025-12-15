import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

String _mask(String value) {
  if (value.isEmpty) {
    return '***';
  }
  final visible = value.length <= 6 ? value : value.substring(0, 6);
  return '$visible***';
}

/// Logs the Firebase options for a given flavor (debug builds only).
void logFirebaseOptions({
  required String flavor,
  required FirebaseOptions options,
  String? expectedProjectId,
}) {
  assert(flavor.isNotEmpty, 'Flavor label is required');
  if (!kDebugMode) return;

  debugPrint(
    '🔥 Firebase[$flavor] projectId=${options.projectId} | appId=${options.appId}',
  );
  debugPrint(
    '   iosBundleId=${options.iosBundleId ?? '-'} | apiKey=${_mask(options.apiKey)}',
  );

  if (expectedProjectId != null && options.projectId != expectedProjectId) {
    debugPrint(
      '⚠️ Firebase[$flavor] expected projectId=$expectedProjectId but got ${options.projectId}',
    );
  }
}
