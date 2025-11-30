import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wegig_app/features/profile/domain/usecases/update_profile.dart';

import 'mock_profile_repository.dart';

void main() {
  late UpdateProfileUseCase useCase;
  late MockProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockProfileRepository();
    useCase = UpdateProfileUseCase(mockRepository);
  });

  group('UpdateProfileUseCase - Success Cases', () {
    const tUid = 'user-123';
    final tValidProfile = ProfileEntity(
      profileId: 'profile-1',
      uid: tUid,
      name: 'Updated Band',
      isBand: true,
      location: const GeoPoint(-23.5505, -46.6333),
      city: 'São Paulo',
      createdAt: DateTime.now(),
    );

    test('should update profile when user is owner and data is valid',
        () async {
      // given
      mockRepository.setupOwnership('profile-1', tUid, isOwner: true);

      // when
      final result = await useCase(tValidProfile, tUid);

      // then
      expect(result.profileId, tValidProfile.profileId);
      expect(result.name, tValidProfile.name);
      expect(mockRepository.isProfileOwnerCalled, true);
      expect(mockRepository.lastOwnershipCheckProfileId, 'profile-1');
      expect(mockRepository.lastOwnershipCheckUid, tUid);
    });
  });

  group('UpdateProfileUseCase - Ownership Validation', () {
    const tUid = 'user-123';
    const tOtherUid = 'user-456';
    final tProfile = ProfileEntity(
      profileId: 'profile-1',
      uid: tOtherUid,
      name: 'Someone Elses Band',
      isBand: true,
      location: const GeoPoint(-23.5505, -46.6333),
      city: 'São Paulo',
      createdAt: DateTime.now(),
    );

    test('should throw when user is not the owner', () async {
      // given
      mockRepository.setupOwnership('profile-1', tUid, isOwner: false);

      // when & then
      expect(
        () => useCase(tProfile, tUid),
        throwsA(
          predicate(
            (e) => e
                .toString()
                .contains('Você não tem permissão para editar este perfil'),
          ),
        ),
      );
      expect(mockRepository.isProfileOwnerCalled, true);
    });
  });

  group('UpdateProfileUseCase - Name Validation', () {
    const tUid = 'user-123';

    setUp(() {
      mockRepository.setupOwnership('profile-1', tUid, isOwner: true);
    });

    test('should throw when name is empty', () async {
      // given
      final invalidProfile = ProfileEntity(
        profileId: 'profile-1',
        uid: tUid,
        name: '',
        isBand: true,
        location: const GeoPoint(-23.5505, -46.6333),
        city: 'São Paulo',
        createdAt: DateTime.now(),
      );

      // when & then
      expect(
        () => useCase(invalidProfile, tUid),
        throwsA(
          predicate((e) => e.toString().contains('Nome é obrigatório')),
        ),
      );
    });

    test('should throw when name is only whitespace', () async {
      // given
      final invalidProfile = ProfileEntity(
        profileId: 'profile-1',
        uid: tUid,
        name: '   ',
        isBand: false,
        location: const GeoPoint(-23.5505, -46.6333),
        city: 'São Paulo',
        createdAt: DateTime.now(),
      );

      // when & then
      expect(
        () => useCase(invalidProfile, tUid),
        throwsA(
          predicate((e) => e.toString().contains('Nome é obrigatório')),
        ),
      );
    });

    test('should throw when name is too short (< 2 chars)', () async {
      // given
      final invalidProfile = ProfileEntity(
        profileId: 'profile-1',
        uid: tUid,
        name: 'X',
        isBand: false,
        location: const GeoPoint(-23.5505, -46.6333),
        city: 'São Paulo',
        createdAt: DateTime.now(),
      );

      // when & then
      expect(
        () => useCase(invalidProfile, tUid),
        throwsA(
          predicate((e) => e.toString().contains('pelo menos 2 caracteres')),
        ),
      );
    });

    test('should throw when name is too long (> 50 chars)', () async {
      // given
      final invalidProfile = ProfileEntity(
        profileId: 'profile-1',
        uid: tUid,
        name: 'A' * 51,
        isBand: true,
        location: const GeoPoint(-23.5505, -46.6333),
        city: 'São Paulo',
        createdAt: DateTime.now(),
      );

      // when & then
      expect(
        () => useCase(invalidProfile, tUid),
        throwsA(
          predicate((e) => e.toString().contains('no máximo 50 caracteres')),
        ),
      );
    });

    test('should accept name with exactly 2 chars', () async {
      // given
      final validProfile = ProfileEntity(
        profileId: 'profile-1',
        uid: tUid,
        name: 'AB',
        isBand: false,
        location: const GeoPoint(-23.5505, -46.6333),
        city: 'São Paulo',
        createdAt: DateTime.now(),
      );

      // when
      final result = await useCase(validProfile, tUid);

      // then
      expect(result.name, 'AB');
    });

    test('should accept name with exactly 50 chars', () async {
      // given
      final validProfile = ProfileEntity(
        profileId: 'profile-1',
        uid: tUid,
        name: 'A' * 50,
        isBand: true,
        location: const GeoPoint(-23.5505, -46.6333),
        city: 'São Paulo',
        createdAt: DateTime.now(),
      );

      // when
      final result = await useCase(validProfile, tUid);

      // then
      expect(result.name.length, 50);
    });
  });

  group('UpdateProfileUseCase - Location Validation', () {
    const tUid = 'user-123';

    setUp(() {
      mockRepository.setupOwnership('profile-1', tUid, isOwner: true);
    });

    test('should throw when location is (0,0)', () async {
      // given
      final invalidProfile = ProfileEntity(
        profileId: 'profile-1',
        uid: tUid,
        name: 'Valid Band',
        isBand: true,
        location: const GeoPoint(0, 0),
        city: 'São Paulo',
        createdAt: DateTime.now(),
      );

      // when & then
      expect(
        () => useCase(invalidProfile, tUid),
        throwsA(
          predicate((e) => e.toString().contains('Localização inválida')),
        ),
      );
    });

    test('should accept valid location', () async {
      // given
      final validProfile = ProfileEntity(
        profileId: 'profile-1',
        uid: tUid,
        name: 'Valid Band',
        isBand: true,
        location: const GeoPoint(-23.5505, -46.6333), // São Paulo
        city: 'São Paulo',
        createdAt: DateTime.now(),
      );

      // when
      final result = await useCase(validProfile, tUid);

      // then
      expect(result.location.latitude, -23.5505);
      expect(result.location.longitude, -46.6333);
    });
  });

  group('UpdateProfileUseCase - City Validation', () {
    const tUid = 'user-123';

    setUp(() {
      mockRepository.setupOwnership('profile-1', tUid, isOwner: true);
    });

    test('should throw when city is empty', () async {
      // given
      final invalidProfile = ProfileEntity(
        profileId: 'profile-1',
        uid: tUid,
        name: 'Valid Band',
        isBand: true,
        location: const GeoPoint(-23.5505, -46.6333),
        city: '',
        createdAt: DateTime.now(),
      );

      // when & then
      expect(
        () => useCase(invalidProfile, tUid),
        throwsA(
          predicate((e) => e.toString().contains('Cidade é obrigatória')),
        ),
      );
    });

    test('should throw when city is only whitespace', () async {
      // given
      final invalidProfile = ProfileEntity(
        profileId: 'profile-1',
        uid: tUid,
        name: 'Valid Band',
        isBand: false,
        location: const GeoPoint(-23.5505, -46.6333),
        city: '   ',
        createdAt: DateTime.now(),
      );

      // when & then
      expect(
        () => useCase(invalidProfile, tUid),
        throwsA(
          predicate((e) => e.toString().contains('Cidade é obrigatória')),
        ),
      );
    });
  });
}
