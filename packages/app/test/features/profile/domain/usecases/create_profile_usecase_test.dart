import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wegig_app/features/profile/domain/usecases/create_profile.dart';

import 'mock_profile_repository.dart';

void main() {
  late CreateProfileUseCase useCase;
  late MockProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockProfileRepository();
    useCase = CreateProfileUseCase(mockRepository);
  });

  group('CreateProfileUseCase - Validations', () {
    const tUid = 'user-123';
    final tValidProfile = ProfileEntity(
      profileId: 'profile-1',
      uid: tUid,
      name: 'Test Band',
      isBand: true,
      location: const GeoPoint(-23.5505, -46.6333), // São Paulo
      city: 'São Paulo',
      createdAt: DateTime.now(),
    );

    test('should create profile when data is valid', () async {
      // Arrange
      mockRepository.setupExistingProfiles([]); // Nenhum perfil existente
      mockRepository.setupCreateResponse(tValidProfile);

      // Act
      final result = await useCase(tValidProfile, tUid);

      // Assert
      expect(result.profileId, tValidProfile.profileId);
      expect(result.name, tValidProfile.name);
      expect(mockRepository.createProfileCalled, true);
    });

    test('should throw when profile limit exceeded (5 profiles)', () async {
      // Arrange
      final existingProfiles = List.generate(
        5,
        (i) => ProfileEntity(
          profileId: 'profile-$i',
          uid: tUid,
          name: 'Profile $i',
          isBand: false,
          location: const GeoPoint(-23.5505, -46.6333),
          city: 'São Paulo',
          createdAt: DateTime.now(),
        ),
      );
      mockRepository.setupExistingProfiles(existingProfiles);

      // Act & Assert
      expect(
        () => useCase(tValidProfile, tUid),
        throwsA(
          predicate(
              (e) => e.toString().contains('Limite de 5 perfis atingido')),
        ),
      );
    });

    test('should throw when name is empty', () async {
      // Arrange
      mockRepository.setupExistingProfiles([]);
      final invalidProfile = ProfileEntity(
        profileId: 'profile-1',
        uid: tUid,
        name: '',
        isBand: true,
        location: const GeoPoint(-23.5505, -46.6333),
        city: 'São Paulo',
        createdAt: DateTime.now(),
      );

      // Act & Assert
      expect(
        () => useCase(invalidProfile, tUid),
        throwsA(
          predicate((e) => e.toString().contains('Nome é obrigatório')),
        ),
      );
    });

    test('should throw when name is too short (< 2 chars)', () async {
      // Arrange
      mockRepository.setupExistingProfiles([]);
      final invalidProfile = ProfileEntity(
        profileId: 'profile-1',
        uid: tUid,
        name: 'A',
        isBand: true,
        location: const GeoPoint(-23.5505, -46.6333),
        city: 'São Paulo',
        createdAt: DateTime.now(),
      );

      // Act & Assert
      expect(
        () => useCase(invalidProfile, tUid),
        throwsA(
          predicate((e) => e.toString().contains('pelo menos 2 caracteres')),
        ),
      );
    });

    test('should throw when name is too long (> 50 chars)', () async {
      // Arrange
      mockRepository.setupExistingProfiles([]);
      final invalidProfile = ProfileEntity(
        profileId: 'profile-1',
        uid: tUid,
        name: 'A' * 51,
        isBand: true,
        location: const GeoPoint(-23.5505, -46.6333),
        city: 'São Paulo',
        createdAt: DateTime.now(),
      );

      // Act & Assert
      expect(
        () => useCase(invalidProfile, tUid),
        throwsA(
          predicate((e) => e.toString().contains('no máximo 50 caracteres')),
        ),
      );
    });

    test('should throw when location is invalid (0,0)', () async {
      // Arrange
      mockRepository.setupExistingProfiles([]);
      final invalidProfile = ProfileEntity(
        profileId: 'profile-1',
        uid: tUid,
        name: 'Test Band',
        isBand: true,
        location: const GeoPoint(0, 0),
        city: 'São Paulo',
        createdAt: DateTime.now(),
      );

      // Act & Assert
      expect(
        () => useCase(invalidProfile, tUid),
        throwsA(
          predicate((e) => e.toString().contains('Localização inválida')),
        ),
      );
    });

    test('should throw when city is empty', () async {
      // Arrange
      mockRepository.setupExistingProfiles([]);
      final invalidProfile = ProfileEntity(
        profileId: 'profile-1',
        uid: tUid,
        name: 'Test Band',
        isBand: true,
        location: const GeoPoint(-23.5505, -46.6333),
        city: '',
        createdAt: DateTime.now(),
      );

      // Act & Assert
      expect(
        () => useCase(invalidProfile, tUid),
        throwsA(
          predicate((e) => e.toString().contains('Cidade é obrigatória')),
        ),
      );
    });
  });
}
