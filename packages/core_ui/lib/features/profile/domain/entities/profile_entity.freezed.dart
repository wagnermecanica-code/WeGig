// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ProfileEntity _$ProfileEntityFromJson(Map<String, dynamic> json) {
  return _ProfileEntity.fromJson(json);
}

/// @nodoc
mixin _$ProfileEntity {
  String get profileId => throw _privateConstructorUsedError;
  String get uid => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get username => throw _privateConstructorUsedError;
  bool get isBand => throw _privateConstructorUsedError;
  String get city => throw _privateConstructorUsedError;
  @GeoPointConverter()
  GeoPoint get location => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  double get notificationRadius => throw _privateConstructorUsedError;
  bool get notificationRadiusEnabled => throw _privateConstructorUsedError;
  String? get photoUrl => throw _privateConstructorUsedError;
  int? get birthYear => throw _privateConstructorUsedError;
  String? get bio => throw _privateConstructorUsedError;
  List<String>? get instruments => throw _privateConstructorUsedError;
  List<String>? get genres => throw _privateConstructorUsedError;
  String? get level => throw _privateConstructorUsedError;
  String? get instagramLink => throw _privateConstructorUsedError;
  String? get tiktokLink => throw _privateConstructorUsedError;
  String? get youtubeLink => throw _privateConstructorUsedError;
  String? get neighborhood => throw _privateConstructorUsedError;
  String? get state => throw _privateConstructorUsedError;
  List<String>? get bandMembers => throw _privateConstructorUsedError;
  @NullableTimestampConverter()
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this ProfileEntity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProfileEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProfileEntityCopyWith<ProfileEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProfileEntityCopyWith<$Res> {
  factory $ProfileEntityCopyWith(
          ProfileEntity value, $Res Function(ProfileEntity) then) =
      _$ProfileEntityCopyWithImpl<$Res, ProfileEntity>;
  @useResult
  $Res call(
      {String profileId,
      String uid,
      String name,
      String? username,
      bool isBand,
      String city,
      @GeoPointConverter() GeoPoint location,
      @TimestampConverter() DateTime createdAt,
      double notificationRadius,
      bool notificationRadiusEnabled,
      String? photoUrl,
      int? birthYear,
      String? bio,
      List<String>? instruments,
      List<String>? genres,
      String? level,
      String? instagramLink,
      String? tiktokLink,
      String? youtubeLink,
      String? neighborhood,
      String? state,
      List<String>? bandMembers,
      @NullableTimestampConverter() DateTime? updatedAt});
}

/// @nodoc
class _$ProfileEntityCopyWithImpl<$Res, $Val extends ProfileEntity>
    implements $ProfileEntityCopyWith<$Res> {
  _$ProfileEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProfileEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? profileId = null,
    Object? uid = null,
    Object? name = null,
    Object? username = freezed,
    Object? isBand = null,
    Object? city = null,
    Object? location = null,
    Object? createdAt = null,
    Object? notificationRadius = null,
    Object? notificationRadiusEnabled = null,
    Object? photoUrl = freezed,
    Object? birthYear = freezed,
    Object? bio = freezed,
    Object? instruments = freezed,
    Object? genres = freezed,
    Object? level = freezed,
    Object? instagramLink = freezed,
    Object? tiktokLink = freezed,
    Object? youtubeLink = freezed,
    Object? neighborhood = freezed,
    Object? state = freezed,
    Object? bandMembers = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      profileId: null == profileId
          ? _value.profileId
          : profileId // ignore: cast_nullable_to_non_nullable
              as String,
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      username: freezed == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String?,
      isBand: null == isBand
          ? _value.isBand
          : isBand // ignore: cast_nullable_to_non_nullable
              as bool,
      city: null == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String,
      location: null == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as GeoPoint,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      notificationRadius: null == notificationRadius
          ? _value.notificationRadius
          : notificationRadius // ignore: cast_nullable_to_non_nullable
              as double,
      notificationRadiusEnabled: null == notificationRadiusEnabled
          ? _value.notificationRadiusEnabled
          : notificationRadiusEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      birthYear: freezed == birthYear
          ? _value.birthYear
          : birthYear // ignore: cast_nullable_to_non_nullable
              as int?,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      instruments: freezed == instruments
          ? _value.instruments
          : instruments // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      genres: freezed == genres
          ? _value.genres
          : genres // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      level: freezed == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as String?,
      instagramLink: freezed == instagramLink
          ? _value.instagramLink
          : instagramLink // ignore: cast_nullable_to_non_nullable
              as String?,
      tiktokLink: freezed == tiktokLink
          ? _value.tiktokLink
          : tiktokLink // ignore: cast_nullable_to_non_nullable
              as String?,
      youtubeLink: freezed == youtubeLink
          ? _value.youtubeLink
          : youtubeLink // ignore: cast_nullable_to_non_nullable
              as String?,
      neighborhood: freezed == neighborhood
          ? _value.neighborhood
          : neighborhood // ignore: cast_nullable_to_non_nullable
              as String?,
      state: freezed == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String?,
      bandMembers: freezed == bandMembers
          ? _value.bandMembers
          : bandMembers // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProfileEntityImplCopyWith<$Res>
    implements $ProfileEntityCopyWith<$Res> {
  factory _$$ProfileEntityImplCopyWith(
          _$ProfileEntityImpl value, $Res Function(_$ProfileEntityImpl) then) =
      __$$ProfileEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String profileId,
      String uid,
      String name,
      String? username,
      bool isBand,
      String city,
      @GeoPointConverter() GeoPoint location,
      @TimestampConverter() DateTime createdAt,
      double notificationRadius,
      bool notificationRadiusEnabled,
      String? photoUrl,
      int? birthYear,
      String? bio,
      List<String>? instruments,
      List<String>? genres,
      String? level,
      String? instagramLink,
      String? tiktokLink,
      String? youtubeLink,
      String? neighborhood,
      String? state,
      List<String>? bandMembers,
      @NullableTimestampConverter() DateTime? updatedAt});
}

/// @nodoc
class __$$ProfileEntityImplCopyWithImpl<$Res>
    extends _$ProfileEntityCopyWithImpl<$Res, _$ProfileEntityImpl>
    implements _$$ProfileEntityImplCopyWith<$Res> {
  __$$ProfileEntityImplCopyWithImpl(
      _$ProfileEntityImpl _value, $Res Function(_$ProfileEntityImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProfileEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? profileId = null,
    Object? uid = null,
    Object? name = null,
    Object? username = freezed,
    Object? isBand = null,
    Object? city = null,
    Object? location = null,
    Object? createdAt = null,
    Object? notificationRadius = null,
    Object? notificationRadiusEnabled = null,
    Object? photoUrl = freezed,
    Object? birthYear = freezed,
    Object? bio = freezed,
    Object? instruments = freezed,
    Object? genres = freezed,
    Object? level = freezed,
    Object? instagramLink = freezed,
    Object? tiktokLink = freezed,
    Object? youtubeLink = freezed,
    Object? neighborhood = freezed,
    Object? state = freezed,
    Object? bandMembers = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$ProfileEntityImpl(
      profileId: null == profileId
          ? _value.profileId
          : profileId // ignore: cast_nullable_to_non_nullable
              as String,
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      username: freezed == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String?,
      isBand: null == isBand
          ? _value.isBand
          : isBand // ignore: cast_nullable_to_non_nullable
              as bool,
      city: null == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String,
      location: null == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as GeoPoint,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      notificationRadius: null == notificationRadius
          ? _value.notificationRadius
          : notificationRadius // ignore: cast_nullable_to_non_nullable
              as double,
      notificationRadiusEnabled: null == notificationRadiusEnabled
          ? _value.notificationRadiusEnabled
          : notificationRadiusEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      birthYear: freezed == birthYear
          ? _value.birthYear
          : birthYear // ignore: cast_nullable_to_non_nullable
              as int?,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      instruments: freezed == instruments
          ? _value._instruments
          : instruments // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      genres: freezed == genres
          ? _value._genres
          : genres // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      level: freezed == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as String?,
      instagramLink: freezed == instagramLink
          ? _value.instagramLink
          : instagramLink // ignore: cast_nullable_to_non_nullable
              as String?,
      tiktokLink: freezed == tiktokLink
          ? _value.tiktokLink
          : tiktokLink // ignore: cast_nullable_to_non_nullable
              as String?,
      youtubeLink: freezed == youtubeLink
          ? _value.youtubeLink
          : youtubeLink // ignore: cast_nullable_to_non_nullable
              as String?,
      neighborhood: freezed == neighborhood
          ? _value.neighborhood
          : neighborhood // ignore: cast_nullable_to_non_nullable
              as String?,
      state: freezed == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String?,
      bandMembers: freezed == bandMembers
          ? _value._bandMembers
          : bandMembers // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProfileEntityImpl extends _ProfileEntity {
  const _$ProfileEntityImpl(
      {required this.profileId,
      required this.uid,
      required this.name,
      this.username,
      required this.isBand,
      required this.city,
      @GeoPointConverter() required this.location,
      @TimestampConverter() required this.createdAt,
      this.notificationRadius = 20.0,
      this.notificationRadiusEnabled = true,
      this.photoUrl,
      this.birthYear,
      this.bio,
      final List<String>? instruments,
      final List<String>? genres,
      this.level,
      this.instagramLink,
      this.tiktokLink,
      this.youtubeLink,
      this.neighborhood,
      this.state,
      final List<String>? bandMembers,
      @NullableTimestampConverter() this.updatedAt})
      : _instruments = instruments,
        _genres = genres,
        _bandMembers = bandMembers,
        super._();

  factory _$ProfileEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProfileEntityImplFromJson(json);

  @override
  final String profileId;
  @override
  final String uid;
  @override
  final String name;
  @override
  final String? username;
  @override
  final bool isBand;
  @override
  final String city;
  @override
  @GeoPointConverter()
  final GeoPoint location;
  @override
  @TimestampConverter()
  final DateTime createdAt;
  @override
  @JsonKey()
  final double notificationRadius;
  @override
  @JsonKey()
  final bool notificationRadiusEnabled;
  @override
  final String? photoUrl;
  @override
  final int? birthYear;
  @override
  final String? bio;
  final List<String>? _instruments;
  @override
  List<String>? get instruments {
    final value = _instruments;
    if (value == null) return null;
    if (_instruments is EqualUnmodifiableListView) return _instruments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _genres;
  @override
  List<String>? get genres {
    final value = _genres;
    if (value == null) return null;
    if (_genres is EqualUnmodifiableListView) return _genres;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? level;
  @override
  final String? instagramLink;
  @override
  final String? tiktokLink;
  @override
  final String? youtubeLink;
  @override
  final String? neighborhood;
  @override
  final String? state;
  final List<String>? _bandMembers;
  @override
  List<String>? get bandMembers {
    final value = _bandMembers;
    if (value == null) return null;
    if (_bandMembers is EqualUnmodifiableListView) return _bandMembers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @NullableTimestampConverter()
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'ProfileEntity(profileId: $profileId, uid: $uid, name: $name, username: $username, isBand: $isBand, city: $city, location: $location, createdAt: $createdAt, notificationRadius: $notificationRadius, notificationRadiusEnabled: $notificationRadiusEnabled, photoUrl: $photoUrl, birthYear: $birthYear, bio: $bio, instruments: $instruments, genres: $genres, level: $level, instagramLink: $instagramLink, tiktokLink: $tiktokLink, youtubeLink: $youtubeLink, neighborhood: $neighborhood, state: $state, bandMembers: $bandMembers, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProfileEntityImpl &&
            (identical(other.profileId, profileId) ||
                other.profileId == profileId) &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.isBand, isBand) || other.isBand == isBand) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.notificationRadius, notificationRadius) ||
                other.notificationRadius == notificationRadius) &&
            (identical(other.notificationRadiusEnabled,
                    notificationRadiusEnabled) ||
                other.notificationRadiusEnabled == notificationRadiusEnabled) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.birthYear, birthYear) ||
                other.birthYear == birthYear) &&
            (identical(other.bio, bio) || other.bio == bio) &&
            const DeepCollectionEquality()
                .equals(other._instruments, _instruments) &&
            const DeepCollectionEquality().equals(other._genres, _genres) &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.instagramLink, instagramLink) ||
                other.instagramLink == instagramLink) &&
            (identical(other.tiktokLink, tiktokLink) ||
                other.tiktokLink == tiktokLink) &&
            (identical(other.youtubeLink, youtubeLink) ||
                other.youtubeLink == youtubeLink) &&
            (identical(other.neighborhood, neighborhood) ||
                other.neighborhood == neighborhood) &&
            (identical(other.state, state) || other.state == state) &&
            const DeepCollectionEquality()
                .equals(other._bandMembers, _bandMembers) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        profileId,
        uid,
        name,
        username,
        isBand,
        city,
        location,
        createdAt,
        notificationRadius,
        notificationRadiusEnabled,
        photoUrl,
        birthYear,
        bio,
        const DeepCollectionEquality().hash(_instruments),
        const DeepCollectionEquality().hash(_genres),
        level,
        instagramLink,
        tiktokLink,
        youtubeLink,
        neighborhood,
        state,
        const DeepCollectionEquality().hash(_bandMembers),
        updatedAt
      ]);

  /// Create a copy of ProfileEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProfileEntityImplCopyWith<_$ProfileEntityImpl> get copyWith =>
      __$$ProfileEntityImplCopyWithImpl<_$ProfileEntityImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProfileEntityImplToJson(
      this,
    );
  }
}

abstract class _ProfileEntity extends ProfileEntity {
  const factory _ProfileEntity(
          {required final String profileId,
          required final String uid,
          required final String name,
          final String? username,
          required final bool isBand,
          required final String city,
          @GeoPointConverter() required final GeoPoint location,
          @TimestampConverter() required final DateTime createdAt,
          final double notificationRadius,
          final bool notificationRadiusEnabled,
          final String? photoUrl,
          final int? birthYear,
          final String? bio,
          final List<String>? instruments,
          final List<String>? genres,
          final String? level,
          final String? instagramLink,
          final String? tiktokLink,
          final String? youtubeLink,
          final String? neighborhood,
          final String? state,
          final List<String>? bandMembers,
          @NullableTimestampConverter() final DateTime? updatedAt}) =
      _$ProfileEntityImpl;
  const _ProfileEntity._() : super._();

  factory _ProfileEntity.fromJson(Map<String, dynamic> json) =
      _$ProfileEntityImpl.fromJson;

  @override
  String get profileId;
  @override
  String get uid;
  @override
  String get name;
  @override
  String? get username;
  @override
  bool get isBand;
  @override
  String get city;
  @override
  @GeoPointConverter()
  GeoPoint get location;
  @override
  @TimestampConverter()
  DateTime get createdAt;
  @override
  double get notificationRadius;
  @override
  bool get notificationRadiusEnabled;
  @override
  String? get photoUrl;
  @override
  int? get birthYear;
  @override
  String? get bio;
  @override
  List<String>? get instruments;
  @override
  List<String>? get genres;
  @override
  String? get level;
  @override
  String? get instagramLink;
  @override
  String? get tiktokLink;
  @override
  String? get youtubeLink;
  @override
  String? get neighborhood;
  @override
  String? get state;
  @override
  List<String>? get bandMembers;
  @override
  @NullableTimestampConverter()
  DateTime? get updatedAt;

  /// Create a copy of ProfileEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProfileEntityImplCopyWith<_$ProfileEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
