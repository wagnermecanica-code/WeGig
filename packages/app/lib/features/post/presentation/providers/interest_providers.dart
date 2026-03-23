import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wegig_app/features/post/data/models/interest_document.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';

part 'interest_providers.g.dart';

/// Provider global que gerencia o estado de interesses (posts salvos/curtidos)
/// Sincroniza entre HomePage, PostDetailPage e ViewProfilePage
@riverpod
class InterestNotifier extends _$InterestNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _lastLoadedProfileId;
  String? _lastLoadedProfileUid;

  @override
  Set<String> build() {
    // ✅ Dependência reativa: quando o perfil ativo muda, este provider rebuilda.
    final activeProfileId = ref.watch(
      profileProvider.select((value) => value.value?.activeProfile?.profileId),
    );
    final activeProfileUid = ref.watch(
      profileProvider.select((value) => value.value?.activeProfile?.uid),
    );

    // Sem perfil ativo: estado vazio
    if (activeProfileId == null || activeProfileId.isEmpty) {
      _lastLoadedProfileId = null;
      _lastLoadedProfileUid = null;
      return <String>{};
    }

    // Perfil sem uid carregado ainda: estado vazio
    if (activeProfileUid == null || activeProfileUid.isEmpty) {
      _lastLoadedProfileId = activeProfileId;
      _lastLoadedProfileUid = null;
      return <String>{};
    }

    // Troca de perfil: limpar estado imediatamente para evitar "leak" visual
    final didProfileChange =
        _lastLoadedProfileId != activeProfileId || _lastLoadedProfileUid != activeProfileUid;
    if (didProfileChange) {
      _lastLoadedProfileId = activeProfileId;
      _lastLoadedProfileUid = activeProfileUid;

      // Recarrega em background (build não pode ser async)
      Future.microtask(() => _loadInterestsFor(
            profileId: activeProfileId,
        profileUid: activeProfileUid,
          ));

      return <String>{};
    }

    // Mesmo perfil: mantém estado atual
    return state;
  }

  /// Carrega interesses do Firestore para o perfil ativo
  Future<void> _loadInterestsFor({
    required String profileId,
    required String profileUid,
  }) async {
    try {
      if (profileId.isEmpty || profileUid.isEmpty) {
        debugPrint('⚠️ InterestNotifier: Perfil inválido para carregar interesses');
        state = <String>{};
        return;
      }

      debugPrint('🔍 InterestNotifier: Carregando interesses para $profileId');

      final snapshot = await _firestore
          .collection('interests')
          .where('interestedProfileId', isEqualTo: profileId)
          .where('profileUid', isEqualTo: profileUid)
          .get();

      final postIds = snapshot.docs
          .map((doc) => doc.data()['postId'] as String?)
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet();

      state = postIds;
      debugPrint('✅ InterestNotifier: ${postIds.length} interesses carregados');
    } catch (e, stackTrace) {
      debugPrint('❌ InterestNotifier._loadInterests: Erro: $e');
      debugPrint('Stack trace: $stackTrace');
      state = <String>{};
    }
  }

  /// Demonstra interesse em um post (Optimistic Update)
  Future<void> addInterest({
    required String postId,
    required String postAuthorUid,
    required String postAuthorProfileId,
  }) async {
    // Validações
    if (postId.isEmpty) {
      throw Exception('postId está vazio');
    }
    if (postAuthorProfileId.isEmpty) {
      throw Exception('postAuthorProfileId está vazio');
    }
    if (postAuthorUid.isEmpty) {
      throw Exception('postAuthorUid está vazio');
    }

    final currentUser = _auth.currentUser;
    final activeProfile = ref.read(profileProvider).value?.activeProfile;

    if (currentUser == null || activeProfile == null) {
      throw Exception('Usuário não autenticado ou perfil não ativo');
    }

    // ✅ VERIFICAÇÃO: Se já está no estado local, não criar novamente
    if (state.contains(postId)) {
      debugPrint('⚠️ InterestNotifier: Interesse já existe no estado local, pulando...');
      return;
    }

    // 1. Optimistic Update: Adicionar imediatamente ao estado
    final previousState = state;
    state = {...state, postId};
    debugPrint('✅ InterestNotifier: Interesse adicionado otimisticamente (postId: $postId)');

    try {
      // ✅ VERIFICAÇÃO NO FIRESTORE: Evitar duplicatas
      final existingInterest = await _firestore
          .collection('interests')
          .where('postId', isEqualTo: postId)
          .where('interestedProfileId', isEqualTo: activeProfile.profileId)
          .limit(1)
          .get();

      if (existingInterest.docs.isNotEmpty) {
        debugPrint('⚠️ InterestNotifier: Interesse já existe no Firestore. Limpando stale docs e recriando...');
        for (final doc in existingInterest.docs) {
          await doc.reference.delete();
        }
      }

      // 2. Criar documento no Firestore
      final interestData = InterestDocumentFactory.create(
        postId: postId,
        postAuthorUid: postAuthorUid,
        postAuthorProfileId: postAuthorProfileId,
        currentUserUid: currentUser.uid,
        activeProfileUid: activeProfile.uid,
        activeProfileId: activeProfile.profileId,
        activeProfileName: activeProfile.name,
        activeProfileUsername: activeProfile.username,
        activeProfilePhotoUrl: activeProfile.photoUrl,
      );

      await _firestore.collection('interests').add(interestData);
      debugPrint('✅ InterestNotifier: Documento de interesse criado no Firestore');
    } catch (e, stackTrace) {
      // 3. Rollback em caso de erro
      debugPrint('❌ InterestNotifier.addInterest: Erro: $e');
      debugPrint('Stack trace: $stackTrace');
      state = previousState;
      rethrow;
    }
  }

  /// Remove interesse de um post (Optimistic Update)
  Future<void> removeInterest({
    required String postId,
  }) async {
    if (postId.isEmpty) {
      throw Exception('postId está vazio');
    }

    final activeProfile = ref.read(profileProvider).value?.activeProfile;
    if (activeProfile == null) {
      throw Exception('Perfil ativo não encontrado');
    }

    // 1. Optimistic Update: Remover imediatamente do estado
    final previousState = state;
    state = state.where((id) => id != postId).toSet();
    debugPrint('✅ InterestNotifier: Interesse removido otimisticamente (postId: $postId)');

    try {
      // 2. Deletar documento do Firestore
      final snapshot = await _firestore
          .collection('interests')
          .where('postId', isEqualTo: postId)
          .where('interestedProfileId', isEqualTo: activeProfile.profileId)
          .limit(1)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }

      debugPrint('✅ InterestNotifier: Documento de interesse deletado do Firestore');
    } catch (e, stackTrace) {
      // 3. Rollback em caso de erro
      debugPrint('❌ InterestNotifier.removeInterest: Erro: $e');
      debugPrint('Stack trace: $stackTrace');
      state = previousState;
      rethrow;
    }
  }

  /// Verifica se demonstrou interesse em um post específico
  bool hasInterest(String postId) {
    return state.contains(postId);
  }

  /// Recarrega interesses do Firestore (útil após trocar perfil)
  Future<void> refresh() async {
    final activeProfile = ref.read(profileProvider).value?.activeProfile;
    if (activeProfile == null) {
      state = <String>{};
      return;
    }
    await _loadInterestsFor(
      profileId: activeProfile.profileId,
      profileUid: activeProfile.uid,
    );
  }
}
