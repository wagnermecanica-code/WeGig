import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:core_ui/profile_result.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wegig_app/core/firebase/blocked_relations.dart';
import 'package:wegig_app/features/notifications_new/data/services/push_notification_service.dart';
import 'package:core_ui/utils/objectionable_content_filter.dart';
import 'package:wegig_app/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:wegig_app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:wegig_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:wegig_app/features/profile/domain/usecases/create_profile.dart';
import 'package:wegig_app/features/profile/domain/usecases/delete_profile.dart';
import 'package:wegig_app/features/profile/domain/usecases/get_active_profile.dart';
import 'package:wegig_app/features/profile/domain/usecases/load_all_profiles.dart';
import 'package:wegig_app/features/profile/domain/usecases/switch_active_profile.dart';
import 'package:wegig_app/features/profile/domain/usecases/update_profile.dart';
import 'package:wegig_app/features/auth/presentation/providers/auth_providers.dart';

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
  bool _retryScheduled = false;
  bool _isDisposed = false;

  @override
  set state(AsyncValue<ProfileState> value) {
    super.state = value;
    if (value is AsyncData<ProfileState> && !_streamController.isClosed) {
      _streamController.add(value.value);  // ✅ Check if closed before adding
    }
  }

  @override
  FutureOr<ProfileState> build() async {
    // ✅ IMPORTANT: react to auth user changes (login/logout/account switch)
    // This prevents leaking profile state (activeProfile/profileUid/profileId) between users.
    // Also distinguish cold-start auth bootstrap (auth loading) from an actual logged-out state.
    final authState = ref.watch(authStateProvider);
    final uid = authState.valueOrNull?.uid;

    // Registra dispose para cleanup (com verificação)
    ref.onDispose(() {
      _isDisposed = true;
      if (!_streamController.isClosed) {
        _streamController.close();  // ✅ Only close if not already closed
      }
    });

    if (authState.isLoading) {
      debugPrint('⏳ ProfileNotifier: Auth carregando (cold start)');
      return const ProfileState(isLoading: true);
    }

    if (uid == null) {
      debugPrint('⚠️ ProfileNotifier: Usuário não autenticado (build)');
      return const ProfileState();
    }

    return _loadProfiles(uid);
  }

  Future<ProfileState> _loadProfiles(String uid) async {
    try {
      debugPrint('🔄 ProfileNotifier: Carregando perfis...');

      final loadAllProfiles = ref.read(loadAllProfilesUseCaseProvider);
      final getActiveProfile = ref.read(getActiveProfileUseCaseProvider);

      final profiles = await loadAllProfiles(uid);
      ProfileEntity? activeProfile = await getActiveProfile(uid);

      // Compat: contas legadas podem ter perfis mas não ter users/{uid}.activeProfileId.
      // Nesse caso, escolher um perfil padrão e persistir (best-effort) para estabilizar o login.
      if (activeProfile == null && profiles.isNotEmpty) {
        activeProfile = profiles.first;
        Future.microtask(() async {
          try {
            await FirebaseFirestore.instance.collection('users').doc(uid).set(
              {
                'activeProfileId': activeProfile!.profileId,
              },
              SetOptions(merge: true),
            );
            debugPrint('🧩 ProfileNotifier: activeProfileId ausente, definido para ${activeProfile!.profileId}');
          } catch (e) {
            debugPrint('⚠️ ProfileNotifier: Falha ao definir activeProfileId (non-critical): $e');
          }
        });
      }

      debugPrint(
          '✅ ProfileNotifier: ${profiles.length} perfis carregados, ativo: ${activeProfile?.name ?? "nenhum"}');

      // CRITICAL: Analytics - Track active profile para segmentação
      if (activeProfile != null) {
        _setAnalyticsProfile(activeProfile.profileId);
      }
      
      // CRITICAL: Salvar token FCM em TODOS os perfis do usuário
      // Isso garante que push notifications cheguem independente do perfil ativo
      if (profiles.isNotEmpty) {
        _saveFcmTokenForAllProfiles(
          profiles.map((p) => p.profileId).toList(),
          expectedUid: uid,
        );
      }
      
      // BEST-EFFORT: Reparar edges de bloqueio antigos que não têm blockedUid.
      // Executa em background sem bloquear o carregamento.
      // Isso é necessário para garantir reverse visibility (perfil bloqueado
      // conseguir ver que foi bloqueado).
      _repairBlockedRelationsInBackground(
        profileIds: profiles.map((p) => p.profileId).toList(growable: false),
        uid: uid,
      );

      return ProfileState(
        activeProfile: activeProfile,
        profiles: profiles,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ ProfileNotifier: Erro ao carregar - $e');
      debugPrint(stackTrace.toString());

      // 🔁 Android/Google Sign-In: às vezes o token ainda não está pronto.
      // Se receber permission-denied/unauthenticated, reintentar automaticamente.
      if (e is FirebaseException &&
          (e.code == 'permission-denied' || e.code == 'unauthenticated')) {
        if (!_retryScheduled) {
          _retryScheduled = true;
          debugPrint('🔁 ProfileNotifier: agendando retry após erro ${e.code}');
          Future<void>.delayed(const Duration(milliseconds: 800), () {
            _retryScheduled = false;
            if (!_isDisposed) {
              ref.invalidateSelf();
            }
          });
        }
        return ProfileState(
          isLoading: true,
          error: e.toString(),
        );
      }

      return ProfileState(
        error: e.toString(),
      );
    }
  }
  
  /// Repara edges de bloqueio em background (fire-and-forget).
  /// Necessário apenas uma vez para corrigir bloqueios antigos.
  void _repairBlockedRelationsInBackground({required List<String> profileIds, required String uid}) {
    Future.microtask(() async {
      try {
        final synced = await BlockedRelations.syncEdgesForBlockedLists(
          firestore: FirebaseFirestore.instance,
          blockerProfileIds: profileIds,
          blockerUid: uid,
        );
        if (synced > 0) {
          debugPrint('✅ ProfileNotifier: Sincronizou $synced edges de bloqueio (blockedProfileIds → blocks)');
        }
      } catch (e) {
        debugPrint('⚠️ ProfileNotifier: Falha ao reparar edges (non-critical): $e');
      }
    });
  }

  Future<void> switchProfile(String profileId) async {
    try {
      final uid = ref.read(currentUserProvider)?.uid;
      if (uid == null) throw Exception('Usuário não autenticado');

      final switchUseCase = ref.read(switchActiveProfileUseCaseProvider);
      await switchUseCase(uid, profileId);

      // CRITICAL: Analytics - Track profile switch
      _setAnalyticsProfile(profileId);
      _logProfileSwitch(profileId);

      state = AsyncValue.data(await _loadProfiles(uid));
    } catch (e) {
      debugPrint('❌ ProfileNotifier: Erro ao trocar perfil - $e');
      rethrow;
    }
  }

  /// CRITICAL: Set active_profile_id in Firebase Analytics
  void _setAnalyticsProfile(String profileId) {
    try {
      FirebaseAnalytics.instance.setUserProperty(
        name: 'active_profile_id',
        value: profileId,
      );
      debugPrint('📊 Analytics: active_profile_id = $profileId');
    } catch (e) {
      debugPrint('⚠️ Analytics error: $e');
    }
  }

  /// Log profile switch event
  void _logProfileSwitch(String toProfileId) {
    try {
      FirebaseAnalytics.instance.logEvent(
        name: 'profile_switched',
        parameters: {
          'to_profile_id': toProfileId,
        },
      );
    } catch (e) {
      debugPrint('⚠️ Analytics error: $e');
    }
  }

  /// CRITICAL: Salva token FCM em TODOS os perfis do usuário
  /// 
  /// Chamado quando perfis são carregados (login) para garantir que
  /// push notifications cheguem independente do perfil ativo.
  /// Também solicita permissão de notificação se ainda não concedida.
  void _saveFcmTokenForAllProfiles(
    List<String> profileIds, {
    required String expectedUid,
  }) {
    debugPrint('🔔 FCM: Iniciando salvamento de token para ${profileIds.length} perfis');
    // Usar Future para não bloquear o carregamento de perfis
    Future.microtask(() async {
      try {
        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        if (currentUid == null || currentUid != expectedUid) {
          debugPrint(
            '🔔 FCM: Ignorando salvamento de token (uid mudou: $expectedUid -> $currentUid)',
          );
          return;
        }

        final service = PushNotificationService();
        
        debugPrint('🔔 FCM: Solicitando permissão de notificação...');
        // Solicitar permissão de notificação (iOS requer, Android 13+ também)
        // Se já foi concedida, retorna imediatamente
        final settings = await service.requestPermission();
        debugPrint('🔔 FCM: Permissão: ${settings.authorizationStatus}');

        debugPrint('🔔 FCM: Obtendo token atual...');
        var token = await service.getToken();

        if (token == null) {
          debugPrint('🔔 FCM: Token indisponível, tentando refresh controlado...');
          token = await service.forceTokenRefresh();
        }

        debugPrint('🔔 FCM: Token obtido: ${token != null ? "SIM (${token.length} chars)" : "NULL"}');
        if (token != null) {
          debugPrint('🔔 FCM: FULL TOKEN: $token');
        } else {
          debugPrint('⚠️ FCM: Token ainda indisponível; salvamento será adiado');
          return;
        }
        
        // Salvar token para TODOS os perfis do usuário
        await service.saveTokenForProfiles(profileIds);
        debugPrint('🔔 FCM: Token salvo para ${profileIds.length} perfis');
      } catch (e, stackTrace) {
        debugPrint('⚠️ FCM: Erro ao salvar tokens - $e');
        debugPrint('⚠️ FCM: StackTrace - $stackTrace');
        // Não faz rethrow - falha em FCM não deve bloquear login
      }
    });
  }

  Future<ProfileResult> createProfile(ProfileEntity profile) async {
    try {
      final uid = ref.read(currentUserProvider)?.uid;
      if (uid == null) {
        return const ProfileFailure(message: 'Usuário não autenticado');
      }

      final bioError = ObjectionableContentFilter.validate('bio', profile.bio);
      if (bioError != null) {
        return ProfileFailure(message: bioError);
      }

      final createUseCase =
          ref.read(createProfileUseCaseProvider);
      await createUseCase(profile, uid);

      state = AsyncValue.data(await _loadProfiles(uid));
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
      final uid = ref.read(currentUserProvider)?.uid;
      if (uid == null) {
        return const ProfileFailure(message: 'Usuário não autenticado');
      }

      final bioError = ObjectionableContentFilter.validate('bio', profile.bio);
      if (bioError != null) {
        return ProfileFailure(message: bioError);
      }

      final updateUseCase =
          ref.read(updateProfileUseCaseProvider);
      await updateUseCase(profile, uid);

      state = AsyncValue.data(await _loadProfiles(uid));
      return ProfileSuccess(profile: profile);
    } catch (e) {
      debugPrint('❌ ProfileNotifier: Erro ao atualizar perfil - $e');
      return ProfileFailure(
        message: 'Erro ao atualizar perfil: $e',
        exception: e is Exception ? e : null,
      );
    }
  }

  Future<void> deleteProfile(String profileId, {bool forceDelete = false}) async {
    try {
      final uid = ref.read(currentUserProvider)?.uid;
      if (uid == null) throw Exception('Usuário não autenticado');

      final deleteUseCase = ref.read(deleteProfileUseCaseProvider);
      await deleteUseCase(profileId, uid, forceDelete: forceDelete);

      state = AsyncValue.data(await _loadProfiles(uid));
    } catch (e) {
      debugPrint('❌ ProfileNotifier: Erro ao deletar perfil - $e');
      rethrow;
    }
  }

  Future<void> refresh() async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) {
      state = const AsyncValue.data(ProfileState());
      return;
    }
    state = AsyncValue.data(await _loadProfiles(uid));
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
