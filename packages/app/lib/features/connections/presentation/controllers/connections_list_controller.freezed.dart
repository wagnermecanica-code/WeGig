// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'connections_list_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ConnectionsListState {
  List<ConnectionEntity> get connections => throw _privateConstructorUsedError;
  bool get hasMore => throw _privateConstructorUsedError;
  bool get isLoadingMore => throw _privateConstructorUsedError;
  String? get nextCursor => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Create a copy of ConnectionsListState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConnectionsListStateCopyWith<ConnectionsListState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConnectionsListStateCopyWith<$Res> {
  factory $ConnectionsListStateCopyWith(ConnectionsListState value,
          $Res Function(ConnectionsListState) then) =
      _$ConnectionsListStateCopyWithImpl<$Res, ConnectionsListState>;
  @useResult
  $Res call(
      {List<ConnectionEntity> connections,
      bool hasMore,
      bool isLoadingMore,
      String? nextCursor,
      String? errorMessage});
}

/// @nodoc
class _$ConnectionsListStateCopyWithImpl<$Res,
        $Val extends ConnectionsListState>
    implements $ConnectionsListStateCopyWith<$Res> {
  _$ConnectionsListStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConnectionsListState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? connections = null,
    Object? hasMore = null,
    Object? isLoadingMore = null,
    Object? nextCursor = freezed,
    Object? errorMessage = freezed,
  }) {
    return _then(_value.copyWith(
      connections: null == connections
          ? _value.connections
          : connections // ignore: cast_nullable_to_non_nullable
              as List<ConnectionEntity>,
      hasMore: null == hasMore
          ? _value.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoadingMore: null == isLoadingMore
          ? _value.isLoadingMore
          : isLoadingMore // ignore: cast_nullable_to_non_nullable
              as bool,
      nextCursor: freezed == nextCursor
          ? _value.nextCursor
          : nextCursor // ignore: cast_nullable_to_non_nullable
              as String?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ConnectionsListStateImplCopyWith<$Res>
    implements $ConnectionsListStateCopyWith<$Res> {
  factory _$$ConnectionsListStateImplCopyWith(_$ConnectionsListStateImpl value,
          $Res Function(_$ConnectionsListStateImpl) then) =
      __$$ConnectionsListStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<ConnectionEntity> connections,
      bool hasMore,
      bool isLoadingMore,
      String? nextCursor,
      String? errorMessage});
}

/// @nodoc
class __$$ConnectionsListStateImplCopyWithImpl<$Res>
    extends _$ConnectionsListStateCopyWithImpl<$Res, _$ConnectionsListStateImpl>
    implements _$$ConnectionsListStateImplCopyWith<$Res> {
  __$$ConnectionsListStateImplCopyWithImpl(_$ConnectionsListStateImpl _value,
      $Res Function(_$ConnectionsListStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of ConnectionsListState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? connections = null,
    Object? hasMore = null,
    Object? isLoadingMore = null,
    Object? nextCursor = freezed,
    Object? errorMessage = freezed,
  }) {
    return _then(_$ConnectionsListStateImpl(
      connections: null == connections
          ? _value._connections
          : connections // ignore: cast_nullable_to_non_nullable
              as List<ConnectionEntity>,
      hasMore: null == hasMore
          ? _value.hasMore
          : hasMore // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoadingMore: null == isLoadingMore
          ? _value.isLoadingMore
          : isLoadingMore // ignore: cast_nullable_to_non_nullable
              as bool,
      nextCursor: freezed == nextCursor
          ? _value.nextCursor
          : nextCursor // ignore: cast_nullable_to_non_nullable
              as String?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$ConnectionsListStateImpl
    with DiagnosticableTreeMixin
    implements _ConnectionsListState {
  const _$ConnectionsListStateImpl(
      {final List<ConnectionEntity> connections = const [],
      this.hasMore = true,
      this.isLoadingMore = false,
      this.nextCursor,
      this.errorMessage})
      : _connections = connections;

  final List<ConnectionEntity> _connections;
  @override
  @JsonKey()
  List<ConnectionEntity> get connections {
    if (_connections is EqualUnmodifiableListView) return _connections;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_connections);
  }

  @override
  @JsonKey()
  final bool hasMore;
  @override
  @JsonKey()
  final bool isLoadingMore;
  @override
  final String? nextCursor;
  @override
  final String? errorMessage;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'ConnectionsListState(connections: $connections, hasMore: $hasMore, isLoadingMore: $isLoadingMore, nextCursor: $nextCursor, errorMessage: $errorMessage)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'ConnectionsListState'))
      ..add(DiagnosticsProperty('connections', connections))
      ..add(DiagnosticsProperty('hasMore', hasMore))
      ..add(DiagnosticsProperty('isLoadingMore', isLoadingMore))
      ..add(DiagnosticsProperty('nextCursor', nextCursor))
      ..add(DiagnosticsProperty('errorMessage', errorMessage));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConnectionsListStateImpl &&
            const DeepCollectionEquality()
                .equals(other._connections, _connections) &&
            (identical(other.hasMore, hasMore) || other.hasMore == hasMore) &&
            (identical(other.isLoadingMore, isLoadingMore) ||
                other.isLoadingMore == isLoadingMore) &&
            (identical(other.nextCursor, nextCursor) ||
                other.nextCursor == nextCursor) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_connections),
      hasMore,
      isLoadingMore,
      nextCursor,
      errorMessage);

  /// Create a copy of ConnectionsListState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConnectionsListStateImplCopyWith<_$ConnectionsListStateImpl>
      get copyWith =>
          __$$ConnectionsListStateImplCopyWithImpl<_$ConnectionsListStateImpl>(
              this, _$identity);
}

abstract class _ConnectionsListState implements ConnectionsListState {
  const factory _ConnectionsListState(
      {final List<ConnectionEntity> connections,
      final bool hasMore,
      final bool isLoadingMore,
      final String? nextCursor,
      final String? errorMessage}) = _$ConnectionsListStateImpl;

  @override
  List<ConnectionEntity> get connections;
  @override
  bool get hasMore;
  @override
  bool get isLoadingMore;
  @override
  String? get nextCursor;
  @override
  String? get errorMessage;

  /// Create a copy of ConnectionsListState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConnectionsListStateImplCopyWith<_$ConnectionsListStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
