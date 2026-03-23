import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:flutter/foundation.dart';

/// ProfileRemoteDataSource - Comunicação direta com Firestore
///
/// Responsabilidades:
/// - CRUD no Firestore (profiles/{profileId}, users/{uid})
/// - Transações atômicas
/// - Retorna ProfileEntity ou lança FirebaseException
abstract class ProfileRemoteDataSource {
  /// Busca todos os perfis do usuário
  Future<List<ProfileEntity>> getAllProfiles(String uid);

  /// Busca perfil específico por ID
  Future<ProfileEntity?> getProfileById(String profileId);

  /// Busca perfil ativo do usuário (via users/{uid}.activeProfileId)
  Future<ProfileEntity?> getActiveProfile(String uid);

  /// Cria novo perfil em profiles/{profileId}
  Future<void> createProfile(ProfileEntity profile);

  /// Atualiza perfil existente
  Future<void> updateProfile(ProfileEntity profile);

  /// Deleta perfil (transação atômica com switch activeProfileId)
  Future<void> deleteProfile(
    String profileId,
    String uid, {
    String? newActiveProfileId,
  });

  /// Troca perfil ativo (atualiza users/{uid}.activeProfileId)
  Future<void> switchActiveProfile(String uid, String newProfileId);

  /// Verifica se perfil pertence ao usuário
  Future<bool> isProfileOwner(String profileId, String uid);

  /// Busca ID do perfil ativo
  Future<String?> getActiveProfileId(String uid);
}

/// Implementação do ProfileRemoteDataSource usando Firestore
class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  ProfileRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  CollectionReference get _profilesRef => _firestore.collection('profiles');
  CollectionReference get _usersRef => _firestore.collection('users');

  /// Compat/Migration: some legacy builds stored profiles under `users/{uid}/profiles/{profileId}`
  /// (or even a single profile doc at `profiles/{uid}` without `uid` set).
  ///
  /// New builds expect all profiles in the top-level `profiles` collection with a `uid` field.
  /// This helper best-effort migrates legacy docs into the new structure.
  Future<void> _migrateLegacyProfilesToGlobalCollection(String uid) async {
    try {
      final legacyProfilesRef = _usersRef.doc(uid).collection('profiles');
      final legacySnap = await legacyProfilesRef.get();
      if (legacySnap.docs.isEmpty) {
        return;
      }

      debugPrint(
        '🧩 ProfileRemoteDataSource: Encontrados ${legacySnap.docs.length} perfis legados em users/{uid}/profiles. Migrando...'
      );

      final now = Timestamp.now();

      // Best-effort, do not use a transaction here to avoid read/write ordering issues
      // across many docs; each profile is merged independently.
      for (final doc in legacySnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final profileId = doc.id;

        final migrated = <String, dynamic>{...data};
        migrated['uid'] = uid;
        migrated['updatedAt'] ??= now;
        migrated['createdAt'] ??= now;

        // Ensure `profileType` exists for newer clients (while keeping `isBand`).
        if (!migrated.containsKey('profileType')) {
          final isBand = (migrated['isBand'] as bool?) ?? false;
          migrated['profileType'] = isBand ? 'band' : 'musician';
        }

        await _profilesRef.doc(profileId).set(
              migrated,
              SetOptions(merge: true),
            );
      }

      debugPrint('✅ ProfileRemoteDataSource: Migração de perfis legados concluída');
    } catch (e) {
      debugPrint('⚠️ ProfileRemoteDataSource: Falha ao migrar perfis legados (non-critical): $e');
    }
  }

  @override
  Future<List<ProfileEntity>> getAllProfiles(String uid) async {
    debugPrint('🔍 ProfileRemoteDataSource: getAllProfiles - uid=$uid');
    debugPrint('🔍 ProfileRemoteDataSource: uid.length=${uid.length}, uid.trim()=${uid.trim()}');

    QuerySnapshot snapshot;
    try {
      debugPrint('🔍 ProfileRemoteDataSource: Executando query profiles.uid == $uid com orderBy (SERVIDOR)...');
      // ⚠️ IMPORTANTE: Forçar leitura do servidor para evitar cache stale após reinstalar
      snapshot = await _profilesRef
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get(const GetOptions(source: Source.server));
      debugPrint('🔍 ProfileRemoteDataSource: Query SERVIDOR retornou ${snapshot.docs.length} docs');
    } on FirebaseException catch (e) {
      // If composite indexes are temporarily missing in some environments,
      // or if server is unreachable, fall back to simpler query
      debugPrint('⚠️ ProfileRemoteDataSource: Query com orderBy/servidor falhou (${e.code}). Tentando fallback...');
      try {
        snapshot = await _profilesRef
            .where('uid', isEqualTo: uid)
            .get(const GetOptions(source: Source.server));
        debugPrint('🔍 ProfileRemoteDataSource: Fallback SERVIDOR retornou ${snapshot.docs.length} docs');
      } catch (e2) {
        debugPrint('⚠️ ProfileRemoteDataSource: Servidor falhou, usando cache: $e2');
        snapshot = await _profilesRef.where('uid', isEqualTo: uid).get();
        debugPrint('🔍 ProfileRemoteDataSource: Fallback CACHE retornou ${snapshot.docs.length} docs');
      }
    }

    // Legacy migration path: if we didn't find any profiles, attempt to migrate
    // from `users/{uid}/profiles` into global `profiles`.
    if (snapshot.docs.isEmpty) {
      await _migrateLegacyProfilesToGlobalCollection(uid);

      // Fallback for very old accounts that used `profiles/{uid}` as the doc id.
      try {
        final legacySingle = await _profilesRef.doc(uid).get();
        if (legacySingle.exists) {
          final data = (legacySingle.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
          if ((data['uid'] as String?)?.isNotEmpty != true) {
            final now = Timestamp.now();
            final migrated = <String, dynamic>{...data};
            migrated['uid'] = uid;
            migrated['updatedAt'] ??= now;
            migrated['createdAt'] ??= now;
            if (!migrated.containsKey('profileType')) {
              final isBand = (migrated['isBand'] as bool?) ?? false;
              migrated['profileType'] = isBand ? 'band' : 'musician';
            }
            await _profilesRef.doc(uid).set(migrated, SetOptions(merge: true));
          }
        }
      } catch (e) {
        debugPrint('⚠️ ProfileRemoteDataSource: Falha no fallback profiles/{uid} (non-critical): $e');
      }

      // Re-query after migration.
      try {
        snapshot = await _profilesRef
            .where('uid', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .get();
      } on FirebaseException {
        snapshot = await _profilesRef.where('uid', isEqualTo: uid).get();
      }
    }

    final profiles = snapshot.docs
        .map((doc) => ProfileEntity.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>,
            ))
        .toList();

    debugPrint(
        '✅ ProfileRemoteDataSource: Encontrados ${profiles.length} perfis');
    return profiles;
  }

  @override
  Future<ProfileEntity?> getProfileById(String profileId) async {
    debugPrint('🔍 ProfileRemoteDataSource: getProfileById - id=$profileId');

    final doc = await _profilesRef.doc(profileId).get();

    if (!doc.exists) {
      debugPrint('⚠️ ProfileRemoteDataSource: Perfil não encontrado');
      return null;
    }

    final profile = ProfileEntity.fromFirestore(
      doc as DocumentSnapshot<Map<String, dynamic>>,
    );

    debugPrint(
        '✅ ProfileRemoteDataSource: Perfil encontrado - ${profile.name}');
    return profile;
  }

  @override
  Future<ProfileEntity?> getActiveProfile(String uid) async {
    debugPrint('🔍 ProfileRemoteDataSource: getActiveProfile - uid=$uid');

    // 1. Buscar activeProfileId em users/{uid} - forçar servidor para evitar cache stale
    DocumentSnapshot userDoc;
    try {
      userDoc = await _usersRef.doc(uid).get(const GetOptions(source: Source.server));
      debugPrint('🔍 ProfileRemoteDataSource: userDoc do SERVIDOR');
    } catch (e) {
      debugPrint('⚠️ ProfileRemoteDataSource: Servidor falhou, usando cache: $e');
      userDoc = await _usersRef.doc(uid).get();
    }
    
    final activeId = (userDoc.data()
        as Map<String, dynamic>?)?['activeProfileId'] as String?;

    if (activeId == null) {
      debugPrint('⚠️ ProfileRemoteDataSource: Nenhum perfil ativo definido');
      return null;
    }

    // 2. Buscar perfil em profiles/{activeId} - forçar servidor
    DocumentSnapshot profileDoc;
    try {
      profileDoc = await _profilesRef.doc(activeId).get(const GetOptions(source: Source.server));
      debugPrint('🔍 ProfileRemoteDataSource: profileDoc do SERVIDOR');
    } catch (e) {
      debugPrint('⚠️ ProfileRemoteDataSource: Servidor falhou, usando cache: $e');
      profileDoc = await _profilesRef.doc(activeId).get();
    }

    if (!profileDoc.exists) {
      debugPrint(
          '⚠️ ProfileRemoteDataSource: Perfil ativo não encontrado no Firestore');
      return null;
    }

    final profile = ProfileEntity.fromFirestore(
      profileDoc as DocumentSnapshot<Map<String, dynamic>>,
    );

    debugPrint('✅ ProfileRemoteDataSource: Perfil ativo: ${profile.name}');
    return profile;
  }

  @override
  Future<void> createProfile(ProfileEntity profile) async {
    debugPrint('📝 ProfileRemoteDataSource: createProfile - ${profile.name}');

    // Transação atômica: criar perfil + definir como ativo se for o primeiro
    await _firestore.runTransaction((transaction) async {
      // ⚠️ FIRESTORE RULE: Todas as LEITURAS devem vir ANTES de todas as ESCRITAS

      // 1. PRIMEIRO: Ler documento do usuário (READ)
      final userRef = _usersRef.doc(profile.uid);
      final userDoc = await transaction.get(userRef);

      // 2. DEPOIS: Todas as escritas (WRITES)
      final profileRef = _profilesRef.doc(profile.profileId);
      transaction.set(profileRef, profile.toFirestore());

      if (!userDoc.exists) {
        // Criar documento users/{uid} com activeProfileId
        transaction.set(userRef, {
          'activeProfileId': profile.profileId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint('📝 ProfileRemoteDataSource: Documento users/{uid} criado');
      } else {
        final userData = userDoc.data() as Map<String, dynamic>?;
        final currentActiveId = userData?['activeProfileId'];

        // Se não tem perfil ativo, definir este como ativo
        if (currentActiveId == null || currentActiveId.toString().isEmpty) {
          transaction.update(userRef, {
            'activeProfileId': profile.profileId,
          });
          debugPrint(
              '📝 ProfileRemoteDataSource: activeProfileId definido para primeiro perfil');
        }
      }
    });

    debugPrint('✅ ProfileRemoteDataSource: Perfil criado com sucesso');
  }

  @override
  Future<void> updateProfile(ProfileEntity profile) async {
    debugPrint('📝 ProfileRemoteDataSource: updateProfile - ${profile.name}');

    // Atualiza com merge (preserva campos não enviados)
    await _profilesRef.doc(profile.profileId).set(
          profile.toFirestore(),
          SetOptions(merge: true),
        );

    debugPrint('✅ ProfileRemoteDataSource: Perfil atualizado com sucesso');
  }

  @override
  Future<void> deleteProfile(
    String profileId,
    String uid, {
    String? newActiveProfileId,
  }) async {
    debugPrint('🗑️ ProfileRemoteDataSource: deleteProfile - id=$profileId');

    // Transação atômica: delete perfil + switch activeProfileId
    await _firestore.runTransaction((transaction) async {
      // 1. Verificar propriedade
      final profileRef = _profilesRef.doc(profileId);
      final profileDoc = await transaction.get(profileRef);

      if (!profileDoc.exists) {
        throw Exception('Perfil não encontrado');
      }

      final profileData = profileDoc.data()! as Map<String, dynamic>;
      if (profileData['uid'] != uid) {
        throw Exception('Perfil não pertence ao usuário');
      }

      // 2. Delete perfil
      transaction.delete(profileRef);

      // 3. Atualizar activeProfileId se fornecido
      if (newActiveProfileId != null) {
        final userRef = _usersRef.doc(uid);
        transaction.update(userRef, {'activeProfileId': newActiveProfileId});
      }
    });

    debugPrint('✅ ProfileRemoteDataSource: Perfil deletado com sucesso');
  }

  @override
  Future<void> switchActiveProfile(String uid, String newProfileId) async {
    debugPrint(
        '🔄 ProfileRemoteDataSource: switchActiveProfile - new=$newProfileId');

    // Verificar se perfil pertence ao usuário
    final profileDoc = await _profilesRef.doc(newProfileId).get();

    if (!profileDoc.exists) {
      throw Exception('Perfil não encontrado');
    }

    final profileData = profileDoc.data()! as Map<String, dynamic>;
    if (profileData['uid'] != uid) {
      throw Exception('Perfil não pertence ao usuário');
    }

    // Atualizar activeProfileId
    await _usersRef.doc(uid).update({'activeProfileId': newProfileId});

    debugPrint('✅ ProfileRemoteDataSource: Perfil ativo alterado');
  }

  @override
  Future<bool> isProfileOwner(String profileId, String uid) async {
    debugPrint(
        '🔍 ProfileRemoteDataSource: isProfileOwner - id=$profileId, uid=$uid');

    final doc = await _profilesRef.doc(profileId).get();

    if (!doc.exists) {
      debugPrint('⚠️ ProfileRemoteDataSource: Perfil não existe');
      return false;
    }

    final profileData = doc.data()! as Map<String, dynamic>;
    final isOwner = profileData['uid'] == uid;

    debugPrint('✅ ProfileRemoteDataSource: isOwner=$isOwner');
    return isOwner;
  }

  @override
  Future<String?> getActiveProfileId(String uid) async {
    debugPrint('🔍 ProfileRemoteDataSource: getActiveProfileId - uid=$uid');

    // Forçar leitura do servidor para evitar cache stale após reinstalar
    DocumentSnapshot userDoc;
    try {
      userDoc = await _usersRef.doc(uid).get(const GetOptions(source: Source.server));
      debugPrint('🔍 ProfileRemoteDataSource: userDoc do SERVIDOR');
    } catch (e) {
      debugPrint('⚠️ ProfileRemoteDataSource: Servidor falhou, usando cache: $e');
      userDoc = await _usersRef.doc(uid).get();
    }
    
    final activeId = (userDoc.data()
        as Map<String, dynamic>?)?['activeProfileId'] as String?;

    debugPrint('✅ ProfileRemoteDataSource: activeProfileId=$activeId');
    return activeId;
  }
}
