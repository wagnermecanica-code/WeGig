// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ConversationEntity _$ConversationEntityFromJson(Map<String, dynamic> json) {
  return _ConversationEntity.fromJson(json);
}

/// @nodoc
mixin _$ConversationEntity {
  String get id => throw _privateConstructorUsedError;
  List<String> get participants => throw _privateConstructorUsedError;
  List<String> get participantProfiles => throw _privateConstructorUsedError;
  String get lastMessage => throw _privateConstructorUsedError;
  DateTime get lastMessageTimestamp => throw _privateConstructorUsedError;
  Map<String, int> get unreadCount => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<Map<String, dynamic>> get participantProfilesData =>
      throw _privateConstructorUsedError;
  bool get archived => throw _privateConstructorUsedError;
  List<String> get archivedProfileIds => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this ConversationEntity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ConversationEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConversationEntityCopyWith<ConversationEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConversationEntityCopyWith<$Res> {
  factory $ConversationEntityCopyWith(
          ConversationEntity value, $Res Function(ConversationEntity) then) =
      _$ConversationEntityCopyWithImpl<$Res, ConversationEntity>;
  @useResult
  $Res call(
      {String id,
      List<String> participants,
      List<String> participantProfiles,
      String lastMessage,
      DateTime lastMessageTimestamp,
      Map<String, int> unreadCount,
      DateTime createdAt,
      @JsonKey(includeFromJson: false, includeToJson: false)
      List<Map<String, dynamic>> participantProfilesData,
      bool archived,
      List<String> archivedProfileIds,
      DateTime? updatedAt});
}

/// @nodoc
class _$ConversationEntityCopyWithImpl<$Res, $Val extends ConversationEntity>
    implements $ConversationEntityCopyWith<$Res> {
  _$ConversationEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConversationEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? participants = null,
    Object? participantProfiles = null,
    Object? lastMessage = null,
    Object? lastMessageTimestamp = null,
    Object? unreadCount = null,
    Object? createdAt = null,
    Object? participantProfilesData = null,
    Object? archived = null,
    Object? archivedProfileIds = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      participants: null == participants
          ? _value.participants
          : participants // ignore: cast_nullable_to_non_nullable
              as List<String>,
      participantProfiles: null == participantProfiles
          ? _value.participantProfiles
          : participantProfiles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      lastMessage: null == lastMessage
          ? _value.lastMessage
          : lastMessage // ignore: cast_nullable_to_non_nullable
              as String,
      lastMessageTimestamp: null == lastMessageTimestamp
          ? _value.lastMessageTimestamp
          : lastMessageTimestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      unreadCount: null == unreadCount
          ? _value.unreadCount
          : unreadCount // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      participantProfilesData: null == participantProfilesData
          ? _value.participantProfilesData
          : participantProfilesData // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      archived: null == archived
          ? _value.archived
          : archived // ignore: cast_nullable_to_non_nullable
              as bool,
      archivedProfileIds: null == archivedProfileIds
          ? _value.archivedProfileIds
          : archivedProfileIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ConversationEntityImplCopyWith<$Res>
    implements $ConversationEntityCopyWith<$Res> {
  factory _$$ConversationEntityImplCopyWith(_$ConversationEntityImpl value,
          $Res Function(_$ConversationEntityImpl) then) =
      __$$ConversationEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      List<String> participants,
      List<String> participantProfiles,
      String lastMessage,
      DateTime lastMessageTimestamp,
      Map<String, int> unreadCount,
      DateTime createdAt,
      @JsonKey(includeFromJson: false, includeToJson: false)
      List<Map<String, dynamic>> participantProfilesData,
      bool archived,
      List<String> archivedProfileIds,
      DateTime? updatedAt});
}

/// @nodoc
class __$$ConversationEntityImplCopyWithImpl<$Res>
    extends _$ConversationEntityCopyWithImpl<$Res, _$ConversationEntityImpl>
    implements _$$ConversationEntityImplCopyWith<$Res> {
  __$$ConversationEntityImplCopyWithImpl(_$ConversationEntityImpl _value,
      $Res Function(_$ConversationEntityImpl) _then)
      : super(_value, _then);

  /// Create a copy of ConversationEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? participants = null,
    Object? participantProfiles = null,
    Object? lastMessage = null,
    Object? lastMessageTimestamp = null,
    Object? unreadCount = null,
    Object? createdAt = null,
    Object? participantProfilesData = null,
    Object? archived = null,
    Object? archivedProfileIds = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_$ConversationEntityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      participants: null == participants
          ? _value._participants
          : participants // ignore: cast_nullable_to_non_nullable
              as List<String>,
      participantProfiles: null == participantProfiles
          ? _value._participantProfiles
          : participantProfiles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      lastMessage: null == lastMessage
          ? _value.lastMessage
          : lastMessage // ignore: cast_nullable_to_non_nullable
              as String,
      lastMessageTimestamp: null == lastMessageTimestamp
          ? _value.lastMessageTimestamp
          : lastMessageTimestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      unreadCount: null == unreadCount
          ? _value._unreadCount
          : unreadCount // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      participantProfilesData: null == participantProfilesData
          ? _value._participantProfilesData
          : participantProfilesData // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      archived: null == archived
          ? _value.archived
          : archived // ignore: cast_nullable_to_non_nullable
              as bool,
      archivedProfileIds: null == archivedProfileIds
          ? _value._archivedProfileIds
          : archivedProfileIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ConversationEntityImpl extends _ConversationEntity {
  const _$ConversationEntityImpl(
      {required this.id,
      required final List<String> participants,
      required final List<String> participantProfiles,
      required this.lastMessage,
      required this.lastMessageTimestamp,
      required final Map<String, int> unreadCount,
      required this.createdAt,
      @JsonKey(includeFromJson: false, includeToJson: false)
      final List<Map<String, dynamic>> participantProfilesData = const [],
      this.archived = false,
      final List<String> archivedProfileIds = const <String>[],
      this.updatedAt})
      : _participants = participants,
        _participantProfiles = participantProfiles,
        _unreadCount = unreadCount,
        _participantProfilesData = participantProfilesData,
        _archivedProfileIds = archivedProfileIds,
        super._();

  factory _$ConversationEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConversationEntityImplFromJson(json);

  @override
  final String id;
  final List<String> _participants;
  @override
  List<String> get participants {
    if (_participants is EqualUnmodifiableListView) return _participants;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_participants);
  }

  final List<String> _participantProfiles;
  @override
  List<String> get participantProfiles {
    if (_participantProfiles is EqualUnmodifiableListView)
      return _participantProfiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_participantProfiles);
  }

  @override
  final String lastMessage;
  @override
  final DateTime lastMessageTimestamp;
  final Map<String, int> _unreadCount;
  @override
  Map<String, int> get unreadCount {
    if (_unreadCount is EqualUnmodifiableMapView) return _unreadCount;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_unreadCount);
  }

  @override
  final DateTime createdAt;
  final List<Map<String, dynamic>> _participantProfilesData;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<Map<String, dynamic>> get participantProfilesData {
    if (_participantProfilesData is EqualUnmodifiableListView)
      return _participantProfilesData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_participantProfilesData);
  }

  @override
  @JsonKey()
  final bool archived;
  final List<String> _archivedProfileIds;
  @override
  @JsonKey()
  List<String> get archivedProfileIds {
    if (_archivedProfileIds is EqualUnmodifiableListView)
      return _archivedProfileIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_archivedProfileIds);
  }

  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'ConversationEntity(id: $id, participants: $participants, participantProfiles: $participantProfiles, lastMessage: $lastMessage, lastMessageTimestamp: $lastMessageTimestamp, unreadCount: $unreadCount, createdAt: $createdAt, participantProfilesData: $participantProfilesData, archived: $archived, archivedProfileIds: $archivedProfileIds, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConversationEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality()
                .equals(other._participants, _participants) &&
            const DeepCollectionEquality()
                .equals(other._participantProfiles, _participantProfiles) &&
            (identical(other.lastMessage, lastMessage) ||
                other.lastMessage == lastMessage) &&
            (identical(other.lastMessageTimestamp, lastMessageTimestamp) ||
                other.lastMessageTimestamp == lastMessageTimestamp) &&
            const DeepCollectionEquality()
                .equals(other._unreadCount, _unreadCount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            const DeepCollectionEquality().equals(
                other._participantProfilesData, _participantProfilesData) &&
            (identical(other.archived, archived) ||
                other.archived == archived) &&
            const DeepCollectionEquality()
                .equals(other._archivedProfileIds, _archivedProfileIds) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      const DeepCollectionEquality().hash(_participants),
      const DeepCollectionEquality().hash(_participantProfiles),
      lastMessage,
      lastMessageTimestamp,
      const DeepCollectionEquality().hash(_unreadCount),
      createdAt,
      const DeepCollectionEquality().hash(_participantProfilesData),
      archived,
      const DeepCollectionEquality().hash(_archivedProfileIds),
      updatedAt);

  /// Create a copy of ConversationEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConversationEntityImplCopyWith<_$ConversationEntityImpl> get copyWith =>
      __$$ConversationEntityImplCopyWithImpl<_$ConversationEntityImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ConversationEntityImplToJson(
      this,
    );
  }
}

abstract class _ConversationEntity extends ConversationEntity {
  const factory _ConversationEntity(
      {required final String id,
      required final List<String> participants,
      required final List<String> participantProfiles,
      required final String lastMessage,
      required final DateTime lastMessageTimestamp,
      required final Map<String, int> unreadCount,
      required final DateTime createdAt,
      @JsonKey(includeFromJson: false, includeToJson: false)
      final List<Map<String, dynamic>> participantProfilesData,
      final bool archived,
      final List<String> archivedProfileIds,
      final DateTime? updatedAt}) = _$ConversationEntityImpl;
  const _ConversationEntity._() : super._();

  factory _ConversationEntity.fromJson(Map<String, dynamic> json) =
      _$ConversationEntityImpl.fromJson;

  @override
  String get id;
  @override
  List<String> get participants;
  @override
  List<String> get participantProfiles;
  @override
  String get lastMessage;
  @override
  DateTime get lastMessageTimestamp;
  @override
  Map<String, int> get unreadCount;
  @override
  DateTime get createdAt;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<Map<String, dynamic>> get participantProfilesData;
  @override
  bool get archived;
  @override
  List<String> get archivedProfileIds;
  @override
  DateTime? get updatedAt;

  /// Create a copy of ConversationEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConversationEntityImplCopyWith<_$ConversationEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
