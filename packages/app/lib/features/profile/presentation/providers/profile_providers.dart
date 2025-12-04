import 'dart:async';

import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:core_ui/profile_result.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wegig_app/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:wegig_app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:wegig_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:wegig_app/features/profile/domain/usecases/create_profile.dart';
import 'package:wegig_app/features/profile/domain/usecases/delete_profile.dart';
import 'package:wegig_app/features/profile/domain/usecases/get_active_profile.dart';
import 'package:wegig_app/features/profile/domain/usecases/load_all_profiles.dart';
import 'package:wegig_app/features/profile/domain/usecases/switch_active_profile.dart';
import 'package:wegig_app/features/profile/domain/usecases/update_profile.dart';

part 'profile_providers.freezed.dart';
part 'profile_providers.g.dart';

/// ============================================
/// DATA LAYER - Dependency Injection
/// ============================================

/// Provider para ProfileRemoteDataSource (singleton)
@riverpod
ProfileRemoteDataSource profileRemoteDataSource(Ref ref) {
  return ProfileRemoteDataSourceImpl();
}

/// Provider para FirebaseAuth (facilita override em testes)
final profileFirebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

/// Provider para ProfileRepository (singleton)
@riverpod
ProfileRepository profileRepositoryNew(Ref ref) {
  final dataSource = ref.watch(profileRemoteDataSourceProvider);
  return ProfileRepositoryImpl(remoteDataSource: dataSource);
}

/// ============================================
/// DOMAIN LAYER - UseCases
/// ============================================

@riverpod
CreateProfileUseCase createProfileUseCase(Ref ref) {
  final repository = ref.watch(profileRepositoryNewProvider);
  return CreateProfileUseCase(repository);
}

@riverpod
UpdateProfileUseCase updateProfileUseCase(Ref ref) {
  final repository = ref.watch(profileRepositoryNewProvider);
  return UpdateProfileUseCase(repository);
}

@riverpod
SwitchActiveProfileUseCase switchActiveProfileUseCase(Ref ref) {
  final repository = ref.watch(profileRepositoryNewProvider);
  return SwitchActiveProfileUseCase(repository);
}

@riverpod
DeleteProfileUseCase deleteProfileUseCase(Ref ref) {
  final repository = ref.watch(profileRepositoryNewProvider);
  return DeleteProfileUseCase(repository);
}

@riverpod
LoadAllProfilesUseCase loadAllProfilesUseCase(Ref ref) {
  final repository = ref.watch(profileRepositoryNewProvider);
  return LoadAllProfilesUseCase(repository);
}

@riverpod
GetActiveProfileUseCase getActiveProfileUseCase(Ref ref) {
  final repository = ref.watch(profileRepositoryNewProvider);
  return GetActiveProfileUseCase(repository);
}

/// ============================================
/// PRESENTATION LAYER - State Management
/// ============================================

/// State do perfil (migrado para ProfileEntity + Freezed)
@freezed
class ProfileState with _$ProfileState {
  const factory ProfileState({
    ProfileEntity? activeProfile,
    @Default([]) List<ProfileEntity> profiles,
    @Default(false) bool isLoading,
    String? error,
  }) = _ProfileState;
}

/// ProfileNotifier - Gerencia estado global de perfis (Riverpod 2.x AutoDisposeAsyncNotifier)
class ProfileNotifier extends AutoDisposeAsyncNotifier<ProfileState> {
  /// Stream para observar mudanças no perfil ativo
  Stream<ProfileState> get stream => _streamController.stream;

  final StreamController<ProfileState> _streamController =
      StreamController.broadcast();

  @override
  set state(AsyncValue<ProfileState> value) {
    super.state = value;
    if (value is AsyncData<ProfileState> && !_streamController.isClosed) {
      _streamController.add(value.value);  // ✅ Check if closed before adding
    }
  }

  @override
  FutureOr<ProfileState> build() async {
    // Registra dispose para cleanup (com verificação)
    ref.onDispose(() {
      if (!_streamController.isClosed) {
        _streamController.close();  // ✅ Only close if not already closed
      }
    });

    return _loadProfiles();
  }

  Future<ProfileState> _loadProfiles() async {
    try {
      debugPrint('🔄 ProfileNotifier: Carregando perfis...');

      final uid = ref.read(profileFirebaseAuthProvider).currentUser?.uid;
      if (uid == null) {
        debugPrint('⚠️ ProfileNotifier: Usuário não autenticado');
        return ProfileState();
      }

      final loadAllProfiles = ref.read(loadAllProfilesUseCaseProvider);
      final getActiveProfile = ref.read(getActiveProfileUseCaseProvider);

      final profiles = await loadAllProfiles(uid);
      final activeProfile = await getActiveProfile(uid);

      debugPrint(
          '✅ ProfileNotifier: ${profiles.length} perfis carregados, ativo: ${activeProfile?.name ?? "nenhum"}');

      return ProfileState(
        activeProfile: activeProfile,
        profiles: profiles,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ ProfileNotifier: Erro ao carregar - $e');
      debugPrint(stackTrace.toString());
      return ProfileState(
        error: e.toString(),
      );
    }
  }

  Future<void> switchProfile(String profileId) async {
    try {
      final uid = ref.read(profileFirebaseAuthProvider).currentUser?.uid;
      if (uid == null) throw Exception('Usuário não autenticado');

      final switchUseCase = ref.read(switchActiveProfileUseCaseProvider);
      await switchUseCase(uid, profileId);

      state = AsyncValue.data(await _loadProfiles());
    } catch (e) {
      debugPrint('❌ ProfileNotifier: Erro ao trocar perfil - $e');
      rethrow;
    }
  }

  Future<ProfileResult> createProfile(ProfileEntity profile) async {
    try {
      final uid = ref.read(profileFirebaseAuthProvider).currentUser?.uid;
      if (uid == null) {
        return const ProfileFailure(message: 'Usuário não autenticado');
      }

      final createUseCase =
          ref.read(createProfileUseCaseProvider);
      await createUseCase(profile, uid);

      state = AsyncValue.data(await _loadProfiles());
      return ProfileSuccess(profile: profile);
    } catch (e) {
      debugPrint('❌ ProfileNotifier: Erro ao criar perfil - $e');
      return ProfileFailure(
        message: 'Erro ao criar perfil: $e',
        exception: e is Exception ? e : null,
      );
    }
  }

  Future<ProfileResult> updateProfile(ProfileEntity profile) async {
    try {
      final uid = ref.read(profileFirebaseAuthProvider).currentUser?.uid;
      if (uid == null) {
        return const ProfileFailure(message: 'Usuário não autenticado');
      }

      final updateUseCase =
          ref.read(updateProfileUseCaseProvider);
      await updateUseCase(profile, uid);

      state = AsyncValue.data(await _loadProfiles());
      return ProfileSuccess(profile: profile);
    } catch (e) {
      debugPrint('❌ ProfileNotifier: Erro ao atualizar perfil - $e');
      return ProfileFailure(
        message: 'Erro ao atualizar perfil: $e',
        exception: e is Exception ? e : null,
      );
    }
  }

  Future<void> deleteProfile(String profileId) async {
    try {
      final uid = ref.read(profileFirebaseAuthProvider).currentUser?.uid;
      if (uid == null) throw Exception('Usuário não autenticado');

      final deleteUseCase = ref.read(deleteProfileUseCaseProvider);
      await deleteUseCase(profileId, uid);

      state = AsyncValue.data(await _loadProfiles());
    } catch (e) {
      debugPrint('❌ ProfileNotifier: Erro ao deletar perfil - $e');
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = AsyncValue.data(await _loadProfiles());
  }
}

/// ============================================
/// GLOBAL PROVIDERS - Mantidos para compatibilidade
/// ============================================

/// Provider para perfil ativo atual (null-safe)
@riverpod
ProfileEntity? activeProfile(Ref ref) {
  final profileState = ref.watch(profileProvider);
  return profileState.maybeWhen(
    data: (ProfileState state) => state.activeProfile,
    orElse: () => null,
  );
}

/// Provider para lista de perfis
@riverpod
List<ProfileEntity> profileList(Ref ref) {
  final profileState = ref.watch(profileProvider);
  return profileState.maybeWhen(
    data: (ProfileState state) => state.profiles,
    orElse: () => <ProfileEntity>[],
  );
}

/// Provider para verificar se tem múltiplos perfis
@riverpod
bool hasMultipleProfiles(Ref ref) {
  final profiles = ref.watch(profileListProvider);
  return profiles.length > 1;
}

/// Provider para stream de mudanças de perfil
@riverpod
Stream<ProfileState> profileStream(Ref ref) {
  final notifier = ref.watch(profileProvider.notifier);
  return notifier.stream;
}

/// ============================================
/// MANUAL PROVIDERS (Riverpod 2.x compatibility)
/// ============================================

/// Provider para ProfileNotifier (manual - Riverpod 2.x não suporta @riverpod class)
final profileProvider =
    AutoDisposeAsyncNotifierProvider<ProfileNotifier, ProfileState>(
  ProfileNotifier.new,
);
