import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:wegig_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:wegig_app/features/auth/domain/entities/auth_result.dart';
import 'package:wegig_app/features/auth/domain/repositories/auth_repository.dart';

/// Implementação do AuthRepository
///
/// Responsabilidades:
/// - Converter exceções em AuthResult
/// - Cleanup local (SharedPreferences, ImageCache)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;
  final AuthRemoteDataSource _remoteDataSource;

  @override
  Stream<User?> get authStateChanges => _remoteDataSource.authStateChanges;

  @override
  User? get currentUser => _remoteDataSource.currentUser;

  @override
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  @override
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      debugPrint('🔐 AuthRepository: signInWithEmail');

      final user = await _remoteDataSource.signInWithEmail(email, password);

      debugPrint('✅ AuthRepository: signInWithEmail success');
      return AuthSuccess(user: user);
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ AuthRepository: FirebaseAuthException - ${e.code}');

      return AuthFailure(
        message: _mapFirebaseErrorToMessage(e),
        code: e.code,
      );
    } catch (e) {
      debugPrint('❌ AuthRepository: Unexpected error - $e');

      return const AuthFailure(
        message: 'Erro inesperado ao fazer login. Tente novamente.',
      );
    }
  }

  @override
  Future<AuthResult> signUpWithEmail(
    String email,
    String password,
  ) async {
    try {
      debugPrint('🔐 AuthRepository: signUpWithEmail');

      final user = await _remoteDataSource.signUpWithEmail(
        email,
        password,
      );

      debugPrint('✅ AuthRepository: signUpWithEmail success');
      return AuthSuccess(
        user: user,
        requiresEmailVerification: true,
        requiresProfileCreation: true,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ AuthRepository: FirebaseAuthException - ${e.code}');

      return AuthFailure(
        message: _mapFirebaseErrorToMessage(e),
        code: e.code,
      );
    } catch (e) {
      debugPrint('❌ AuthRepository: Unexpected error - $e');

      return const AuthFailure(
        message: 'Erro inesperado ao criar conta. Tente novamente.',
      );
    }
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    try {
      debugPrint('🔐 AuthRepository: signInWithGoogle');

      final user = await _remoteDataSource.signInWithGoogle();

      // Usuário cancelou
      if (user == null) {
        debugPrint('⚠️ AuthRepository: Usuário cancelou Google Sign-In');
        return const AuthCancelled();
      }

      // Verificar se é novo usuário (documento users/{uid} criado recentemente)
      final isNewUser = !(await _remoteDataSource.userDocumentExists(user.uid));

      debugPrint('✅ AuthRepository: signInWithGoogle success');
      return AuthSuccess(
        user: user,
        requiresProfileCreation: isNewUser,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ AuthRepository: FirebaseAuthException - ${e.code}');

      return AuthFailure(
        message: _mapFirebaseErrorToMessage(e),
        code: e.code,
      );
    } catch (e) {
      debugPrint('❌ AuthRepository: Unexpected error - $e');

      return const AuthFailure(
        message: 'Erro ao fazer login com Google. Tente novamente.',
      );
    }
  }

  @override
  Future<AuthResult> signInWithApple() async {
    try {
      debugPrint('🔐 AuthRepository: signInWithApple');

      final user = await _remoteDataSource.signInWithApple();

      // Usuário cancelou
      if (user == null) {
        debugPrint('⚠️ AuthRepository: Usuário cancelou Apple Sign-In');
        return const AuthCancelled();
      }

      // Verificar se é novo usuário
      final isNewUser = !(await _remoteDataSource.userDocumentExists(user.uid));

      debugPrint('✅ AuthRepository: signInWithApple success');
      return AuthSuccess(
        user: user,
        requiresProfileCreation: isNewUser,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      debugPrint('❌ AuthRepository: Apple Authorization Exception - ${e.code}');

      // Usuário cancelou
      if (e.code == AuthorizationErrorCode.canceled) {
        debugPrint('⚠️ AuthRepository: Usuário cancelou Apple Sign-In');
        return const AuthCancelled();
      }

      return AuthFailure(
        message: 'Erro ao fazer login com Apple: ${e.message}',
        code: e.code.toString(),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ AuthRepository: FirebaseAuthException - ${e.code}');

      return AuthFailure(
        message: _mapFirebaseErrorToMessage(e),
        code: e.code,
      );
    } catch (e) {
      debugPrint('❌ AuthRepository: Unexpected error - $e');

      return const AuthFailure(
        message: 'Erro ao fazer login com Apple. Tente novamente.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      debugPrint('🔓 AuthRepository: signOut - iniciando cleanup...');

      // 1. Limpar SharedPreferences
      debugPrint('🧹 AuthRepository: Limpando SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // 2. Limpar cache de imagens
      debugPrint('🧹 AuthRepository: Limpando cache de imagens...');
      try {
        final imageCache = PaintingBinding.instance.imageCache;
        imageCache.clear();
        imageCache.clearLiveImages();
      } catch (e) {
        debugPrint('⚠️ AuthRepository: Erro ao limpar cache de imagens: $e');
      }

      // 4. Sign out remoto (Firebase + Google)
      await _remoteDataSource.signOut();

      debugPrint('✅ AuthRepository: signOut completo');
    } catch (e) {
      debugPrint('❌ AuthRepository: Erro durante signOut: $e');
      rethrow;
    }
  }

  @override
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      debugPrint('🔐 AuthRepository: sendPasswordResetEmail');

      await _remoteDataSource.sendPasswordResetEmail(email);

      debugPrint('✅ AuthRepository: Password reset email sent');
      return AuthSuccess(
        user: currentUser!, // Não vai ser usado, mas precisa retornar
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ AuthRepository: FirebaseAuthException - ${e.code}');

      return AuthFailure(
        message: _mapFirebaseErrorToMessage(e),
        code: e.code,
      );
    } catch (e) {
      debugPrint('❌ AuthRepository: Unexpected error - $e');

      return const AuthFailure(
        message: 'Erro ao enviar email de recuperação. Tente novamente.',
      );
    }
  }

  @override
  Future<AuthResult> sendEmailVerification() async {
    try {
      debugPrint('🔐 AuthRepository: sendEmailVerification');

      await _remoteDataSource.sendEmailVerification();

      debugPrint('✅ AuthRepository: Email verification sent');
      return AuthSuccess(user: currentUser!);
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ AuthRepository: FirebaseAuthException - ${e.code}');

      return AuthFailure(
        message: _mapFirebaseErrorToMessage(e),
        code: e.code,
      );
    } catch (e) {
      debugPrint('❌ AuthRepository: Unexpected error - $e');

      return const AuthFailure(
        message: 'Erro ao enviar email de verificação. Tente novamente.',
      );
    }
  }

  /// Mapeia erros Firebase para mensagens amigáveis
  String _mapFirebaseErrorToMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Usuário não encontrado. Verifique o e-mail.';
      case 'wrong-password':
        return 'Senha incorreta. Tente novamente.';
      case 'email-already-in-use':
        return 'Este e-mail já está em uso.';
      case 'weak-password':
        return 'Senha muito fraca. Use pelo menos 6 caracteres.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'network-request-failed':
        return 'Erro de conexão. Verifique sua internet.';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'operation-not-allowed':
        return 'Operação não permitida.';
      case 'invalid-credential':
        return 'Credenciais inválidas.';
      default:
        return e.message ?? 'Erro desconhecido. Tente novamente.';
    }
  }
}
