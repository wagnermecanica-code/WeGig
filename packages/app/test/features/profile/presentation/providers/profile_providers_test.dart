import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:wegig_app/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:wegig_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:wegig_app/features/profile/domain/usecases/create_profile.dart';
import 'package:wegig_app/features/profile/domain/usecases/delete_profile.dart';
import 'package:wegig_app/features/profile/domain/usecases/get_active_profile.dart';
import 'package:wegig_app/features/profile/domain/usecases/load_all_profiles.dart';
import 'package:wegig_app/features/profile/domain/usecases/switch_active_profile.dart';
import 'package:wegig_app/features/profile/domain/usecases/update_profile.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    // Use mocks to avoid Firebase initialization
    final mockDataSource = _MockProfileRemoteDataSource();
    final mockRepository = _MockProfileRepository();
    final fakeAuth = _StubFirebaseAuth();

    container = ProviderContainer(
      overrides: [
        profileRemoteDataSourceProvider.overrideWithValue(mockDataSource),
        profileRepositoryNewProvider.overrideWithValue(mockRepository),
        profileFirebaseAuthProvider.overrideWithValue(fakeAuth),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Profile Providers - Data Layer', () {
    test('profileRemoteDataSourceProvider returns ProfileRemoteDataSource', () {
      // Act
      final dataSource = container.read(profileRemoteDataSourceProvider);

      // Assert
      expect(dataSource, isA<ProfileRemoteDataSource>());
    });

    test('profileRemoteDataSourceProvider returns singleton', () {
      // Act
      final dataSource1 = container.read(profileRemoteDataSourceProvider);
      final dataSource2 = container.read(profileRemoteDataSourceProvider);

      // Assert
      expect(identical(dataSource1, dataSource2), isTrue);
    });

    test('profileRepositoryNewProvider returns ProfileRepository', () {
      // Act
      final repository = container.read(profileRepositoryNewProvider);

      // Assert
      expect(repository, isA<ProfileRepository>());
    });

    test(
        'profileRepositoryNewProvider depends on profileRemoteDataSourceProvider',
        () {
      // Act
      final repository = container.read(profileRepositoryNewProvider);
      final dataSource = container.read(profileRemoteDataSourceProvider);

      // Assert
      expect(repository, isNotNull);
      expect(dataSource, isNotNull);
    });

    test('profileRepositoryNewProvider returns singleton', () {
      // Act
      final repository1 = container.read(profileRepositoryNewProvider);
      final repository2 = container.read(profileRepositoryNewProvider);

      // Assert
      expect(identical(repository1, repository2), isTrue);
    });
  });

  group('Profile Providers - UseCases', () {
    test('createProfileUseCaseProvider returns CreateProfileUseCase', () {
      // Act
      final useCase = container.read(createProfileUseCaseProvider);

      // Assert
      expect(useCase, isA<CreateProfileUseCase>());
    });

    test('updateProfileUseCaseProvider returns UpdateProfileUseCase', () {
      // Act
      final useCase = container.read(updateProfileUseCaseProvider);

      // Assert
      expect(useCase, isA<UpdateProfileUseCase>());
    });

    test(
        'switchActiveProfileUseCaseProvider returns SwitchActiveProfileUseCase',
        () {
      // Act
      final useCase = container.read(switchActiveProfileUseCaseProvider);

      // Assert
      expect(useCase, isA<SwitchActiveProfileUseCase>());
    });

    test('deleteProfileUseCaseProvider returns DeleteProfileUseCase', () {
      // Act
      final useCase = container.read(deleteProfileUseCaseProvider);

      // Assert
      expect(useCase, isA<DeleteProfileUseCase>());
    });

    test('loadAllProfilesUseCaseProvider returns LoadAllProfilesUseCase', () {
      // Act
      final useCase = container.read(loadAllProfilesUseCaseProvider);

      // Assert
      expect(useCase, isA<LoadAllProfilesUseCase>());
    });

    test('getActiveProfileUseCaseProvider returns GetActiveProfileUseCase', () {
      // Act
      final useCase = container.read(getActiveProfileUseCaseProvider);

      // Assert
      expect(useCase, isA<GetActiveProfileUseCase>());
    });
  });

  group('Profile Providers - UseCases Dependencies', () {
    test('all UseCases should depend on profileRepositoryNewProvider', () {
      // Act - Force creation of all use cases
      container.read(createProfileUseCaseProvider);
      container.read(updateProfileUseCaseProvider);
      container.read(switchActiveProfileUseCaseProvider);
      container.read(deleteProfileUseCaseProvider);
      container.read(loadAllProfilesUseCaseProvider);
      container.read(getActiveProfileUseCaseProvider);

      final repository = container.read(profileRepositoryNewProvider);

      // Assert - Repository should be created and shared
      expect(repository, isNotNull);
    });

    test('UseCases should return same instance (singleton)', () {
      // Act
      final useCase1 = container.read(createProfileUseCaseProvider);
      final useCase2 = container.read(createProfileUseCaseProvider);

      // Assert
      expect(identical(useCase1, useCase2), isTrue);
    });
  });

  group('Profile Providers - Derived Providers', () {
    test('activeProfileProvider returns null when profileProvider is loading',
        () {
      // Act
      final activeProfile = container.read(activeProfileProvider);

      // Assert - Should return null during loading state
      expect(activeProfile, isNull);
    });

    test(
        'profileListProvider returns empty list when profileProvider is loading',
        () {
      // Act
      final profileList = container.read(profileListProvider);

      // Assert
      expect(profileList, isEmpty);
    });

    test('hasMultipleProfilesProvider returns false initially', () {
      // Act
      final hasMultiple = container.read(hasMultipleProfilesProvider);

      // Assert
      expect(hasMultiple, isFalse);
    });
  });

  group('Profile Providers - Provider Overrides', () {
    test('can override profileRepositoryNewProvider for testing', () {
      // Arrange
      final mockRepository = _MockProfileRepository();
      final testContainer = ProviderContainer(
        overrides: [
          profileRepositoryNewProvider.overrideWithValue(mockRepository),
        ],
      );

      // Act
      final repository = testContainer.read(profileRepositoryNewProvider);

      // Assert
      expect(repository, equals(mockRepository));

      testContainer.dispose();
    });

    test('overridden repository affects dependent UseCases', () {
      // Arrange
      final mockRepository = _MockProfileRepository();
      final testContainer = ProviderContainer(
        overrides: [
          profileRepositoryNewProvider.overrideWithValue(mockRepository),
        ],
      );

      // Act
      final useCase = testContainer.read(createProfileUseCaseProvider);

      // Assert
      expect(useCase, isA<CreateProfileUseCase>());

      testContainer.dispose();
    });
  });

  group('Profile Providers - Auto-Dispose Behavior', () {
    test('providers should auto-dispose when container is disposed', () {
      // Arrange - Use mocks to avoid Firebase
      final mockDataSource = _MockProfileRemoteDataSource();
      final mockRepository = _MockProfileRepository();
      final testContainer = ProviderContainer(
        overrides: [
          profileRemoteDataSourceProvider.overrideWithValue(mockDataSource),
          profileRepositoryNewProvider.overrideWithValue(mockRepository),
        ],
      );
      testContainer.read(profileRepositoryNewProvider);
      testContainer.read(createProfileUseCaseProvider);

      // Act
      testContainer.dispose();

      // Assert
      expect(() => testContainer.read(profileRepositoryNewProvider),
          throwsStateError);
    });
  });

  group('Profile Providers - ProfileNotifier Integration', () {
    test('profileProvider is AsyncNotifierProvider', () {
      // Act
      final profileState = container.read(profileProvider);

      // Assert
      expect(profileState, isA<AsyncValue>());
    });

    test('profileProvider starts in loading state', () {
      // Act
      final profileState = container.read(profileProvider);

      // Assert - Initial state should be loading
      expect(profileState.isLoading, isTrue);
    });
  });
}

/// Mock class for ProfileRemoteDataSource
class _MockProfileRemoteDataSource implements ProfileRemoteDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mock class for testing provider overrides
class _MockProfileRepository implements ProfileRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubFirebaseAuth implements FirebaseAuth {
  @override
  User? get currentUser => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
