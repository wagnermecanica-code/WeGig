import 'package:wegig_app/features/auth/domain/entities/auth_result.dart';
import 'package:wegig_app/features/auth/domain/repositories/auth_repository.dart';

/// UseCase: Cadastro com email e senha
///
/// Single Responsibility: Executar lógica de negócio para cadastro
class SignUpWithEmailUseCase {
  SignUpWithEmailUseCase(this._repository);
  final AuthRepository _repository;

  /// Executa cadastro com email e senha
  ///
  /// Validações:
  /// - Email não vazio e formato válido
  /// - Senha não vazia e >= 6 caracteres
  /// - Senha com complexidade: maiúscula + número + símbolo
  ///
  /// Returns AuthResult
  Future<AuthResult> call(
    String email,
    String password,
    String username,
  ) async {
    // Validações de negócio
    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();
    final normalizedUsername = _normalizeUsername(username);

    if (trimmedEmail.isEmpty) {
      return const AuthFailure(
        message: 'E-mail é obrigatório',
        code: 'empty-email',
      );
    }

    // Validação básica de formato email
    if (!_isValidEmail(trimmedEmail)) {
      return const AuthFailure(
        message: 'E-mail inválido',
        code: 'invalid-email-format',
      );
    }

    if (trimmedPassword.isEmpty) {
      return const AuthFailure(
        message: 'Senha é obrigatória',
        code: 'empty-password',
      );
    }

    // ✅ Política mínima: 6 caracteres
    if (trimmedPassword.length < 6) {
      return const AuthFailure(
        message: 'Senha deve ter pelo menos 6 caracteres',
        code: 'weak-password',
      );
    }

    // ✅ Validação de complexidade
    if (!_isStrongPassword(trimmedPassword)) {
      return const AuthFailure(
        message: 'Senha deve conter: 1 maiúscula, 1 número e 1 símbolo (!@#\$%^&*)',
        code: 'weak-password-complexity',
      );
    }

    if (normalizedUsername.isEmpty) {
      return const AuthFailure(
        message: 'Nome de usuário é obrigatório',
        code: 'empty-username',
      );
    }

    if (normalizedUsername.length < 3) {
      return const AuthFailure(
        message: 'Nome de usuário deve ter pelo menos 3 caracteres',
        code: 'invalid-username-length',
      );
    }

    if (!_isValidUsername(normalizedUsername)) {
      return const AuthFailure(
        message:
            'Nome de usuário inválido. Use apenas letras, números, ponto ou underline',
        code: 'invalid-username-format',
      );
    }

    // Delegar para repository
    return _repository.signUpWithEmail(
      trimmedEmail,
      trimmedPassword,
      normalizedUsername,
    );
  }

  String _normalizeUsername(String username) {
    final trimmed = username.trim();
    final withoutAt = trimmed.startsWith('@') ? trimmed.substring(1) : trimmed;
    return withoutAt.replaceAll(RegExp(r'\s+'), '');
  }

  /// Validação básica de formato de email
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Validação de força de senha (OWASP-compliant)
  ///
  /// Requisitos:
  /// - Pelo menos 1 letra maiúscula
  /// - Pelo menos 1 letra minúscula
  /// - Pelo menos 1 número
  /// - Pelo menos 1 símbolo especial
  bool _isStrongPassword(String password) {
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));

    return hasUppercase && hasLowercase && hasDigit && hasSpecialChar;
  }

  bool _isValidUsername(String username) {
    return RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(username);
  }
}
