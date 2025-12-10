// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notifications_new_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$NotificationsNewState {
  /// Lista de notificações carregadas
  List<NotificationEntity> get notifications =>
      throw _privateConstructorUsedError;

  /// Flag indicando se há mais páginas para carregar
  bool get hasMore => throw _privateConstructorUsedError;

  /// Flag indicando se está carregando mais itens (paginação)
  bool get isLoadingMore => throw _privateConstructorUsedError;

  /// Mensagem de erro (se houver)
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Create a copy of NotificationsNewState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NotificationsNewStateCopyWith<NotificationsNewState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationsNewStateCopyWith<$Res> {
  factory $NotificationsNewStateCopyWith(NotificationsNewState value,
          $Res Function(NotificationsNewState) then) =
      _$NotificationsNewStateCopyWithImpl<$Res, NotificationsNewState>;
  @useResult
  $Res call(
      {List<NotificationEntity> notifications,
      bool hasMore,
      bool isLoadingMore,
      String? errorMessage});
}

/// @nodoc
class _$NotificationsNewStateCopyWithImpl<$Res,
        $Val extends NotificationsNewState>
    implements $NotificationsNewStateCopyWith<$Res> {
  _$NotificationsNewStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NotificationsNewState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? notifications = null,
    Object? hasMore = null,
    Object? isLoadingMore = null,
    Object? errorMessage = freezed,
  }) {
    return _then(_value.copyWith(
      notifications: null == notifications
          ? _value.notifications
          : notifications // ignore: cast_nullable_to_non_nullable
              as List<NotificationEntity>,
      hasMore: null == hasMore
          ? _value.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoadingMore: null == isLoadingMore
          ? _value.isLoadingMore
          : isLoadingMore // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NotificationsNewStateImplCopyWith<$Res>
    implements $NotificationsNewStateCopyWith<$Res> {
  factory _$$NotificationsNewStateImplCopyWith(
          _$NotificationsNewStateImpl value,
          $Res Function(_$NotificationsNewStateImpl) then) =
      __$$NotificationsNewStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<NotificationEntity> notifications,
      bool hasMore,
      bool isLoadingMore,
      String? errorMessage});
}

/// @nodoc
class __$$NotificationsNewStateImplCopyWithImpl<$Res>
    extends _$NotificationsNewStateCopyWithImpl<$Res,
        _$NotificationsNewStateImpl>
    implements _$$NotificationsNewStateImplCopyWith<$Res> {
  __$$NotificationsNewStateImplCopyWithImpl(_$NotificationsNewStateImpl _value,
      $Res Function(_$NotificationsNewStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of NotificationsNewState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? notifications = null,
    Object? hasMore = null,
    Object? isLoadingMore = null,
    Object? errorMessage = freezed,
  }) {
    return _then(_$NotificationsNewStateImpl(
      notifications: null == notifications
          ? _value._notifications
          : notifications // ignore: cast_nullable_to_non_nullable
              as List<NotificationEntity>,
      hasMore: null == hasMore
          ? _value.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoadingMore: null == isLoadingMore
          ? _value.isLoadingMore
          : isLoadingMore // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$NotificationsNewStateImpl
    with DiagnosticableTreeMixin
    implements _NotificationsNewState {
  const _$NotificationsNewStateImpl(
      {final List<NotificationEntity> notifications = const [],
      this.hasMore = true,
      this.isLoadingMore = false,
      this.errorMessage})
      : _notifications = notifications;

  /// Lista de notificações carregadas
  final List<NotificationEntity> _notifications;

  /// Lista de notificações carregadas
  @override
  @JsonKey()
  List<NotificationEntity> get notifications {
    if (_notifications is EqualUnmodifiableListView) return _notifications;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_notifications);
  }

  /// Flag indicando se há mais páginas para carregar
  @override
  @JsonKey()
  final bool hasMore;

  /// Flag indicando se está carregando mais itens (paginação)
  @override
  @JsonKey()
  final bool isLoadingMore;

  /// Mensagem de erro (se houver)
  @override
  final String? errorMessage;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'NotificationsNewState(notifications: $notifications, hasMore: $hasMore, isLoadingMore: $isLoadingMore, errorMessage: $errorMessage)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'NotificationsNewState'))
      ..add(DiagnosticsProperty('notifications', notifications))
      ..add(DiagnosticsProperty('hasMore', hasMore))
      ..add(DiagnosticsProperty('isLoadingMore', isLoadingMore))
      ..add(DiagnosticsProperty('errorMessage', errorMessage));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationsNewStateImpl &&
            const DeepCollectionEquality()
                .equals(other._notifications, _notifications) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore) &&
            (identical(other.isLoadingMore, isLoadingMore) ||
                other.isLoadingMore == isLoadingMore) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_notifications),
      hasMore,
      isLoadingMore,
      errorMessage);

  /// Create a copy of NotificationsNewState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationsNewStateImplCopyWith<_$NotificationsNewStateImpl>
      get copyWith => __$$NotificationsNewStateImplCopyWithImpl<
          _$NotificationsNewStateImpl>(this, _$identity);
}

abstract class _NotificationsNewState implements NotificationsNewState {
  const factory _NotificationsNewState(
      {final List<NotificationEntity> notifications,
      final bool hasMore,
      final bool isLoadingMore,
      final String? errorMessage}) = _$NotificationsNewStateImpl;

  /// Lista de notificações carregadas
  @override
  List<NotificationEntity> get notifications;

  /// Flag indicando se há mais páginas para carregar
  @override
  bool get hasMore;

  /// Flag indicando se está carregando mais itens (paginação)
  @override
  bool get isLoadingMore;

  /// Mensagem de erro (se houver)
  @override
  String? get errorMessage;

  /// Create a copy of NotificationsNewState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotificationsNewStateImplCopyWith<_$NotificationsNewStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
