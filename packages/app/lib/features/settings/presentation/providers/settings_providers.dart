import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/settings/domain/entities/user_settings_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wegig_app/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:wegig_app/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:wegig_app/features/settings/domain/repositories/settings_repository.dart';

part 'settings_providers.g.dart';

// ============================================================================
// DATA LAYER PROVIDERS
// ============================================================================

/// Provider para FirebaseFirestore instance
@riverpod
FirebaseFirestore firestore(Ref ref) {
  return FirebaseFirestore.instance;
}

/// Provider para SettingsRemoteDataSource
@riverpod
ISettingsRemoteDataSource settingsRemoteDataSource(Ref ref) {
  return SettingsRemoteDataSource();
}

/// Provider para SettingsRepository
@riverpod
SettingsRepository settingsRepository(Ref ref) {
  final dataSource = ref.watch(settingsRemoteDataSourceProvider);
  return SettingsRepositoryImpl(remoteDataSource: dataSource);
}

// ============================================================================
// STATE PROVIDER
// ============================================================================

/// Provider for user settings with AsyncNotifier
@riverpod
class UserSettings extends _$UserSettings {
  @override
  Future<UserSettingsEntity?> build() async {
    // Initially return null (no profile selected)
    return null;
  }

  /// Load settings for a profile
  Future<void> loadSettings(String profileId) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final repository = ref.read(settingsRepositoryProvider);
      return repository.getSettings(profileId);
    });
  }

  /// Update notification settings
  Future<void> updateSettings(UserSettingsEntity settings) async {
    // Optimistically update UI
    state = AsyncValue.data(settings);

    // Persist to Firestore
    await AsyncValue.guard(() async {
      final repository = ref.read(settingsRepositoryProvider);
      await repository.updateSettings(settings);
    });
  }

  /// Update single field helpers
  Future<void> toggleNotifyInterests(bool value) async {
    final current = state.value;
    if (current == null) return;
    await updateSettings(current.copyWith(notifyInterests: value));
  }

  Future<void> toggleNotifyMessages(bool value) async {
    final current = state.value;
    if (current == null) return;
    await updateSettings(current.copyWith(notifyMessages: value));
  }

  Future<void> toggleNotifyNearbyPosts(bool value) async {
    final current = state.value;
    if (current == null) return;
    await updateSettings(current.copyWith(notifyNearbyPosts: value));
  }

  Future<void> updateNearbyRadius(double value) async {
    final current = state.value;
    if (current == null) return;
    await updateSettings(current.copyWith(nearbyRadiusKm: value));
  }
}
