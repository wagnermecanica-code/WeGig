import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wegig_app/features/post/domain/usecases/toggle_interest.dart';

import 'mock_post_repository.dart';

void main() {
  late ToggleInterest useCase;
  late MockPostRepository mockRepository;

  setUp(() {
    mockRepository = MockPostRepository();
    useCase = ToggleInterest(mockRepository);
  });

  group('ToggleInterest - Success Cases', () {
    final tPost = PostEntity(
      id: 'post-1',
      authorProfileId: 'profile-1',
      authorUid: 'user-123',
      content: 'Procurando banda',
      location: const GeoPoint(-23.5505, -46.6333),
      city: 'São Paulo',
      type: 'musician',
      level: 'intermediário',
      instruments: ['Guitarra'],
      genres: ['Rock'],
      seekingMusicians: [],
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );

    test('should add interest when profile has not expressed interest yet',
        () async {
      // given
      const postId = 'post-1';
      const profileId = 'profile-2';
      mockRepository.setupPostById(postId, tPost);
      mockRepository.setupToggleInterestResponse(true);

      // when
      final result = await useCase(postId, profileId);

      // then
      expect(result, true);
      expect(mockRepository.toggleInterestCalled, true);
    });

    test('should remove interest when profile has already expressed interest',
        () async {
      // given
      const postId = 'post-1';
      const profileId = 'profile-2';
      mockRepository.setupPostById(postId, tPost);
      mockRepository.setupToggleInterestResponse(false);

      // when
      final result = await useCase(postId, profileId);

      // then
      expect(result, false);
      expect(mockRepository.toggleInterestCalled, true);
    });
  });

  group('ToggleInterest - Validation', () {
    test('should throw when postId is empty', () async {
      // given
      const postId = '';
      const profileId = 'profile-2';

      // when & then
      expect(
        () => useCase(postId, profileId),
        throwsA(
          predicate((e) => e.toString().contains('ID do post é obrigatório')),
        ),
      );
    });

    test('should throw when profileId is empty', () async {
      // given
      const postId = 'post-1';
      const profileId = '';

      // when & then
      expect(
        () => useCase(postId, profileId),
        throwsA(
          predicate((e) => e.toString().contains('ID do perfil é obrigatório')),
        ),
      );
    });

    test('should throw when post does not exist', () async {
      // given
      const postId = 'non-existent-post';
      const profileId = 'profile-2';
      mockRepository.setupPostById(postId, null);

      // when & then
      expect(
        () => useCase(postId, profileId),
        throwsA(
          predicate((e) => e.toString().contains('Post não encontrado')),
        ),
      );
    });
  });

  group('ToggleInterest - Self-Interest Prevention', () {
    final tPost = PostEntity(
      id: 'post-1',
      authorProfileId: 'profile-1',
      authorUid: 'user-123',
      content: 'Procurando banda',
      location: const GeoPoint(-23.5505, -46.6333),
      city: 'São Paulo',
      type: 'musician',
      level: 'intermediário',
      instruments: ['Baixo'],
      genres: ['Funk'],
      seekingMusicians: [],
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );

    test('should throw when trying to express interest in own post', () async {
      // given
      const postId = 'post-1';
      const profileId = 'profile-1'; // Same as authorProfileId
      mockRepository.setupPostById(postId, tPost);

      // when & then
      expect(
        () => useCase(postId, profileId),
        throwsA(
          predicate((e) => e.toString().contains(
              'Você não pode demonstrar interesse no seu próprio post')),
        ),
      );
    });
  });

  group('ToggleInterest - Repository Failures', () {
    test('should propagate exception when repository fails', () async {
      // given
      const postId = 'post-1';
      const profileId = 'profile-2';
      final tPost = PostEntity(
        id: 'post-1',
        authorProfileId: 'profile-1',
        authorUid: 'user-123',
        content: 'Procurando banda',
        location: const GeoPoint(-23.5505, -46.6333),
        city: 'Rio de Janeiro',
        type: 'band',
        level: 'profissional',
        instruments: [],
        genres: ['Jazz'],
        seekingMusicians: ['Trompetista'],
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      mockRepository.setupPostById(postId, tPost);
      mockRepository
          .setupToggleInterestFailure('Erro ao salvar interesse no Firestore');

      // when & then
      expect(
        () => useCase(postId, profileId),
        throwsA(
          predicate((e) =>
              e.toString().contains('Erro ao salvar interesse no Firestore')),
        ),
      );
    });
  });
}
