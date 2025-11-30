import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_settings_entity.freezed.dart';

/// User settings entity for notification preferences
@freezed
class UserSettingsEntity with _$UserSettingsEntity {
  const factory UserSettingsEntity({
    required String profileId,
    @Default(true) bool notifyInterests,
    @Default(true) bool notifyMessages,
    @Default(true) bool notifyNearbyPosts,
    @Default(20.0) double nearbyRadiusKm,
  }) = _UserSettingsEntity;
}
