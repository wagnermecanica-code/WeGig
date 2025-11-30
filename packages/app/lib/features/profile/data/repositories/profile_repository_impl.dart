import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:wegig_app/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:wegig_app/features/profile/domain/repositories/profile_repository.dart';

/// ProfileRepositoryImpl - Implementação do ProfileRepository
///
/// Responsabilidades:
/// - Converter exceções do DataSource em erros tratáveis
/// - Integrar com AnalyticsService (TODO: implementar)
/// - Logging para debug
class ProfileRepositoryImpl implements ProfileRepository {
  // TODO: Implementar AnalyticsService
  // final AnalyticsService _analytics;

  ProfileRepositoryImpl({
    required ProfileRemoteDataSource remoteDataSource,
    // AnalyticsService? analytics,
  }) : _remoteDataSource = remoteDataSource;
  final ProfileRemoteDataSource _remoteDataSource;
  // _analytics = analytics ?? AnalyticsService();

  @override
  Future<List<ProfileEntity>> getAllProfiles(String uid) async {
    try {
      debugPrint('🔍 ProfileRepository: getAllProfiles - uid=$uid');

      final profiles = await _remoteDataSource.getAllProfiles(uid);

      debugPrint('✅ ProfileRepository: Retornados ${profiles.length} perfis');
      return profiles;
    } catch (e) {
      debugPrint('❌ ProfileRepository: Erro em getAllProfiles - $e');
      rethrow;
    }
  }

  @override
  Future<ProfileEntity?> getProfileById(String profileId) async {
    try {
      debugPrint('🔍 ProfileRepository: getProfileById - id=$profileId');

      final profile = await _remoteDataSource.getProfileById(profileId);

      if (profile != null) {
        debugPrint('✅ ProfileRepository: Perfil encontrado - ${profile.name}');
      } else {
        debugPrint('⚠️ ProfileRepository: Perfil não encontrado');
      }

      return profile;
    } catch (e) {
      debugPrint('❌ ProfileRepository: Erro em getProfileById - $e');
      rethrow;
    }
  }

  @override
  Future<ProfileEntity> createProfile(ProfileEntity profile) async {
    try {
      debugPrint('📝 ProfileRepository: createProfile - ${profile.name}');

      await _remoteDataSource.createProfile(profile);

      // Analytics
      debugPrint(
          '📊 Analytics: Profile created - ${profile.profileId} (${profile.isBand ? 'band' : 'musician'})');

      debugPrint('✅ ProfileRepository: Perfil criado com sucesso');
      return profile;
    } catch (e) {
      debugPrint('❌ ProfileRepository: Erro em createProfile - $e');
      rethrow;
    }
  }

  @override
  Future<ProfileEntity> updateProfile(ProfileEntity profile) async {
    try {
      debugPrint('📝 ProfileRepository: updateProfile - ${profile.name}');

      await _remoteDataSource.updateProfile(profile);

      // Analytics
      debugPrint('📊 Analytics: Profile updated - ${profile.profileId}');

      debugPrint('✅ ProfileRepository: Perfil atualizado com sucesso');
      return profile;
    } catch (e) {
      debugPrint('❌ ProfileRepository: Erro em updateProfile - $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteProfile(
    String profileId, {
    String? newActiveProfileId,
  }) async {
    try {
      debugPrint('🗑️ ProfileRepository: deleteProfile - id=$profileId');

      // Precisa do uid para transação atômica
      // Assumindo que verificação de ownership já foi feita no UseCase
      // Por isso, vamos buscar o perfil primeiro para pegar o uid
      final profile = await _remoteDataSource.getProfileById(profileId);

      if (profile == null) {
        throw Exception('Perfil não encontrado');
      }

      await _remoteDataSource.deleteProfile(
        profileId,
        profile.uid,
        newActiveProfileId: newActiveProfileId,
      );

      // Analytics
      debugPrint('📊 Analytics: Profile deleted - $profileId');

      debugPrint('✅ ProfileRepository: Perfil deletado com sucesso');
    } catch (e) {
      debugPrint('❌ ProfileRepository: Erro em deleteProfile - $e');
      rethrow;
    }
  }

  @override
  Future<void> switchActiveProfile(String uid, String newProfileId) async {
    try {
      debugPrint(
          '🔄 ProfileRepository: switchActiveProfile - new=$newProfileId');

      await _remoteDataSource.switchActiveProfile(uid, newProfileId);

      // Analytics
      debugPrint('📊 Analytics: Profile switched - $newProfileId');

      debugPrint('✅ ProfileRepository: Perfil ativo alterado');
    } catch (e) {
      debugPrint('❌ ProfileRepository: Erro em switchActiveProfile - $e');
      rethrow;
    }
  }

  @override
  Future<ProfileEntity?> getActiveProfile(String uid) async {
    try {
      debugPrint('🔍 ProfileRepository: getActiveProfile - uid=$uid');

      final profile = await _remoteDataSource.getActiveProfile(uid);

      if (profile != null) {
        debugPrint('✅ ProfileRepository: Perfil ativo - ${profile.name}');
      } else {
        debugPrint('⚠️ ProfileRepository: Nenhum perfil ativo');
      }

      return profile;
    } catch (e) {
      debugPrint('❌ ProfileRepository: Erro em getActiveProfile - $e');
      rethrow;
    }
  }

  @override
  Future<bool> isProfileOwner(String profileId, String uid) async {
    try {
      debugPrint(
          '🔍 ProfileRepository: isProfileOwner - id=$profileId, uid=$uid');

      final isOwner = await _remoteDataSource.isProfileOwner(profileId, uid);

      debugPrint('✅ ProfileRepository: isOwner=$isOwner');
      return isOwner;
    } catch (e) {
      debugPrint('❌ ProfileRepository: Erro em isProfileOwner - $e');
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getProfilesSummary(String uid) async {
    try {
      debugPrint('🔍 ProfileRepository: getProfilesSummary - uid=$uid');

      final profiles = await _remoteDataSource.getAllProfiles(uid);

      final summaries = profiles.map((p) => p.toSummary()).toList();

      debugPrint('✅ ProfileRepository: Retornados ${summaries.length} resumos');
      return summaries;
    } catch (e) {
      debugPrint('❌ ProfileRepository: Erro em getProfilesSummary - $e');
      rethrow;
    }
  }
}
