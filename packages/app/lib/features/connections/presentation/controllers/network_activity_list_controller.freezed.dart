// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'network_activity_list_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$NetworkActivityListState {
  List<PostEntity> get posts => throw _privateConstructorUsedError;
  bool get hasMore => throw _privateConstructorUsedError;
  bool get isLoadingMore => throw _privateConstructorUsedError;
  NetworkActivityCursorEntity? get nextCursor =>
      throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Create a copy of NetworkActivityListState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NetworkActivityListStateCopyWith<NetworkActivityListState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NetworkActivityListStateCopyWith<$Res> {
  factory $NetworkActivityListStateCopyWith(NetworkActivityListState value,
          $Res Function(NetworkActivityListState) then) =
      _$NetworkActivityListStateCopyWithImpl<$Res, NetworkActivityListState>;
  @useResult
  $Res call(
      {List<PostEntity> posts,
      bool hasMore,
      bool isLoadingMore,
      NetworkActivityCursorEntity? nextCursor,
      String? errorMessage});
}

/// @nodoc
class _$NetworkActivityListStateCopyWithImpl<$Res,
        $Val extends NetworkActivityListState>
    implements $NetworkActivityListStateCopyWith<$Res> {
  _$NetworkActivityListStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NetworkActivityListState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? posts = null,
    Object? hasMore = null,
    Object? isLoadingMore = null,
    Object? nextCursor = freezed,
    Object? errorMessage = freezed,
  }) {
    return _then(_value.copyWith(
      posts: null == posts
          ? _value.posts
          : posts // ignore: cast_nullable_to_non_nullable
              as List<PostEntity>,
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
              as NetworkActivityCursorEntity?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NetworkActivityListStateImplCopyWith<$Res>
    implements $NetworkActivityListStateCopyWith<$Res> {
  factory _$$NetworkActivityListStateImplCopyWith(
          _$NetworkActivityListStateImpl value,
          $Res Function(_$NetworkActivityListStateImpl) then) =
      __$$NetworkActivityListStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<PostEntity> posts,
      bool hasMore,
      bool isLoadingMore,
      NetworkActivityCursorEntity? nextCursor,
      String? errorMessage});
}

/// @nodoc
class __$$NetworkActivityListStateImplCopyWithImpl<$Res>
    extends _$NetworkActivityListStateCopyWithImpl<$Res,
        _$NetworkActivityListStateImpl>
    implements _$$NetworkActivityListStateImplCopyWith<$Res> {
  __$$NetworkActivityListStateImplCopyWithImpl(
      _$NetworkActivityListStateImpl _value,
      $Res Function(_$NetworkActivityListStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of NetworkActivityListState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? posts = null,
    Object? hasMore = null,
    Object? isLoadingMore = null,
    Object? nextCursor = freezed,
    Object? errorMessage = freezed,
  }) {
    return _then(_$NetworkActivityListStateImpl(
      posts: null == posts
          ? _value._posts
          : posts // ignore: cast_nullable_to_non_nullable
              as List<PostEntity>,
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
              as NetworkActivityCursorEntity?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$NetworkActivityListStateImpl implements _NetworkActivityListState {
  const _$NetworkActivityListStateImpl(
      {final List<PostEntity> posts = const [],
      this.hasMore = true,
      this.isLoadingMore = false,
      this.nextCursor,
      this.errorMessage})
      : _posts = posts;

  final List<PostEntity> _posts;
  @override
  @JsonKey()
  List<PostEntity> get posts {
    if (_posts is EqualUnmodifiableListView) return _posts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_posts);
  }

  @override
  @JsonKey()
  final bool hasMore;
  @override
  @JsonKey()
  final bool isLoadingMore;
  @override
  final NetworkActivityCursorEntity? nextCursor;
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'NetworkActivityListState(posts: $posts, hasMore: $hasMore, isLoadingMore: $isLoadingMore, nextCursor: $nextCursor, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NetworkActivityListStateImpl &&
            const DeepCollectionEquality().equals(other._posts, _posts) &&
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
      const DeepCollectionEquality().hash(_posts),
      hasMore,
      isLoadingMore,
      nextCursor,
      errorMessage);

  /// Create a copy of NetworkActivityListState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NetworkActivityListStateImplCopyWith<_$NetworkActivityListStateImpl>
      get copyWith => __$$NetworkActivityListStateImplCopyWithImpl<
          _$NetworkActivityListStateImpl>(this, _$identity);
}

abstract class _NetworkActivityListState implements NetworkActivityListState {
  const factory _NetworkActivityListState(
      {final List<PostEntity> posts,
      final bool hasMore,
      final bool isLoadingMore,
      final NetworkActivityCursorEntity? nextCursor,
      final String? errorMessage}) = _$NetworkActivityListStateImpl;

  @override
  List<PostEntity> get posts;
  @override
  bool get hasMore;
  @override
  bool get isLoadingMore;
  @override
  NetworkActivityCursorEntity? get nextCursor;
  @override
  String? get errorMessage;

  /// Create a copy of NetworkActivityListState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NetworkActivityListStateImplCopyWith<_$NetworkActivityListStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
