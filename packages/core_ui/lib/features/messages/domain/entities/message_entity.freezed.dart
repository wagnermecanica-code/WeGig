// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MessageEntity {
  String get messageId;
  String get senderId;
  String get senderProfileId;
  String get text;
  DateTime get timestamp;
  String? get imageUrl;
  MessageReplyEntity? get replyTo;
  Map<String, String> get reactions;
  bool get read;

  /// Create a copy of MessageEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MessageEntityCopyWith<MessageEntity> get copyWith =>
      _$MessageEntityCopyWithImpl<MessageEntity>(
          this as MessageEntity, _$identity);

  /// Serializes this MessageEntity to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MessageEntity &&
            (identical(other.messageId, messageId) ||
                other.messageId == messageId) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.senderProfileId, senderProfileId) ||
                other.senderProfileId == senderProfileId) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.replyTo, replyTo) || other.replyTo == replyTo) &&
            const DeepCollectionEquality().equals(other.reactions, reactions) &&
            (identical(other.read, read) || other.read == read));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      messageId,
      senderId,
      senderProfileId,
      text,
      timestamp,
      imageUrl,
      replyTo,
      const DeepCollectionEquality().hash(reactions),
      read);

  @override
  String toString() {
    return 'MessageEntity(messageId: $messageId, senderId: $senderId, senderProfileId: $senderProfileId, text: $text, timestamp: $timestamp, imageUrl: $imageUrl, replyTo: $replyTo, reactions: $reactions, read: $read)';
  }
}

/// @nodoc
abstract mixin class $MessageEntityCopyWith<$Res> {
  factory $MessageEntityCopyWith(
          MessageEntity value, $Res Function(MessageEntity) _then) =
      _$MessageEntityCopyWithImpl;
  @useResult
  $Res call(
      {String messageId,
      String senderId,
      String senderProfileId,
      String text,
      DateTime timestamp,
      String? imageUrl,
      MessageReplyEntity? replyTo,
      Map<String, String> reactions,
      bool read});

  $MessageReplyEntityCopyWith<$Res>? get replyTo;
}

/// @nodoc
class _$MessageEntityCopyWithImpl<$Res>
    implements $MessageEntityCopyWith<$Res> {
  _$MessageEntityCopyWithImpl(this._self, this._then);

  final MessageEntity _self;
  final $Res Function(MessageEntity) _then;

  /// Create a copy of MessageEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messageId = null,
    Object? senderId = null,
    Object? senderProfileId = null,
    Object? text = null,
    Object? timestamp = null,
    Object? imageUrl = freezed,
    Object? replyTo = freezed,
    Object? reactions = null,
    Object? read = null,
  }) {
    return _then(_self.copyWith(
      messageId: null == messageId
          ? _self.messageId
          : messageId // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _self.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      senderProfileId: null == senderProfileId
          ? _self.senderProfileId
          : senderProfileId // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _self.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      imageUrl: freezed == imageUrl
          ? _self.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      replyTo: freezed == replyTo
          ? _self.replyTo
          : replyTo // ignore: cast_nullable_to_non_nullable
              as MessageReplyEntity?,
      reactions: null == reactions
          ? _self.reactions
          : reactions // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      read: null == read
          ? _self.read
          : read // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }

  /// Create a copy of MessageEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MessageReplyEntityCopyWith<$Res>? get replyTo {
    if (_self.replyTo == null) {
      return null;
    }

    return $MessageReplyEntityCopyWith<$Res>(_self.replyTo!, (value) {
      return _then(_self.copyWith(replyTo: value));
    });
  }
}

/// Adds pattern-matching-related methods to [MessageEntity].
extension MessageEntityPatterns on MessageEntity {
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
    TResult Function(_MessageEntity value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MessageEntity() when $default != null:
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
    TResult Function(_MessageEntity value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MessageEntity():
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
    TResult? Function(_MessageEntity value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MessageEntity() when $default != null:
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
            String messageId,
            String senderId,
            String senderProfileId,
            String text,
            DateTime timestamp,
            String? imageUrl,
            MessageReplyEntity? replyTo,
            Map<String, String> reactions,
            bool read)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MessageEntity() when $default != null:
        return $default(
            _that.messageId,
            _that.senderId,
            _that.senderProfileId,
            _that.text,
            _that.timestamp,
            _that.imageUrl,
            _that.replyTo,
            _that.reactions,
            _that.read);
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
            String messageId,
            String senderId,
            String senderProfileId,
            String text,
            DateTime timestamp,
            String? imageUrl,
            MessageReplyEntity? replyTo,
            Map<String, String> reactions,
            bool read)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MessageEntity():
        return $default(
            _that.messageId,
            _that.senderId,
            _that.senderProfileId,
            _that.text,
            _that.timestamp,
            _that.imageUrl,
            _that.replyTo,
            _that.reactions,
            _that.read);
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
            String messageId,
            String senderId,
            String senderProfileId,
            String text,
            DateTime timestamp,
            String? imageUrl,
            MessageReplyEntity? replyTo,
            Map<String, String> reactions,
            bool read)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MessageEntity() when $default != null:
        return $default(
            _that.messageId,
            _that.senderId,
            _that.senderProfileId,
            _that.text,
            _that.timestamp,
            _that.imageUrl,
            _that.replyTo,
            _that.reactions,
            _that.read);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _MessageEntity extends MessageEntity {
  const _MessageEntity(
      {required this.messageId,
      required this.senderId,
      required this.senderProfileId,
      required this.text,
      required this.timestamp,
      this.imageUrl,
      this.replyTo,
      final Map<String, String> reactions = const {},
      this.read = false})
      : _reactions = reactions,
        super._();
  factory _MessageEntity.fromJson(Map<String, dynamic> json) =>
      _$MessageEntityFromJson(json);

  @override
  final String messageId;
  @override
  final String senderId;
  @override
  final String senderProfileId;
  @override
  final String text;
  @override
  final DateTime timestamp;
  @override
  final String? imageUrl;
  @override
  final MessageReplyEntity? replyTo;
  final Map<String, String> _reactions;
  @override
  @JsonKey()
  Map<String, String> get reactions {
    if (_reactions is EqualUnmodifiableMapView) return _reactions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_reactions);
  }

  @override
  @JsonKey()
  final bool read;

  /// Create a copy of MessageEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MessageEntityCopyWith<_MessageEntity> get copyWith =>
      __$MessageEntityCopyWithImpl<_MessageEntity>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$MessageEntityToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MessageEntity &&
            (identical(other.messageId, messageId) ||
                other.messageId == messageId) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.senderProfileId, senderProfileId) ||
                other.senderProfileId == senderProfileId) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.replyTo, replyTo) || other.replyTo == replyTo) &&
            const DeepCollectionEquality()
                .equals(other._reactions, _reactions) &&
            (identical(other.read, read) || other.read == read));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      messageId,
      senderId,
      senderProfileId,
      text,
      timestamp,
      imageUrl,
      replyTo,
      const DeepCollectionEquality().hash(_reactions),
      read);

  @override
  String toString() {
    return 'MessageEntity(messageId: $messageId, senderId: $senderId, senderProfileId: $senderProfileId, text: $text, timestamp: $timestamp, imageUrl: $imageUrl, replyTo: $replyTo, reactions: $reactions, read: $read)';
  }
}

/// @nodoc
abstract mixin class _$MessageEntityCopyWith<$Res>
    implements $MessageEntityCopyWith<$Res> {
  factory _$MessageEntityCopyWith(
          _MessageEntity value, $Res Function(_MessageEntity) _then) =
      __$MessageEntityCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String messageId,
      String senderId,
      String senderProfileId,
      String text,
      DateTime timestamp,
      String? imageUrl,
      MessageReplyEntity? replyTo,
      Map<String, String> reactions,
      bool read});

  @override
  $MessageReplyEntityCopyWith<$Res>? get replyTo;
}

/// @nodoc
class __$MessageEntityCopyWithImpl<$Res>
    implements _$MessageEntityCopyWith<$Res> {
  __$MessageEntityCopyWithImpl(this._self, this._then);

  final _MessageEntity _self;
  final $Res Function(_MessageEntity) _then;

  /// Create a copy of MessageEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? messageId = null,
    Object? senderId = null,
    Object? senderProfileId = null,
    Object? text = null,
    Object? timestamp = null,
    Object? imageUrl = freezed,
    Object? replyTo = freezed,
    Object? reactions = null,
    Object? read = null,
  }) {
    return _then(_MessageEntity(
      messageId: null == messageId
          ? _self.messageId
          : messageId // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _self.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      senderProfileId: null == senderProfileId
          ? _self.senderProfileId
          : senderProfileId // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _self.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      imageUrl: freezed == imageUrl
          ? _self.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      replyTo: freezed == replyTo
          ? _self.replyTo
          : replyTo // ignore: cast_nullable_to_non_nullable
              as MessageReplyEntity?,
      reactions: null == reactions
          ? _self._reactions
          : reactions // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      read: null == read
          ? _self.read
          : read // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }

  /// Create a copy of MessageEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MessageReplyEntityCopyWith<$Res>? get replyTo {
    if (_self.replyTo == null) {
      return null;
    }

    return $MessageReplyEntityCopyWith<$Res>(_self.replyTo!, (value) {
      return _then(_self.copyWith(replyTo: value));
    });
  }
}

/// @nodoc
mixin _$MessageReplyEntity {
  String get messageId;
  String get text;
  String get senderId;
  String? get senderProfileId;

  /// Create a copy of MessageReplyEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MessageReplyEntityCopyWith<MessageReplyEntity> get copyWith =>
      _$MessageReplyEntityCopyWithImpl<MessageReplyEntity>(
          this as MessageReplyEntity, _$identity);

  /// Serializes this MessageReplyEntity to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MessageReplyEntity &&
            (identical(other.messageId, messageId) ||
                other.messageId == messageId) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.senderProfileId, senderProfileId) ||
                other.senderProfileId == senderProfileId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, messageId, text, senderId, senderProfileId);

  @override
  String toString() {
    return 'MessageReplyEntity(messageId: $messageId, text: $text, senderId: $senderId, senderProfileId: $senderProfileId)';
  }
}

/// @nodoc
abstract mixin class $MessageReplyEntityCopyWith<$Res> {
  factory $MessageReplyEntityCopyWith(
          MessageReplyEntity value, $Res Function(MessageReplyEntity) _then) =
      _$MessageReplyEntityCopyWithImpl;
  @useResult
  $Res call(
      {String messageId,
      String text,
      String senderId,
      String? senderProfileId});
}

/// @nodoc
class _$MessageReplyEntityCopyWithImpl<$Res>
    implements $MessageReplyEntityCopyWith<$Res> {
  _$MessageReplyEntityCopyWithImpl(this._self, this._then);

  final MessageReplyEntity _self;
  final $Res Function(MessageReplyEntity) _then;

  /// Create a copy of MessageReplyEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messageId = null,
    Object? text = null,
    Object? senderId = null,
    Object? senderProfileId = freezed,
  }) {
    return _then(_self.copyWith(
      messageId: null == messageId
          ? _self.messageId
          : messageId // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _self.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _self.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      senderProfileId: freezed == senderProfileId
          ? _self.senderProfileId
          : senderProfileId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [MessageReplyEntity].
extension MessageReplyEntityPatterns on MessageReplyEntity {
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
    TResult Function(_MessageReplyEntity value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MessageReplyEntity() when $default != null:
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
    TResult Function(_MessageReplyEntity value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MessageReplyEntity():
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
    TResult? Function(_MessageReplyEntity value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MessageReplyEntity() when $default != null:
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
    TResult Function(String messageId, String text, String senderId,
            String? senderProfileId)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MessageReplyEntity() when $default != null:
        return $default(
            _that.messageId, _that.text, _that.senderId, _that.senderProfileId);
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
    TResult Function(String messageId, String text, String senderId,
            String? senderProfileId)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MessageReplyEntity():
        return $default(
            _that.messageId, _that.text, _that.senderId, _that.senderProfileId);
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
    TResult? Function(String messageId, String text, String senderId,
            String? senderProfileId)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MessageReplyEntity() when $default != null:
        return $default(
            _that.messageId, _that.text, _that.senderId, _that.senderProfileId);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _MessageReplyEntity extends MessageReplyEntity {
  const _MessageReplyEntity(
      {required this.messageId,
      required this.text,
      required this.senderId,
      this.senderProfileId})
      : super._();
  factory _MessageReplyEntity.fromJson(Map<String, dynamic> json) =>
      _$MessageReplyEntityFromJson(json);

  @override
  final String messageId;
  @override
  final String text;
  @override
  final String senderId;
  @override
  final String? senderProfileId;

  /// Create a copy of MessageReplyEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MessageReplyEntityCopyWith<_MessageReplyEntity> get copyWith =>
      __$MessageReplyEntityCopyWithImpl<_MessageReplyEntity>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$MessageReplyEntityToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MessageReplyEntity &&
            (identical(other.messageId, messageId) ||
                other.messageId == messageId) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.senderProfileId, senderProfileId) ||
                other.senderProfileId == senderProfileId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, messageId, text, senderId, senderProfileId);

  @override
  String toString() {
    return 'MessageReplyEntity(messageId: $messageId, text: $text, senderId: $senderId, senderProfileId: $senderProfileId)';
  }
}

/// @nodoc
abstract mixin class _$MessageReplyEntityCopyWith<$Res>
    implements $MessageReplyEntityCopyWith<$Res> {
  factory _$MessageReplyEntityCopyWith(
          _MessageReplyEntity value, $Res Function(_MessageReplyEntity) _then) =
      __$MessageReplyEntityCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String messageId,
      String text,
      String senderId,
      String? senderProfileId});
}

/// @nodoc
class __$MessageReplyEntityCopyWithImpl<$Res>
    implements _$MessageReplyEntityCopyWith<$Res> {
  __$MessageReplyEntityCopyWithImpl(this._self, this._then);

  final _MessageReplyEntity _self;
  final $Res Function(_MessageReplyEntity) _then;

  /// Create a copy of MessageReplyEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? messageId = null,
    Object? text = null,
    Object? senderId = null,
    Object? senderProfileId = freezed,
  }) {
    return _then(_MessageReplyEntity(
      messageId: null == messageId
          ? _self.messageId
          : messageId // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _self.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _self.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      senderProfileId: freezed == senderProfileId
          ? _self.senderProfileId
          : senderProfileId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
