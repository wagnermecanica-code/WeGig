import 'package:core_ui/features/settings/domain/entities/user_settings_entity.dart';

/// Repository interface for user settings
abstract class SettingsRepository {
  /// Get settings for a profile
  Future<UserSettingsEntity> getSettings(String profileId);

  /// Update notification settings
  Future<void> updateSettings(UserSettingsEntity settings);
}
