import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wegig_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:wegig_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:wegig_app/features/auth/domain/entities/auth_result.dart';
import 'package:wegig_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:wegig_app/features/auth/domain/usecases/send_email_verification.dart';
import 'package:wegig_app/features/auth/domain/usecases/send_password_reset_email.dart';
import 'package:wegig_app/features/auth/domain/usecases/sign_in_with_apple.dart';
import 'package:wegig_app/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:wegig_app/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:wegig_app/features/auth/domain/usecases/sign_out.dart';
import 'package:wegig_app/features/auth/domain/usecases/sign_up_with_email.dart';

part 'auth_providers.g.dart';

/// ============================================
/// Provider para bloquear redirect durante operações críticas
/// ============================================
/// 
/// Quando true, o router não deve fazer redirect automático.
/// Isso previne race conditions durante login social onde:
/// 1. Firebase Auth cria usuário automaticamente
/// 2. AuthPage precisa verificar Firestore e possivelmente fazer signOut
/// 3. Router quer redirecionar para /profiles/new antes do signOut completar
final authOperationInProgressProvider = StateProvider<bool>((ref) {
  debugPrint('🔐 authOperationInProgressProvider: Criando provider');
  return false;
});

/// ============================================
/// Provider para mensagem de erro pendente (exibida após redirecionamento)
/// ============================================
/// 
/// Usado quando um erro ocorre durante login social mas o router já navegou
/// antes que a mensagem pudesse ser exibida. A mensagem será consumida
/// quando a tela de auth for reconstruída.
final pendingAuthErrorProvider = StateProvider<String?>((ref) => null);

/// ============================================
/// Provider para dados do login social (Apple/Google)
/// ============================================
/// 
/// Armazena temporariamente os dados fornecidos pelo provider social
/// (nome, email) para serem usados na tela de criação de perfil.
/// Isso garante conformidade com as diretrizes da Apple (HIG) ao não
/// solicitar novamente dados que já foram fornecidos pelo Sign in with Apple.
class SocialLoginData {
  const SocialLoginData({
    this.displayName,
    this.email,
    this.photoUrl,
    this.provider,
  });

  /// Nome completo fornecido pelo provider (Apple/Google)
  final String? displayName;
  
  /// Email fornecido pelo provider (pode ser private relay no caso da Apple)
  final String? email;
  
  /// URL da foto de perfil (geralmente disponível apenas no Google)
  final String? photoUrl;
  
  /// Provider de autenticação ('apple' ou 'google')
  final String? provider;

  /// Retorna true se temos um nome para usar
  bool get hasDisplayName => displayName != null && displayName!.trim().isNotEmpty;
  
  /// Retorna true se temos um email
  bool get hasEmail => email != null && email!.trim().isNotEmpty;
  
  /// Gera sugestões de username baseadas no nome
  List<String> generateUsernameSuggestions() {
    // Apple muitas vezes não fornece nome nas tentativas subsequentes.
    // Fallback: usar a parte local do email (antes do @) para sugerir username.
    final base = hasDisplayName
        ? displayName!.trim().toLowerCase()
        : (hasEmail ? email!.split('@').first.trim().toLowerCase() : '');
    if (base.isEmpty) return [];

    final name = base;
    final parts = name.split(RegExp(r'\s+'));
    final suggestions = <String>[];
    
    // Remover caracteres especiais e acentos
    String normalize(String s) {
      return s
          .replaceAll(RegExp(r'[àáâãäå]'), 'a')
          .replaceAll(RegExp(r'[èéêë]'), 'e')
          .replaceAll(RegExp(r'[ìíîï]'), 'i')
          .replaceAll(RegExp(r'[òóôõö]'), 'o')
          .replaceAll(RegExp(r'[ùúûü]'), 'u')
          .replaceAll(RegExp(r'[ç]'), 'c')
          .replaceAll(RegExp(r'[^a-z0-9_]'), '');
    }
    
    // 1. Primeiro nome apenas
    if (parts.isNotEmpty) {
      final firstName = normalize(parts.first);
      if (firstName.length >= 3) {
        suggestions.add(firstName);
      }
    }
    
    // 2. Primeiro nome + inicial do sobrenome
    if (parts.length >= 2) {
      final firstName = normalize(parts.first);
      final lastInitial = normalize(parts.last.substring(0, 1));
      if (firstName.length >= 2) {
        suggestions.add('$firstName$lastInitial');
      }
    }
    
    // 3. Primeiro nome + sobrenome
    if (parts.length >= 2) {
      final firstName = normalize(parts.first);
      final lastName = normalize(parts.last);
      if (firstName.isNotEmpty && lastName.isNotEmpty) {
        suggestions.add('${firstName}_$lastName');
        suggestions.add('$firstName$lastName');
      }
    }
    
    // 4. Iniciais + números aleatórios
    if (parts.isNotEmpty) {
      final firstName = normalize(parts.first);
      final random = DateTime.now().millisecondsSinceEpoch % 1000;
      suggestions.add('$firstName$random');
    }
    
    // Filtrar sugestões válidas (3-20 caracteres, sem underscore no início/fim)
    return suggestions
        .where((s) => s.length >= 3 && s.length <= 20)
        .where((s) => !s.startsWith('_') && !s.endsWith('_'))
        .toSet()
        .take(4)
        .toList();
  }

  @override
  String toString() => 'SocialLoginData(displayName: $displayName, email: $email, provider: $provider)';
}

/// Provider para armazenar dados do login social temporariamente
final socialLoginDataProvider = StateProvider<SocialLoginData?>((ref) => null);

/// ============================================
/// DATA LAYER - Dependency Injection
/// ============================================

/// Provider para AuthRemoteDataSource (singleton)
@riverpod
AuthRemoteDataSource authRemoteDataSource(Ref ref) {
  return AuthRemoteDataSourceImpl();
}

/// Provider para AuthRepository (singleton)
@riverpod
AuthRepository authRepository(Ref ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(remoteDataSource: remoteDataSource);
}

/// ============================================
/// DOMAIN LAYER - UseCases
/// ============================================

/// Provider para SignInWithEmailUseCase
@riverpod
SignInWithEmailUseCase signInWithEmailUseCase(Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignInWithEmailUseCase(repository);
}

/// Provider para SignUpWithEmailUseCase
@riverpod
SignUpWithEmailUseCase signUpWithEmailUseCase(Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignUpWithEmailUseCase(repository);
}

/// Provider para SignInWithGoogleUseCase
@riverpod
SignInWithGoogleUseCase signInWithGoogleUseCase(Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignInWithGoogleUseCase(repository);
}

/// Provider para SignInWithAppleUseCase
@riverpod
SignInWithAppleUseCase signInWithAppleUseCase(Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignInWithAppleUseCase(repository);
}

/// Provider para SignOutUseCase
@riverpod
SignOutUseCase signOutUseCase(Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignOutUseCase(repository);
}

/// Provider para SendPasswordResetEmailUseCase
@riverpod
SendPasswordResetEmailUseCase sendPasswordResetEmailUseCase(Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SendPasswordResetEmailUseCase(repository);
}

/// Provider para SendEmailVerificationUseCase
@riverpod
SendEmailVerificationUseCase sendEmailVerificationUseCase(Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SendEmailVerificationUseCase(repository);
}

/// ============================================
/// PRESENTATION LAYER - State
/// ============================================

/// Provider para o stream de auth state changes
///
/// Reactivo - atualiza automaticamente quando user faz login/logout
@riverpod
Stream<User?> authState(Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
}

/// Provider para o usuário atual (nullable)
///
/// Útil para checagens rápidas sem async
@riverpod
User? currentUser(Ref ref) {
  return ref.watch(authStateProvider).value;
}

/// Provider para verificar se usuário está autenticado
@riverpod
bool isAuthenticated(Ref ref) {
  return ref.watch(currentUserProvider) != null;
}

/// Provider para verificar se email foi verificado
@riverpod
bool isEmailVerified(Ref ref) {
  final user = ref.watch(currentUserProvider);
  return user?.emailVerified ?? false;
}

/// ============================================
/// FACADE - Simplificação de acesso
/// ============================================

/// Provider para AuthService (facade)
///
/// MANTIDO PARA RETROCOMPATIBILIDADE COM CÓDIGO ANTIGO
/// Fornece interface simples para código legado que usa AuthService
///
/// DEPRECATED: Novo código deve usar UseCases diretamente
@Deprecated('Use UseCases diretamente (signInWithEmailUseCaseProvider, etc)')
@riverpod
IAuthService authService(Ref ref) {
  return _AuthServiceFacade(ref);
}

/// Facade que adapta nova arquitetura para interface antiga
///
/// Permite código legado funcionar sem modificações enquanto
/// migramos gradualmente para UseCases
class _AuthServiceFacade implements IAuthService {
  _AuthServiceFacade(this._ref);
  final Ref _ref;

  @override
  Stream<User?> get authStateChanges {
    return _ref.read(authRepositoryProvider).authStateChanges;
  }

  @override
  User? get currentUser {
    return _ref.read(authRepositoryProvider).currentUser;
  }

  @override
  Future<AuthResult> signInWithEmail(String email, String password) async {
    final useCase = _ref.read(signInWithEmailUseCaseProvider);
    return useCase(email, password);
  }

  @override
  Future<AuthResult> signUpWithEmail(
    String email,
    String password,
  ) async {
    final useCase = _ref.read(signUpWithEmailUseCaseProvider);
    return useCase(email, password);
  }

  @override
  Future<AuthResult> signInWithGoogle() async {
    final useCase = _ref.read(signInWithGoogleUseCaseProvider);
    return useCase();
  }

  @override
  Future<AuthResult> signInWithApple() async {
    final useCase = _ref.read(signInWithAppleUseCaseProvider);
    return useCase();
  }

  @override
  Future<void> signOut() async {
    final useCase = _ref.read(signOutUseCaseProvider);
    await useCase();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    final useCase = _ref.read(sendPasswordResetEmailUseCaseProvider);
    await useCase(email);
  }

  @override
  Future<void> sendEmailVerification() async {
    final useCase = _ref.read(sendEmailVerificationUseCaseProvider);
    await useCase();
  }
}

/// Interface IAuthService (mantida para retrocompatibilidade)
abstract class IAuthService {
  Stream<User?> get authStateChanges;
  User? get currentUser;
  Future<AuthResult> signInWithEmail(String email, String password);
  Future<AuthResult> signUpWithEmail(String email, String password);
  Future<AuthResult> signInWithGoogle();
  Future<AuthResult> signInWithApple();
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> sendEmailVerification();
}

/// Documento users/{uid} no Firestore
class UserAccountDocument {
  const UserAccountDocument({
    required this.uid,
    this.username,
    this.provider,
    this.displayName,
  });

  final String uid;
  final String? username;
  final String? provider;
  final String? displayName;

  bool get hasUsername => (username ?? '').trim().isNotEmpty;

  factory UserAccountDocument.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return UserAccountDocument(
      uid: doc.id,
      username: data?['username'] as String?,
      provider: data?['provider'] as String?,
      displayName: data?['displayName'] as String?,
    );
  }

  factory UserAccountDocument.fromJson(Map<String, dynamic> json) {
    return UserAccountDocument(
      uid: json['uid'] as String? ?? '',
      username: json['username'] as String?,
      provider: json['provider'] as String?,
      displayName: json['displayName'] as String?,
    );
  }
}

/// Stream do documento users/{uid} para saber se já existe username
final userDocumentProvider =
    StreamProvider.autoDispose<UserAccountDocument?>((ref) {
  final authAsync = ref.watch(authStateProvider);

  return authAsync.when(
    data: (user) {
      if (user == null) {
        return Stream<UserAccountDocument?>.value(null);
      }
      
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((snapshot) {
        if (!snapshot.exists) {
          return null;
        }
        return UserAccountDocument.fromJson(
            snapshot.data() as Map<String, dynamic>);
      });
    },
    loading: () => Stream<UserAccountDocument?>.value(null),
    error: (_, __) => Stream<UserAccountDocument?>.value(null),
  );
});
