// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'post_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PostEntity _$PostEntityFromJson(Map<String, dynamic> json) {
  return _PostEntity.fromJson(json);
}

/// @nodoc
mixin _$PostEntity {
  String get id => throw _privateConstructorUsedError;
  String get authorProfileId => throw _privateConstructorUsedError;
  String get authorUid => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  @GeoPointConverter()
  GeoPoint get location => throw _privateConstructorUsedError;
  String get city => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String get level => throw _privateConstructorUsedError;
  List<String> get instruments => throw _privateConstructorUsedError;
  List<String> get genres => throw _privateConstructorUsedError;
  List<String> get seekingMusicians => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get expiresAt => throw _privateConstructorUsedError;
  String? get neighborhood => throw _privateConstructorUsedError;
  String? get state => throw _privateConstructorUsedError;
  String? get photoUrl => throw _privateConstructorUsedError;
  String? get youtubeLink => throw _privateConstructorUsedError;
  List<String> get availableFor => throw _privateConstructorUsedError;
  double? get distanceKm => throw _privateConstructorUsedError;
  String? get authorName => throw _privateConstructorUsedError;
  String? get authorPhotoUrl => throw _privateConstructorUsedError;
  String? get activeProfileName => throw _privateConstructorUsedError;
  String? get activeProfilePhotoUrl => throw _privateConstructorUsedError;

  /// Serializes this PostEntity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PostEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PostEntityCopyWith<PostEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PostEntityCopyWith<$Res> {
  factory $PostEntityCopyWith(
          PostEntity value, $Res Function(PostEntity) then) =
      _$PostEntityCopyWithImpl<$Res, PostEntity>;
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
      double? distanceKm,
      String? authorName,
      String? authorPhotoUrl,
      String? activeProfileName,
      String? activeProfilePhotoUrl});
}

/// @nodoc
class _$PostEntityCopyWithImpl<$Res, $Val extends PostEntity>
    implements $PostEntityCopyWith<$Res> {
  _$PostEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

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
    Object? authorName = freezed,
    Object? authorPhotoUrl = freezed,
    Object? activeProfileName = freezed,
    Object? activeProfilePhotoUrl = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      authorProfileId: null == authorProfileId
          ? _value.authorProfileId
          : authorProfileId // ignore: cast_nullable_to_non_nullable
              as String,
      authorUid: null == authorUid
          ? _value.authorUid
          : authorUid // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      location: null == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as GeoPoint,
      city: null == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as String,
      instruments: null == instruments
          ? _value.instruments
          : instruments // ignore: cast_nullable_to_non_nullable
              as List<String>,
      genres: null == genres
          ? _value.genres
          : genres // ignore: cast_nullable_to_non_nullable
              as List<String>,
      seekingMusicians: null == seekingMusicians
          ? _value.seekingMusicians
          : seekingMusicians // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      neighborhood: freezed == neighborhood
          ? _value.neighborhood
          : neighborhood // ignore: cast_nullable_to_non_nullable
              as String?,
      state: freezed == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String?,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      youtubeLink: freezed == youtubeLink
          ? _value.youtubeLink
          : youtubeLink // ignore: cast_nullable_to_non_nullable
              as String?,
      availableFor: null == availableFor
          ? _value.availableFor
          : availableFor // ignore: cast_nullable_to_non_nullable
              as List<String>,
      distanceKm: freezed == distanceKm
          ? _value.distanceKm
          : distanceKm // ignore: cast_nullable_to_non_nullable
              as double?,
      authorName: freezed == authorName
          ? _value.authorName
          : authorName // ignore: cast_nullable_to_non_nullable
              as String?,
      authorPhotoUrl: freezed == authorPhotoUrl
          ? _value.authorPhotoUrl
          : authorPhotoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      activeProfileName: freezed == activeProfileName
          ? _value.activeProfileName
          : activeProfileName // ignore: cast_nullable_to_non_nullable
              as String?,
      activeProfilePhotoUrl: freezed == activeProfilePhotoUrl
          ? _value.activeProfilePhotoUrl
          : activeProfilePhotoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PostEntityImplCopyWith<$Res>
    implements $PostEntityCopyWith<$Res> {
  factory _$$PostEntityImplCopyWith(
          _$PostEntityImpl value, $Res Function(_$PostEntityImpl) then) =
      __$$PostEntityImplCopyWithImpl<$Res>;
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
      double? distanceKm,
      String? authorName,
      String? authorPhotoUrl,
      String? activeProfileName,
      String? activeProfilePhotoUrl});
}

/// @nodoc
class __$$PostEntityImplCopyWithImpl<$Res>
    extends _$PostEntityCopyWithImpl<$Res, _$PostEntityImpl>
    implements _$$PostEntityImplCopyWith<$Res> {
  __$$PostEntityImplCopyWithImpl(
      _$PostEntityImpl _value, $Res Function(_$PostEntityImpl) _then)
      : super(_value, _then);

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
    Object? authorName = freezed,
    Object? authorPhotoUrl = freezed,
    Object? activeProfileName = freezed,
    Object? activeProfilePhotoUrl = freezed,
  }) {
    return _then(_$PostEntityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      authorProfileId: null == authorProfileId
          ? _value.authorProfileId
          : authorProfileId // ignore: cast_nullable_to_non_nullable
              as String,
      authorUid: null == authorUid
          ? _value.authorUid
          : authorUid // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      location: null == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as GeoPoint,
      city: null == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as String,
      instruments: null == instruments
          ? _value._instruments
          : instruments // ignore: cast_nullable_to_non_nullable
              as List<String>,
      genres: null == genres
          ? _value._genres
          : genres // ignore: cast_nullable_to_non_nullable
              as List<String>,
      seekingMusicians: null == seekingMusicians
          ? _value._seekingMusicians
          : seekingMusicians // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      neighborhood: freezed == neighborhood
          ? _value.neighborhood
          : neighborhood // ignore: cast_nullable_to_non_nullable
              as String?,
      state: freezed == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String?,
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      youtubeLink: freezed == youtubeLink
          ? _value.youtubeLink
          : youtubeLink // ignore: cast_nullable_to_non_nullable
              as String?,
      availableFor: null == availableFor
          ? _value._availableFor
          : availableFor // ignore: cast_nullable_to_non_nullable
              as List<String>,
      distanceKm: freezed == distanceKm
          ? _value.distanceKm
          : distanceKm // ignore: cast_nullable_to_non_nullable
              as double?,
      authorName: freezed == authorName
          ? _value.authorName
          : authorName // ignore: cast_nullable_to_non_nullable
              as String?,
      authorPhotoUrl: freezed == authorPhotoUrl
          ? _value.authorPhotoUrl
          : authorPhotoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      activeProfileName: freezed == activeProfileName
          ? _value.activeProfileName
          : activeProfileName // ignore: cast_nullable_to_non_nullable
              as String?,
      activeProfilePhotoUrl: freezed == activeProfilePhotoUrl
          ? _value.activeProfilePhotoUrl
          : activeProfilePhotoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PostEntityImpl extends _PostEntity {
  const _$PostEntityImpl(
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
      this.distanceKm,
      this.authorName,
      this.authorPhotoUrl,
      this.activeProfileName,
      this.activeProfilePhotoUrl})
      : _instruments = instruments,
        _genres = genres,
        _seekingMusicians = seekingMusicians,
        _availableFor = availableFor,
        super._();

  factory _$PostEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$PostEntityImplFromJson(json);

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
  @override
  final String? authorName;
  @override
  final String? authorPhotoUrl;
  @override
  final String? activeProfileName;
  @override
  final String? activeProfilePhotoUrl;

  @override
  String toString() {
    return 'PostEntity(id: $id, authorProfileId: $authorProfileId, authorUid: $authorUid, content: $content, location: $location, city: $city, type: $type, level: $level, instruments: $instruments, genres: $genres, seekingMusicians: $seekingMusicians, createdAt: $createdAt, expiresAt: $expiresAt, neighborhood: $neighborhood, state: $state, photoUrl: $photoUrl, youtubeLink: $youtubeLink, availableFor: $availableFor, distanceKm: $distanceKm, authorName: $authorName, authorPhotoUrl: $authorPhotoUrl, activeProfileName: $activeProfileName, activeProfilePhotoUrl: $activeProfilePhotoUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PostEntityImpl &&
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
                other.distanceKm == distanceKm) &&
            (identical(other.authorName, authorName) ||
                other.authorName == authorName) &&
            (identical(other.authorPhotoUrl, authorPhotoUrl) ||
                other.authorPhotoUrl == authorPhotoUrl) &&
            (identical(other.activeProfileName, activeProfileName) ||
                other.activeProfileName == activeProfileName) &&
            (identical(other.activeProfilePhotoUrl, activeProfilePhotoUrl) ||
                other.activeProfilePhotoUrl == activeProfilePhotoUrl));
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
        distanceKm,
        authorName,
        authorPhotoUrl,
        activeProfileName,
        activeProfilePhotoUrl
      ]);

  /// Create a copy of PostEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PostEntityImplCopyWith<_$PostEntityImpl> get copyWith =>
      __$$PostEntityImplCopyWithImpl<_$PostEntityImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PostEntityImplToJson(
      this,
    );
  }
}

abstract class _PostEntity extends PostEntity {
  const factory _PostEntity(
      {required final String id,
      required final String authorProfileId,
      required final String authorUid,
      required final String content,
      @GeoPointConverter() required final GeoPoint location,
      required final String city,
      required final String type,
      required final String level,
      required final List<String> instruments,
      required final List<String> genres,
      required final List<String> seekingMusicians,
      @TimestampConverter() required final DateTime createdAt,
      @TimestampConverter() required final DateTime expiresAt,
      final String? neighborhood,
      final String? state,
      final String? photoUrl,
      final String? youtubeLink,
      final List<String> availableFor,
      final double? distanceKm,
      final String? authorName,
      final String? authorPhotoUrl,
      final String? activeProfileName,
      final String? activeProfilePhotoUrl}) = _$PostEntityImpl;
  const _PostEntity._() : super._();

  factory _PostEntity.fromJson(Map<String, dynamic> json) =
      _$PostEntityImpl.fromJson;

  @override
  String get id;
  @override
  String get authorProfileId;
  @override
  String get authorUid;
  @override
  String get content;
  @override
  @GeoPointConverter()
  GeoPoint get location;
  @override
  String get city;
  @override
  String get type;
  @override
  String get level;
  @override
  List<String> get instruments;
  @override
  List<String> get genres;
  @override
  List<String> get seekingMusicians;
  @override
  @TimestampConverter()
  DateTime get createdAt;
  @override
  @TimestampConverter()
  DateTime get expiresAt;
  @override
  String? get neighborhood;
  @override
  String? get state;
  @override
  String? get photoUrl;
  @override
  String? get youtubeLink;
  @override
  List<String> get availableFor;
  @override
  double? get distanceKm;
  @override
  String? get authorName;
  @override
  String? get authorPhotoUrl;
  @override
  String? get activeProfileName;
  @override
  String? get activeProfilePhotoUrl;

  /// Create a copy of PostEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PostEntityImplCopyWith<_$PostEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
