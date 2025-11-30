// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ConversationEntity {
  String get id;
  List<String> get participants;
  List<String> get participantProfiles;
  String get lastMessage;
  DateTime get lastMessageTimestamp;
  Map<String, int> get unreadCount;
  DateTime get createdAt;
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<Map<String, dynamic>> get participantProfilesData;
  bool get archived;
  DateTime? get updatedAt;

  /// Create a copy of ConversationEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ConversationEntityCopyWith<ConversationEntity> get copyWith =>
      _$ConversationEntityCopyWithImpl<ConversationEntity>(
          this as ConversationEntity, _$identity);

  /// Serializes this ConversationEntity to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ConversationEntity &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality()
                .equals(other.participants, participants) &&
            const DeepCollectionEquality()
                .equals(other.participantProfiles, participantProfiles) &&
            (identical(other.lastMessage, lastMessage) ||
                other.lastMessage == lastMessage) &&
            (identical(other.lastMessageTimestamp, lastMessageTimestamp) ||
                other.lastMessageTimestamp == lastMessageTimestamp) &&
            const DeepCollectionEquality()
                .equals(other.unreadCount, unreadCount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            const DeepCollectionEquality().equals(
                other.participantProfilesData, participantProfilesData) &&
            (identical(other.archived, archived) ||
                other.archived == archived) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      const DeepCollectionEquality().hash(participants),
      const DeepCollectionEquality().hash(participantProfiles),
      lastMessage,
      lastMessageTimestamp,
      const DeepCollectionEquality().hash(unreadCount),
      createdAt,
      const DeepCollectionEquality().hash(participantProfilesData),
      archived,
      updatedAt);

  @override
  String toString() {
    return 'ConversationEntity(id: $id, participants: $participants, participantProfiles: $participantProfiles, lastMessage: $lastMessage, lastMessageTimestamp: $lastMessageTimestamp, unreadCount: $unreadCount, createdAt: $createdAt, participantProfilesData: $participantProfilesData, archived: $archived, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $ConversationEntityCopyWith<$Res> {
  factory $ConversationEntityCopyWith(
          ConversationEntity value, $Res Function(ConversationEntity) _then) =
      _$ConversationEntityCopyWithImpl;
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
      DateTime? updatedAt});
}

/// @nodoc
class _$ConversationEntityCopyWithImpl<$Res>
    implements $ConversationEntityCopyWith<$Res> {
  _$ConversationEntityCopyWithImpl(this._self, this._then);

  final ConversationEntity _self;
  final $Res Function(ConversationEntity) _then;

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
    Object? updatedAt = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      participants: null == participants
          ? _self.participants
          : participants // ignore: cast_nullable_to_non_nullable
              as List<String>,
      participantProfiles: null == participantProfiles
          ? _self.participantProfiles
          : participantProfiles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      lastMessage: null == lastMessage
          ? _self.lastMessage
          : lastMessage // ignore: cast_nullable_to_non_nullable
              as String,
      lastMessageTimestamp: null == lastMessageTimestamp
          ? _self.lastMessageTimestamp
          : lastMessageTimestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      unreadCount: null == unreadCount
          ? _self.unreadCount
          : unreadCount // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      participantProfilesData: null == participantProfilesData
          ? _self.participantProfilesData
          : participantProfilesData // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      archived: null == archived
          ? _self.archived
          : archived // ignore: cast_nullable_to_non_nullable
              as bool,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// Adds pattern-matching-related methods to [ConversationEntity].
extension ConversationEntityPatterns on ConversationEntity {
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
    TResult Function(_ConversationEntity value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ConversationEntity() when $default != null:
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
    TResult Function(_ConversationEntity value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ConversationEntity():
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
    TResult? Function(_ConversationEntity value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ConversationEntity() when $default != null:
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
            List<String> participants,
            List<String> participantProfiles,
            String lastMessage,
            DateTime lastMessageTimestamp,
            Map<String, int> unreadCount,
            DateTime createdAt,
            @JsonKey(includeFromJson: false, includeToJson: false)
            List<Map<String, dynamic>> participantProfilesData,
            bool archived,
            DateTime? updatedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ConversationEntity() when $default != null:
        return $default(
            _that.id,
            _that.participants,
            _that.participantProfiles,
            _that.lastMessage,
            _that.lastMessageTimestamp,
            _that.unreadCount,
            _that.createdAt,
            _that.participantProfilesData,
            _that.archived,
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
            String id,
            List<String> participants,
            List<String> participantProfiles,
            String lastMessage,
            DateTime lastMessageTimestamp,
            Map<String, int> unreadCount,
            DateTime createdAt,
            @JsonKey(includeFromJson: false, includeToJson: false)
            List<Map<String, dynamic>> participantProfilesData,
            bool archived,
            DateTime? updatedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ConversationEntity():
        return $default(
            _that.id,
            _that.participants,
            _that.participantProfiles,
            _that.lastMessage,
            _that.lastMessageTimestamp,
            _that.unreadCount,
            _that.createdAt,
            _that.participantProfilesData,
            _that.archived,
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
            String id,
            List<String> participants,
            List<String> participantProfiles,
            String lastMessage,
            DateTime lastMessageTimestamp,
            Map<String, int> unreadCount,
            DateTime createdAt,
            @JsonKey(includeFromJson: false, includeToJson: false)
            List<Map<String, dynamic>> participantProfilesData,
            bool archived,
            DateTime? updatedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ConversationEntity() when $default != null:
        return $default(
            _that.id,
            _that.participants,
            _that.participantProfiles,
            _that.lastMessage,
            _that.lastMessageTimestamp,
            _that.unreadCount,
            _that.createdAt,
            _that.participantProfilesData,
            _that.archived,
            _that.updatedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ConversationEntity extends ConversationEntity {
  const _ConversationEntity(
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
      this.updatedAt})
      : _participants = participants,
        _participantProfiles = participantProfiles,
        _unreadCount = unreadCount,
        _participantProfilesData = participantProfilesData,
        super._();
  factory _ConversationEntity.fromJson(Map<String, dynamic> json) =>
      _$ConversationEntityFromJson(json);

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
  @override
  final DateTime? updatedAt;

  /// Create a copy of ConversationEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ConversationEntityCopyWith<_ConversationEntity> get copyWith =>
      __$ConversationEntityCopyWithImpl<_ConversationEntity>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ConversationEntityToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ConversationEntity &&
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
      updatedAt);

  @override
  String toString() {
    return 'ConversationEntity(id: $id, participants: $participants, participantProfiles: $participantProfiles, lastMessage: $lastMessage, lastMessageTimestamp: $lastMessageTimestamp, unreadCount: $unreadCount, createdAt: $createdAt, participantProfilesData: $participantProfilesData, archived: $archived, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$ConversationEntityCopyWith<$Res>
    implements $ConversationEntityCopyWith<$Res> {
  factory _$ConversationEntityCopyWith(
          _ConversationEntity value, $Res Function(_ConversationEntity) _then) =
      __$ConversationEntityCopyWithImpl;
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
      DateTime? updatedAt});
}

/// @nodoc
class __$ConversationEntityCopyWithImpl<$Res>
    implements _$ConversationEntityCopyWith<$Res> {
  __$ConversationEntityCopyWithImpl(this._self, this._then);

  final _ConversationEntity _self;
  final $Res Function(_ConversationEntity) _then;

  /// Create a copy of ConversationEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
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
    Object? updatedAt = freezed,
  }) {
    return _then(_ConversationEntity(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      participants: null == participants
          ? _self._participants
          : participants // ignore: cast_nullable_to_non_nullable
              as List<String>,
      participantProfiles: null == participantProfiles
          ? _self._participantProfiles
          : participantProfiles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      lastMessage: null == lastMessage
          ? _self.lastMessage
          : lastMessage // ignore: cast_nullable_to_non_nullable
              as String,
      lastMessageTimestamp: null == lastMessageTimestamp
          ? _self.lastMessageTimestamp
          : lastMessageTimestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      unreadCount: null == unreadCount
          ? _self._unreadCount
          : unreadCount // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      participantProfilesData: null == participantProfilesData
          ? _self._participantProfilesData
          : participantProfilesData // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      archived: null == archived
          ? _self.archived
          : archived // ignore: cast_nullable_to_non_nullable
              as bool,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
