import 'package:firebase_auth/firebase_auth.dart';
import 'package:wegig_app/features/auth/domain/entities/auth_result.dart';

/// Repository interface para autenticação (domain layer)
///
/// Define contrato para operações de autenticação
/// Implementação real em data/repositories/auth_repository_impl.dart
///
/// Responsabilidades:
/// - Definir operações de autenticação
/// - Retornar AuthResult (domain entity) ao invés de exceções
/// - Abstrair detalhes de implementação (Firebase, Google, Apple)
abstract class AuthRepository {
  /// Stream de mudanças no estado de autenticação
  Stream<User?> get authStateChanges;

  /// Usuário atualmente autenticado (nullable)
  User? get currentUser;

  /// Login com email e senha
  ///
  /// Returns:
  /// - AuthSuccess se credenciais corretas
  /// - AuthFailure se erro (email/senha incorretos, rede, etc)
  Future<AuthResult> signInWithEmail(String email, String password);

  /// Cadastro com email e senha
  ///
  /// Returns:
  /// - AuthSuccess(requiresEmailVerification: true, requiresProfileCreation: true)
  /// - AuthFailure se erro (email já existe, senha fraca, etc)
  Future<AuthResult> signUpWithEmail(
    String email,
    String password,
    String username,
  );

  /// Login com Google
  ///
  /// Returns:
  /// - AuthSuccess se sucesso
  /// - AuthCancelled se usuário cancelou
  /// - AuthFailure se erro
  Future<AuthResult> signInWithGoogle();

  /// Login com Apple
  ///
  /// Returns:
  /// - AuthSuccess se sucesso
  /// - AuthCancelled se usuário cancelou
  /// - AuthFailure se erro
  Future<AuthResult> signInWithApple();

  /// Logout completo (Firebase + Google + Apple + local cleanup)
  ///
  /// Returns:
  /// - AuthSuccess(user: null) sempre (não pode falhar)
  Future<void> signOut();

  /// Enviar email de recuperação de senha
  ///
  /// Returns:
  /// - AuthSuccess se email enviado
  /// - AuthFailure se erro
  Future<AuthResult> sendPasswordResetEmail(String email);

  /// Enviar email de verificação
  ///
  /// Returns:
  /// - AuthSuccess se email enviado
  /// - AuthFailure se erro ou sem usuário logado
  Future<AuthResult> sendEmailVerification();

  /// Verificar se email foi verificado
  bool get isEmailVerified;
}
