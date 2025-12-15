// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AuthResult {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(User user, bool requiresEmailVerification,
            bool requiresProfileCreation)
        success,
    required TResult Function(String message, String? code) failure,
    required TResult Function() cancelled,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(User user, bool requiresEmailVerification,
            bool requiresProfileCreation)?
        success,
    TResult? Function(String message, String? code)? failure,
    TResult? Function()? cancelled,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(User user, bool requiresEmailVerification,
            bool requiresProfileCreation)?
        success,
    TResult Function(String message, String? code)? failure,
    TResult Function()? cancelled,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AuthSuccess value) success,
    required TResult Function(AuthFailure value) failure,
    required TResult Function(AuthCancelled value) cancelled,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AuthSuccess value)? success,
    TResult? Function(AuthFailure value)? failure,
    TResult? Function(AuthCancelled value)? cancelled,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AuthSuccess value)? success,
    TResult Function(AuthFailure value)? failure,
    TResult Function(AuthCancelled value)? cancelled,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthResultCopyWith<$Res> {
  factory $AuthResultCopyWith(
          AuthResult value, $Res Function(AuthResult) then) =
      _$AuthResultCopyWithImpl<$Res, AuthResult>;
}

/// @nodoc
class _$AuthResultCopyWithImpl<$Res, $Val extends AuthResult>
    implements $AuthResultCopyWith<$Res> {
  _$AuthResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$AuthSuccessImplCopyWith<$Res> {
  factory _$$AuthSuccessImplCopyWith(
          _$AuthSuccessImpl value, $Res Function(_$AuthSuccessImpl) then) =
      __$$AuthSuccessImplCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {User user,
      bool requiresEmailVerification,
      bool requiresProfileCreation});
}

/// @nodoc
class __$$AuthSuccessImplCopyWithImpl<$Res>
    extends _$AuthResultCopyWithImpl<$Res, _$AuthSuccessImpl>
    implements _$$AuthSuccessImplCopyWith<$Res> {
  __$$AuthSuccessImplCopyWithImpl(
      _$AuthSuccessImpl _value, $Res Function(_$AuthSuccessImpl) _then)
      : super(_value, _then);

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? user = null,
    Object? requiresEmailVerification = null,
    Object? requiresProfileCreation = null,
  }) {
    return _then(_$AuthSuccessImpl(
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as User,
      requiresEmailVerification: null == requiresEmailVerification
          ? _value.requiresEmailVerification
          : requiresEmailVerification // ignore: cast_nullable_to_non_nullable
              as bool,
      requiresProfileCreation: null == requiresProfileCreation
          ? _value.requiresProfileCreation
          : requiresProfileCreation // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$AuthSuccessImpl implements AuthSuccess {
  const _$AuthSuccessImpl(
      {required this.user,
      this.requiresEmailVerification = false,
      this.requiresProfileCreation = false});

  @override
  final User user;
  @override
  @JsonKey()
  final bool requiresEmailVerification;
  @override
  @JsonKey()
  final bool requiresProfileCreation;

  @override
  String toString() {
    return 'AuthResult.success(user: $user, requiresEmailVerification: $requiresEmailVerification, requiresProfileCreation: $requiresProfileCreation)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthSuccessImpl &&
            (identical(other.user, user) || other.user == user) &&
            (identical(other.requiresEmailVerification,
                    requiresEmailVerification) ||
                other.requiresEmailVerification == requiresEmailVerification) &&
            (identical(
                    other.requiresProfileCreation, requiresProfileCreation) ||
                other.requiresProfileCreation == requiresProfileCreation));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, user, requiresEmailVerification, requiresProfileCreation);

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthSuccessImplCopyWith<_$AuthSuccessImpl> get copyWith =>
      __$$AuthSuccessImplCopyWithImpl<_$AuthSuccessImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(User user, bool requiresEmailVerification,
            bool requiresProfileCreation)
        success,
    required TResult Function(String message, String? code) failure,
    required TResult Function() cancelled,
  }) {
    return success(user, requiresEmailVerification, requiresProfileCreation);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(User user, bool requiresEmailVerification,
            bool requiresProfileCreation)?
        success,
    TResult? Function(String message, String? code)? failure,
    TResult? Function()? cancelled,
  }) {
    return success?.call(
        user, requiresEmailVerification, requiresProfileCreation);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(User user, bool requiresEmailVerification,
            bool requiresProfileCreation)?
        success,
    TResult Function(String message, String? code)? failure,
    TResult Function()? cancelled,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(user, requiresEmailVerification, requiresProfileCreation);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AuthSuccess value) success,
    required TResult Function(AuthFailure value) failure,
    required TResult Function(AuthCancelled value) cancelled,
  }) {
    return success(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AuthSuccess value)? success,
    TResult? Function(AuthFailure value)? failure,
    TResult? Function(AuthCancelled value)? cancelled,
  }) {
    return success?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AuthSuccess value)? success,
    TResult Function(AuthFailure value)? failure,
    TResult Function(AuthCancelled value)? cancelled,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(this);
    }
    return orElse();
  }
}

abstract class AuthSuccess implements AuthResult {
  const factory AuthSuccess(
      {required final User user,
      final bool requiresEmailVerification,
      final bool requiresProfileCreation}) = _$AuthSuccessImpl;

  User get user;
  bool get requiresEmailVerification;
  bool get requiresProfileCreation;

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthSuccessImplCopyWith<_$AuthSuccessImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AuthFailureImplCopyWith<$Res> {
  factory _$$AuthFailureImplCopyWith(
          _$AuthFailureImpl value, $Res Function(_$AuthFailureImpl) then) =
      __$$AuthFailureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message, String? code});
}

/// @nodoc
class __$$AuthFailureImplCopyWithImpl<$Res>
    extends _$AuthResultCopyWithImpl<$Res, _$AuthFailureImpl>
    implements _$$AuthFailureImplCopyWith<$Res> {
  __$$AuthFailureImplCopyWithImpl(
      _$AuthFailureImpl _value, $Res Function(_$AuthFailureImpl) _then)
      : super(_value, _then);

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? code = freezed,
  }) {
    return _then(_$AuthFailureImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      code: freezed == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$AuthFailureImpl implements AuthFailure {
  const _$AuthFailureImpl({required this.message, this.code});

  @override
  final String message;
  @override
  final String? code;

  @override
  String toString() {
    return 'AuthResult.failure(message: $message, code: $code)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthFailureImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.code, code) || other.code == code));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message, code);

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthFailureImplCopyWith<_$AuthFailureImpl> get copyWith =>
      __$$AuthFailureImplCopyWithImpl<_$AuthFailureImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(User user, bool requiresEmailVerification,
            bool requiresProfileCreation)
        success,
    required TResult Function(String message, String? code) failure,
    required TResult Function() cancelled,
  }) {
    return failure(message, code);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(User user, bool requiresEmailVerification,
            bool requiresProfileCreation)?
        success,
    TResult? Function(String message, String? code)? failure,
    TResult? Function()? cancelled,
  }) {
    return failure?.call(message, code);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(User user, bool requiresEmailVerification,
            bool requiresProfileCreation)?
        success,
    TResult Function(String message, String? code)? failure,
    TResult Function()? cancelled,
    required TResult orElse(),
  }) {
    if (failure != null) {
      return failure(message, code);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AuthSuccess value) success,
    required TResult Function(AuthFailure value) failure,
    required TResult Function(AuthCancelled value) cancelled,
  }) {
    return failure(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AuthSuccess value)? success,
    TResult? Function(AuthFailure value)? failure,
    TResult? Function(AuthCancelled value)? cancelled,
  }) {
    return failure?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AuthSuccess value)? success,
    TResult Function(AuthFailure value)? failure,
    TResult Function(AuthCancelled value)? cancelled,
    required TResult orElse(),
  }) {
    if (failure != null) {
      return failure(this);
    }
    return orElse();
  }
}

abstract class AuthFailure implements AuthResult {
  const factory AuthFailure(
      {required final String message, final String? code}) = _$AuthFailureImpl;

  String get message;
  String? get code;

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthFailureImplCopyWith<_$AuthFailureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AuthCancelledImplCopyWith<$Res> {
  factory _$$AuthCancelledImplCopyWith(
          _$AuthCancelledImpl value, $Res Function(_$AuthCancelledImpl) then) =
      __$$AuthCancelledImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$AuthCancelledImplCopyWithImpl<$Res>
    extends _$AuthResultCopyWithImpl<$Res, _$AuthCancelledImpl>
    implements _$$AuthCancelledImplCopyWith<$Res> {
  __$$AuthCancelledImplCopyWithImpl(
      _$AuthCancelledImpl _value, $Res Function(_$AuthCancelledImpl) _then)
      : super(_value, _then);

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$AuthCancelledImpl implements AuthCancelled {
  const _$AuthCancelledImpl();

  @override
  String toString() {
    return 'AuthResult.cancelled()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$AuthCancelledImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(User user, bool requiresEmailVerification,
            bool requiresProfileCreation)
        success,
    required TResult Function(String message, String? code) failure,
    required TResult Function() cancelled,
  }) {
    return cancelled();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(User user, bool requiresEmailVerification,
            bool requiresProfileCreation)?
        success,
    TResult? Function(String message, String? code)? failure,
    TResult? Function()? cancelled,
  }) {
    return cancelled?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(User user, bool requiresEmailVerification,
            bool requiresProfileCreation)?
        success,
    TResult Function(String message, String? code)? failure,
    TResult Function()? cancelled,
    required TResult orElse(),
  }) {
    if (cancelled != null) {
      return cancelled();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AuthSuccess value) success,
    required TResult Function(AuthFailure value) failure,
    required TResult Function(AuthCancelled value) cancelled,
  }) {
    return cancelled(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AuthSuccess value)? success,
    TResult? Function(AuthFailure value)? failure,
    TResult? Function(AuthCancelled value)? cancelled,
  }) {
    return cancelled?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AuthSuccess value)? success,
    TResult Function(AuthFailure value)? failure,
    TResult Function(AuthCancelled value)? cancelled,
    required TResult orElse(),
  }) {
    if (cancelled != null) {
      return cancelled(this);
    }
    return orElse();
  }
}

abstract class AuthCancelled implements AuthResult {
  const factory AuthCancelled() = _$AuthCancelledImpl;
}
