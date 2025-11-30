// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// ============================================
/// DATA LAYER - Dependency Injection
/// ============================================
/// Provider para AuthRemoteDataSource (singleton)

@ProviderFor(authRemoteDataSource)
const authRemoteDataSourceProvider = AuthRemoteDataSourceProvider._();

/// ============================================
/// DATA LAYER - Dependency Injection
/// ============================================
/// Provider para AuthRemoteDataSource (singleton)

final class AuthRemoteDataSourceProvider extends $FunctionalProvider<
    AuthRemoteDataSource,
    AuthRemoteDataSource,
    AuthRemoteDataSource> with $Provider<AuthRemoteDataSource> {
  /// ============================================
  /// DATA LAYER - Dependency Injection
  /// ============================================
  /// Provider para AuthRemoteDataSource (singleton)
  const AuthRemoteDataSourceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'authRemoteDataSourceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$authRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<AuthRemoteDataSource> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRemoteDataSource create(Ref ref) {
    return authRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRemoteDataSource>(value),
    );
  }
}

String _$authRemoteDataSourceHash() =>
    r'b6a9edd1b6c48be8564688bac362316f598b4432';

/// Provider para AuthRepository (singleton)

@ProviderFor(authRepository)
const authRepositoryProvider = AuthRepositoryProvider._();

/// Provider para AuthRepository (singleton)

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  /// Provider para AuthRepository (singleton)
  const AuthRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'authRepositoryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'05c6159f6976986da64509d15b55d499b8b724b4';

/// ============================================
/// DOMAIN LAYER - UseCases
/// ============================================
/// Provider para SignInWithEmailUseCase

@ProviderFor(signInWithEmailUseCase)
const signInWithEmailUseCaseProvider = SignInWithEmailUseCaseProvider._();

/// ============================================
/// DOMAIN LAYER - UseCases
/// ============================================
/// Provider para SignInWithEmailUseCase

final class SignInWithEmailUseCaseProvider extends $FunctionalProvider<
    SignInWithEmailUseCase,
    SignInWithEmailUseCase,
    SignInWithEmailUseCase> with $Provider<SignInWithEmailUseCase> {
  /// ============================================
  /// DOMAIN LAYER - UseCases
  /// ============================================
  /// Provider para SignInWithEmailUseCase
  const SignInWithEmailUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'signInWithEmailUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$signInWithEmailUseCaseHash();

  @$internal
  @override
  $ProviderElement<SignInWithEmailUseCase> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SignInWithEmailUseCase create(Ref ref) {
    return signInWithEmailUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignInWithEmailUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignInWithEmailUseCase>(value),
    );
  }
}

String _$signInWithEmailUseCaseHash() =>
    r'8b12333bcccdb296a736f6374d468c815512c4ab';

/// Provider para SignUpWithEmailUseCase

@ProviderFor(signUpWithEmailUseCase)
const signUpWithEmailUseCaseProvider = SignUpWithEmailUseCaseProvider._();

/// Provider para SignUpWithEmailUseCase

final class SignUpWithEmailUseCaseProvider extends $FunctionalProvider<
    SignUpWithEmailUseCase,
    SignUpWithEmailUseCase,
    SignUpWithEmailUseCase> with $Provider<SignUpWithEmailUseCase> {
  /// Provider para SignUpWithEmailUseCase
  const SignUpWithEmailUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'signUpWithEmailUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$signUpWithEmailUseCaseHash();

  @$internal
  @override
  $ProviderElement<SignUpWithEmailUseCase> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SignUpWithEmailUseCase create(Ref ref) {
    return signUpWithEmailUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignUpWithEmailUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignUpWithEmailUseCase>(value),
    );
  }
}

String _$signUpWithEmailUseCaseHash() =>
    r'208b6723dc4d6968f330194e094d32220878df52';

/// Provider para SignInWithGoogleUseCase

@ProviderFor(signInWithGoogleUseCase)
const signInWithGoogleUseCaseProvider = SignInWithGoogleUseCaseProvider._();

/// Provider para SignInWithGoogleUseCase

final class SignInWithGoogleUseCaseProvider extends $FunctionalProvider<
    SignInWithGoogleUseCase,
    SignInWithGoogleUseCase,
    SignInWithGoogleUseCase> with $Provider<SignInWithGoogleUseCase> {
  /// Provider para SignInWithGoogleUseCase
  const SignInWithGoogleUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'signInWithGoogleUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$signInWithGoogleUseCaseHash();

  @$internal
  @override
  $ProviderElement<SignInWithGoogleUseCase> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SignInWithGoogleUseCase create(Ref ref) {
    return signInWithGoogleUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignInWithGoogleUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignInWithGoogleUseCase>(value),
    );
  }
}

String _$signInWithGoogleUseCaseHash() =>
    r'dc90c4b43fcbfc22a70458e8591d8f4c2d9bc76b';

/// Provider para SignInWithAppleUseCase

@ProviderFor(signInWithAppleUseCase)
const signInWithAppleUseCaseProvider = SignInWithAppleUseCaseProvider._();

/// Provider para SignInWithAppleUseCase

final class SignInWithAppleUseCaseProvider extends $FunctionalProvider<
    SignInWithAppleUseCase,
    SignInWithAppleUseCase,
    SignInWithAppleUseCase> with $Provider<SignInWithAppleUseCase> {
  /// Provider para SignInWithAppleUseCase
  const SignInWithAppleUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'signInWithAppleUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$signInWithAppleUseCaseHash();

  @$internal
  @override
  $ProviderElement<SignInWithAppleUseCase> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SignInWithAppleUseCase create(Ref ref) {
    return signInWithAppleUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignInWithAppleUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignInWithAppleUseCase>(value),
    );
  }
}

String _$signInWithAppleUseCaseHash() =>
    r'2ddf12d1c1a02d09e209d7c45c6614c387a2c051';

/// Provider para SignOutUseCase

@ProviderFor(signOutUseCase)
const signOutUseCaseProvider = SignOutUseCaseProvider._();

/// Provider para SignOutUseCase

final class SignOutUseCaseProvider
    extends $FunctionalProvider<SignOutUseCase, SignOutUseCase, SignOutUseCase>
    with $Provider<SignOutUseCase> {
  /// Provider para SignOutUseCase
  const SignOutUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'signOutUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$signOutUseCaseHash();

  @$internal
  @override
  $ProviderElement<SignOutUseCase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SignOutUseCase create(Ref ref) {
    return signOutUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignOutUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignOutUseCase>(value),
    );
  }
}

String _$signOutUseCaseHash() => r'8cc2470ed44022c6868a2e710009d5234e1a80fc';

/// Provider para SendPasswordResetEmailUseCase

@ProviderFor(sendPasswordResetEmailUseCase)
const sendPasswordResetEmailUseCaseProvider =
    SendPasswordResetEmailUseCaseProvider._();

/// Provider para SendPasswordResetEmailUseCase

final class SendPasswordResetEmailUseCaseProvider extends $FunctionalProvider<
        SendPasswordResetEmailUseCase,
        SendPasswordResetEmailUseCase,
        SendPasswordResetEmailUseCase>
    with $Provider<SendPasswordResetEmailUseCase> {
  /// Provider para SendPasswordResetEmailUseCase
  const SendPasswordResetEmailUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'sendPasswordResetEmailUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$sendPasswordResetEmailUseCaseHash();

  @$internal
  @override
  $ProviderElement<SendPasswordResetEmailUseCase> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SendPasswordResetEmailUseCase create(Ref ref) {
    return sendPasswordResetEmailUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SendPasswordResetEmailUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<SendPasswordResetEmailUseCase>(value),
    );
  }
}

String _$sendPasswordResetEmailUseCaseHash() =>
    r'6e03dbb68ffd2ed8bdd85e6f93e2cd61f0945f9b';

/// Provider para SendEmailVerificationUseCase

@ProviderFor(sendEmailVerificationUseCase)
const sendEmailVerificationUseCaseProvider =
    SendEmailVerificationUseCaseProvider._();

/// Provider para SendEmailVerificationUseCase

final class SendEmailVerificationUseCaseProvider extends $FunctionalProvider<
    SendEmailVerificationUseCase,
    SendEmailVerificationUseCase,
    SendEmailVerificationUseCase> with $Provider<SendEmailVerificationUseCase> {
  /// Provider para SendEmailVerificationUseCase
  const SendEmailVerificationUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'sendEmailVerificationUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$sendEmailVerificationUseCaseHash();

  @$internal
  @override
  $ProviderElement<SendEmailVerificationUseCase> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SendEmailVerificationUseCase create(Ref ref) {
    return sendEmailVerificationUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SendEmailVerificationUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SendEmailVerificationUseCase>(value),
    );
  }
}

String _$sendEmailVerificationUseCaseHash() =>
    r'ca5d253611bfc934c36e87e2a979b71c19aba89c';

/// ============================================
/// PRESENTATION LAYER - State
/// ============================================
/// Provider para o stream de auth state changes
///
/// Reactivo - atualiza automaticamente quando user faz login/logout

@ProviderFor(authState)
const authStateProvider = AuthStateProvider._();

/// ============================================
/// PRESENTATION LAYER - State
/// ============================================
/// Provider para o stream de auth state changes
///
/// Reactivo - atualiza automaticamente quando user faz login/logout

final class AuthStateProvider
    extends $FunctionalProvider<AsyncValue<User?>, User?, Stream<User?>>
    with $FutureModifier<User?>, $StreamProvider<User?> {
  /// ============================================
  /// PRESENTATION LAYER - State
  /// ============================================
  /// Provider para o stream de auth state changes
  ///
  /// Reactivo - atualiza automaticamente quando user faz login/logout
  const AuthStateProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'authStateProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$authStateHash();

  @$internal
  @override
  $StreamProviderElement<User?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<User?> create(Ref ref) {
    return authState(ref);
  }
}

String _$authStateHash() => r'3287ebbacddb50a826fd28bc6d4a4708785c8891';

/// Provider para o usuário atual (nullable)
///
/// Útil para checagens rápidas sem async

@ProviderFor(currentUser)
const currentUserProvider = CurrentUserProvider._();

/// Provider para o usuário atual (nullable)
///
/// Útil para checagens rápidas sem async

final class CurrentUserProvider extends $FunctionalProvider<User?, User?, User?>
    with $Provider<User?> {
  /// Provider para o usuário atual (nullable)
  ///
  /// Útil para checagens rápidas sem async
  const CurrentUserProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'currentUserProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$currentUserHash();

  @$internal
  @override
  $ProviderElement<User?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  User? create(Ref ref) {
    return currentUser(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(User? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<User?>(value),
    );
  }
}

String _$currentUserHash() => r'ab87a355dd423d79a81ba656f9396a458ad8ed84';

/// Provider para verificar se usuário está autenticado

@ProviderFor(isAuthenticated)
const isAuthenticatedProvider = IsAuthenticatedProvider._();

/// Provider para verificar se usuário está autenticado

final class IsAuthenticatedProvider
    extends $FunctionalProvider<bool, bool, bool> with $Provider<bool> {
  /// Provider para verificar se usuário está autenticado
  const IsAuthenticatedProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'isAuthenticatedProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$isAuthenticatedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isAuthenticated(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isAuthenticatedHash() => r'54fa2e7165f29e09a4d03d1f0bf7ae0df72cf5dc';

/// Provider para verificar se email foi verificado

@ProviderFor(isEmailVerified)
const isEmailVerifiedProvider = IsEmailVerifiedProvider._();

/// Provider para verificar se email foi verificado

final class IsEmailVerifiedProvider
    extends $FunctionalProvider<bool, bool, bool> with $Provider<bool> {
  /// Provider para verificar se email foi verificado
  const IsEmailVerifiedProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'isEmailVerifiedProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$isEmailVerifiedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isEmailVerified(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isEmailVerifiedHash() => r'21699e3260e423b151b31d17a002ba63097dfde5';

/// ============================================
/// FACADE - Simplificação de acesso
/// ============================================
/// Provider para AuthService (facade)
///
/// MANTIDO PARA RETROCOMPATIBILIDADE COM CÓDIGO ANTIGO
/// Fornece interface simples para código legado que usa AuthService
///
/// DEPRECATED: Novo código deve usar UseCases diretamente

@ProviderFor(authService)
@Deprecated('Use UseCases diretamente (signInWithEmailUseCaseProvider, etc)')
const authServiceProvider = AuthServiceProvider._();

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
final class AuthServiceProvider
    extends $FunctionalProvider<IAuthService, IAuthService, IAuthService>
    with $Provider<IAuthService> {
  /// ============================================
  /// FACADE - Simplificação de acesso
  /// ============================================
  /// Provider para AuthService (facade)
  ///
  /// MANTIDO PARA RETROCOMPATIBILIDADE COM CÓDIGO ANTIGO
  /// Fornece interface simples para código legado que usa AuthService
  ///
  /// DEPRECATED: Novo código deve usar UseCases diretamente
  const AuthServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'authServiceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$authServiceHash();

  @$internal
  @override
  $ProviderElement<IAuthService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IAuthService create(Ref ref) {
    return authService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IAuthService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IAuthService>(value),
    );
  }
}

String _$authServiceHash() => r'38f5a8ac9bb90db989e951984da80601ff22f4a6';
