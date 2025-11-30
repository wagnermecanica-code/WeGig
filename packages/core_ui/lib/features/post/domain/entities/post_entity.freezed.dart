// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'post_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PostEntity {
  String get id;
  String get authorProfileId;
  String get authorUid;
  String get content;
  @GeoPointConverter()
  GeoPoint get location;
  String get city;
  String get type;
  String get level;
  List<String> get instruments;
  List<String> get genres;
  List<String> get seekingMusicians;
  @TimestampConverter()
  DateTime get createdAt;
  @TimestampConverter()
  DateTime get expiresAt;
  String? get neighborhood;
  String? get state;
  String? get photoUrl;
  String? get youtubeLink;
  List<String> get availableFor;
  double? get distanceKm;

  /// Create a copy of PostEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PostEntityCopyWith<PostEntity> get copyWith =>
      _$PostEntityCopyWithImpl<PostEntity>(this as PostEntity, _$identity);

  /// Serializes this PostEntity to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PostEntity &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.authorProfileId, authorProfileId) ||
                other.authorProfileId == authorProfileId) &&
            (identical(other.authorUid, authorUid) ||
                other.authorUid == authorUid) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.level, level) || other.level == level) &&
            const DeepCollectionEquality()
                .equals(other.instruments, instruments) &&
            const DeepCollectionEquality().equals(other.genres, genres) &&
            const DeepCollectionEquality()
                .equals(other.seekingMusicians, seekingMusicians) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.neighborhood, neighborhood) ||
                other.neighborhood == neighborhood) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.youtubeLink, youtubeLink) ||
                other.youtubeLink == youtubeLink) &&
            const DeepCollectionEquality()
                .equals(other.availableFor, availableFor) &&
            (identical(other.distanceKm, distanceKm) ||
                other.distanceKm == distanceKm));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        authorProfileId,
        authorUid,
        content,
        location,
        city,
        type,
        level,
        const DeepCollectionEquality().hash(instruments),
        const DeepCollectionEquality().hash(genres),
        const DeepCollectionEquality().hash(seekingMusicians),
        createdAt,
        expiresAt,
        neighborhood,
        state,
        photoUrl,
        youtubeLink,
        const DeepCollectionEquality().hash(availableFor),
        distanceKm
      ]);

  @override
  String toString() {
    return 'PostEntity(id: $id, authorProfileId: $authorProfileId, authorUid: $authorUid, content: $content, location: $location, city: $city, type: $type, level: $level, instruments: $instruments, genres: $genres, seekingMusicians: $seekingMusicians, createdAt: $createdAt, expiresAt: $expiresAt, neighborhood: $neighborhood, state: $state, photoUrl: $photoUrl, youtubeLink: $youtubeLink, availableFor: $availableFor, distanceKm: $distanceKm)';
  }
}

/// @nodoc
abstract mixin class $PostEntityCopyWith<$Res> {
  factory $PostEntityCopyWith(
          PostEntity value, $Res Function(PostEntity) _then) =
      _$PostEntityCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String authorProfileId,
      String authorUid,
      String content,
      @GeoPointConverter() GeoPoint location,
      String city,
      String type,
      String level,
      List<String> instruments,
      List<String> genres,
      List<String> seekingMusicians,
      @TimestampConverter() DateTime createdAt,
      @TimestampConverter() DateTime expiresAt,
      String? neighborhood,
      String? state,
      String? photoUrl,
      String? youtubeLink,
      List<String> availableFor,
      double? distanceKm});
}

/// @nodoc
class _$PostEntityCopyWithImpl<$Res> implements $PostEntityCopyWith<$Res> {
  _$PostEntityCopyWithImpl(this._self, this._then);

  final PostEntity _self;
  final $Res Function(PostEntity) _then;

  /// Create a copy of PostEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? authorProfileId = null,
    Object? authorUid = null,
    Object? content = null,
    Object? location = null,
    Object? city = null,
    Object? type = null,
    Object? level = null,
    Object? instruments = null,
    Object? genres = null,
    Object? seekingMusicians = null,
    Object? createdAt = null,
    Object? expiresAt = null,
    Object? neighborhood = freezed,
    Object? state = freezed,
    Object? photoUrl = freezed,
    Object? youtubeLink = freezed,
    Object? availableFor = null,
    Object? distanceKm = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      authorProfileId: null == authorProfileId
          ? _self.authorProfileId
          : authorProfileId // ignore: cast_nullable_to_non_nullable
              as String,
      authorUid: null == authorUid
          ? _self.authorUid
          : authorUid // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _self.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      location: null == location
          ? _self.location
          : location // ignore: cast_nullable_to_non_nullable
              as GeoPoint,
      city: null == city
          ? _self.city
          : city // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      level: null == level
          ? _self.level
          : level // ignore: cast_nullable_to_non_nullable
              as String,
      instruments: null == instruments
          ? _self.instruments
          : instruments // ignore: cast_nullable_to_non_nullable
              as List<String>,
      genres: null == genres
          ? _self.genres
          : genres // ignore: cast_nullable_to_non_nullable
              as List<String>,
      seekingMusicians: null == seekingMusicians
          ? _self.seekingMusicians
          : seekingMusicians // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      expiresAt: null == expiresAt
          ? _self.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      neighborhood: freezed == neighborhood
          ? _self.neighborhood
          : neighborhood // ignore: cast_nullable_to_non_nullable
              as String?,
      state: freezed == state
          ? _self.state
          : state // ignore: cast_nullable_to_non_nullable
              as String?,
      photoUrl: freezed == photoUrl
          ? _self.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      youtubeLink: freezed == youtubeLink
          ? _self.youtubeLink
          : youtubeLink // ignore: cast_nullable_to_non_nullable
              as String?,
      availableFor: null == availableFor
          ? _self.availableFor
          : availableFor // ignore: cast_nullable_to_non_nullable
              as List<String>,
      distanceKm: freezed == distanceKm
          ? _self.distanceKm
          : distanceKm // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// Adds pattern-matching-related methods to [PostEntity].
extension PostEntityPatterns on PostEntity {
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
    TResult Function(_PostEntity value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PostEntity() when $default != null:
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
    TResult Function(_PostEntity value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PostEntity():
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
    TResult? Function(_PostEntity value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PostEntity() when $default != null:
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
            String id,
            String authorProfileId,
            String authorUid,
            String content,
            @GeoPointConverter() GeoPoint location,
            String city,
            String type,
            String level,
            List<String> instruments,
            List<String> genres,
            List<String> seekingMusicians,
            @TimestampConverter() DateTime createdAt,
            @TimestampConverter() DateTime expiresAt,
            String? neighborhood,
            String? state,
            String? photoUrl,
            String? youtubeLink,
            List<String> availableFor,
            double? distanceKm)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PostEntity() when $default != null:
        return $default(
            _that.id,
            _that.authorProfileId,
            _that.authorUid,
            _that.content,
            _that.location,
            _that.city,
            _that.type,
            _that.level,
            _that.instruments,
            _that.genres,
            _that.seekingMusicians,
            _that.createdAt,
            _that.expiresAt,
            _that.neighborhood,
            _that.state,
            _that.photoUrl,
            _that.youtubeLink,
            _that.availableFor,
            _that.distanceKm);
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
            String id,
            String authorProfileId,
            String authorUid,
            String content,
            @GeoPointConverter() GeoPoint location,
            String city,
            String type,
            String level,
            List<String> instruments,
            List<String> genres,
            List<String> seekingMusicians,
            @TimestampConverter() DateTime createdAt,
            @TimestampConverter() DateTime expiresAt,
            String? neighborhood,
            String? state,
            String? photoUrl,
            String? youtubeLink,
            List<String> availableFor,
            double? distanceKm)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PostEntity():
        return $default(
            _that.id,
            _that.authorProfileId,
            _that.authorUid,
            _that.content,
            _that.location,
            _that.city,
            _that.type,
            _that.level,
            _that.instruments,
            _that.genres,
            _that.seekingMusicians,
            _that.createdAt,
            _that.expiresAt,
            _that.neighborhood,
            _that.state,
            _that.photoUrl,
            _that.youtubeLink,
            _that.availableFor,
            _that.distanceKm);
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
            String id,
            String authorProfileId,
            String authorUid,
            String content,
            @GeoPointConverter() GeoPoint location,
            String city,
            String type,
            String level,
            List<String> instruments,
            List<String> genres,
            List<String> seekingMusicians,
            @TimestampConverter() DateTime createdAt,
            @TimestampConverter() DateTime expiresAt,
            String? neighborhood,
            String? state,
            String? photoUrl,
            String? youtubeLink,
            List<String> availableFor,
            double? distanceKm)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PostEntity() when $default != null:
        return $default(
            _that.id,
            _that.authorProfileId,
            _that.authorUid,
            _that.content,
            _that.location,
            _that.city,
            _that.type,
            _that.level,
            _that.instruments,
            _that.genres,
            _that.seekingMusicians,
            _that.createdAt,
            _that.expiresAt,
            _that.neighborhood,
            _that.state,
            _that.photoUrl,
            _that.youtubeLink,
            _that.availableFor,
            _that.distanceKm);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _PostEntity extends PostEntity {
  const _PostEntity(
      {required this.id,
      required this.authorProfileId,
      required this.authorUid,
      required this.content,
      @GeoPointConverter() required this.location,
      required this.city,
      required this.type,
      required this.level,
      required final List<String> instruments,
      required final List<String> genres,
      required final List<String> seekingMusicians,
      @TimestampConverter() required this.createdAt,
      @TimestampConverter() required this.expiresAt,
      this.neighborhood,
      this.state,
      this.photoUrl,
      this.youtubeLink,
      final List<String> availableFor = const [],
      this.distanceKm})
      : _instruments = instruments,
        _genres = genres,
        _seekingMusicians = seekingMusicians,
        _availableFor = availableFor,
        super._();
  factory _PostEntity.fromJson(Map<String, dynamic> json) =>
      _$PostEntityFromJson(json);

  @override
  final String id;
  @override
  final String authorProfileId;
  @override
  final String authorUid;
  @override
  final String content;
  @override
  @GeoPointConverter()
  final GeoPoint location;
  @override
  final String city;
  @override
  final String type;
  @override
  final String level;
  final List<String> _instruments;
  @override
  List<String> get instruments {
    if (_instruments is EqualUnmodifiableListView) return _instruments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_instruments);
  }

  final List<String> _genres;
  @override
  List<String> get genres {
    if (_genres is EqualUnmodifiableListView) return _genres;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_genres);
  }

  final List<String> _seekingMusicians;
  @override
  List<String> get seekingMusicians {
    if (_seekingMusicians is EqualUnmodifiableListView)
      return _seekingMusicians;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_seekingMusicians);
  }

  @override
  @TimestampConverter()
  final DateTime createdAt;
  @override
  @TimestampConverter()
  final DateTime expiresAt;
  @override
  final String? neighborhood;
  @override
  final String? state;
  @override
  final String? photoUrl;
  @override
  final String? youtubeLink;
  final List<String> _availableFor;
  @override
  @JsonKey()
  List<String> get availableFor {
    if (_availableFor is EqualUnmodifiableListView) return _availableFor;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_availableFor);
  }

  @override
  final double? distanceKm;

  /// Create a copy of PostEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PostEntityCopyWith<_PostEntity> get copyWith =>
      __$PostEntityCopyWithImpl<_PostEntity>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PostEntityToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PostEntity &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.authorProfileId, authorProfileId) ||
                other.authorProfileId == authorProfileId) &&
            (identical(other.authorUid, authorUid) ||
                other.authorUid == authorUid) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.level, level) || other.level == level) &&
            const DeepCollectionEquality()
                .equals(other._instruments, _instruments) &&
            const DeepCollectionEquality().equals(other._genres, _genres) &&
            const DeepCollectionEquality()
                .equals(other._seekingMusicians, _seekingMusicians) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.neighborhood, neighborhood) ||
                other.neighborhood == neighborhood) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.youtubeLink, youtubeLink) ||
                other.youtubeLink == youtubeLink) &&
            const DeepCollectionEquality()
                .equals(other._availableFor, _availableFor) &&
            (identical(other.distanceKm, distanceKm) ||
                other.distanceKm == distanceKm));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        authorProfileId,
        authorUid,
        content,
        location,
        city,
        type,
        level,
        const DeepCollectionEquality().hash(_instruments),
        const DeepCollectionEquality().hash(_genres),
        const DeepCollectionEquality().hash(_seekingMusicians),
        createdAt,
        expiresAt,
        neighborhood,
        state,
        photoUrl,
        youtubeLink,
        const DeepCollectionEquality().hash(_availableFor),
        distanceKm
      ]);

  @override
  String toString() {
    return 'PostEntity(id: $id, authorProfileId: $authorProfileId, authorUid: $authorUid, content: $content, location: $location, city: $city, type: $type, level: $level, instruments: $instruments, genres: $genres, seekingMusicians: $seekingMusicians, createdAt: $createdAt, expiresAt: $expiresAt, neighborhood: $neighborhood, state: $state, photoUrl: $photoUrl, youtubeLink: $youtubeLink, availableFor: $availableFor, distanceKm: $distanceKm)';
  }
}

/// @nodoc
abstract mixin class _$PostEntityCopyWith<$Res>
    implements $PostEntityCopyWith<$Res> {
  factory _$PostEntityCopyWith(
          _PostEntity value, $Res Function(_PostEntity) _then) =
      __$PostEntityCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String authorProfileId,
      String authorUid,
      String content,
      @GeoPointConverter() GeoPoint location,
      String city,
      String type,
      String level,
      List<String> instruments,
      List<String> genres,
      List<String> seekingMusicians,
      @TimestampConverter() DateTime createdAt,
      @TimestampConverter() DateTime expiresAt,
      String? neighborhood,
      String? state,
      String? photoUrl,
      String? youtubeLink,
      List<String> availableFor,
      double? distanceKm});
}

/// @nodoc
class __$PostEntityCopyWithImpl<$Res> implements _$PostEntityCopyWith<$Res> {
  __$PostEntityCopyWithImpl(this._self, this._then);

  final _PostEntity _self;
  final $Res Function(_PostEntity) _then;

  /// Create a copy of PostEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? authorProfileId = null,
    Object? authorUid = null,
    Object? content = null,
    Object? location = null,
    Object? city = null,
    Object? type = null,
    Object? level = null,
    Object? instruments = null,
    Object? genres = null,
    Object? seekingMusicians = null,
    Object? createdAt = null,
    Object? expiresAt = null,
    Object? neighborhood = freezed,
    Object? state = freezed,
    Object? photoUrl = freezed,
    Object? youtubeLink = freezed,
    Object? availableFor = null,
    Object? distanceKm = freezed,
  }) {
    return _then(_PostEntity(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      authorProfileId: null == authorProfileId
          ? _self.authorProfileId
          : authorProfileId // ignore: cast_nullable_to_non_nullable
              as String,
      authorUid: null == authorUid
          ? _self.authorUid
          : authorUid // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _self.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      location: null == location
          ? _self.location
          : location // ignore: cast_nullable_to_non_nullable
              as GeoPoint,
      city: null == city
          ? _self.city
          : city // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      level: null == level
          ? _self.level
          : level // ignore: cast_nullable_to_non_nullable
              as String,
      instruments: null == instruments
          ? _self._instruments
          : instruments // ignore: cast_nullable_to_non_nullable
              as List<String>,
      genres: null == genres
          ? _self._genres
          : genres // ignore: cast_nullable_to_non_nullable
              as List<String>,
      seekingMusicians: null == seekingMusicians
          ? _self._seekingMusicians
          : seekingMusicians // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      expiresAt: null == expiresAt
          ? _self.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      neighborhood: freezed == neighborhood
          ? _self.neighborhood
          : neighborhood // ignore: cast_nullable_to_non_nullable
              as String?,
      state: freezed == state
          ? _self.state
          : state // ignore: cast_nullable_to_non_nullable
              as String?,
      photoUrl: freezed == photoUrl
          ? _self.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      youtubeLink: freezed == youtubeLink
          ? _self.youtubeLink
          : youtubeLink // ignore: cast_nullable_to_non_nullable
              as String?,
      availableFor: null == availableFor
          ? _self._availableFor
          : availableFor // ignore: cast_nullable_to_non_nullable
              as List<String>,
      distanceKm: freezed == distanceKm
          ? _self.distanceKm
          : distanceKm // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

// dart format on
