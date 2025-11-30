import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wegig_app/features/profile/domain/usecases/switch_active_profile.dart';

import 'mock_profile_repository.dart';

void main() {
  late SwitchActiveProfileUseCase useCase;
  late MockProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockProfileRepository();
    useCase = SwitchActiveProfileUseCase(mockRepository);
  });

  group('SwitchActiveProfileUseCase - Validations', () {
    const tUid = 'user-123';
    const tProfileId = 'profile-1';
    final tProfile = ProfileEntity(
      profileId: tProfileId,
      uid: tUid,
      name: 'Test Profile',
      isBand: false,
      location: const GeoPoint(-23.5505, -46.6333),
      city: 'São Paulo',
      createdAt: DateTime.now(),
    );

    test('should switch active profile when profile exists and user is owner',
        () async {
      // Arrange
      mockRepository.setupProfileById(tProfileId, tProfile);
      mockRepository.setupOwnership(tProfileId, tUid, isOwner: true);

      // Act
      await useCase(tUid, tProfileId);

      // Assert
      expect(mockRepository.switchActiveProfileCalled, true);
      expect(mockRepository.lastSwitchedUid, tUid);
      expect(mockRepository.lastSwitchedProfileId, tProfileId);
    });

    test('should throw when profile does not exist', () async {
      // Arrange
      mockRepository.setupProfileById(tProfileId, null); // Profile não existe

      // Act & Assert
      expect(
        () => useCase(tUid, tProfileId),
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
        () => useCase(tUid, tProfileId),
        throwsA(
          predicate((e) => e.toString().contains('não tem permissão')),
        ),
      );
    });

    test('should validate ownership before switching', () async {
      // Arrange
      mockRepository.setupProfileById(tProfileId, tProfile);
      mockRepository.setupOwnership(tProfileId, tUid, isOwner: true);

      // Act
      await useCase(tUid, tProfileId);

      // Assert
      expect(mockRepository.isProfileOwnerCalled, true);
      expect(mockRepository.lastOwnershipCheckProfileId, tProfileId);
      expect(mockRepository.lastOwnershipCheckUid, tUid);
    });
  });
}
