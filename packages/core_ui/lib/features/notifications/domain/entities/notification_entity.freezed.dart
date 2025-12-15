// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

NotificationEntity _$NotificationEntityFromJson(Map<String, dynamic> json) {
  return _NotificationEntity.fromJson(json);
}

/// @nodoc
mixin _$NotificationEntity {
  String get notificationId => throw _privateConstructorUsedError;
  @NotificationTypeConverter()
  NotificationType get type => throw _privateConstructorUsedError;
  String get recipientUid => throw _privateConstructorUsedError;
  String get recipientProfileId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  String? get senderUid => throw _privateConstructorUsedError;
  String? get senderProfileId => throw _privateConstructorUsedError;
  String? get senderName => throw _privateConstructorUsedError;
  String? get senderUsername => throw _privateConstructorUsedError;
  String? get senderPhoto => throw _privateConstructorUsedError;
  Map<String, dynamic> get data => throw _privateConstructorUsedError;
  @NullableNotificationActionTypeConverter()
  NotificationActionType? get actionType => throw _privateConstructorUsedError;
  Map<String, dynamic>? get actionData => throw _privateConstructorUsedError;
  @NotificationPriorityConverter()
  NotificationPriority get priority => throw _privateConstructorUsedError;
  bool get read => throw _privateConstructorUsedError;
  @NullableTimestampConverter()
  DateTime? get readAt => throw _privateConstructorUsedError;
  @NullableTimestampConverter()
  DateTime? get expiresAt =>
      throw _privateConstructorUsedError; // Documento Firestore para paginação cursor-based
  @JsonKey(includeFromJson: false, includeToJson: false)
  DocumentSnapshot<Object?>? get document => throw _privateConstructorUsedError;

  /// Serializes this NotificationEntity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NotificationEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NotificationEntityCopyWith<NotificationEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationEntityCopyWith<$Res> {
  factory $NotificationEntityCopyWith(
          NotificationEntity value, $Res Function(NotificationEntity) then) =
      _$NotificationEntityCopyWithImpl<$Res, NotificationEntity>;
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
      String? senderUsername,
      String? senderPhoto,
      Map<String, dynamic> data,
      @NullableNotificationActionTypeConverter()
      NotificationActionType? actionType,
      Map<String, dynamic>? actionData,
      @NotificationPriorityConverter() NotificationPriority priority,
      bool read,
      @NullableTimestampConverter() DateTime? readAt,
      @NullableTimestampConverter() DateTime? expiresAt,
      @JsonKey(includeFromJson: false, includeToJson: false)
      DocumentSnapshot<Object?>? document});
}

/// @nodoc
class _$NotificationEntityCopyWithImpl<$Res, $Val extends NotificationEntity>
    implements $NotificationEntityCopyWith<$Res> {
  _$NotificationEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

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
    Object? senderUsername = freezed,
    Object? senderPhoto = freezed,
    Object? data = null,
    Object? actionType = freezed,
    Object? actionData = freezed,
    Object? priority = null,
    Object? read = null,
    Object? readAt = freezed,
    Object? expiresAt = freezed,
    Object? document = freezed,
  }) {
    return _then(_value.copyWith(
      notificationId: null == notificationId
          ? _value.notificationId
          : notificationId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as NotificationType,
      recipientUid: null == recipientUid
          ? _value.recipientUid
          : recipientUid // ignore: cast_nullable_to_non_nullable
              as String,
      recipientProfileId: null == recipientProfileId
          ? _value.recipientProfileId
          : recipientProfileId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      senderUid: freezed == senderUid
          ? _value.senderUid
          : senderUid // ignore: cast_nullable_to_non_nullable
              as String?,
      senderProfileId: freezed == senderProfileId
          ? _value.senderProfileId
          : senderProfileId // ignore: cast_nullable_to_non_nullable
              as String?,
      senderName: freezed == senderName
          ? _value.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String?,
      senderUsername: freezed == senderUsername
          ? _value.senderUsername
          : senderUsername // ignore: cast_nullable_to_non_nullable
              as String?,
      senderPhoto: freezed == senderPhoto
          ? _value.senderPhoto
          : senderPhoto // ignore: cast_nullable_to_non_nullable
              as String?,
      data: null == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      actionType: freezed == actionType
          ? _value.actionType
          : actionType // ignore: cast_nullable_to_non_nullable
              as NotificationActionType?,
      actionData: freezed == actionData
          ? _value.actionData
          : actionData // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as NotificationPriority,
      read: null == read
          ? _value.read
          : read // ignore: cast_nullable_to_non_nullable
              as bool,
      readAt: freezed == readAt
          ? _value.readAt
          : readAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      document: freezed == document
          ? _value.document
          : document // ignore: cast_nullable_to_non_nullable
              as DocumentSnapshot<Object?>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NotificationEntityImplCopyWith<$Res>
    implements $NotificationEntityCopyWith<$Res> {
  factory _$$NotificationEntityImplCopyWith(_$NotificationEntityImpl value,
          $Res Function(_$NotificationEntityImpl) then) =
      __$$NotificationEntityImplCopyWithImpl<$Res>;
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
      String? senderUsername,
      String? senderPhoto,
      Map<String, dynamic> data,
      @NullableNotificationActionTypeConverter()
      NotificationActionType? actionType,
      Map<String, dynamic>? actionData,
      @NotificationPriorityConverter() NotificationPriority priority,
      bool read,
      @NullableTimestampConverter() DateTime? readAt,
      @NullableTimestampConverter() DateTime? expiresAt,
      @JsonKey(includeFromJson: false, includeToJson: false)
      DocumentSnapshot<Object?>? document});
}

/// @nodoc
class __$$NotificationEntityImplCopyWithImpl<$Res>
    extends _$NotificationEntityCopyWithImpl<$Res, _$NotificationEntityImpl>
    implements _$$NotificationEntityImplCopyWith<$Res> {
  __$$NotificationEntityImplCopyWithImpl(_$NotificationEntityImpl _value,
      $Res Function(_$NotificationEntityImpl) _then)
      : super(_value, _then);

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
    Object? senderUsername = freezed,
    Object? senderPhoto = freezed,
    Object? data = null,
    Object? actionType = freezed,
    Object? actionData = freezed,
    Object? priority = null,
    Object? read = null,
    Object? readAt = freezed,
    Object? expiresAt = freezed,
    Object? document = freezed,
  }) {
    return _then(_$NotificationEntityImpl(
      notificationId: null == notificationId
          ? _value.notificationId
          : notificationId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as NotificationType,
      recipientUid: null == recipientUid
          ? _value.recipientUid
          : recipientUid // ignore: cast_nullable_to_non_nullable
              as String,
      recipientProfileId: null == recipientProfileId
          ? _value.recipientProfileId
          : recipientProfileId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      senderUid: freezed == senderUid
          ? _value.senderUid
          : senderUid // ignore: cast_nullable_to_non_nullable
              as String?,
      senderProfileId: freezed == senderProfileId
          ? _value.senderProfileId
          : senderProfileId // ignore: cast_nullable_to_non_nullable
              as String?,
      senderName: freezed == senderName
          ? _value.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String?,
      senderUsername: freezed == senderUsername
          ? _value.senderUsername
          : senderUsername // ignore: cast_nullable_to_non_nullable
              as String?,
      senderPhoto: freezed == senderPhoto
          ? _value.senderPhoto
          : senderPhoto // ignore: cast_nullable_to_non_nullable
              as String?,
      data: null == data
          ? _value._data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      actionType: freezed == actionType
          ? _value.actionType
          : actionType // ignore: cast_nullable_to_non_nullable
              as NotificationActionType?,
      actionData: freezed == actionData
          ? _value._actionData
          : actionData // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as NotificationPriority,
      read: null == read
          ? _value.read
          : read // ignore: cast_nullable_to_non_nullable
              as bool,
      readAt: freezed == readAt
          ? _value.readAt
          : readAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      document: freezed == document
          ? _value.document
          : document // ignore: cast_nullable_to_non_nullable
              as DocumentSnapshot<Object?>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NotificationEntityImpl extends _NotificationEntity {
  const _$NotificationEntityImpl(
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
      this.senderUsername,
      this.senderPhoto,
      final Map<String, dynamic> data = const {},
      @NullableNotificationActionTypeConverter() this.actionType,
      final Map<String, dynamic>? actionData,
      @NotificationPriorityConverter()
      this.priority = NotificationPriority.medium,
      this.read = false,
      @NullableTimestampConverter() this.readAt,
      @NullableTimestampConverter() this.expiresAt,
      @JsonKey(includeFromJson: false, includeToJson: false) this.document})
      : _data = data,
        _actionData = actionData,
        super._();

  factory _$NotificationEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$NotificationEntityImplFromJson(json);

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
  final String? senderUsername;
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
// Documento Firestore para paginação cursor-based
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final DocumentSnapshot<Object?>? document;

  @override
  String toString() {
    return 'NotificationEntity(notificationId: $notificationId, type: $type, recipientUid: $recipientUid, recipientProfileId: $recipientProfileId, title: $title, message: $message, createdAt: $createdAt, senderUid: $senderUid, senderProfileId: $senderProfileId, senderName: $senderName, senderUsername: $senderUsername, senderPhoto: $senderPhoto, data: $data, actionType: $actionType, actionData: $actionData, priority: $priority, read: $read, readAt: $readAt, expiresAt: $expiresAt, document: $document)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationEntityImpl &&
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
            (identical(other.senderUsername, senderUsername) ||
                other.senderUsername == senderUsername) &&
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
                other.expiresAt == expiresAt) &&
            (identical(other.document, document) ||
                other.document == document));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
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
        senderUsername,
        senderPhoto,
        const DeepCollectionEquality().hash(_data),
        actionType,
        const DeepCollectionEquality().hash(_actionData),
        priority,
        read,
        readAt,
        expiresAt,
        document
      ]);

  /// Create a copy of NotificationEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationEntityImplCopyWith<_$NotificationEntityImpl> get copyWith =>
      __$$NotificationEntityImplCopyWithImpl<_$NotificationEntityImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NotificationEntityImplToJson(
      this,
    );
  }
}

abstract class _NotificationEntity extends NotificationEntity {
  const factory _NotificationEntity(
      {required final String notificationId,
      @NotificationTypeConverter() required final NotificationType type,
      required final String recipientUid,
      required final String recipientProfileId,
      required final String title,
      required final String message,
      @TimestampConverter() required final DateTime createdAt,
      final String? senderUid,
      final String? senderProfileId,
      final String? senderName,
      final String? senderUsername,
      final String? senderPhoto,
      final Map<String, dynamic> data,
      @NullableNotificationActionTypeConverter()
      final NotificationActionType? actionType,
      final Map<String, dynamic>? actionData,
      @NotificationPriorityConverter() final NotificationPriority priority,
      final bool read,
      @NullableTimestampConverter() final DateTime? readAt,
      @NullableTimestampConverter() final DateTime? expiresAt,
      @JsonKey(includeFromJson: false, includeToJson: false)
      final DocumentSnapshot<Object?>? document}) = _$NotificationEntityImpl;
  const _NotificationEntity._() : super._();

  factory _NotificationEntity.fromJson(Map<String, dynamic> json) =
      _$NotificationEntityImpl.fromJson;

  @override
  String get notificationId;
  @override
  @NotificationTypeConverter()
  NotificationType get type;
  @override
  String get recipientUid;
  @override
  String get recipientProfileId;
  @override
  String get title;
  @override
  String get message;
  @override
  @TimestampConverter()
  DateTime get createdAt;
  @override
  String? get senderUid;
  @override
  String? get senderProfileId;
  @override
  String? get senderName;
  @override
  String? get senderUsername;
  @override
  String? get senderPhoto;
  @override
  Map<String, dynamic> get data;
  @override
  @NullableNotificationActionTypeConverter()
  NotificationActionType? get actionType;
  @override
  Map<String, dynamic>? get actionData;
  @override
  @NotificationPriorityConverter()
  NotificationPriority get priority;
  @override
  bool get read;
  @override
  @NullableTimestampConverter()
  DateTime? get readAt;
  @override
  @NullableTimestampConverter()
  DateTime? get expiresAt; // Documento Firestore para paginação cursor-based
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  DocumentSnapshot<Object?>? get document;

  /// Create a copy of NotificationEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotificationEntityImplCopyWith<_$NotificationEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
