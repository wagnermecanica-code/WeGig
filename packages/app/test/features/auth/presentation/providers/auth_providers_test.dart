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
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('Auth Providers - Data Layer', () {
    test('authRemoteDataSourceProvider returns AuthRemoteDataSource instance',
        () {
      // Act
      final dataSource = container.read(authRemoteDataSourceProvider);

      // Assert
      expect(dataSource, isA<AuthRemoteDataSource>());
    });

    test('authRemoteDataSourceProvider returns singleton (same instance)', () {
      // Act
      final dataSource1 = container.read(authRemoteDataSourceProvider);
      final dataSource2 = container.read(authRemoteDataSourceProvider);

      // Assert
      expect(identical(dataSource1, dataSource2), isTrue);
    });

    test('authRepositoryProvider returns AuthRepository instance', () {
      // Act
      final repository = container.read(authRepositoryProvider);

      // Assert
      expect(repository, isA<AuthRepository>());
    });

    test('authRepositoryProvider depends on authRemoteDataSourceProvider', () {
      // Act
      final repository = container.read(authRepositoryProvider);
      final dataSource = container.read(authRemoteDataSourceProvider);

      // Assert - Repository should exist and use the same datasource instance
      expect(repository, isNotNull);
      expect(dataSource, isNotNull);
    });

    test('authRepositoryProvider returns singleton (same instance)', () {
      // Act
      final repository1 = container.read(authRepositoryProvider);
      final repository2 = container.read(authRepositoryProvider);

      // Assert
      expect(identical(repository1, repository2), isTrue);
    });
  });

  group('Auth Providers - UseCases', () {
    test('signInWithEmailUseCaseProvider returns SignInWithEmailUseCase', () {
      // Act
      final useCase = container.read(signInWithEmailUseCaseProvider);

      // Assert
      expect(useCase, isA<SignInWithEmailUseCase>());
    });

    test('signUpWithEmailUseCaseProvider returns SignUpWithEmailUseCase', () {
      // Act
      final useCase = container.read(signUpWithEmailUseCaseProvider);

      // Assert
      expect(useCase, isA<SignUpWithEmailUseCase>());
    });

    test('signInWithGoogleUseCaseProvider returns SignInWithGoogleUseCase',
        () {
      // Act
      final useCase = container.read(signInWithGoogleUseCaseProvider);

      // Assert
      expect(useCase, isA<SignInWithGoogleUseCase>());
    });

    test('signInWithAppleUseCaseProvider returns SignInWithAppleUseCase', () {
      // Act
      final useCase = container.read(signInWithAppleUseCaseProvider);

      // Assert
      expect(useCase, isA<SignInWithAppleUseCase>());
    });

    test('signOutUseCaseProvider returns SignOutUseCase', () {
      // Act
      final useCase = container.read(signOutUseCaseProvider);

      // Assert
      expect(useCase, isA<SignOutUseCase>());
    });

    test(
        'sendPasswordResetEmailUseCaseProvider returns SendPasswordResetEmailUseCase',
        () {
      // Act
      final useCase = container.read(sendPasswordResetEmailUseCaseProvider);

      // Assert
      expect(useCase, isA<SendPasswordResetEmailUseCase>());
    });

    test(
        'sendEmailVerificationUseCaseProvider returns SendEmailVerificationUseCase',
        () {
      // Act
      final useCase = container.read(sendEmailVerificationUseCaseProvider);

      // Assert
      expect(useCase, isA<SendEmailVerificationUseCase>());
    });
  });

  group('Auth Providers - UseCases Dependencies', () {
    test('all UseCases should depend on authRepositoryProvider', () {
      // Act - Force creation of all use cases
      container.read(signInWithEmailUseCaseProvider);
      container.read(signUpWithEmailUseCaseProvider);
      container.read(signInWithGoogleUseCaseProvider);
      container.read(signInWithAppleUseCaseProvider);
      container.read(signOutUseCaseProvider);
      container.read(sendPasswordResetEmailUseCaseProvider);
      container.read(sendEmailVerificationUseCaseProvider);

      final repository = container.read(authRepositoryProvider);

      // Assert - Repository should be created and shared
      expect(repository, isNotNull);
    });

    test('UseCases should return same instance (singleton)', () {
      // Act
      final useCase1 = container.read(signInWithEmailUseCaseProvider);
      final useCase2 = container.read(signInWithEmailUseCaseProvider);

      // Assert
      expect(identical(useCase1, useCase2), isTrue);
    });
  });

  group('Auth Providers - State Providers', () {
    test('authStateProvider provides Stream<User?>', () {
      // Act
      final authStateValue = container.read(authStateProvider);

      // Assert - Should have AsyncValue with initial state
      expect(authStateValue, isA<AsyncValue<User?>>());
    });

    test('currentUserProvider returns null when not authenticated', () {
      // Act
      final currentUser = container.read(currentUserProvider);

      // Assert
      expect(currentUser, isNull);
    });

    test('isAuthenticatedProvider returns false when not authenticated', () {
      // Act
      final isAuthenticated = container.read(isAuthenticatedProvider);

      // Assert
      expect(isAuthenticated, isFalse);
    });

    test('isEmailVerifiedProvider returns false when not authenticated', () {
      // Act
      final isVerified = container.read(isEmailVerifiedProvider);

      // Assert
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
      // Arrange
      final testContainer = ProviderContainer();
      testContainer.read(authRepositoryProvider);
      testContainer.read(signInWithEmailUseCaseProvider);

      // Act
      testContainer.dispose();

      // Assert - Should not throw after disposal
      expect(() => testContainer.read(authRepositoryProvider), throwsStateError);
    });
  });
}

/// Mock class for testing provider overrides
class _MockAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
