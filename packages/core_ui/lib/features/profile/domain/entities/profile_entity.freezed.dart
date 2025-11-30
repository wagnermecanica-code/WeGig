// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProfileEntity {
  String get profileId;
  String get uid;
  String get name;
  bool get isBand;
  String get city;
  @GeoPointConverter()
  GeoPoint get location;
  @TimestampConverter()
  DateTime get createdAt;
  double get notificationRadius;
  bool get notificationRadiusEnabled;
  String? get photoUrl;
  int? get birthYear;
  String? get bio;
  List<String>? get instruments;
  List<String>? get genres;
  String? get level;
  String? get instagramLink;
  String? get tiktokLink;
  String? get youtubeLink;
  String? get neighborhood;
  String? get state;
  List<String>? get bandMembers;
  @NullableTimestampConverter()
  DateTime? get updatedAt;

  /// Create a copy of ProfileEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ProfileEntityCopyWith<ProfileEntity> get copyWith =>
      _$ProfileEntityCopyWithImpl<ProfileEntity>(
          this as ProfileEntity, _$identity);

  /// Serializes this ProfileEntity to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ProfileEntity &&
            (identical(other.profileId, profileId) ||
                other.profileId == profileId) &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.name, name) || other.name == name) &&
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
                .equals(other.instruments, instruments) &&
            const DeepCollectionEquality().equals(other.genres, genres) &&
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
                .equals(other.bandMembers, bandMembers) &&
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
        isBand,
        city,
        location,
        createdAt,
        notificationRadius,
        notificationRadiusEnabled,
        photoUrl,
        birthYear,
        bio,
        const DeepCollectionEquality().hash(instruments),
        const DeepCollectionEquality().hash(genres),
        level,
        instagramLink,
        tiktokLink,
        youtubeLink,
        neighborhood,
        state,
        const DeepCollectionEquality().hash(bandMembers),
        updatedAt
      ]);

  @override
  String toString() {
    return 'ProfileEntity(profileId: $profileId, uid: $uid, name: $name, isBand: $isBand, city: $city, location: $location, createdAt: $createdAt, notificationRadius: $notificationRadius, notificationRadiusEnabled: $notificationRadiusEnabled, photoUrl: $photoUrl, birthYear: $birthYear, bio: $bio, instruments: $instruments, genres: $genres, level: $level, instagramLink: $instagramLink, tiktokLink: $tiktokLink, youtubeLink: $youtubeLink, neighborhood: $neighborhood, state: $state, bandMembers: $bandMembers, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $ProfileEntityCopyWith<$Res> {
  factory $ProfileEntityCopyWith(
          ProfileEntity value, $Res Function(ProfileEntity) _then) =
      _$ProfileEntityCopyWithImpl;
  @useResult
  $Res call(
      {String profileId,
      String uid,
      String name,
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
class _$ProfileEntityCopyWithImpl<$Res>
    implements $ProfileEntityCopyWith<$Res> {
  _$ProfileEntityCopyWithImpl(this._self, this._then);

  final ProfileEntity _self;
  final $Res Function(ProfileEntity) _then;

  /// Create a copy of ProfileEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? profileId = null,
    Object? uid = null,
    Object? name = null,
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
    return _then(_self.copyWith(
      profileId: null == profileId
          ? _self.profileId
          : profileId // ignore: cast_nullable_to_non_nullable
              as String,
      uid: null == uid
          ? _self.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      isBand: null == isBand
          ? _self.isBand
          : isBand // ignore: cast_nullable_to_non_nullable
              as bool,
      city: null == city
          ? _self.city
          : city // ignore: cast_nullable_to_non_nullable
              as String,
      location: null == location
          ? _self.location
          : location // ignore: cast_nullable_to_non_nullable
              as GeoPoint,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      notificationRadius: null == notificationRadius
          ? _self.notificationRadius
          : notificationRadius // ignore: cast_nullable_to_non_nullable
              as double,
      notificationRadiusEnabled: null == notificationRadiusEnabled
          ? _self.notificationRadiusEnabled
          : notificationRadiusEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      photoUrl: freezed == photoUrl
          ? _self.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      birthYear: freezed == birthYear
          ? _self.birthYear
          : birthYear // ignore: cast_nullable_to_non_nullable
              as int?,
      bio: freezed == bio
          ? _self.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      instruments: freezed == instruments
          ? _self.instruments
          : instruments // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      genres: freezed == genres
          ? _self.genres
          : genres // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      level: freezed == level
          ? _self.level
          : level // ignore: cast_nullable_to_non_nullable
              as String?,
      instagramLink: freezed == instagramLink
          ? _self.instagramLink
          : instagramLink // ignore: cast_nullable_to_non_nullable
              as String?,
      tiktokLink: freezed == tiktokLink
          ? _self.tiktokLink
          : tiktokLink // ignore: cast_nullable_to_non_nullable
              as String?,
      youtubeLink: freezed == youtubeLink
          ? _self.youtubeLink
          : youtubeLink // ignore: cast_nullable_to_non_nullable
              as String?,
      neighborhood: freezed == neighborhood
          ? _self.neighborhood
          : neighborhood // ignore: cast_nullable_to_non_nullable
              as String?,
      state: freezed == state
          ? _self.state
          : state // ignore: cast_nullable_to_non_nullable
              as String?,
      bandMembers: freezed == bandMembers
          ? _self.bandMembers
          : bandMembers // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// Adds pattern-matching-related methods to [ProfileEntity].
extension ProfileEntityPatterns on ProfileEntity {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ProfileEntity value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ProfileEntity() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ProfileEntity value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProfileEntity():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ProfileEntity value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProfileEntity() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String profileId,
            String uid,
            String name,
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
            @NullableTimestampConverter() DateTime? updatedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ProfileEntity() when $default != null:
        return $default(
            _that.profileId,
            _that.uid,
            _that.name,
            _that.isBand,
            _that.city,
            _that.location,
            _that.createdAt,
            _that.notificationRadius,
            _that.notificationRadiusEnabled,
            _that.photoUrl,
            _that.birthYear,
            _that.bio,
            _that.instruments,
            _that.genres,
            _that.level,
            _that.instagramLink,
            _that.tiktokLink,
            _that.youtubeLink,
            _that.neighborhood,
            _that.state,
            _that.bandMembers,
            _that.updatedAt);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String profileId,
            String uid,
            String name,
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
            @NullableTimestampConverter() DateTime? updatedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProfileEntity():
        return $default(
            _that.profileId,
            _that.uid,
            _that.name,
            _that.isBand,
            _that.city,
            _that.location,
            _that.createdAt,
            _that.notificationRadius,
            _that.notificationRadiusEnabled,
            _that.photoUrl,
            _that.birthYear,
            _that.bio,
            _that.instruments,
            _that.genres,
            _that.level,
            _that.instagramLink,
            _that.tiktokLink,
            _that.youtubeLink,
            _that.neighborhood,
            _that.state,
            _that.bandMembers,
            _that.updatedAt);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String profileId,
            String uid,
            String name,
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
            @NullableTimestampConverter() DateTime? updatedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ProfileEntity() when $default != null:
        return $default(
            _that.profileId,
            _that.uid,
            _that.name,
            _that.isBand,
            _that.city,
            _that.location,
            _that.createdAt,
            _that.notificationRadius,
            _that.notificationRadiusEnabled,
            _that.photoUrl,
            _that.birthYear,
            _that.bio,
            _that.instruments,
            _that.genres,
            _that.level,
            _that.instagramLink,
            _that.tiktokLink,
            _that.youtubeLink,
            _that.neighborhood,
            _that.state,
            _that.bandMembers,
            _that.updatedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ProfileEntity extends ProfileEntity {
  const _ProfileEntity(
      {required this.profileId,
      required this.uid,
      required this.name,
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
  factory _ProfileEntity.fromJson(Map<String, dynamic> json) =>
      _$ProfileEntityFromJson(json);

  @override
  final String profileId;
  @override
  final String uid;
  @override
  final String name;
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

  /// Create a copy of ProfileEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ProfileEntityCopyWith<_ProfileEntity> get copyWith =>
      __$ProfileEntityCopyWithImpl<_ProfileEntity>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ProfileEntityToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ProfileEntity &&
            (identical(other.profileId, profileId) ||
                other.profileId == profileId) &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.name, name) || other.name == name) &&
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

  @override
  String toString() {
    return 'ProfileEntity(profileId: $profileId, uid: $uid, name: $name, isBand: $isBand, city: $city, location: $location, createdAt: $createdAt, notificationRadius: $notificationRadius, notificationRadiusEnabled: $notificationRadiusEnabled, photoUrl: $photoUrl, birthYear: $birthYear, bio: $bio, instruments: $instruments, genres: $genres, level: $level, instagramLink: $instagramLink, tiktokLink: $tiktokLink, youtubeLink: $youtubeLink, neighborhood: $neighborhood, state: $state, bandMembers: $bandMembers, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$ProfileEntityCopyWith<$Res>
    implements $ProfileEntityCopyWith<$Res> {
  factory _$ProfileEntityCopyWith(
          _ProfileEntity value, $Res Function(_ProfileEntity) _then) =
      __$ProfileEntityCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String profileId,
      String uid,
      String name,
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
class __$ProfileEntityCopyWithImpl<$Res>
    implements _$ProfileEntityCopyWith<$Res> {
  __$ProfileEntityCopyWithImpl(this._self, this._then);

  final _ProfileEntity _self;
  final $Res Function(_ProfileEntity) _then;

  /// Create a copy of ProfileEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? profileId = null,
    Object? uid = null,
    Object? name = null,
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
    return _then(_ProfileEntity(
      profileId: null == profileId
          ? _self.profileId
          : profileId // ignore: cast_nullable_to_non_nullable
              as String,
      uid: null == uid
          ? _self.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      isBand: null == isBand
          ? _self.isBand
          : isBand // ignore: cast_nullable_to_non_nullable
              as bool,
      city: null == city
          ? _self.city
          : city // ignore: cast_nullable_to_non_nullable
              as String,
      location: null == location
          ? _self.location
          : location // ignore: cast_nullable_to_non_nullable
              as GeoPoint,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      notificationRadius: null == notificationRadius
          ? _self.notificationRadius
          : notificationRadius // ignore: cast_nullable_to_non_nullable
              as double,
      notificationRadiusEnabled: null == notificationRadiusEnabled
          ? _self.notificationRadiusEnabled
          : notificationRadiusEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      photoUrl: freezed == photoUrl
          ? _self.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      birthYear: freezed == birthYear
          ? _self.birthYear
          : birthYear // ignore: cast_nullable_to_non_nullable
              as int?,
      bio: freezed == bio
          ? _self.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      instruments: freezed == instruments
          ? _self._instruments
          : instruments // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      genres: freezed == genres
          ? _self._genres
          : genres // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      level: freezed == level
          ? _self.level
          : level // ignore: cast_nullable_to_non_nullable
              as String?,
      instagramLink: freezed == instagramLink
          ? _self.instagramLink
          : instagramLink // ignore: cast_nullable_to_non_nullable
              as String?,
      tiktokLink: freezed == tiktokLink
          ? _self.tiktokLink
          : tiktokLink // ignore: cast_nullable_to_non_nullable
              as String?,
      youtubeLink: freezed == youtubeLink
          ? _self.youtubeLink
          : youtubeLink // ignore: cast_nullable_to_non_nullable
              as String?,
      neighborhood: freezed == neighborhood
          ? _self.neighborhood
          : neighborhood // ignore: cast_nullable_to_non_nullable
              as String?,
      state: freezed == state
          ? _self.state
          : state // ignore: cast_nullable_to_non_nullable
              as String?,
      bandMembers: freezed == bandMembers
          ? _self._bandMembers
          : bandMembers // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
