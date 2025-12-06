/// ⚠️ DEPRECATED: Este arquivo está sendo mantido apenas para retrocompatibilidade
///
/// Novos imports devem usar:
/// import 'package:wegig_app/features/auth/domain/entities/auth_result.dart';
///
/// Este arquivo define as entidades diretamente para evitar dependências circulares
/// com o package wegig_app.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_result.freezed.dart';

/// Resultado de operações de autenticação com Freezed
///
/// Sealed class para type-safety e exhaustive pattern matching
@freezed
sealed class AuthResult with _$AuthResult {
  const factory AuthResult.success({
    required User user,
    @Default(false) bool requiresEmailVerification,
    @Default(false) bool requiresProfileCreation,
  }) = AuthSuccess;

  const factory AuthResult.failure({
    required String message,
    String? code,
  }) = AuthFailure;

  const factory AuthResult.cancelled() = AuthCancelled;
}
