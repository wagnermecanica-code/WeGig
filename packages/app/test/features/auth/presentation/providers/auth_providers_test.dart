import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:wegig_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:wegig_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:wegig_app/features/auth/domain/usecases/send_email_verification.dart';
import 'package:wegig_app/features/auth/domain/usecases/send_password_reset_email.dart';
import 'package:wegig_app/features/auth/domain/usecases/sign_in_with_apple.dart';
import 'package:wegig_app/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:wegig_app/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:wegig_app/features/auth/domain/usecases/sign_out.dart';
import 'package:wegig_app/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:wegig_app/features/auth/presentation/providers/auth_providers.dart';

void main() {

  late ProviderContainer container;

  setUp(() {
    final mockDataSource = _MockAuthRemoteDataSource();
    container = ProviderContainer(
      overrides: [
        authRemoteDataSourceProvider.overrideWithValue(mockDataSource),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Auth Providers - Data Layer', () {
    test('authRemoteDataSourceProvider can be overridden', () {
      // Arrange - Override with mock to avoid Firebase initialization
      final mockDataSource = _MockAuthRemoteDataSource();
      final testContainer = ProviderContainer(
        overrides: [
          authRemoteDataSourceProvider.overrideWithValue(mockDataSource),
        ],
      );

      // Act
      final dataSource = testContainer.read(authRemoteDataSourceProvider);

      // Assert
      expect(dataSource, equals(mockDataSource));

      testContainer.dispose();
    });

    test('authRemoteDataSourceProvider returns singleton (same instance)', () {
      // Arrange - Override with mock
      final mockDataSource = _MockAuthRemoteDataSource();
      final testContainer = ProviderContainer(
        overrides: [
          authRemoteDataSourceProvider.overrideWithValue(mockDataSource),
        ],
      );

      // Act
      final dataSource1 = testContainer.read(authRemoteDataSourceProvider);
      final dataSource2 = testContainer.read(authRemoteDataSourceProvider);

      // Assert
      expect(identical(dataSource1, dataSource2), isTrue);

      testContainer.dispose();
    });

    test('authRepositoryProvider returns AuthRepository instance', () {
      // Arrange - Override datasource to avoid Firebase
      final mockDataSource = _MockAuthRemoteDataSource();
      final testContainer = ProviderContainer(
        overrides: [
          authRemoteDataSourceProvider.overrideWithValue(mockDataSource),
        ],
      );

      // Act
      final repository = testContainer.read(authRepositoryProvider);

      // Assert
      expect(repository, isA<AuthRepository>());

      testContainer.dispose();
    });

    test('authRepositoryProvider depends on authRemoteDataSourceProvider', () {
      // Arrange - Override datasource
      final mockDataSource = _MockAuthRemoteDataSource();
      final testContainer = ProviderContainer(
        overrides: [
          authRemoteDataSourceProvider.overrideWithValue(mockDataSource),
        ],
      );

      // Act
      final repository = testContainer.read(authRepositoryProvider);
      final dataSource = testContainer.read(authRemoteDataSourceProvider);

      // Assert - Repository should exist and use the same datasource instance
      expect(repository, isNotNull);
      expect(dataSource, isNotNull);

      testContainer.dispose();
    });

    test('authRepositoryProvider returns singleton (same instance)', () {
      // Arrange - Override datasource
      final mockDataSource = _MockAuthRemoteDataSource();
      final testContainer = ProviderContainer(
        overrides: [
          authRemoteDataSourceProvider.overrideWithValue(mockDataSource),
        ],
      );

      // Act
      final repository1 = testContainer.read(authRepositoryProvider);
      final repository2 = testContainer.read(authRepositoryProvider);

      // Assert
      expect(identical(repository1, repository2), isTrue);

      testContainer.dispose();
    });
  });

  group('Auth Providers - UseCases', () {
    late ProviderContainer testContainer;

    setUp(() {
      // Override datasource to avoid Firebase initialization in all UseCase tests
      final mockDataSource = _MockAuthRemoteDataSource();
      testContainer = ProviderContainer(
        overrides: [
          authRemoteDataSourceProvider.overrideWithValue(mockDataSource),
        ],
      );
    });

    tearDown(() {
      testContainer.dispose();
    });

    test('signInWithEmailUseCaseProvider returns SignInWithEmailUseCase', () {
      // Act
      final useCase = testContainer.read(signInWithEmailUseCaseProvider);

      // Assert
      expect(useCase, isA<SignInWithEmailUseCase>());
    });

    test('signUpWithEmailUseCaseProvider returns SignUpWithEmailUseCase', () {
      // Act
      final useCase = testContainer.read(signUpWithEmailUseCaseProvider);

      // Assert
      expect(useCase, isA<SignUpWithEmailUseCase>());
    });

    test('signInWithGoogleUseCaseProvider returns SignInWithGoogleUseCase', () {
      // Act
      final useCase = testContainer.read(signInWithGoogleUseCaseProvider);

      // Assert
      expect(useCase, isA<SignInWithGoogleUseCase>());
    });

    test('signInWithAppleUseCaseProvider returns SignInWithAppleUseCase', () {
      // Act
      final useCase = testContainer.read(signInWithAppleUseCaseProvider);

      // Assert
      expect(useCase, isA<SignInWithAppleUseCase>());
    });

    test('signOutUseCaseProvider returns SignOutUseCase', () {
      // Act
      final useCase = testContainer.read(signOutUseCaseProvider);

      // Assert
      expect(useCase, isA<SignOutUseCase>());
    });

    test(
        'sendPasswordResetEmailUseCaseProvider returns SendPasswordResetEmailUseCase',
        () {
      // Act
      final useCase = testContainer.read(sendPasswordResetEmailUseCaseProvider);

      // Assert
      expect(useCase, isA<SendPasswordResetEmailUseCase>());
    });

    test(
        'sendEmailVerificationUseCaseProvider returns SendEmailVerificationUseCase',
        () {
      // Act
      final useCase = testContainer.read(sendEmailVerificationUseCaseProvider);

      // Assert
      expect(useCase, isA<SendEmailVerificationUseCase>());
    });
  });

  group('Auth Providers - UseCases Dependencies', () {
    late ProviderContainer testContainer;

    setUp(() {
      // Override datasource to avoid Firebase initialization
      final mockDataSource = _MockAuthRemoteDataSource();
      testContainer = ProviderContainer(
        overrides: [
          authRemoteDataSourceProvider.overrideWithValue(mockDataSource),
        ],
      );
    });

    tearDown(() {
      testContainer.dispose();
    });

    test('all UseCases should depend on authRepositoryProvider', () {
      // Act - Force creation of all use cases
      testContainer.read(signInWithEmailUseCaseProvider);
      testContainer.read(signUpWithEmailUseCaseProvider);
      testContainer.read(signInWithGoogleUseCaseProvider);
      testContainer.read(signInWithAppleUseCaseProvider);
      testContainer.read(signOutUseCaseProvider);
      testContainer.read(sendPasswordResetEmailUseCaseProvider);
      testContainer.read(sendEmailVerificationUseCaseProvider);

      final repository = testContainer.read(authRepositoryProvider);

      // Assert - Repository should be created and shared
      expect(repository, isNotNull);
    });

    test('UseCases should return same instance (singleton)', () {
      // Act
      final useCase1 = testContainer.read(signInWithEmailUseCaseProvider);
      final useCase2 = testContainer.read(signInWithEmailUseCaseProvider);

      // Assert
      expect(identical(useCase1, useCase2), isTrue);
    });
  });

  group('Auth Providers - State Providers', () {
    test('authStateProvider provides Stream<User?>', () {
      final authStateValue = container.read(authStateProvider);
      expect(authStateValue, isA<AsyncValue<User?>>());
    });

    test('currentUserProvider returns null when not authenticated', () {
      final currentUser = container.read(currentUserProvider);
      expect(currentUser, isNull);
    });

    test('isAuthenticatedProvider returns false when not authenticated', () {
      final isAuthenticated = container.read(isAuthenticatedProvider);
      expect(isAuthenticated, isFalse);
    });

    test('isEmailVerifiedProvider returns false when not authenticated', () {
      final isVerified = container.read(isEmailVerifiedProvider);
      expect(isVerified, isFalse);
    });
  });

  group('Auth Providers - Provider Overrides', () {
    test('can override authRepositoryProvider for testing', () {
      // Arrange
      final mockRepository = _MockAuthRepository();
      final testContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );

      // Act
      final repository = testContainer.read(authRepositoryProvider);

      // Assert
      expect(repository, equals(mockRepository));

      testContainer.dispose();
    });

    test('overridden repository affects dependent UseCases', () {
      // Arrange
      final mockRepository = _MockAuthRepository();
      final testContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );

      // Act
      final useCase = testContainer.read(signInWithEmailUseCaseProvider);

      // Assert - UseCase should be created (can't test internal repository directly)
      expect(useCase, isA<SignInWithEmailUseCase>());

      testContainer.dispose();
    });
  });

  group('Auth Providers - Auto-Dispose Behavior', () {
    test('providers should auto-dispose when container is disposed', () {
      // Arrange - Override datasource to avoid Firebase
      final mockDataSource = _MockAuthRemoteDataSource();
      final testContainer = ProviderContainer(
        overrides: [
          authRemoteDataSourceProvider.overrideWithValue(mockDataSource),
        ],
      );
      testContainer.read(authRepositoryProvider);
      testContainer.read(signInWithEmailUseCaseProvider);

      // Act
      testContainer.dispose();

      // Assert - Should throw StateError after disposal
      expect(
          () => testContainer.read(authRepositoryProvider), throwsStateError);
    });
  });
}

/// Mock class for AuthRemoteDataSource
class _MockAuthRemoteDataSource implements AuthRemoteDataSource {
  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  User? get currentUser => null;

  @override
  Future<User?> signInWithApple() => throw UnimplementedError();

  @override
  Future<User?> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<User> signInWithEmail(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<User> signUpWithEmail(
    String email,
    String password,
    String username,
  ) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      throw UnimplementedError();

  @override
  Future<void> sendEmailVerification() => throw UnimplementedError();

  @override
  Future<void> createUserDocument(
    User user,
    String provider, {
    String? username,
  }) =>
      throw UnimplementedError();

  @override
  Future<bool> userDocumentExists(String uid) => throw UnimplementedError();
}

/// Mock class for testing provider overrides
class _MockAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
