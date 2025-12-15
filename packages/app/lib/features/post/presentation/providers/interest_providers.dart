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

  @override
  Set<String> build() {
    // Estado inicial vazio - será populado por _loadInterests()
    _loadInterests();
    return <String>{};
  }

  /// Carrega interesses do Firestore para o perfil ativo
  Future<void> _loadInterests() async {
    try {
      final activeProfile = ref.read(profileProvider).value?.activeProfile;
      if (activeProfile == null) {
        debugPrint('⚠️ InterestNotifier: Perfil ativo não encontrado');
        return;
      }

      debugPrint('🔍 InterestNotifier: Carregando interesses para ${activeProfile.profileId}');

      final snapshot = await _firestore
          .collection('interests')
          .where('interestedProfileId', isEqualTo: activeProfile.profileId)
          .where('profileUid', isEqualTo: activeProfile.uid)
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
        debugPrint('⚠️ InterestNotifier: Interesse já existe no Firestore, pulando criação...');
        return;
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
          .where('profileUid', isEqualTo: activeProfile.uid)
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
    await _loadInterests();
  }
}
