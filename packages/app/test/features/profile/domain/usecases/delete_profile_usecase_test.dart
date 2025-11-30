import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wegig_app/features/profile/domain/usecases/delete_profile.dart';

import 'mock_profile_repository.dart';

void main() {
  late DeleteProfileUseCase useCase;
  late MockProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockProfileRepository();
    useCase = DeleteProfileUseCase(mockRepository);
  });

  group('DeleteProfileUseCase - Validations', () {
    const tUid = 'user-123';
    const tProfileId = 'profile-1';
    const tNewActiveProfileId = 'profile-2';

    final tProfile = ProfileEntity(
      profileId: tProfileId,
      uid: tUid,
      name: 'Profile to Delete',
      isBand: false,
      location: const GeoPoint(-23.5505, -46.6333),
      city: 'São Paulo',
      createdAt: DateTime.now(),
    );

    final tOtherProfile = ProfileEntity(
      profileId: tNewActiveProfileId,
      uid: tUid,
      name: 'Other Profile',
      isBand: true,
      location: const GeoPoint(-23.5505, -46.6333),
      city: 'São Paulo',
      createdAt: DateTime.now(),
    );

    test('should delete profile when user is owner and has other profiles',
        () async {
      // Arrange
      mockRepository.setupProfileById(tProfileId, tProfile);
      mockRepository.setupOwnership(tProfileId, tUid, isOwner: true);
      mockRepository
          .setupExistingProfiles([tProfile, tOtherProfile]); // 2 perfis
      mockRepository
          .setupActiveProfile(tOtherProfile); // Outro perfil é o ativo

      // Act
      await useCase(tProfileId, tUid);

      // Assert
      expect(mockRepository.deleteProfileCalled, true);
      expect(mockRepository.lastDeletedProfileId, tProfileId);
    });

    test('should throw when profile does not exist', () async {
      // Arrange
      mockRepository.setupProfileById(tProfileId, null); // Profile não existe

      // Act & Assert
      expect(
        () => useCase(tProfileId, tUid),
        throwsA(
          predicate((e) => e.toString().contains('Perfil não encontrado')),
        ),
      );
    });

    test('should throw when user is not the owner', () async {
      // Arrange
      mockRepository.setupProfileById(tProfileId, tProfile);
      mockRepository.setupOwnership(tProfileId, tUid,
          isOwner: false); // Não é dono

      // Act & Assert
      expect(
        () => useCase(tProfileId, tUid),
        throwsA(
          predicate((e) => e.toString().contains('não tem permissão')),
        ),
      );
    });

    test('should throw when trying to delete last profile', () async {
      // Arrange
      mockRepository.setupProfileById(tProfileId, tProfile);
      mockRepository.setupOwnership(tProfileId, tUid, isOwner: true);
      mockRepository.setupExistingProfiles([tProfile]); // Apenas 1 perfil

      // Act & Assert
      expect(
        () => useCase(tProfileId, tUid),
        throwsA(
          predicate((e) => e.toString().contains('pelo menos um perfil')),
        ),
      );
    });

    test('should throw when deleting active profile without newActiveProfileId',
        () async {
      // Arrange
      mockRepository.setupProfileById(tProfileId, tProfile);
      mockRepository.setupOwnership(tProfileId, tUid, isOwner: true);
      mockRepository.setupExistingProfiles([tProfile, tOtherProfile]);
      mockRepository.setupActiveProfile(tProfile); // Este é o ativo

      // Act & Assert
      expect(
        () => useCase(tProfileId, tUid),
        throwsA(
          predicate((e) => e.toString().contains('Selecione outro perfil')),
        ),
      );
    });

    test('should delete active profile when newActiveProfileId is provided',
        () async {
      // Arrange
      mockRepository.setupProfileById(tProfileId, tProfile);
      mockRepository.setupOwnership(tProfileId, tUid, isOwner: true);
      mockRepository.setupExistingProfiles([tProfile, tOtherProfile]);
      mockRepository.setupActiveProfile(tProfile); // Este é o ativo

      // Act
      await useCase(
        tProfileId,
        tUid,
        newActiveProfileId: tNewActiveProfileId,
      );

      // Assert
      expect(mockRepository.deleteProfileCalled, true);
      expect(mockRepository.lastDeletedProfileId, tProfileId);
      expect(mockRepository.lastDeletedNewActiveProfileId, tNewActiveProfileId);
    });
  });
}
