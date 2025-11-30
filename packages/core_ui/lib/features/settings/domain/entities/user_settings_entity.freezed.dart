// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_settings_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$UserSettingsEntity {
  String get profileId => throw _privateConstructorUsedError;
  bool get notifyInterests => throw _privateConstructorUsedError;
  bool get notifyMessages => throw _privateConstructorUsedError;
  bool get notifyNearbyPosts => throw _privateConstructorUsedError;
  double get nearbyRadiusKm => throw _privateConstructorUsedError;

  /// Create a copy of UserSettingsEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserSettingsEntityCopyWith<UserSettingsEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserSettingsEntityCopyWith<$Res> {
  factory $UserSettingsEntityCopyWith(
          UserSettingsEntity value, $Res Function(UserSettingsEntity) then) =
      _$UserSettingsEntityCopyWithImpl<$Res, UserSettingsEntity>;
  @useResult
  $Res call(
      {String profileId,
      bool notifyInterests,
      bool notifyMessages,
      bool notifyNearbyPosts,
      double nearbyRadiusKm});
}

/// @nodoc
class _$UserSettingsEntityCopyWithImpl<$Res, $Val extends UserSettingsEntity>
    implements $UserSettingsEntityCopyWith<$Res> {
  _$UserSettingsEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserSettingsEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? profileId = null,
    Object? notifyInterests = null,
    Object? notifyMessages = null,
    Object? notifyNearbyPosts = null,
    Object? nearbyRadiusKm = null,
  }) {
    return _then(_value.copyWith(
      profileId: null == profileId
          ? _value.profileId
          : profileId // ignore: cast_nullable_to_non_nullable
              as String,
      notifyInterests: null == notifyInterests
          ? _value.notifyInterests
          : notifyInterests // ignore: cast_nullable_to_non_nullable
              as bool,
      notifyMessages: null == notifyMessages
          ? _value.notifyMessages
          : notifyMessages // ignore: cast_nullable_to_non_nullable
              as bool,
      notifyNearbyPosts: null == notifyNearbyPosts
          ? _value.notifyNearbyPosts
          : notifyNearbyPosts // ignore: cast_nullable_to_non_nullable
              as bool,
      nearbyRadiusKm: null == nearbyRadiusKm
          ? _value.nearbyRadiusKm
          : nearbyRadiusKm // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserSettingsEntityImplCopyWith<$Res>
    implements $UserSettingsEntityCopyWith<$Res> {
  factory _$$UserSettingsEntityImplCopyWith(_$UserSettingsEntityImpl value,
          $Res Function(_$UserSettingsEntityImpl) then) =
      __$$UserSettingsEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String profileId,
      bool notifyInterests,
      bool notifyMessages,
      bool notifyNearbyPosts,
      double nearbyRadiusKm});
}

/// @nodoc
class __$$UserSettingsEntityImplCopyWithImpl<$Res>
    extends _$UserSettingsEntityCopyWithImpl<$Res, _$UserSettingsEntityImpl>
    implements _$$UserSettingsEntityImplCopyWith<$Res> {
  __$$UserSettingsEntityImplCopyWithImpl(_$UserSettingsEntityImpl _value,
      $Res Function(_$UserSettingsEntityImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserSettingsEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? profileId = null,
    Object? notifyInterests = null,
    Object? notifyMessages = null,
    Object? notifyNearbyPosts = null,
    Object? nearbyRadiusKm = null,
  }) {
    return _then(_$UserSettingsEntityImpl(
      profileId: null == profileId
          ? _value.profileId
          : profileId // ignore: cast_nullable_to_non_nullable
              as String,
      notifyInterests: null == notifyInterests
          ? _value.notifyInterests
          : notifyInterests // ignore: cast_nullable_to_non_nullable
              as bool,
      notifyMessages: null == notifyMessages
          ? _value.notifyMessages
          : notifyMessages // ignore: cast_nullable_to_non_nullable
              as bool,
      notifyNearbyPosts: null == notifyNearbyPosts
          ? _value.notifyNearbyPosts
          : notifyNearbyPosts // ignore: cast_nullable_to_non_nullable
              as bool,
      nearbyRadiusKm: null == nearbyRadiusKm
          ? _value.nearbyRadiusKm
          : nearbyRadiusKm // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc

class _$UserSettingsEntityImpl implements _UserSettingsEntity {
  const _$UserSettingsEntityImpl(
      {required this.profileId,
      this.notifyInterests = true,
      this.notifyMessages = true,
      this.notifyNearbyPosts = true,
      this.nearbyRadiusKm = 20.0});

  @override
  final String profileId;
  @override
  @JsonKey()
  final bool notifyInterests;
  @override
  @JsonKey()
  final bool notifyMessages;
  @override
  @JsonKey()
  final bool notifyNearbyPosts;
  @override
  @JsonKey()
  final double nearbyRadiusKm;

  @override
  String toString() {
    return 'UserSettingsEntity(profileId: $profileId, notifyInterests: $notifyInterests, notifyMessages: $notifyMessages, notifyNearbyPosts: $notifyNearbyPosts, nearbyRadiusKm: $nearbyRadiusKm)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserSettingsEntityImpl &&
            (identical(other.profileId, profileId) ||
                other.profileId == profileId) &&
            (identical(other.notifyInterests, notifyInterests) ||
                other.notifyInterests == notifyInterests) &&
            (identical(other.notifyMessages, notifyMessages) ||
                other.notifyMessages == notifyMessages) &&
            (identical(other.notifyNearbyPosts, notifyNearbyPosts) ||
                other.notifyNearbyPosts == notifyNearbyPosts) &&
            (identical(other.nearbyRadiusKm, nearbyRadiusKm) ||
                other.nearbyRadiusKm == nearbyRadiusKm));
  }

  @override
  int get hashCode => Object.hash(runtimeType, profileId, notifyInterests,
      notifyMessages, notifyNearbyPosts, nearbyRadiusKm);

  /// Create a copy of UserSettingsEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserSettingsEntityImplCopyWith<_$UserSettingsEntityImpl> get copyWith =>
      __$$UserSettingsEntityImplCopyWithImpl<_$UserSettingsEntityImpl>(
          this, _$identity);
}

abstract class _UserSettingsEntity implements UserSettingsEntity {
  const factory _UserSettingsEntity(
      {required final String profileId,
      final bool notifyInterests,
      final bool notifyMessages,
      final bool notifyNearbyPosts,
      final double nearbyRadiusKm}) = _$UserSettingsEntityImpl;

  @override
  String get profileId;
  @override
  bool get notifyInterests;
  @override
  bool get notifyMessages;
  @override
  bool get notifyNearbyPosts;
  @override
  double get nearbyRadiusKm;

  /// Create a copy of UserSettingsEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserSettingsEntityImplCopyWith<_$UserSettingsEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
