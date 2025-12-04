import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:wegig_app/features/post/data/datasources/post_remote_datasource.dart';
import 'package:wegig_app/features/post/domain/repositories/post_repository.dart';
import 'package:wegig_app/features/post/domain/usecases/create_post.dart';
import 'package:wegig_app/features/post/domain/usecases/delete_post.dart';
import 'package:wegig_app/features/post/domain/usecases/load_interested_users.dart';
import 'package:wegig_app/features/post/domain/usecases/toggle_interest.dart';
import 'package:wegig_app/features/post/domain/usecases/update_post.dart';
import 'package:wegig_app/features/post/presentation/providers/post_providers.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    // Use mocks to avoid Firebase initialization
    final mockDataSource = _MockPostRemoteDataSource();
    final mockRepository = _MockPostRepository();
    final fakeAuth = _StubFirebaseAuth();

    container = ProviderContainer(
      overrides: [
        postRemoteDataSourceProvider.overrideWithValue(mockDataSource),
        postRepositoryNewProvider.overrideWithValue(mockRepository),
        postFirebaseAuthProvider.overrideWithValue(fakeAuth),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Post Providers - Data Layer', () {
    test('postRemoteDataSourceProvider returns IPostRemoteDataSource', () {
      // Act
      final dataSource = container.read(postRemoteDataSourceProvider);

      // Assert
      expect(dataSource, isA<IPostRemoteDataSource>());
    });

    test('postRemoteDataSourceProvider returns singleton', () {
      // Act
      final dataSource1 = container.read(postRemoteDataSourceProvider);
      final dataSource2 = container.read(postRemoteDataSourceProvider);

      // Assert
      expect(identical(dataSource1, dataSource2), isTrue);
    });

    test('postRepositoryNewProvider returns PostRepository', () {
      // Act
      final repository = container.read(postRepositoryNewProvider);

      // Assert
      expect(repository, isA<PostRepository>());
    });

    test(
        'postRepositoryNewProvider depends on postRemoteDataSourceProvider', () {
      // Arrange
      var called = false;
      final mockDataSource = _MockPostRemoteDataSource();

      final overriddenContainer = ProviderContainer(
        overrides: [
          postRemoteDataSourceProvider.overrideWith((ref) {
            called = true;
            return mockDataSource;
          }),
        ],
      );

      // Act
      overriddenContainer.read(postRepositoryNewProvider);

      // Assert
      expect(called, isTrue,
          reason:
              'postRepositoryNewProvider should call postRemoteDataSourceProvider');

      overriddenContainer.dispose();
    });
  });

  group('Post Providers - Use Cases', () {
    test('createPostUseCaseProvider returns CreatePost', () {
      // Act
      final useCase = container.read(createPostUseCaseProvider);

      // Assert
      expect(useCase, isA<CreatePost>());
    });

    test('updatePostUseCaseProvider returns UpdatePost', () {
      // Act
      final useCase = container.read(updatePostUseCaseProvider);

      // Assert
      expect(useCase, isA<UpdatePost>());
    });

    test('deletePostUseCaseProvider returns DeletePost', () {
      // Act
      final useCase = container.read(deletePostUseCaseProvider);

      // Assert
      expect(useCase, isA<DeletePost>());
    });

    test('toggleInterestUseCaseProvider returns ToggleInterest', () {
      // Act
      final useCase = container.read(toggleInterestUseCaseProvider);

      // Assert
      expect(useCase, isA<ToggleInterest>());
    });

    test('loadInterestedUsersUseCaseProvider returns LoadInterestedUsers', () {
      // Act
      final useCase = container.read(loadInterestedUsersUseCaseProvider);

      // Assert
      expect(useCase, isA<LoadInterestedUsers>());
    });

    test('All UseCases depend on repository', () {
      // Arrange
      var repositoryCalls = 0;
      final mockRepository = _MockPostRepository();

      final overriddenContainer = ProviderContainer(
        overrides: [
          postRemoteDataSourceProvider
              .overrideWithValue(_MockPostRemoteDataSource()),
          postRepositoryNewProvider.overrideWith((ref) {
            repositoryCalls++;
            return mockRepository;
          }),
        ],
      );

      // Act - Read all use cases
      overriddenContainer.read(createPostUseCaseProvider);
      overriddenContainer.read(updatePostUseCaseProvider);
      overriddenContainer.read(deletePostUseCaseProvider);
      overriddenContainer.read(toggleInterestUseCaseProvider);
      overriddenContainer.read(loadInterestedUsersUseCaseProvider);

      // Assert - Repository should be called once (shared dependency)
      expect(repositoryCalls, equals(1),
          reason: 'Repository is singleton, called once and shared');

      overriddenContainer.dispose();
    });

    test('UseCases return same instance (singleton)', () {
      // Act
      final useCase1 = container.read(createPostUseCaseProvider);
      final useCase2 = container.read(createPostUseCaseProvider);

      // Assert
      expect(identical(useCase1, useCase2), isTrue,
          reason: 'Use cases should be singletons');
    });
  });

  group('Post Providers - Overrides', () {
    test('Can override repository for testing', () {
      // Arrange
      final customRepository = _MockPostRepository();
      final overriddenContainer = ProviderContainer(
        overrides: [
          postRemoteDataSourceProvider
              .overrideWithValue(_MockPostRemoteDataSource()),
          postRepositoryNewProvider.overrideWithValue(customRepository),
        ],
      );

      // Act
      final repository = overriddenContainer.read(postRepositoryNewProvider);

      // Assert
      expect(identical(repository, customRepository), isTrue);

      overriddenContainer.dispose();
    });

    test('Can override use cases for testing', () {
      // Arrange
      final customUseCase = CreatePost(_MockPostRepository());
      final overriddenContainer = ProviderContainer(
        overrides: [
          postRemoteDataSourceProvider
              .overrideWithValue(_MockPostRemoteDataSource()),
          postRepositoryNewProvider.overrideWithValue(_MockPostRepository()),
          createPostUseCaseProvider.overrideWithValue(customUseCase),
        ],
      );

      // Act
      final useCase = overriddenContainer.read(createPostUseCaseProvider);

      // Assert
      expect(identical(useCase, customUseCase), isTrue);

      overriddenContainer.dispose();
    });
  });

  group('Post Providers - PostNotifier', () {
    test('postNotifierProvider is AutoDisposeAsyncNotifierProvider', () {
      // Act & Assert
      expect(postNotifierProvider, isA<AutoDisposeAsyncNotifierProvider>());
    });

    test('postNotifierProvider can be read', () async {
      // Arrange
      final overriddenContainer = ProviderContainer(
        overrides: [
          postRemoteDataSourceProvider
              .overrideWithValue(_MockPostRemoteDataSource()),
          postRepositoryNewProvider.overrideWithValue(_MockPostRepository()),
          postFirebaseAuthProvider.overrideWithValue(_StubFirebaseAuth()),
        ],
      );

      // Act
      final state = overriddenContainer.read(postNotifierProvider);

      // Assert
      expect(state, isA<AsyncValue>());

      overriddenContainer.dispose();
    });
  });

  group('Post Providers - Lifecycle', () {
    test('Providers auto-dispose when container disposed', () {
      // Arrange
      final testContainer = ProviderContainer(
        overrides: [
          postRemoteDataSourceProvider
              .overrideWithValue(_MockPostRemoteDataSource()),
          postRepositoryNewProvider.overrideWithValue(_MockPostRepository()),
          postFirebaseAuthProvider.overrideWithValue(_StubFirebaseAuth()),
        ],
      );

      // Act
      testContainer.read(createPostUseCaseProvider);
      testContainer.dispose();

      // Assert - No exception should be thrown
      expect(() => testContainer.read(createPostUseCaseProvider),
          throwsA(isA<StateError>()));
    });
  });
}

// ============================================
// Mock Classes
// ============================================

class _MockPostRemoteDataSource implements IPostRemoteDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockPostRepository implements PostRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubFirebaseAuth implements FirebaseAuth {
  @override
  User? get currentUser => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
