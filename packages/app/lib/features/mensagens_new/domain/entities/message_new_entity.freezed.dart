// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message_new_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MessageNewEntity _$MessageNewEntityFromJson(Map<String, dynamic> json) {
  return _MessageNewEntity.fromJson(json);
}

/// @nodoc
mixin _$MessageNewEntity {
  /// ID único da mensagem no Firestore
  String get id => throw _privateConstructorUsedError;

  /// ID da conversa pai
  String get conversationId => throw _privateConstructorUsedError;

  /// UID do remetente (Firebase Auth)
  String get senderId => throw _privateConstructorUsedError;

  /// ProfileId do remetente
  String get senderProfileId => throw _privateConstructorUsedError;

  /// Nome do remetente (desnormalizado para performance)
  String? get senderName => throw _privateConstructorUsedError;

  /// Foto do remetente (desnormalizado para performance)
  String? get senderPhotoUrl => throw _privateConstructorUsedError;

  /// Conteúdo textual da mensagem
  String get text => throw _privateConstructorUsedError;

  /// URL da imagem (se houver)
  String? get imageUrl => throw _privateConstructorUsedError;

  /// Tipo da mensagem
  MessageType get type => throw _privateConstructorUsedError;

  /// Status de entrega
  MessageDeliveryStatus get status => throw _privateConstructorUsedError;

  /// Timestamp de criação
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Timestamp de edição (null se nunca editado)
  DateTime? get editedAt => throw _privateConstructorUsedError;

  /// Se a mensagem foi editada
  bool get isEdited => throw _privateConstructorUsedError;

  /// Reações: Map<profileId, emoji>
  Map<String, String> get reactions => throw _privateConstructorUsedError;

  /// Dados da mensagem que está sendo respondida
  MessageReplyData? get replyTo => throw _privateConstructorUsedError;

  /// Lista de profileIds que deletaram a mensagem "para mim"
  List<String> get deletedForProfiles => throw _privateConstructorUsedError;

  /// Se a mensagem foi deletada para todos
  bool get deletedForEveryone => throw _privateConstructorUsedError;

  /// Texto original (antes de deletar para todos)
  String? get originalText => throw _privateConstructorUsedError;

  /// Metadados extras (extensível)
  Map<String, dynamic> get metadata => throw _privateConstructorUsedError;

  /// Serializes this MessageNewEntity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MessageNewEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MessageNewEntityCopyWith<MessageNewEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageNewEntityCopyWith<$Res> {
  factory $MessageNewEntityCopyWith(
          MessageNewEntity value, $Res Function(MessageNewEntity) then) =
      _$MessageNewEntityCopyWithImpl<$Res, MessageNewEntity>;
  @useResult
  $Res call(
      {String id,
      String conversationId,
      String senderId,
      String senderProfileId,
      String? senderName,
      String? senderPhotoUrl,
      String text,
      String? imageUrl,
      MessageType type,
      MessageDeliveryStatus status,
      DateTime createdAt,
      DateTime? editedAt,
      bool isEdited,
      Map<String, String> reactions,
      MessageReplyData? replyTo,
      List<String> deletedForProfiles,
      bool deletedForEveryone,
      String? originalText,
      Map<String, dynamic> metadata});

  $MessageReplyDataCopyWith<$Res>? get replyTo;
}

/// @nodoc
class _$MessageNewEntityCopyWithImpl<$Res, $Val extends MessageNewEntity>
    implements $MessageNewEntityCopyWith<$Res> {
  _$MessageNewEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MessageNewEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? conversationId = null,
    Object? senderId = null,
    Object? senderProfileId = null,
    Object? senderName = freezed,
    Object? senderPhotoUrl = freezed,
    Object? text = null,
    Object? imageUrl = freezed,
    Object? type = null,
    Object? status = null,
    Object? createdAt = null,
    Object? editedAt = freezed,
    Object? isEdited = null,
    Object? reactions = null,
    Object? replyTo = freezed,
    Object? deletedForProfiles = null,
    Object? deletedForEveryone = null,
    Object? originalText = freezed,
    Object? metadata = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      conversationId: null == conversationId
          ? _value.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      senderProfileId: null == senderProfileId
          ? _value.senderProfileId
          : senderProfileId // ignore: cast_nullable_to_non_nullable
              as String,
      senderName: freezed == senderName
          ? _value.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String?,
      senderPhotoUrl: freezed == senderPhotoUrl
          ? _value.senderPhotoUrl
          : senderPhotoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as MessageType,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as MessageDeliveryStatus,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      editedAt: freezed == editedAt
          ? _value.editedAt
          : editedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isEdited: null == isEdited
          ? _value.isEdited
          : isEdited // ignore: cast_nullable_to_non_nullable
              as bool,
      reactions: null == reactions
          ? _value.reactions
          : reactions // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      replyTo: freezed == replyTo
          ? _value.replyTo
          : replyTo // ignore: cast_nullable_to_non_nullable
              as MessageReplyData?,
      deletedForProfiles: null == deletedForProfiles
          ? _value.deletedForProfiles
          : deletedForProfiles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      deletedForEveryone: null == deletedForEveryone
          ? _value.deletedForEveryone
          : deletedForEveryone // ignore: cast_nullable_to_non_nullable
              as bool,
      originalText: freezed == originalText
          ? _value.originalText
          : originalText // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }

  /// Create a copy of MessageNewEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MessageReplyDataCopyWith<$Res>? get replyTo {
    if (_value.replyTo == null) {
      return null;
    }

    return $MessageReplyDataCopyWith<$Res>(_value.replyTo!, (value) {
      return _then(_value.copyWith(replyTo: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MessageNewEntityImplCopyWith<$Res>
    implements $MessageNewEntityCopyWith<$Res> {
  factory _$$MessageNewEntityImplCopyWith(_$MessageNewEntityImpl value,
          $Res Function(_$MessageNewEntityImpl) then) =
      __$$MessageNewEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String conversationId,
      String senderId,
      String senderProfileId,
      String? senderName,
      String? senderPhotoUrl,
      String text,
      String? imageUrl,
      MessageType type,
      MessageDeliveryStatus status,
      DateTime createdAt,
      DateTime? editedAt,
      bool isEdited,
      Map<String, String> reactions,
      MessageReplyData? replyTo,
      List<String> deletedForProfiles,
      bool deletedForEveryone,
      String? originalText,
      Map<String, dynamic> metadata});

  @override
  $MessageReplyDataCopyWith<$Res>? get replyTo;
}

/// @nodoc
class __$$MessageNewEntityImplCopyWithImpl<$Res>
    extends _$MessageNewEntityCopyWithImpl<$Res, _$MessageNewEntityImpl>
    implements _$$MessageNewEntityImplCopyWith<$Res> {
  __$$MessageNewEntityImplCopyWithImpl(_$MessageNewEntityImpl _value,
      $Res Function(_$MessageNewEntityImpl) _then)
      : super(_value, _then);

  /// Create a copy of MessageNewEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? conversationId = null,
    Object? senderId = null,
    Object? senderProfileId = null,
    Object? senderName = freezed,
    Object? senderPhotoUrl = freezed,
    Object? text = null,
    Object? imageUrl = freezed,
    Object? type = null,
    Object? status = null,
    Object? createdAt = null,
    Object? editedAt = freezed,
    Object? isEdited = null,
    Object? reactions = null,
    Object? replyTo = freezed,
    Object? deletedForProfiles = null,
    Object? deletedForEveryone = null,
    Object? originalText = freezed,
    Object? metadata = null,
  }) {
    return _then(_$MessageNewEntityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      conversationId: null == conversationId
          ? _value.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      senderProfileId: null == senderProfileId
          ? _value.senderProfileId
          : senderProfileId // ignore: cast_nullable_to_non_nullable
              as String,
      senderName: freezed == senderName
          ? _value.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String?,
      senderPhotoUrl: freezed == senderPhotoUrl
          ? _value.senderPhotoUrl
          : senderPhotoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as MessageType,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as MessageDeliveryStatus,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      editedAt: freezed == editedAt
          ? _value.editedAt
          : editedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isEdited: null == isEdited
          ? _value.isEdited
          : isEdited // ignore: cast_nullable_to_non_nullable
              as bool,
      reactions: null == reactions
          ? _value._reactions
          : reactions // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      replyTo: freezed == replyTo
          ? _value.replyTo
          : replyTo // ignore: cast_nullable_to_non_nullable
              as MessageReplyData?,
      deletedForProfiles: null == deletedForProfiles
          ? _value._deletedForProfiles
          : deletedForProfiles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      deletedForEveryone: null == deletedForEveryone
          ? _value.deletedForEveryone
          : deletedForEveryone // ignore: cast_nullable_to_non_nullable
              as bool,
      originalText: freezed == originalText
          ? _value.originalText
          : originalText // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: null == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MessageNewEntityImpl extends _MessageNewEntity {
  const _$MessageNewEntityImpl(
      {required this.id,
      required this.conversationId,
      required this.senderId,
      required this.senderProfileId,
      this.senderName,
      this.senderPhotoUrl,
      required this.text,
      this.imageUrl,
      this.type = MessageType.text,
      this.status = MessageDeliveryStatus.sending,
      required this.createdAt,
      this.editedAt,
      this.isEdited = false,
      final Map<String, String> reactions = const {},
      this.replyTo,
      final List<String> deletedForProfiles = const [],
      this.deletedForEveryone = false,
      this.originalText,
      final Map<String, dynamic> metadata = const {}})
      : _reactions = reactions,
        _deletedForProfiles = deletedForProfiles,
        _metadata = metadata,
        super._();

  factory _$MessageNewEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$MessageNewEntityImplFromJson(json);

  /// ID único da mensagem no Firestore
  @override
  final String id;

  /// ID da conversa pai
  @override
  final String conversationId;

  /// UID do remetente (Firebase Auth)
  @override
  final String senderId;

  /// ProfileId do remetente
  @override
  final String senderProfileId;

  /// Nome do remetente (desnormalizado para performance)
  @override
  final String? senderName;

  /// Foto do remetente (desnormalizado para performance)
  @override
  final String? senderPhotoUrl;

  /// Conteúdo textual da mensagem
  @override
  final String text;

  /// URL da imagem (se houver)
  @override
  final String? imageUrl;

  /// Tipo da mensagem
  @override
  @JsonKey()
  final MessageType type;

  /// Status de entrega
  @override
  @JsonKey()
  final MessageDeliveryStatus status;

  /// Timestamp de criação
  @override
  final DateTime createdAt;

  /// Timestamp de edição (null se nunca editado)
  @override
  final DateTime? editedAt;

  /// Se a mensagem foi editada
  @override
  @JsonKey()
  final bool isEdited;

  /// Reações: Map<profileId, emoji>
  final Map<String, String> _reactions;

  /// Reações: Map<profileId, emoji>
  @override
  @JsonKey()
  Map<String, String> get reactions {
    if (_reactions is EqualUnmodifiableMapView) return _reactions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_reactions);
  }

  /// Dados da mensagem que está sendo respondida
  @override
  final MessageReplyData? replyTo;

  /// Lista de profileIds que deletaram a mensagem "para mim"
  final List<String> _deletedForProfiles;

  /// Lista de profileIds que deletaram a mensagem "para mim"
  @override
  @JsonKey()
  List<String> get deletedForProfiles {
    if (_deletedForProfiles is EqualUnmodifiableListView)
      return _deletedForProfiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_deletedForProfiles);
  }

  /// Se a mensagem foi deletada para todos
  @override
  @JsonKey()
  final bool deletedForEveryone;

  /// Texto original (antes de deletar para todos)
  @override
  final String? originalText;

  /// Metadados extras (extensível)
  final Map<String, dynamic> _metadata;

  /// Metadados extras (extensível)
  @override
  @JsonKey()
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  @override
  String toString() {
    return 'MessageNewEntity(id: $id, conversationId: $conversationId, senderId: $senderId, senderProfileId: $senderProfileId, senderName: $senderName, senderPhotoUrl: $senderPhotoUrl, text: $text, imageUrl: $imageUrl, type: $type, status: $status, createdAt: $createdAt, editedAt: $editedAt, isEdited: $isEdited, reactions: $reactions, replyTo: $replyTo, deletedForProfiles: $deletedForProfiles, deletedForEveryone: $deletedForEveryone, originalText: $originalText, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageNewEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.conversationId, conversationId) ||
                other.conversationId == conversationId) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.senderProfileId, senderProfileId) ||
                other.senderProfileId == senderProfileId) &&
            (identical(other.senderName, senderName) ||
                other.senderName == senderName) &&
            (identical(other.senderPhotoUrl, senderPhotoUrl) ||
                other.senderPhotoUrl == senderPhotoUrl) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.editedAt, editedAt) ||
                other.editedAt == editedAt) &&
            (identical(other.isEdited, isEdited) ||
                other.isEdited == isEdited) &&
            const DeepCollectionEquality()
                .equals(other._reactions, _reactions) &&
            (identical(other.replyTo, replyTo) || other.replyTo == replyTo) &&
            const DeepCollectionEquality()
                .equals(other._deletedForProfiles, _deletedForProfiles) &&
            (identical(other.deletedForEveryone, deletedForEveryone) ||
                other.deletedForEveryone == deletedForEveryone) &&
            (identical(other.originalText, originalText) ||
                other.originalText == originalText) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        conversationId,
        senderId,
        senderProfileId,
        senderName,
        senderPhotoUrl,
        text,
        imageUrl,
        type,
        status,
        createdAt,
        editedAt,
        isEdited,
        const DeepCollectionEquality().hash(_reactions),
        replyTo,
        const DeepCollectionEquality().hash(_deletedForProfiles),
        deletedForEveryone,
        originalText,
        const DeepCollectionEquality().hash(_metadata)
      ]);

  /// Create a copy of MessageNewEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageNewEntityImplCopyWith<_$MessageNewEntityImpl> get copyWith =>
      __$$MessageNewEntityImplCopyWithImpl<_$MessageNewEntityImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MessageNewEntityImplToJson(
      this,
    );
  }
}

abstract class _MessageNewEntity extends MessageNewEntity {
  const factory _MessageNewEntity(
      {required final String id,
      required final String conversationId,
      required final String senderId,
      required final String senderProfileId,
      final String? senderName,
      final String? senderPhotoUrl,
      required final String text,
      final String? imageUrl,
      final MessageType type,
      final MessageDeliveryStatus status,
      required final DateTime createdAt,
      final DateTime? editedAt,
      final bool isEdited,
      final Map<String, String> reactions,
      final MessageReplyData? replyTo,
      final List<String> deletedForProfiles,
      final bool deletedForEveryone,
      final String? originalText,
      final Map<String, dynamic> metadata}) = _$MessageNewEntityImpl;
  const _MessageNewEntity._() : super._();

  factory _MessageNewEntity.fromJson(Map<String, dynamic> json) =
      _$MessageNewEntityImpl.fromJson;

  /// ID único da mensagem no Firestore
  @override
  String get id;

  /// ID da conversa pai
  @override
  String get conversationId;

  /// UID do remetente (Firebase Auth)
  @override
  String get senderId;

  /// ProfileId do remetente
  @override
  String get senderProfileId;

  /// Nome do remetente (desnormalizado para performance)
  @override
  String? get senderName;

  /// Foto do remetente (desnormalizado para performance)
  @override
  String? get senderPhotoUrl;

  /// Conteúdo textual da mensagem
  @override
  String get text;

  /// URL da imagem (se houver)
  @override
  String? get imageUrl;

  /// Tipo da mensagem
  @override
  MessageType get type;

  /// Status de entrega
  @override
  MessageDeliveryStatus get status;

  /// Timestamp de criação
  @override
  DateTime get createdAt;

  /// Timestamp de edição (null se nunca editado)
  @override
  DateTime? get editedAt;

  /// Se a mensagem foi editada
  @override
  bool get isEdited;

  /// Reações: Map<profileId, emoji>
  @override
  Map<String, String> get reactions;

  /// Dados da mensagem que está sendo respondida
  @override
  MessageReplyData? get replyTo;

  /// Lista de profileIds que deletaram a mensagem "para mim"
  @override
  List<String> get deletedForProfiles;

  /// Se a mensagem foi deletada para todos
  @override
  bool get deletedForEveryone;

  /// Texto original (antes de deletar para todos)
  @override
  String? get originalText;

  /// Metadados extras (extensível)
  @override
  Map<String, dynamic> get metadata;

  /// Create a copy of MessageNewEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageNewEntityImplCopyWith<_$MessageNewEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MessageReplyData _$MessageReplyDataFromJson(Map<String, dynamic> json) {
  return _MessageReplyData.fromJson(json);
}

/// @nodoc
mixin _$MessageReplyData {
  /// ID da mensagem original
  String get messageId => throw _privateConstructorUsedError;

  /// Texto da mensagem original (preview)
  String get text => throw _privateConstructorUsedError;

  /// ProfileId do autor da mensagem original
  String get senderProfileId => throw _privateConstructorUsedError;

  /// Nome do autor (desnormalizado)
  String? get senderName => throw _privateConstructorUsedError;

  /// URL da imagem (se a mensagem original tinha imagem)
  String? get imageUrl => throw _privateConstructorUsedError;

  /// Serializes this MessageReplyData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MessageReplyData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MessageReplyDataCopyWith<MessageReplyData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageReplyDataCopyWith<$Res> {
  factory $MessageReplyDataCopyWith(
          MessageReplyData value, $Res Function(MessageReplyData) then) =
      _$MessageReplyDataCopyWithImpl<$Res, MessageReplyData>;
  @useResult
  $Res call(
      {String messageId,
      String text,
      String senderProfileId,
      String? senderName,
      String? imageUrl});
}

/// @nodoc
class _$MessageReplyDataCopyWithImpl<$Res, $Val extends MessageReplyData>
    implements $MessageReplyDataCopyWith<$Res> {
  _$MessageReplyDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MessageReplyData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messageId = null,
    Object? text = null,
    Object? senderProfileId = null,
    Object? senderName = freezed,
    Object? imageUrl = freezed,
  }) {
    return _then(_value.copyWith(
      messageId: null == messageId
          ? _value.messageId
          : messageId // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      senderProfileId: null == senderProfileId
          ? _value.senderProfileId
          : senderProfileId // ignore: cast_nullable_to_non_nullable
              as String,
      senderName: freezed == senderName
          ? _value.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MessageReplyDataImplCopyWith<$Res>
    implements $MessageReplyDataCopyWith<$Res> {
  factory _$$MessageReplyDataImplCopyWith(_$MessageReplyDataImpl value,
          $Res Function(_$MessageReplyDataImpl) then) =
      __$$MessageReplyDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String messageId,
      String text,
      String senderProfileId,
      String? senderName,
      String? imageUrl});
}

/// @nodoc
class __$$MessageReplyDataImplCopyWithImpl<$Res>
    extends _$MessageReplyDataCopyWithImpl<$Res, _$MessageReplyDataImpl>
    implements _$$MessageReplyDataImplCopyWith<$Res> {
  __$$MessageReplyDataImplCopyWithImpl(_$MessageReplyDataImpl _value,
      $Res Function(_$MessageReplyDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of MessageReplyData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messageId = null,
    Object? text = null,
    Object? senderProfileId = null,
    Object? senderName = freezed,
    Object? imageUrl = freezed,
  }) {
    return _then(_$MessageReplyDataImpl(
      messageId: null == messageId
          ? _value.messageId
          : messageId // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      senderProfileId: null == senderProfileId
          ? _value.senderProfileId
          : senderProfileId // ignore: cast_nullable_to_non_nullable
              as String,
      senderName: freezed == senderName
          ? _value.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MessageReplyDataImpl extends _MessageReplyData {
  const _$MessageReplyDataImpl(
      {required this.messageId,
      required this.text,
      required this.senderProfileId,
      this.senderName,
      this.imageUrl})
      : super._();

  factory _$MessageReplyDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$MessageReplyDataImplFromJson(json);

  /// ID da mensagem original
  @override
  final String messageId;

  /// Texto da mensagem original (preview)
  @override
  final String text;

  /// ProfileId do autor da mensagem original
  @override
  final String senderProfileId;

  /// Nome do autor (desnormalizado)
  @override
  final String? senderName;

  /// URL da imagem (se a mensagem original tinha imagem)
  @override
  final String? imageUrl;

  @override
  String toString() {
    return 'MessageReplyData(messageId: $messageId, text: $text, senderProfileId: $senderProfileId, senderName: $senderName, imageUrl: $imageUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageReplyDataImpl &&
            (identical(other.messageId, messageId) ||
                other.messageId == messageId) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.senderProfileId, senderProfileId) ||
                other.senderProfileId == senderProfileId) &&
            (identical(other.senderName, senderName) ||
                other.senderName == senderName) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, messageId, text, senderProfileId, senderName, imageUrl);

  /// Create a copy of MessageReplyData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageReplyDataImplCopyWith<_$MessageReplyDataImpl> get copyWith =>
      __$$MessageReplyDataImplCopyWithImpl<_$MessageReplyDataImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MessageReplyDataImplToJson(
      this,
    );
  }
}

abstract class _MessageReplyData extends MessageReplyData {
  const factory _MessageReplyData(
      {required final String messageId,
      required final String text,
      required final String senderProfileId,
      final String? senderName,
      final String? imageUrl}) = _$MessageReplyDataImpl;
  const _MessageReplyData._() : super._();

  factory _MessageReplyData.fromJson(Map<String, dynamic> json) =
      _$MessageReplyDataImpl.fromJson;

  /// ID da mensagem original
  @override
  String get messageId;

  /// Texto da mensagem original (preview)
  @override
  String get text;

  /// ProfileId do autor da mensagem original
  @override
  String get senderProfileId;

  /// Nome do autor (desnormalizado)
  @override
  String? get senderName;

  /// URL da imagem (se a mensagem original tinha imagem)
  @override
  String? get imageUrl;

  /// Create a copy of MessageReplyData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageReplyDataImplCopyWith<_$MessageReplyDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
