import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/settings/domain/entities/user_settings_entity.dart';
import 'package:flutter/foundation.dart';

/// Interface for settings remote data source
abstract class ISettingsRemoteDataSource {
  Future<UserSettingsEntity> getSettings(String profileId);
  Future<void> updateSettings(UserSettingsEntity settings);
}

/// Remote data source for user settings using Firestore
class SettingsRemoteDataSource implements ISettingsRemoteDataSource {
  SettingsRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<UserSettingsEntity> getSettings(String profileId) async {
    try {
      debugPrint('🔍 SettingsDataSource: getSettings for profile $profileId');

      final doc =
          await _firestore.collection('profiles').doc(profileId).get();

      if (!doc.exists) {
        debugPrint('⚠️ SettingsDataSource: Profile $profileId not found');
        // Return default settings
        return UserSettingsEntity(profileId: profileId);
      }

      final data = doc.data()!;
      final settings = UserSettingsEntity(
        profileId: profileId,
        notifyNearbyPosts: data['notificationRadiusEnabled'] as bool? ?? true,
        nearbyRadiusKm:
            ((data['notificationRadius'] as num?) ?? 20.0).toDouble(),
        // ✅ FIX: Carregar notifyInterests e notifyMessages do Firestore
        notifyInterests: data['notifyInterests'] as bool? ?? true,
        notifyMessages: data['notifyMessages'] as bool? ?? true,
        allowConnectionSuggestions:
          data['allowConnectionSuggestions'] as bool? ?? true,
        allowConnectionRequests:
          data['allowConnectionRequests'] as bool? ?? true,
      );

      debugPrint('✅ SettingsDataSource: Settings loaded');
      return settings;
    } catch (e) {
      debugPrint('❌ SettingsDataSource: Error getting settings - $e');
      rethrow;
    }
  }

  @override
  Future<void> updateSettings(UserSettingsEntity settings) async {
    try {
      debugPrint(
          '📝 SettingsDataSource: updateSettings for profile ${settings.profileId}');

      // 🔒 Clamp radius to [5, 100] km to guarantee valid range
      final clampedRadius = settings.nearbyRadiusKm.clamp(5.0, 100.0);

      await _firestore
          .collection('profiles')
          .doc(settings.profileId)
          .update({
        'notificationRadiusEnabled': settings.notifyNearbyPosts,
        'notificationRadius': clampedRadius,
        // ✅ FIX: Persistir notifyInterests e notifyMessages no Firestore
        'notifyInterests': settings.notifyInterests,
        'notifyMessages': settings.notifyMessages,
        'allowConnectionSuggestions': settings.allowConnectionSuggestions,
        'allowConnectionRequests': settings.allowConnectionRequests,
        'profileUid': settings.profileId, // CRITICAL: Isolamento de perfil
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ SettingsDataSource: Settings updated');
    } catch (e) {
      debugPrint('❌ SettingsDataSource: Error updating settings - $e');
      rethrow;
    }
  }
}
