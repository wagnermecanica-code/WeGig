// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation_new_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ConversationNewEntity _$ConversationNewEntityFromJson(
    Map<String, dynamic> json) {
  return _ConversationNewEntity.fromJson(json);
}

/// @nodoc
mixin _$ConversationNewEntity {
  /// ID único da conversa no Firestore
  String get id => throw _privateConstructorUsedError;

  /// UIDs dos participantes (Firebase Auth UIDs)
  List<String> get participants => throw _privateConstructorUsedError;

  /// IDs dos perfis participantes
  List<String> get participantProfiles => throw _privateConstructorUsedError;

  /// Preview da última mensagem
  String get lastMessage => throw _privateConstructorUsedError;

  /// Timestamp da última mensagem
  DateTime get lastMessageTimestamp => throw _privateConstructorUsedError;

  /// ID do remetente da última mensagem
  String? get lastMessageSenderId => throw _privateConstructorUsedError;

  /// Contagem de mensagens não lidas por profileId
  Map<String, int> get unreadCount => throw _privateConstructorUsedError;

  /// Data de criação da conversa
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Data da última atualização
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Dados completos dos participantes (enriquecidos no read)
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<ParticipantData> get participantsData =>
      throw _privateConstructorUsedError;

  /// Se a conversa foi arquivada (globalmente)
  bool get archived => throw _privateConstructorUsedError;

  /// Lista de profileIds que arquivaram esta conversa
  List<String> get archivedByProfiles => throw _privateConstructorUsedError;

  /// Lista de profileIds que silenciaram notificações
  List<String> get mutedByProfiles => throw _privateConstructorUsedError;

  /// Lista de profileIds que fixaram esta conversa
  List<String> get pinnedByProfiles => throw _privateConstructorUsedError;

  /// Lista de profileIds que deletaram esta conversa (soft delete)
  List<String> get deletedByProfiles => throw _privateConstructorUsedError;

  /// Timestamp de "limpar histórico" por profileId
  /// Quando um perfil deleta a conversa, salva o timestamp atual.
  /// Mensagens anteriores a este timestamp não são exibidas quando a conversa reaparecer.
  Map<String, DateTime> get clearHistoryTimestamp =>
      throw _privateConstructorUsedError;

  /// Quem está digitando atualmente (profileId -> timestamp)
  Map<String, DateTime> get typingIndicators =>
      throw _privateConstructorUsedError;

  /// Serializes this ConversationNewEntity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ConversationNewEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConversationNewEntityCopyWith<ConversationNewEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConversationNewEntityCopyWith<$Res> {
  factory $ConversationNewEntityCopyWith(ConversationNewEntity value,
          $Res Function(ConversationNewEntity) then) =
      _$ConversationNewEntityCopyWithImpl<$Res, ConversationNewEntity>;
  @useResult
  $Res call(
      {String id,
      List<String> participants,
      List<String> participantProfiles,
      String lastMessage,
      DateTime lastMessageTimestamp,
      String? lastMessageSenderId,
      Map<String, int> unreadCount,
      DateTime createdAt,
      DateTime? updatedAt,
      @JsonKey(includeFromJson: false, includeToJson: false)
      List<ParticipantData> participantsData,
      bool archived,
      List<String> archivedByProfiles,
      List<String> mutedByProfiles,
      List<String> pinnedByProfiles,
      List<String> deletedByProfiles,
      Map<String, DateTime> clearHistoryTimestamp,
      Map<String, DateTime> typingIndicators});
}

/// @nodoc
class _$ConversationNewEntityCopyWithImpl<$Res,
        $Val extends ConversationNewEntity>
    implements $ConversationNewEntityCopyWith<$Res> {
  _$ConversationNewEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConversationNewEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? participants = null,
    Object? participantProfiles = null,
    Object? lastMessage = null,
    Object? lastMessageTimestamp = null,
    Object? lastMessageSenderId = freezed,
    Object? unreadCount = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? participantsData = null,
    Object? archived = null,
    Object? archivedByProfiles = null,
    Object? mutedByProfiles = null,
    Object? pinnedByProfiles = null,
    Object? deletedByProfiles = null,
    Object? clearHistoryTimestamp = null,
    Object? typingIndicators = null,
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
      lastMessageSenderId: freezed == lastMessageSenderId
          ? _value.lastMessageSenderId
          : lastMessageSenderId // ignore: cast_nullable_to_non_nullable
              as String?,
      unreadCount: null == unreadCount
          ? _value.unreadCount
          : unreadCount // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      participantsData: null == participantsData
          ? _value.participantsData
          : participantsData // ignore: cast_nullable_to_non_nullable
              as List<ParticipantData>,
      archived: null == archived
          ? _value.archived
          : archived // ignore: cast_nullable_to_non_nullable
              as bool,
      archivedByProfiles: null == archivedByProfiles
          ? _value.archivedByProfiles
          : archivedByProfiles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      mutedByProfiles: null == mutedByProfiles
          ? _value.mutedByProfiles
          : mutedByProfiles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      pinnedByProfiles: null == pinnedByProfiles
          ? _value.pinnedByProfiles
          : pinnedByProfiles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      deletedByProfiles: null == deletedByProfiles
          ? _value.deletedByProfiles
          : deletedByProfiles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      clearHistoryTimestamp: null == clearHistoryTimestamp
          ? _value.clearHistoryTimestamp
          : clearHistoryTimestamp // ignore: cast_nullable_to_non_nullable
              as Map<String, DateTime>,
      typingIndicators: null == typingIndicators
          ? _value.typingIndicators
          : typingIndicators // ignore: cast_nullable_to_non_nullable
              as Map<String, DateTime>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ConversationNewEntityImplCopyWith<$Res>
    implements $ConversationNewEntityCopyWith<$Res> {
  factory _$$ConversationNewEntityImplCopyWith(
          _$ConversationNewEntityImpl value,
          $Res Function(_$ConversationNewEntityImpl) then) =
      __$$ConversationNewEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      List<String> participants,
      List<String> participantProfiles,
      String lastMessage,
      DateTime lastMessageTimestamp,
      String? lastMessageSenderId,
      Map<String, int> unreadCount,
      DateTime createdAt,
      DateTime? updatedAt,
      @JsonKey(includeFromJson: false, includeToJson: false)
      List<ParticipantData> participantsData,
      bool archived,
      List<String> archivedByProfiles,
      List<String> mutedByProfiles,
      List<String> pinnedByProfiles,
      List<String> deletedByProfiles,
      Map<String, DateTime> clearHistoryTimestamp,
      Map<String, DateTime> typingIndicators});
}

/// @nodoc
class __$$ConversationNewEntityImplCopyWithImpl<$Res>
    extends _$ConversationNewEntityCopyWithImpl<$Res,
        _$ConversationNewEntityImpl>
    implements _$$ConversationNewEntityImplCopyWith<$Res> {
  __$$ConversationNewEntityImplCopyWithImpl(_$ConversationNewEntityImpl _value,
      $Res Function(_$ConversationNewEntityImpl) _then)
      : super(_value, _then);

  /// Create a copy of ConversationNewEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? participants = null,
    Object? participantProfiles = null,
    Object? lastMessage = null,
    Object? lastMessageTimestamp = null,
    Object? lastMessageSenderId = freezed,
    Object? unreadCount = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? participantsData = null,
    Object? archived = null,
    Object? archivedByProfiles = null,
    Object? mutedByProfiles = null,
    Object? pinnedByProfiles = null,
    Object? deletedByProfiles = null,
    Object? clearHistoryTimestamp = null,
    Object? typingIndicators = null,
  }) {
    return _then(_$ConversationNewEntityImpl(
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
      lastMessageSenderId: freezed == lastMessageSenderId
          ? _value.lastMessageSenderId
          : lastMessageSenderId // ignore: cast_nullable_to_non_nullable
              as String?,
      unreadCount: null == unreadCount
          ? _value._unreadCount
          : unreadCount // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      participantsData: null == participantsData
          ? _value._participantsData
          : participantsData // ignore: cast_nullable_to_non_nullable
              as List<ParticipantData>,
      archived: null == archived
          ? _value.archived
          : archived // ignore: cast_nullable_to_non_nullable
              as bool,
      archivedByProfiles: null == archivedByProfiles
          ? _value._archivedByProfiles
          : archivedByProfiles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      mutedByProfiles: null == mutedByProfiles
          ? _value._mutedByProfiles
          : mutedByProfiles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      pinnedByProfiles: null == pinnedByProfiles
          ? _value._pinnedByProfiles
          : pinnedByProfiles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      deletedByProfiles: null == deletedByProfiles
          ? _value._deletedByProfiles
          : deletedByProfiles // ignore: cast_nullable_to_non_nullable
              as List<String>,
      clearHistoryTimestamp: null == clearHistoryTimestamp
          ? _value._clearHistoryTimestamp
          : clearHistoryTimestamp // ignore: cast_nullable_to_non_nullable
              as Map<String, DateTime>,
      typingIndicators: null == typingIndicators
          ? _value._typingIndicators
          : typingIndicators // ignore: cast_nullable_to_non_nullable
              as Map<String, DateTime>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ConversationNewEntityImpl extends _ConversationNewEntity {
  const _$ConversationNewEntityImpl(
      {required this.id,
      required final List<String> participants,
      required final List<String> participantProfiles,
      required this.lastMessage,
      required this.lastMessageTimestamp,
      this.lastMessageSenderId,
      required final Map<String, int> unreadCount,
      required this.createdAt,
      this.updatedAt,
      @JsonKey(includeFromJson: false, includeToJson: false)
      final List<ParticipantData> participantsData = const [],
      this.archived = false,
      final List<String> archivedByProfiles = const <String>[],
      final List<String> mutedByProfiles = const <String>[],
      final List<String> pinnedByProfiles = const <String>[],
      final List<String> deletedByProfiles = const <String>[],
      final Map<String, DateTime> clearHistoryTimestamp =
          const <String, DateTime>{},
      final Map<String, DateTime> typingIndicators = const {}})
      : _participants = participants,
        _participantProfiles = participantProfiles,
        _unreadCount = unreadCount,
        _participantsData = participantsData,
        _archivedByProfiles = archivedByProfiles,
        _mutedByProfiles = mutedByProfiles,
        _pinnedByProfiles = pinnedByProfiles,
        _deletedByProfiles = deletedByProfiles,
        _clearHistoryTimestamp = clearHistoryTimestamp,
        _typingIndicators = typingIndicators,
        super._();

  factory _$ConversationNewEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConversationNewEntityImplFromJson(json);

  /// ID único da conversa no Firestore
  @override
  final String id;

  /// UIDs dos participantes (Firebase Auth UIDs)
  final List<String> _participants;

  /// UIDs dos participantes (Firebase Auth UIDs)
  @override
  List<String> get participants {
    if (_participants is EqualUnmodifiableListView) return _participants;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_participants);
  }

  /// IDs dos perfis participantes
  final List<String> _participantProfiles;

  /// IDs dos perfis participantes
  @override
  List<String> get participantProfiles {
    if (_participantProfiles is EqualUnmodifiableListView)
      return _participantProfiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_participantProfiles);
  }

  /// Preview da última mensagem
  @override
  final String lastMessage;

  /// Timestamp da última mensagem
  @override
  final DateTime lastMessageTimestamp;

  /// ID do remetente da última mensagem
  @override
  final String? lastMessageSenderId;

  /// Contagem de mensagens não lidas por profileId
  final Map<String, int> _unreadCount;

  /// Contagem de mensagens não lidas por profileId
  @override
  Map<String, int> get unreadCount {
    if (_unreadCount is EqualUnmodifiableMapView) return _unreadCount;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_unreadCount);
  }

  /// Data de criação da conversa
  @override
  final DateTime createdAt;

  /// Data da última atualização
  @override
  final DateTime? updatedAt;

  /// Dados completos dos participantes (enriquecidos no read)
  final List<ParticipantData> _participantsData;

  /// Dados completos dos participantes (enriquecidos no read)
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<ParticipantData> get participantsData {
    if (_participantsData is EqualUnmodifiableListView)
      return _participantsData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_participantsData);
  }

  /// Se a conversa foi arquivada (globalmente)
  @override
  @JsonKey()
  final bool archived;

  /// Lista de profileIds que arquivaram esta conversa
  final List<String> _archivedByProfiles;

  /// Lista de profileIds que arquivaram esta conversa
  @override
  @JsonKey()
  List<String> get archivedByProfiles {
    if (_archivedByProfiles is EqualUnmodifiableListView)
      return _archivedByProfiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_archivedByProfiles);
  }

  /// Lista de profileIds que silenciaram notificações
  final List<String> _mutedByProfiles;

  /// Lista de profileIds que silenciaram notificações
  @override
  @JsonKey()
  List<String> get mutedByProfiles {
    if (_mutedByProfiles is EqualUnmodifiableListView) return _mutedByProfiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_mutedByProfiles);
  }

  /// Lista de profileIds que fixaram esta conversa
  final List<String> _pinnedByProfiles;

  /// Lista de profileIds que fixaram esta conversa
  @override
  @JsonKey()
  List<String> get pinnedByProfiles {
    if (_pinnedByProfiles is EqualUnmodifiableListView)
      return _pinnedByProfiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_pinnedByProfiles);
  }

  /// Lista de profileIds que deletaram esta conversa (soft delete)
  final List<String> _deletedByProfiles;

  /// Lista de profileIds que deletaram esta conversa (soft delete)
  @override
  @JsonKey()
  List<String> get deletedByProfiles {
    if (_deletedByProfiles is EqualUnmodifiableListView)
      return _deletedByProfiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_deletedByProfiles);
  }

  /// Timestamp de "limpar histórico" por profileId
  /// Quando um perfil deleta a conversa, salva o timestamp atual.
  /// Mensagens anteriores a este timestamp não são exibidas quando a conversa reaparecer.
  final Map<String, DateTime> _clearHistoryTimestamp;

  /// Timestamp de "limpar histórico" por profileId
  /// Quando um perfil deleta a conversa, salva o timestamp atual.
  /// Mensagens anteriores a este timestamp não são exibidas quando a conversa reaparecer.
  @override
  @JsonKey()
  Map<String, DateTime> get clearHistoryTimestamp {
    if (_clearHistoryTimestamp is EqualUnmodifiableMapView)
      return _clearHistoryTimestamp;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_clearHistoryTimestamp);
  }

  /// Quem está digitando atualmente (profileId -> timestamp)
  final Map<String, DateTime> _typingIndicators;

  /// Quem está digitando atualmente (profileId -> timestamp)
  @override
  @JsonKey()
  Map<String, DateTime> get typingIndicators {
    if (_typingIndicators is EqualUnmodifiableMapView) return _typingIndicators;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_typingIndicators);
  }

  @override
  String toString() {
    return 'ConversationNewEntity(id: $id, participants: $participants, participantProfiles: $participantProfiles, lastMessage: $lastMessage, lastMessageTimestamp: $lastMessageTimestamp, lastMessageSenderId: $lastMessageSenderId, unreadCount: $unreadCount, createdAt: $createdAt, updatedAt: $updatedAt, participantsData: $participantsData, archived: $archived, archivedByProfiles: $archivedByProfiles, mutedByProfiles: $mutedByProfiles, pinnedByProfiles: $pinnedByProfiles, deletedByProfiles: $deletedByProfiles, clearHistoryTimestamp: $clearHistoryTimestamp, typingIndicators: $typingIndicators)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConversationNewEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality()
                .equals(other._participants, _participants) &&
            const DeepCollectionEquality()
                .equals(other._participantProfiles, _participantProfiles) &&
            (identical(other.lastMessage, lastMessage) ||
                other.lastMessage == lastMessage) &&
            (identical(other.lastMessageTimestamp, lastMessageTimestamp) ||
                other.lastMessageTimestamp == lastMessageTimestamp) &&
            (identical(other.lastMessageSenderId, lastMessageSenderId) ||
                other.lastMessageSenderId == lastMessageSenderId) &&
            const DeepCollectionEquality()
                .equals(other._unreadCount, _unreadCount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality()
                .equals(other._participantsData, _participantsData) &&
            (identical(other.archived, archived) ||
                other.archived == archived) &&
            const DeepCollectionEquality()
                .equals(other._archivedByProfiles, _archivedByProfiles) &&
            const DeepCollectionEquality()
                .equals(other._mutedByProfiles, _mutedByProfiles) &&
            const DeepCollectionEquality()
                .equals(other._pinnedByProfiles, _pinnedByProfiles) &&
            const DeepCollectionEquality()
                .equals(other._deletedByProfiles, _deletedByProfiles) &&
            const DeepCollectionEquality()
                .equals(other._clearHistoryTimestamp, _clearHistoryTimestamp) &&
            const DeepCollectionEquality()
                .equals(other._typingIndicators, _typingIndicators));
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
      lastMessageSenderId,
      const DeepCollectionEquality().hash(_unreadCount),
      createdAt,
      updatedAt,
      const DeepCollectionEquality().hash(_participantsData),
      archived,
      const DeepCollectionEquality().hash(_archivedByProfiles),
      const DeepCollectionEquality().hash(_mutedByProfiles),
      const DeepCollectionEquality().hash(_pinnedByProfiles),
      const DeepCollectionEquality().hash(_deletedByProfiles),
      const DeepCollectionEquality().hash(_clearHistoryTimestamp),
      const DeepCollectionEquality().hash(_typingIndicators));

  /// Create a copy of ConversationNewEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConversationNewEntityImplCopyWith<_$ConversationNewEntityImpl>
      get copyWith => __$$ConversationNewEntityImplCopyWithImpl<
          _$ConversationNewEntityImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ConversationNewEntityImplToJson(
      this,
    );
  }
}

abstract class _ConversationNewEntity extends ConversationNewEntity {
  const factory _ConversationNewEntity(
          {required final String id,
          required final List<String> participants,
          required final List<String> participantProfiles,
          required final String lastMessage,
          required final DateTime lastMessageTimestamp,
          final String? lastMessageSenderId,
          required final Map<String, int> unreadCount,
          required final DateTime createdAt,
          final DateTime? updatedAt,
          @JsonKey(includeFromJson: false, includeToJson: false)
          final List<ParticipantData> participantsData,
          final bool archived,
          final List<String> archivedByProfiles,
          final List<String> mutedByProfiles,
          final List<String> pinnedByProfiles,
          final List<String> deletedByProfiles,
          final Map<String, DateTime> clearHistoryTimestamp,
          final Map<String, DateTime> typingIndicators}) =
      _$ConversationNewEntityImpl;
  const _ConversationNewEntity._() : super._();

  factory _ConversationNewEntity.fromJson(Map<String, dynamic> json) =
      _$ConversationNewEntityImpl.fromJson;

  /// ID único da conversa no Firestore
  @override
  String get id;

  /// UIDs dos participantes (Firebase Auth UIDs)
  @override
  List<String> get participants;

  /// IDs dos perfis participantes
  @override
  List<String> get participantProfiles;

  /// Preview da última mensagem
  @override
  String get lastMessage;

  /// Timestamp da última mensagem
  @override
  DateTime get lastMessageTimestamp;

  /// ID do remetente da última mensagem
  @override
  String? get lastMessageSenderId;

  /// Contagem de mensagens não lidas por profileId
  @override
  Map<String, int> get unreadCount;

  /// Data de criação da conversa
  @override
  DateTime get createdAt;

  /// Data da última atualização
  @override
  DateTime? get updatedAt;

  /// Dados completos dos participantes (enriquecidos no read)
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<ParticipantData> get participantsData;

  /// Se a conversa foi arquivada (globalmente)
  @override
  bool get archived;

  /// Lista de profileIds que arquivaram esta conversa
  @override
  List<String> get archivedByProfiles;

  /// Lista de profileIds que silenciaram notificações
  @override
  List<String> get mutedByProfiles;

  /// Lista de profileIds que fixaram esta conversa
  @override
  List<String> get pinnedByProfiles;

  /// Lista de profileIds que deletaram esta conversa (soft delete)
  @override
  List<String> get deletedByProfiles;

  /// Timestamp de "limpar histórico" por profileId
  /// Quando um perfil deleta a conversa, salva o timestamp atual.
  /// Mensagens anteriores a este timestamp não são exibidas quando a conversa reaparecer.
  @override
  Map<String, DateTime> get clearHistoryTimestamp;

  /// Quem está digitando atualmente (profileId -> timestamp)
  @override
  Map<String, DateTime> get typingIndicators;

  /// Create a copy of ConversationNewEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConversationNewEntityImplCopyWith<_$ConversationNewEntityImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ParticipantData _$ParticipantDataFromJson(Map<String, dynamic> json) {
  return _ParticipantData.fromJson(json);
}

/// @nodoc
mixin _$ParticipantData {
  /// ID do perfil
  String get profileId => throw _privateConstructorUsedError;

  /// UID (Firebase Auth)
  String get uid => throw _privateConstructorUsedError;

  /// Nome do perfil
  String get name => throw _privateConstructorUsedError;

  /// URL da foto do perfil
  String? get photoUrl => throw _privateConstructorUsedError;

  /// Tipo do perfil (musician/band)
  String? get profileType => throw _privateConstructorUsedError;

  /// Se o perfil está online
  bool get isOnline => throw _privateConstructorUsedError;

  /// Última vez online
  DateTime? get lastSeen => throw _privateConstructorUsedError;

  /// Serializes this ParticipantData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ParticipantData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ParticipantDataCopyWith<ParticipantData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ParticipantDataCopyWith<$Res> {
  factory $ParticipantDataCopyWith(
          ParticipantData value, $Res Function(ParticipantData) then) =
      _$ParticipantDataCopyWithImpl<$Res, ParticipantData>;
  @useResult
  $Res call(
      {String profileId,
      String uid,
      String name,
      String? photoUrl,
      String? profileType,
      bool isOnline,
      DateTime? lastSeen});
}

/// @nodoc
class _$ParticipantDataCopyWithImpl<$Res, $Val extends ParticipantData>
    implements $ParticipantDataCopyWith<$Res> {
  _$ParticipantDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ParticipantData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? profileId = null,
    Object? uid = null,
    Object? name = null,
    Object? photoUrl = freezed,
    Object? profileType = freezed,
    Object? isOnline = null,
    Object? lastSeen = freezed,
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
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      profileType: freezed == profileType
          ? _value.profileType
          : profileType // ignore: cast_nullable_to_non_nullable
              as String?,
      isOnline: null == isOnline
          ? _value.isOnline
          : isOnline // ignore: cast_nullable_to_non_nullable
              as bool,
      lastSeen: freezed == lastSeen
          ? _value.lastSeen
          : lastSeen // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ParticipantDataImplCopyWith<$Res>
    implements $ParticipantDataCopyWith<$Res> {
  factory _$$ParticipantDataImplCopyWith(_$ParticipantDataImpl value,
          $Res Function(_$ParticipantDataImpl) then) =
      __$$ParticipantDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String profileId,
      String uid,
      String name,
      String? photoUrl,
      String? profileType,
      bool isOnline,
      DateTime? lastSeen});
}

/// @nodoc
class __$$ParticipantDataImplCopyWithImpl<$Res>
    extends _$ParticipantDataCopyWithImpl<$Res, _$ParticipantDataImpl>
    implements _$$ParticipantDataImplCopyWith<$Res> {
  __$$ParticipantDataImplCopyWithImpl(
      _$ParticipantDataImpl _value, $Res Function(_$ParticipantDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of ParticipantData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? profileId = null,
    Object? uid = null,
    Object? name = null,
    Object? photoUrl = freezed,
    Object? profileType = freezed,
    Object? isOnline = null,
    Object? lastSeen = freezed,
  }) {
    return _then(_$ParticipantDataImpl(
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
      photoUrl: freezed == photoUrl
          ? _value.photoUrl
          : photoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      profileType: freezed == profileType
          ? _value.profileType
          : profileType // ignore: cast_nullable_to_non_nullable
              as String?,
      isOnline: null == isOnline
          ? _value.isOnline
          : isOnline // ignore: cast_nullable_to_non_nullable
              as bool,
      lastSeen: freezed == lastSeen
          ? _value.lastSeen
          : lastSeen // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ParticipantDataImpl extends _ParticipantData {
  const _$ParticipantDataImpl(
      {required this.profileId,
      required this.uid,
      required this.name,
      this.photoUrl,
      this.profileType,
      this.isOnline = false,
      this.lastSeen})
      : super._();

  factory _$ParticipantDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$ParticipantDataImplFromJson(json);

  /// ID do perfil
  @override
  final String profileId;

  /// UID (Firebase Auth)
  @override
  final String uid;

  /// Nome do perfil
  @override
  final String name;

  /// URL da foto do perfil
  @override
  final String? photoUrl;

  /// Tipo do perfil (musician/band)
  @override
  final String? profileType;

  /// Se o perfil está online
  @override
  @JsonKey()
  final bool isOnline;

  /// Última vez online
  @override
  final DateTime? lastSeen;

  @override
  String toString() {
    return 'ParticipantData(profileId: $profileId, uid: $uid, name: $name, photoUrl: $photoUrl, profileType: $profileType, isOnline: $isOnline, lastSeen: $lastSeen)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ParticipantDataImpl &&
            (identical(other.profileId, profileId) ||
                other.profileId == profileId) &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.photoUrl, photoUrl) ||
                other.photoUrl == photoUrl) &&
            (identical(other.profileType, profileType) ||
                other.profileType == profileType) &&
            (identical(other.isOnline, isOnline) ||
                other.isOnline == isOnline) &&
            (identical(other.lastSeen, lastSeen) ||
                other.lastSeen == lastSeen));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, profileId, uid, name, photoUrl,
      profileType, isOnline, lastSeen);

  /// Create a copy of ParticipantData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ParticipantDataImplCopyWith<_$ParticipantDataImpl> get copyWith =>
      __$$ParticipantDataImplCopyWithImpl<_$ParticipantDataImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ParticipantDataImplToJson(
      this,
    );
  }
}

abstract class _ParticipantData extends ParticipantData {
  const factory _ParticipantData(
      {required final String profileId,
      required final String uid,
      required final String name,
      final String? photoUrl,
      final String? profileType,
      final bool isOnline,
      final DateTime? lastSeen}) = _$ParticipantDataImpl;
  const _ParticipantData._() : super._();

  factory _ParticipantData.fromJson(Map<String, dynamic> json) =
      _$ParticipantDataImpl.fromJson;

  /// ID do perfil
  @override
  String get profileId;

  /// UID (Firebase Auth)
  @override
  String get uid;

  /// Nome do perfil
  @override
  String get name;

  /// URL da foto do perfil
  @override
  String? get photoUrl;

  /// Tipo do perfil (musician/band)
  @override
  String? get profileType;

  /// Se o perfil está online
  @override
  bool get isOnline;

  /// Última vez online
  @override
  DateTime? get lastSeen;

  /// Create a copy of ParticipantData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ParticipantDataImplCopyWith<_$ParticipantDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
