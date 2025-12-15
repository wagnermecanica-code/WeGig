// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_new_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ChatNewState {
  /// Lista de mensagens carregadas
  List<MessageNewEntity> get messages => throw _privateConstructorUsedError;

  /// Se está carregando mais mensagens
  bool get isLoadingMore => throw _privateConstructorUsedError;

  /// Se há mais mensagens para carregar
  bool get hasMore => throw _privateConstructorUsedError;

  /// Se está carregando inicialmente (antes da primeira emissão do stream)
  bool get isInitialLoading => throw _privateConstructorUsedError;

  /// Mensagem sendo respondida (reply)
  MessageNewEntity? get replyingTo => throw _privateConstructorUsedError;

  /// Mensagem sendo editada
  MessageNewEntity? get editingMessage => throw _privateConstructorUsedError;

  /// Se o outro participante está digitando
  bool get isOtherTyping => throw _privateConstructorUsedError;

  /// ProfileId de quem está digitando
  String? get typingProfileId => throw _privateConstructorUsedError;

  /// Erro, se houver
  String? get error => throw _privateConstructorUsedError;

  /// Se está enviando mensagem
  bool get isSending => throw _privateConstructorUsedError;

  /// Create a copy of ChatNewState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatNewStateCopyWith<ChatNewState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatNewStateCopyWith<$Res> {
  factory $ChatNewStateCopyWith(
          ChatNewState value, $Res Function(ChatNewState) then) =
      _$ChatNewStateCopyWithImpl<$Res, ChatNewState>;
  @useResult
  $Res call(
      {List<MessageNewEntity> messages,
      bool isLoadingMore,
      bool hasMore,
      bool isInitialLoading,
      MessageNewEntity? replyingTo,
      MessageNewEntity? editingMessage,
      bool isOtherTyping,
      String? typingProfileId,
      String? error,
      bool isSending});

  $MessageNewEntityCopyWith<$Res>? get replyingTo;
  $MessageNewEntityCopyWith<$Res>? get editingMessage;
}

/// @nodoc
class _$ChatNewStateCopyWithImpl<$Res, $Val extends ChatNewState>
    implements $ChatNewStateCopyWith<$Res> {
  _$ChatNewStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatNewState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messages = null,
    Object? isLoadingMore = null,
    Object? hasMore = null,
    Object? isInitialLoading = null,
    Object? replyingTo = freezed,
    Object? editingMessage = freezed,
    Object? isOtherTyping = null,
    Object? typingProfileId = freezed,
    Object? error = freezed,
    Object? isSending = null,
  }) {
    return _then(_value.copyWith(
      messages: null == messages
          ? _value.messages
          : messages // ignore: cast_nullable_to_non_nullable
              as List<MessageNewEntity>,
      isLoadingMore: null == isLoadingMore
          ? _value.isLoadingMore
          : isLoadingMore // ignore: cast_nullable_to_non_nullable
              as bool,
      hasMore: null == hasMore
          ? _value.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
      isInitialLoading: null == isInitialLoading
          ? _value.isInitialLoading
          : isInitialLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      replyingTo: freezed == replyingTo
          ? _value.replyingTo
          : replyingTo // ignore: cast_nullable_to_non_nullable
              as MessageNewEntity?,
      editingMessage: freezed == editingMessage
          ? _value.editingMessage
          : editingMessage // ignore: cast_nullable_to_non_nullable
              as MessageNewEntity?,
      isOtherTyping: null == isOtherTyping
          ? _value.isOtherTyping
          : isOtherTyping // ignore: cast_nullable_to_non_nullable
              as bool,
      typingProfileId: freezed == typingProfileId
          ? _value.typingProfileId
          : typingProfileId // ignore: cast_nullable_to_non_nullable
              as String?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      isSending: null == isSending
          ? _value.isSending
          : isSending // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  /// Create a copy of ChatNewState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MessageNewEntityCopyWith<$Res>? get replyingTo {
    if (_value.replyingTo == null) {
      return null;
    }

    return $MessageNewEntityCopyWith<$Res>(_value.replyingTo!, (value) {
      return _then(_value.copyWith(replyingTo: value) as $Val);
    });
  }

  /// Create a copy of ChatNewState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MessageNewEntityCopyWith<$Res>? get editingMessage {
    if (_value.editingMessage == null) {
      return null;
    }

    return $MessageNewEntityCopyWith<$Res>(_value.editingMessage!, (value) {
      return _then(_value.copyWith(editingMessage: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ChatNewStateImplCopyWith<$Res>
    implements $ChatNewStateCopyWith<$Res> {
  factory _$$ChatNewStateImplCopyWith(
          _$ChatNewStateImpl value, $Res Function(_$ChatNewStateImpl) then) =
      __$$ChatNewStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<MessageNewEntity> messages,
      bool isLoadingMore,
      bool hasMore,
      bool isInitialLoading,
      MessageNewEntity? replyingTo,
      MessageNewEntity? editingMessage,
      bool isOtherTyping,
      String? typingProfileId,
      String? error,
      bool isSending});

  @override
  $MessageNewEntityCopyWith<$Res>? get replyingTo;
  @override
  $MessageNewEntityCopyWith<$Res>? get editingMessage;
}

/// @nodoc
class __$$ChatNewStateImplCopyWithImpl<$Res>
    extends _$ChatNewStateCopyWithImpl<$Res, _$ChatNewStateImpl>
    implements _$$ChatNewStateImplCopyWith<$Res> {
  __$$ChatNewStateImplCopyWithImpl(
      _$ChatNewStateImpl _value, $Res Function(_$ChatNewStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatNewState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messages = null,
    Object? isLoadingMore = null,
    Object? hasMore = null,
    Object? isInitialLoading = null,
    Object? replyingTo = freezed,
    Object? editingMessage = freezed,
    Object? isOtherTyping = null,
    Object? typingProfileId = freezed,
    Object? error = freezed,
    Object? isSending = null,
  }) {
    return _then(_$ChatNewStateImpl(
      messages: null == messages
          ? _value._messages
          : messages // ignore: cast_nullable_to_non_nullable
              as List<MessageNewEntity>,
      isLoadingMore: null == isLoadingMore
          ? _value.isLoadingMore
          : isLoadingMore // ignore: cast_nullable_to_non_nullable
              as bool,
      hasMore: null == hasMore
          ? _value.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
      isInitialLoading: null == isInitialLoading
          ? _value.isInitialLoading
          : isInitialLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      replyingTo: freezed == replyingTo
          ? _value.replyingTo
          : replyingTo // ignore: cast_nullable_to_non_nullable
              as MessageNewEntity?,
      editingMessage: freezed == editingMessage
          ? _value.editingMessage
          : editingMessage // ignore: cast_nullable_to_non_nullable
              as MessageNewEntity?,
      isOtherTyping: null == isOtherTyping
          ? _value.isOtherTyping
          : isOtherTyping // ignore: cast_nullable_to_non_nullable
              as bool,
      typingProfileId: freezed == typingProfileId
          ? _value.typingProfileId
          : typingProfileId // ignore: cast_nullable_to_non_nullable
              as String?,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      isSending: null == isSending
          ? _value.isSending
          : isSending // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$ChatNewStateImpl with DiagnosticableTreeMixin implements _ChatNewState {
  const _$ChatNewStateImpl(
      {final List<MessageNewEntity> messages = const [],
      this.isLoadingMore = false,
      this.hasMore = true,
      this.isInitialLoading = true,
      this.replyingTo,
      this.editingMessage,
      this.isOtherTyping = false,
      this.typingProfileId,
      this.error,
      this.isSending = false})
      : _messages = messages;

  /// Lista de mensagens carregadas
  final List<MessageNewEntity> _messages;

  /// Lista de mensagens carregadas
  @override
  @JsonKey()
  List<MessageNewEntity> get messages {
    if (_messages is EqualUnmodifiableListView) return _messages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_messages);
  }

  /// Se está carregando mais mensagens
  @override
  @JsonKey()
  final bool isLoadingMore;

  /// Se há mais mensagens para carregar
  @override
  @JsonKey()
  final bool hasMore;

  /// Se está carregando inicialmente (antes da primeira emissão do stream)
  @override
  @JsonKey()
  final bool isInitialLoading;

  /// Mensagem sendo respondida (reply)
  @override
  final MessageNewEntity? replyingTo;

  /// Mensagem sendo editada
  @override
  final MessageNewEntity? editingMessage;

  /// Se o outro participante está digitando
  @override
  @JsonKey()
  final bool isOtherTyping;

  /// ProfileId de quem está digitando
  @override
  final String? typingProfileId;

  /// Erro, se houver
  @override
  final String? error;

  /// Se está enviando mensagem
  @override
  @JsonKey()
  final bool isSending;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'ChatNewState(messages: $messages, isLoadingMore: $isLoadingMore, hasMore: $hasMore, isInitialLoading: $isInitialLoading, replyingTo: $replyingTo, editingMessage: $editingMessage, isOtherTyping: $isOtherTyping, typingProfileId: $typingProfileId, error: $error, isSending: $isSending)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'ChatNewState'))
      ..add(DiagnosticsProperty('messages', messages))
      ..add(DiagnosticsProperty('isLoadingMore', isLoadingMore))
      ..add(DiagnosticsProperty('hasMore', hasMore))
      ..add(DiagnosticsProperty('isInitialLoading', isInitialLoading))
      ..add(DiagnosticsProperty('replyingTo', replyingTo))
      ..add(DiagnosticsProperty('editingMessage', editingMessage))
      ..add(DiagnosticsProperty('isOtherTyping', isOtherTyping))
      ..add(DiagnosticsProperty('typingProfileId', typingProfileId))
      ..add(DiagnosticsProperty('error', error))
      ..add(DiagnosticsProperty('isSending', isSending));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatNewStateImpl &&
            const DeepCollectionEquality().equals(other._messages, _messages) &&
            (identical(other.isLoadingMore, isLoadingMore) ||
                other.isLoadingMore == isLoadingMore) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore) &&
            (identical(other.isInitialLoading, isInitialLoading) ||
                other.isInitialLoading == isInitialLoading) &&
            (identical(other.replyingTo, replyingTo) ||
                other.replyingTo == replyingTo) &&
            (identical(other.editingMessage, editingMessage) ||
                other.editingMessage == editingMessage) &&
            (identical(other.isOtherTyping, isOtherTyping) ||
                other.isOtherTyping == isOtherTyping) &&
            (identical(other.typingProfileId, typingProfileId) ||
                other.typingProfileId == typingProfileId) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.isSending, isSending) ||
                other.isSending == isSending));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_messages),
      isLoadingMore,
      hasMore,
      isInitialLoading,
      replyingTo,
      editingMessage,
      isOtherTyping,
      typingProfileId,
      error,
      isSending);

  /// Create a copy of ChatNewState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatNewStateImplCopyWith<_$ChatNewStateImpl> get copyWith =>
      __$$ChatNewStateImplCopyWithImpl<_$ChatNewStateImpl>(this, _$identity);
}

abstract class _ChatNewState implements ChatNewState {
  const factory _ChatNewState(
      {final List<MessageNewEntity> messages,
      final bool isLoadingMore,
      final bool hasMore,
      final bool isInitialLoading,
      final MessageNewEntity? replyingTo,
      final MessageNewEntity? editingMessage,
      final bool isOtherTyping,
      final String? typingProfileId,
      final String? error,
      final bool isSending}) = _$ChatNewStateImpl;

  /// Lista de mensagens carregadas
  @override
  List<MessageNewEntity> get messages;

  /// Se está carregando mais mensagens
  @override
  bool get isLoadingMore;

  /// Se há mais mensagens para carregar
  @override
  bool get hasMore;

  /// Se está carregando inicialmente (antes da primeira emissão do stream)
  @override
  bool get isInitialLoading;

  /// Mensagem sendo respondida (reply)
  @override
  MessageNewEntity? get replyingTo;

  /// Mensagem sendo editada
  @override
  MessageNewEntity? get editingMessage;

  /// Se o outro participante está digitando
  @override
  bool get isOtherTyping;

  /// ProfileId de quem está digitando
  @override
  String? get typingProfileId;

  /// Erro, se houver
  @override
  String? get error;

  /// Se está enviando mensagem
  @override
  bool get isSending;

  /// Create a copy of ChatNewState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatNewStateImplCopyWith<_$ChatNewStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
