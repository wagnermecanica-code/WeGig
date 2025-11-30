// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NotificationEntity {
  String get notificationId;
  @NotificationTypeConverter()
  NotificationType get type;
  String get recipientUid;
  String get recipientProfileId;
  String get title;
  String get message;
  @TimestampConverter()
  DateTime get createdAt;
  String? get senderUid;
  String? get senderProfileId;
  String? get senderName;
  String? get senderPhoto;
  Map<String, dynamic> get data;
  @NullableNotificationActionTypeConverter()
  NotificationActionType? get actionType;
  Map<String, dynamic>? get actionData;
  @NotificationPriorityConverter()
  NotificationPriority get priority;
  bool get read;
  @NullableTimestampConverter()
  DateTime? get readAt;
  @NullableTimestampConverter()
  DateTime? get expiresAt;

  /// Create a copy of NotificationEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $NotificationEntityCopyWith<NotificationEntity> get copyWith =>
      _$NotificationEntityCopyWithImpl<NotificationEntity>(
          this as NotificationEntity, _$identity);

  /// Serializes this NotificationEntity to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is NotificationEntity &&
            (identical(other.notificationId, notificationId) ||
                other.notificationId == notificationId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.recipientUid, recipientUid) ||
                other.recipientUid == recipientUid) &&
            (identical(other.recipientProfileId, recipientProfileId) ||
                other.recipientProfileId == recipientProfileId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.senderUid, senderUid) ||
                other.senderUid == senderUid) &&
            (identical(other.senderProfileId, senderProfileId) ||
                other.senderProfileId == senderProfileId) &&
            (identical(other.senderName, senderName) ||
                other.senderName == senderName) &&
            (identical(other.senderPhoto, senderPhoto) ||
                other.senderPhoto == senderPhoto) &&
            const DeepCollectionEquality().equals(other.data, data) &&
            (identical(other.actionType, actionType) ||
                other.actionType == actionType) &&
            const DeepCollectionEquality()
                .equals(other.actionData, actionData) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.read, read) || other.read == read) &&
            (identical(other.readAt, readAt) || other.readAt == readAt) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      notificationId,
      type,
      recipientUid,
      recipientProfileId,
      title,
      message,
      createdAt,
      senderUid,
      senderProfileId,
      senderName,
      senderPhoto,
      const DeepCollectionEquality().hash(data),
      actionType,
      const DeepCollectionEquality().hash(actionData),
      priority,
      read,
      readAt,
      expiresAt);

  @override
  String toString() {
    return 'NotificationEntity(notificationId: $notificationId, type: $type, recipientUid: $recipientUid, recipientProfileId: $recipientProfileId, title: $title, message: $message, createdAt: $createdAt, senderUid: $senderUid, senderProfileId: $senderProfileId, senderName: $senderName, senderPhoto: $senderPhoto, data: $data, actionType: $actionType, actionData: $actionData, priority: $priority, read: $read, readAt: $readAt, expiresAt: $expiresAt)';
  }
}

/// @nodoc
abstract mixin class $NotificationEntityCopyWith<$Res> {
  factory $NotificationEntityCopyWith(
          NotificationEntity value, $Res Function(NotificationEntity) _then) =
      _$NotificationEntityCopyWithImpl;
  @useResult
  $Res call(
      {String notificationId,
      @NotificationTypeConverter() NotificationType type,
      String recipientUid,
      String recipientProfileId,
      String title,
      String message,
      @TimestampConverter() DateTime createdAt,
      String? senderUid,
      String? senderProfileId,
      String? senderName,
      String? senderPhoto,
      Map<String, dynamic> data,
      @NullableNotificationActionTypeConverter()
      NotificationActionType? actionType,
      Map<String, dynamic>? actionData,
      @NotificationPriorityConverter() NotificationPriority priority,
      bool read,
      @NullableTimestampConverter() DateTime? readAt,
      @NullableTimestampConverter() DateTime? expiresAt});
}

/// @nodoc
class _$NotificationEntityCopyWithImpl<$Res>
    implements $NotificationEntityCopyWith<$Res> {
  _$NotificationEntityCopyWithImpl(this._self, this._then);

  final NotificationEntity _self;
  final $Res Function(NotificationEntity) _then;

  /// Create a copy of NotificationEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? notificationId = null,
    Object? type = null,
    Object? recipientUid = null,
    Object? recipientProfileId = null,
    Object? title = null,
    Object? message = null,
    Object? createdAt = null,
    Object? senderUid = freezed,
    Object? senderProfileId = freezed,
    Object? senderName = freezed,
    Object? senderPhoto = freezed,
    Object? data = null,
    Object? actionType = freezed,
    Object? actionData = freezed,
    Object? priority = null,
    Object? read = null,
    Object? readAt = freezed,
    Object? expiresAt = freezed,
  }) {
    return _then(_self.copyWith(
      notificationId: null == notificationId
          ? _self.notificationId
          : notificationId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as NotificationType,
      recipientUid: null == recipientUid
          ? _self.recipientUid
          : recipientUid // ignore: cast_nullable_to_non_nullable
              as String,
      recipientProfileId: null == recipientProfileId
          ? _self.recipientProfileId
          : recipientProfileId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      senderUid: freezed == senderUid
          ? _self.senderUid
          : senderUid // ignore: cast_nullable_to_non_nullable
              as String?,
      senderProfileId: freezed == senderProfileId
          ? _self.senderProfileId
          : senderProfileId // ignore: cast_nullable_to_non_nullable
              as String?,
      senderName: freezed == senderName
          ? _self.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String?,
      senderPhoto: freezed == senderPhoto
          ? _self.senderPhoto
          : senderPhoto // ignore: cast_nullable_to_non_nullable
              as String?,
      data: null == data
          ? _self.data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      actionType: freezed == actionType
          ? _self.actionType
          : actionType // ignore: cast_nullable_to_non_nullable
              as NotificationActionType?,
      actionData: freezed == actionData
          ? _self.actionData
          : actionData // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      priority: null == priority
          ? _self.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as NotificationPriority,
      read: null == read
          ? _self.read
          : read // ignore: cast_nullable_to_non_nullable
              as bool,
      readAt: freezed == readAt
          ? _self.readAt
          : readAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      expiresAt: freezed == expiresAt
          ? _self.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// Adds pattern-matching-related methods to [NotificationEntity].
extension NotificationEntityPatterns on NotificationEntity {
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
    TResult Function(_NotificationEntity value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _NotificationEntity() when $default != null:
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
    TResult Function(_NotificationEntity value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NotificationEntity():
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
    TResult? Function(_NotificationEntity value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NotificationEntity() when $default != null:
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
            String notificationId,
            @NotificationTypeConverter() NotificationType type,
            String recipientUid,
            String recipientProfileId,
            String title,
            String message,
            @TimestampConverter() DateTime createdAt,
            String? senderUid,
            String? senderProfileId,
            String? senderName,
            String? senderPhoto,
            Map<String, dynamic> data,
            @NullableNotificationActionTypeConverter()
            NotificationActionType? actionType,
            Map<String, dynamic>? actionData,
            @NotificationPriorityConverter() NotificationPriority priority,
            bool read,
            @NullableTimestampConverter() DateTime? readAt,
            @NullableTimestampConverter() DateTime? expiresAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _NotificationEntity() when $default != null:
        return $default(
            _that.notificationId,
            _that.type,
            _that.recipientUid,
            _that.recipientProfileId,
            _that.title,
            _that.message,
            _that.createdAt,
            _that.senderUid,
            _that.senderProfileId,
            _that.senderName,
            _that.senderPhoto,
            _that.data,
            _that.actionType,
            _that.actionData,
            _that.priority,
            _that.read,
            _that.readAt,
            _that.expiresAt);
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
            String notificationId,
            @NotificationTypeConverter() NotificationType type,
            String recipientUid,
            String recipientProfileId,
            String title,
            String message,
            @TimestampConverter() DateTime createdAt,
            String? senderUid,
            String? senderProfileId,
            String? senderName,
            String? senderPhoto,
            Map<String, dynamic> data,
            @NullableNotificationActionTypeConverter()
            NotificationActionType? actionType,
            Map<String, dynamic>? actionData,
            @NotificationPriorityConverter() NotificationPriority priority,
            bool read,
            @NullableTimestampConverter() DateTime? readAt,
            @NullableTimestampConverter() DateTime? expiresAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NotificationEntity():
        return $default(
            _that.notificationId,
            _that.type,
            _that.recipientUid,
            _that.recipientProfileId,
            _that.title,
            _that.message,
            _that.createdAt,
            _that.senderUid,
            _that.senderProfileId,
            _that.senderName,
            _that.senderPhoto,
            _that.data,
            _that.actionType,
            _that.actionData,
            _that.priority,
            _that.read,
            _that.readAt,
            _that.expiresAt);
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
            String notificationId,
            @NotificationTypeConverter() NotificationType type,
            String recipientUid,
            String recipientProfileId,
            String title,
            String message,
            @TimestampConverter() DateTime createdAt,
            String? senderUid,
            String? senderProfileId,
            String? senderName,
            String? senderPhoto,
            Map<String, dynamic> data,
            @NullableNotificationActionTypeConverter()
            NotificationActionType? actionType,
            Map<String, dynamic>? actionData,
            @NotificationPriorityConverter() NotificationPriority priority,
            bool read,
            @NullableTimestampConverter() DateTime? readAt,
            @NullableTimestampConverter() DateTime? expiresAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NotificationEntity() when $default != null:
        return $default(
            _that.notificationId,
            _that.type,
            _that.recipientUid,
            _that.recipientProfileId,
            _that.title,
            _that.message,
            _that.createdAt,
            _that.senderUid,
            _that.senderProfileId,
            _that.senderName,
            _that.senderPhoto,
            _that.data,
            _that.actionType,
            _that.actionData,
            _that.priority,
            _that.read,
            _that.readAt,
            _that.expiresAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _NotificationEntity extends NotificationEntity {
  const _NotificationEntity(
      {required this.notificationId,
      @NotificationTypeConverter() required this.type,
      required this.recipientUid,
      required this.recipientProfileId,
      required this.title,
      required this.message,
      @TimestampConverter() required this.createdAt,
      this.senderUid,
      this.senderProfileId,
      this.senderName,
      this.senderPhoto,
      final Map<String, dynamic> data = const {},
      @NullableNotificationActionTypeConverter() this.actionType,
      final Map<String, dynamic>? actionData,
      @NotificationPriorityConverter()
      this.priority = NotificationPriority.medium,
      this.read = false,
      @NullableTimestampConverter() this.readAt,
      @NullableTimestampConverter() this.expiresAt})
      : _data = data,
        _actionData = actionData,
        super._();
  factory _NotificationEntity.fromJson(Map<String, dynamic> json) =>
      _$NotificationEntityFromJson(json);

  @override
  final String notificationId;
  @override
  @NotificationTypeConverter()
  final NotificationType type;
  @override
  final String recipientUid;
  @override
  final String recipientProfileId;
  @override
  final String title;
  @override
  final String message;
  @override
  @TimestampConverter()
  final DateTime createdAt;
  @override
  final String? senderUid;
  @override
  final String? senderProfileId;
  @override
  final String? senderName;
  @override
  final String? senderPhoto;
  final Map<String, dynamic> _data;
  @override
  @JsonKey()
  Map<String, dynamic> get data {
    if (_data is EqualUnmodifiableMapView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_data);
  }

  @override
  @NullableNotificationActionTypeConverter()
  final NotificationActionType? actionType;
  final Map<String, dynamic>? _actionData;
  @override
  Map<String, dynamic>? get actionData {
    final value = _actionData;
    if (value == null) return null;
    if (_actionData is EqualUnmodifiableMapView) return _actionData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey()
  @NotificationPriorityConverter()
  final NotificationPriority priority;
  @override
  @JsonKey()
  final bool read;
  @override
  @NullableTimestampConverter()
  final DateTime? readAt;
  @override
  @NullableTimestampConverter()
  final DateTime? expiresAt;

  /// Create a copy of NotificationEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$NotificationEntityCopyWith<_NotificationEntity> get copyWith =>
      __$NotificationEntityCopyWithImpl<_NotificationEntity>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$NotificationEntityToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _NotificationEntity &&
            (identical(other.notificationId, notificationId) ||
                other.notificationId == notificationId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.recipientUid, recipientUid) ||
                other.recipientUid == recipientUid) &&
            (identical(other.recipientProfileId, recipientProfileId) ||
                other.recipientProfileId == recipientProfileId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.senderUid, senderUid) ||
                other.senderUid == senderUid) &&
            (identical(other.senderProfileId, senderProfileId) ||
                other.senderProfileId == senderProfileId) &&
            (identical(other.senderName, senderName) ||
                other.senderName == senderName) &&
            (identical(other.senderPhoto, senderPhoto) ||
                other.senderPhoto == senderPhoto) &&
            const DeepCollectionEquality().equals(other._data, _data) &&
            (identical(other.actionType, actionType) ||
                other.actionType == actionType) &&
            const DeepCollectionEquality()
                .equals(other._actionData, _actionData) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.read, read) || other.read == read) &&
            (identical(other.readAt, readAt) || other.readAt == readAt) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      notificationId,
      type,
      recipientUid,
      recipientProfileId,
      title,
      message,
      createdAt,
      senderUid,
      senderProfileId,
      senderName,
      senderPhoto,
      const DeepCollectionEquality().hash(_data),
      actionType,
      const DeepCollectionEquality().hash(_actionData),
      priority,
      read,
      readAt,
      expiresAt);

  @override
  String toString() {
    return 'NotificationEntity(notificationId: $notificationId, type: $type, recipientUid: $recipientUid, recipientProfileId: $recipientProfileId, title: $title, message: $message, createdAt: $createdAt, senderUid: $senderUid, senderProfileId: $senderProfileId, senderName: $senderName, senderPhoto: $senderPhoto, data: $data, actionType: $actionType, actionData: $actionData, priority: $priority, read: $read, readAt: $readAt, expiresAt: $expiresAt)';
  }
}

/// @nodoc
abstract mixin class _$NotificationEntityCopyWith<$Res>
    implements $NotificationEntityCopyWith<$Res> {
  factory _$NotificationEntityCopyWith(
          _NotificationEntity value, $Res Function(_NotificationEntity) _then) =
      __$NotificationEntityCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String notificationId,
      @NotificationTypeConverter() NotificationType type,
      String recipientUid,
      String recipientProfileId,
      String title,
      String message,
      @TimestampConverter() DateTime createdAt,
      String? senderUid,
      String? senderProfileId,
      String? senderName,
      String? senderPhoto,
      Map<String, dynamic> data,
      @NullableNotificationActionTypeConverter()
      NotificationActionType? actionType,
      Map<String, dynamic>? actionData,
      @NotificationPriorityConverter() NotificationPriority priority,
      bool read,
      @NullableTimestampConverter() DateTime? readAt,
      @NullableTimestampConverter() DateTime? expiresAt});
}

/// @nodoc
class __$NotificationEntityCopyWithImpl<$Res>
    implements _$NotificationEntityCopyWith<$Res> {
  __$NotificationEntityCopyWithImpl(this._self, this._then);

  final _NotificationEntity _self;
  final $Res Function(_NotificationEntity) _then;

  /// Create a copy of NotificationEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? notificationId = null,
    Object? type = null,
    Object? recipientUid = null,
    Object? recipientProfileId = null,
    Object? title = null,
    Object? message = null,
    Object? createdAt = null,
    Object? senderUid = freezed,
    Object? senderProfileId = freezed,
    Object? senderName = freezed,
    Object? senderPhoto = freezed,
    Object? data = null,
    Object? actionType = freezed,
    Object? actionData = freezed,
    Object? priority = null,
    Object? read = null,
    Object? readAt = freezed,
    Object? expiresAt = freezed,
  }) {
    return _then(_NotificationEntity(
      notificationId: null == notificationId
          ? _self.notificationId
          : notificationId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as NotificationType,
      recipientUid: null == recipientUid
          ? _self.recipientUid
          : recipientUid // ignore: cast_nullable_to_non_nullable
              as String,
      recipientProfileId: null == recipientProfileId
          ? _self.recipientProfileId
          : recipientProfileId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _self.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      senderUid: freezed == senderUid
          ? _self.senderUid
          : senderUid // ignore: cast_nullable_to_non_nullable
              as String?,
      senderProfileId: freezed == senderProfileId
          ? _self.senderProfileId
          : senderProfileId // ignore: cast_nullable_to_non_nullable
              as String?,
      senderName: freezed == senderName
          ? _self.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String?,
      senderPhoto: freezed == senderPhoto
          ? _self.senderPhoto
          : senderPhoto // ignore: cast_nullable_to_non_nullable
              as String?,
      data: null == data
          ? _self._data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      actionType: freezed == actionType
          ? _self.actionType
          : actionType // ignore: cast_nullable_to_non_nullable
              as NotificationActionType?,
      actionData: freezed == actionData
          ? _self._actionData
          : actionData // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      priority: null == priority
          ? _self.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as NotificationPriority,
      read: null == read
          ? _self.read
          : read // ignore: cast_nullable_to_non_nullable
              as bool,
      readAt: freezed == readAt
          ? _self.readAt
          : readAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      expiresAt: freezed == expiresAt
          ? _self.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
