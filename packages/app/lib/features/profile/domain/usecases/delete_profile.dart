import 'package:wegig_app/features/profile/domain/repositories/profile_repository.dart';

/// UseCase: Deletar perfil
///
/// Validações:
/// - Perfil existe
/// - Usuário é dono do perfil
/// - Se deletar perfil ativo, exigir newActiveProfileId (exceto se forceDelete)
/// - Não pode deletar último perfil (exceto se forceDelete para exclusão de conta)
class DeleteProfileUseCase {
  DeleteProfileUseCase(this._repository);
  final ProfileRepository _repository;

  Future<void> call(
    String profileId,
    String uid, {
    String? newActiveProfileId,
    bool forceDelete = false, // ✅ Permite deletar último perfil (para exclusão de conta)
  }) async {
    // Validação 1: Perfil existe
    final profile = await _repository.getProfileById(profileId);
    if (profile == null) {
      throw Exception('Perfil não encontrado');
    }

    // Validação 2: Ownership
    final isOwner = await _repository.isProfileOwner(profileId, uid);
    if (!isOwner) {
      throw Exception('Você não tem permissão para deletar este perfil');
    }

    // Validação 3: Não pode deletar último perfil (exceto se forceDelete)
    if (!forceDelete) {
      final allProfiles = await _repository.getAllProfiles(uid);
      if (allProfiles.length <= 1) {
        throw Exception('Você precisa ter pelo menos um perfil');
      }
    }

    // Validação 4: Se deletar perfil ativo, exigir newActiveProfileId (exceto se forceDelete)
    if (!forceDelete) {
      final activeProfile = await _repository.getActiveProfile(uid);
      if (activeProfile?.profileId == profileId && newActiveProfileId == null) {
        throw Exception('Selecione outro perfil antes de deletar o ativo');
      }
    }

    // Delete
    await _repository.deleteProfile(
      profileId,
      newActiveProfileId: newActiveProfileId,
    );
  }
}
