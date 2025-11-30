import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wegig_app/features/post/domain/usecases/create_post.dart';

import 'mock_post_repository.dart';

void main() {
  late CreatePost useCase;
  late MockPostRepository mockRepository;

  setUp(() {
    mockRepository = MockPostRepository();
    useCase = CreatePost(mockRepository);
  });

  group('CreatePost - Success Cases', () {
    final tValidPost = PostEntity(
      id: 'post-1',
      authorProfileId: 'profile-1',
      authorUid: 'user-123',
      content: 'Procurando guitarrista para banda de rock',
      location: const GeoPoint(-23.5505, -46.6333),
      city: 'São Paulo',
      type: 'band',
      level: 'intermediário',
      instruments: ['Guitarra', 'Baixo'],
      genres: ['Rock', 'Metal'],
      seekingMusicians: ['Guitarrista'],
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );

    test('should create post when all data is valid', () async {
      // given
      mockRepository.setupCreateResponse(tValidPost);

      // when
      final result = await useCase(tValidPost);

      // then
      expect(result.id, tValidPost.id);
      expect(result.content, tValidPost.content);
      expect(mockRepository.createPostCalled, true);
    });
  });

  group('CreatePost - Content Validation', () {
    test('should throw when content is empty', () async {
      // given
      final invalidPost = PostEntity(
        id: 'post-1',
        authorProfileId: 'profile-1',
        authorUid: 'user-123',
        content: '',
        location: const GeoPoint(-23.5505, -46.6333),
        city: 'São Paulo',
        type: 'musician',
        level: 'avançado',
        instruments: ['Bateria'],
        genres: ['Jazz'],
        seekingMusicians: [],
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      // when & then
      expect(
        () => useCase(invalidPost),
        throwsA(
          predicate((e) => e.toString().contains('Conteúdo é obrigatório')),
        ),
      );
    });

    test('should throw when content is only whitespace', () async {
      // given
      final invalidPost = PostEntity(
        id: 'post-1',
        authorProfileId: 'profile-1',
        authorUid: 'user-123',
        content: '   ',
        location: const GeoPoint(-23.5505, -46.6333),
        city: 'São Paulo',
        type: 'musician',
        level: 'iniciante',
        instruments: ['Violão'],
        genres: ['MPB'],
        seekingMusicians: [],
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      // when & then
      expect(
        () => useCase(invalidPost),
        throwsA(
          predicate((e) => e.toString().contains('Conteúdo é obrigatório')),
        ),
      );
    });

    test('should throw when content is too long (> 500 chars)', () async {
      // given
      final invalidPost = PostEntity(
        id: 'post-1',
        authorProfileId: 'profile-1',
        authorUid: 'user-123',
        content: 'A' * 501,
        location: const GeoPoint(-23.5505, -46.6333),
        city: 'São Paulo',
        type: 'band',
        level: 'profissional',
        instruments: ['Guitarra'],
        genres: ['Rock'],
        seekingMusicians: [],
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      // when & then
      expect(
        () => useCase(invalidPost),
        throwsA(
          predicate((e) => e.toString().contains('no máximo 500 caracteres')),
        ),
      );
    });

    test('should accept content with exactly 500 chars', () async {
      // given
      final validPost = PostEntity(
        id: 'post-1',
        authorProfileId: 'profile-1',
        authorUid: 'user-123',
        content: 'A' * 500,
        location: const GeoPoint(-23.5505, -46.6333),
        city: 'São Paulo',
        type: 'musician',
        level: 'intermediário',
        instruments: ['Piano'],
        genres: ['Clássica'],
        seekingMusicians: [],
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      mockRepository.setupCreateResponse(validPost);

      // when
      final result = await useCase(validPost);

      // then
      expect(result.content.length, 500);
    });
  });

  group('CreatePost - City Validation', () {
    test('should throw when city is empty', () async {
      // given
      final invalidPost = PostEntity(
        id: 'post-1',
        authorProfileId: 'profile-1',
        authorUid: 'user-123',
        content: 'Procurando banda',
        location: const GeoPoint(-23.5505, -46.6333),
        city: '',
        type: 'musician',
        level: 'intermediário',
        instruments: ['Voz'],
        genres: ['Pop'],
        seekingMusicians: [],
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      // when & then
      expect(
        () => useCase(invalidPost),
        throwsA(
          predicate((e) => e.toString().contains('Cidade é obrigatória')),
        ),
      );
    });

    test('should throw when city is only whitespace', () async {
      // given
      final invalidPost = PostEntity(
        id: 'post-1',
        authorProfileId: 'profile-1',
        authorUid: 'user-123',
        content: 'Procurando banda',
        location: const GeoPoint(-23.5505, -46.6333),
        city: '   ',
        type: 'musician',
        level: 'avançado',
        instruments: ['Saxofone'],
        genres: ['Jazz'],
        seekingMusicians: [],
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      // when & then
      expect(
        () => useCase(invalidPost),
        throwsA(
          predicate((e) => e.toString().contains('Cidade é obrigatória')),
        ),
      );
    });
  });

  group('CreatePost - Location Validation', () {
    test('should throw when location is (0,0)', () async {
      // given
      final invalidPost = PostEntity(
        id: 'post-1',
        authorProfileId: 'profile-1',
        authorUid: 'user-123',
        content: 'Procurando banda de rock',
        location: const GeoPoint(0, 0),
        city: 'São Paulo',
        type: 'musician',
        level: 'profissional',
        instruments: ['Guitarra'],
        genres: ['Rock'],
        seekingMusicians: [],
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      // when & then
      expect(
        () => useCase(invalidPost),
        throwsA(
          predicate((e) => e.toString().contains('Localização é obrigatória')),
        ),
      );
    });
  });

  group('CreatePost - Instruments Validation', () {
    test('should throw when musician has no instruments', () async {
      // given
      final invalidPost = PostEntity(
        id: 'post-1',
        authorProfileId: 'profile-1',
        authorUid: 'user-123',
        content: 'Músico procurando banda',
        location: const GeoPoint(-23.5505, -46.6333),
        city: 'São Paulo',
        type: 'musician',
        level: 'intermediário',
        instruments: [],
        genres: ['Rock'],
        seekingMusicians: [],
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      // when & then
      expect(
        () => useCase(invalidPost),
        throwsA(
          predicate((e) =>
              e.toString().contains('Selecione pelo menos um instrumento')),
        ),
      );
    });

    test('should allow band with no instruments', () async {
      // given
      final validPost = PostEntity(
        id: 'post-1',
        authorProfileId: 'profile-1',
        authorUid: 'user-123',
        content: 'Banda procurando músicos',
        location: const GeoPoint(-23.5505, -46.6333),
        city: 'São Paulo',
        type: 'band',
        level: 'profissional',
        instruments: [],
        genres: ['Rock'],
        seekingMusicians: ['Guitarrista'],
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      mockRepository.setupCreateResponse(validPost);

      // when
      final result = await useCase(validPost);

      // then
      expect(result.instruments, isEmpty);
    });
  });

  group('CreatePost - Genres Validation', () {
    test('should throw when genres list is empty', () async {
      // given
      final invalidPost = PostEntity(
        id: 'post-1',
        authorProfileId: 'profile-1',
        authorUid: 'user-123',
        content: 'Procurando banda',
        location: const GeoPoint(-23.5505, -46.6333),
        city: 'São Paulo',
        type: 'musician',
        level: 'iniciante',
        instruments: ['Bateria'],
        genres: [],
        seekingMusicians: [],
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      // when & then
      expect(
        () => useCase(invalidPost),
        throwsA(
          predicate((e) =>
              e.toString().contains('Selecione pelo menos um gênero musical')),
        ),
      );
    });
  });

  group('CreatePost - Level Validation', () {
    test('should throw when level is empty', () async {
      // given
      final invalidPost = PostEntity(
        id: 'post-1',
        authorProfileId: 'profile-1',
        authorUid: 'user-123',
        content: 'Procurando banda',
        location: const GeoPoint(-23.5505, -46.6333),
        city: 'São Paulo',
        type: 'musician',
        level: '',
        instruments: ['Baixo'],
        genres: ['Funk'],
        seekingMusicians: [],
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      // when & then
      expect(
        () => useCase(invalidPost),
        throwsA(
          predicate(
              (e) => e.toString().contains('Selecione o nível de experiência')),
        ),
      );
    });

    test('should throw when level is only whitespace', () async {
      // given
      final invalidPost = PostEntity(
        id: 'post-1',
        authorProfileId: 'profile-1',
        authorUid: 'user-123',
        content: 'Procurando banda',
        location: const GeoPoint(-23.5505, -46.6333),
        city: 'São Paulo',
        type: 'band',
        level: '   ',
        instruments: ['Teclado'],
        genres: ['Eletrônica'],
        seekingMusicians: [],
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      // when & then
      expect(
        () => useCase(invalidPost),
        throwsA(
          predicate(
              (e) => e.toString().contains('Selecione o nível de experiência')),
        ),
      );
    });
  });

  group('CreatePost - YouTube Link Validation', () {
    test('should throw when YouTube link is invalid', () async {
      // given
      final invalidPost = PostEntity(
        id: 'post-1',
        authorProfileId: 'profile-1',
        authorUid: 'user-123',
        content: 'Procurando banda',
        location: const GeoPoint(-23.5505, -46.6333),
        city: 'São Paulo',
        type: 'musician',
        level: 'avançado',
        instruments: ['Guitarra'],
        genres: ['Rock'],
        seekingMusicians: [],
        youtubeLink: 'https://vimeo.com/123456',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

      // when & then
      expect(
        () => useCase(invalidPost),
        throwsA(
          predicate((e) => e.toString().contains('Link do YouTube inválido')),
        ),
      );
    });

    test('should accept valid youtube.com link', () async {
      // given
      final validPost = PostEntity(
        id: 'post-1',
        authorProfileId: 'profile-1',
        authorUid: 'user-123',
        content: 'Procurando banda',
        location: const GeoPoint(-23.5505, -46.6333),
        city: 'São Paulo',
        type: 'musician',
        level: 'profissional',
        instruments: ['Voz'],
        genres: ['Pop'],
        seekingMusicians: [],
        youtubeLink: 'https://www.youtube.com/watch?v=abc123',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      mockRepository.setupCreateResponse(validPost);

      // when
      final result = await useCase(validPost);

      // then
      expect(result.youtubeLink, validPost.youtubeLink);
    });

    test('should accept valid youtu.be link', () async {
      // given
      final validPost = PostEntity(
        id: 'post-1',
        authorProfileId: 'profile-1',
        authorUid: 'user-123',
        content: 'Procurando banda',
        location: const GeoPoint(-23.5505, -46.6333),
        city: 'São Paulo',
        type: 'musician',
        level: 'intermediário',
        instruments: ['Violino'],
        genres: ['Clássica'],
        seekingMusicians: [],
        youtubeLink: 'https://youtu.be/abc123',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      mockRepository.setupCreateResponse(validPost);

      // when
      final result = await useCase(validPost);

      // then
      expect(result.youtubeLink, validPost.youtubeLink);
    });

    test('should accept post without YouTube link', () async {
      // given
      final validPost = PostEntity(
        id: 'post-1',
        authorProfileId: 'profile-1',
        authorUid: 'user-123',
        content: 'Procurando banda',
        location: const GeoPoint(-23.5505, -46.6333),
        city: 'São Paulo',
        type: 'band',
        level: 'iniciante',
        instruments: [],
        genres: ['Samba'],
        seekingMusicians: ['Cavaquinista'],
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      mockRepository.setupCreateResponse(validPost);

      // when
      final result = await useCase(validPost);

      // then
      expect(result.youtubeLink, isNull);
    });
  });
}
