import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Script de migração do sistema antigo para o novo sistema de múltiplos perfis
/// 
/// MIGRAÇÃO:
/// Antigo: users/{uid} continha dados completos + profiles array
/// Novo: profiles/{profileId} contém dados completos + users/{uid} só tem resumo
/// 
/// Execute com: dart run scripts/migrate_profiles_to_collection.dart
void main() async {
  print('=== Migração de Perfis - Início ===\n');

  try {
    // Inicializar Firebase
    await Firebase.initializeApp();
    print('✓ Firebase inicializado');

    final firestore = FirebaseFirestore.instance;
    final usersCollection = firestore.collection('users');
    final profilesCollection = firestore.collection('profiles');

    // Buscar todos os documentos de usuários
    final usersSnapshot = await usersCollection.get();
    print('✓ Encontrados ${usersSnapshot.docs.length} usuários\n');

    int migratedProfiles = 0;
    int skippedProfiles = 0;
    int errors = 0;

    for (final userDoc in usersSnapshot.docs) {
      final uid = userDoc.id;
      final userData = userDoc.data();

      print('Processando usuário: $uid');

      try {
        final profilesToMigrate = <Map<String, dynamic>>[];
        final profileSummaries = <Map<String, dynamic>>[];

        // 1. Verificar se tem perfil principal (dados diretos no documento)
        if (userData['name'] != null && userData['name'].toString().isNotEmpty) {
          final mainProfile = {
            'profileId': uid, // Perfil principal usa o UID como ID
            'uid': uid,
            'name': userData['name'],
            'isBand': userData['isBand'] ?? false,
            'photoUrl': userData['photoUrl'],
            'city': userData['city'] ?? '',
            'location': userData['location'] ?? GeoPoint(0, 0),
            'instruments': userData['instruments'] ?? [],
            'genres': userData['genres'] ?? [],
            'level': userData['level'],
            'age': userData['age'],
            'bio': userData['bio'],
            'youtubeLink': userData['youtubeLink'],
            'neighborhood': userData['neighborhood'],
            'state': userData['state'],
            'createdAt': userData['createdAt'] ?? FieldValue.serverTimestamp(),
            'updatedAt': null,
          };

          profilesToMigrate.add(mainProfile);
          profileSummaries.add({
            'profileId': uid,
            'name': userData['name'],
            'photoUrl': userData['photoUrl'],
            'type': (userData['isBand'] ?? false) ? 'band' : 'musician',
            'city': userData['city'] ?? '',
          });

          print('  ✓ Perfil principal encontrado: ${userData['name']}');
        }

        // 2. Verificar perfis secundários no array
        final oldProfiles = userData['profiles'] as List<dynamic>?;
        if (oldProfiles != null && oldProfiles.isNotEmpty) {
          for (final oldProfile in oldProfiles) {
            final profileMap = oldProfile as Map<String, dynamic>;
            final profileId = profileMap['profileId'] as String;

            final secondaryProfile = {
              'profileId': profileId,
              'uid': uid,
              'name': profileMap['name'] ?? '',
              'isBand': profileMap['isBand'] ?? false,
              'photoUrl': profileMap['photoUrl'],
              'city': profileMap['city'] ?? '',
              'location': profileMap['location'] ??
                  (profileMap['latitude'] != null && profileMap['longitude'] != null
                      ? GeoPoint(profileMap['latitude'], profileMap['longitude'])
                      : GeoPoint(0, 0)),
              'instruments': profileMap['instruments'] ?? [],
              'genres': profileMap['genres'] ?? [],
              'level': profileMap['level'],
              'age': profileMap['age'],
              'bio': profileMap['bio'],
              'youtubeLink': profileMap['youtubeLink'],
              'neighborhood': profileMap['neighborhood'],
              'state': profileMap['state'],
              'createdAt': profileMap['createdAt'] ?? FieldValue.serverTimestamp(),
              'updatedAt': null,
            };

            profilesToMigrate.add(secondaryProfile);
            profileSummaries.add({
              'profileId': profileId,
              'name': profileMap['name'] ?? '',
              'photoUrl': profileMap['photoUrl'],
              'type': (profileMap['isBand'] ?? false) ? 'band' : 'musician',
              'city': profileMap['city'] ?? '',
            });

            print('  ✓ Perfil secundário encontrado: ${profileMap['name']}');
          }
        }

        if (profilesToMigrate.isEmpty) {
          print('  ⚠ Nenhum perfil encontrado, pulando...\n');
          skippedProfiles++;
          continue;
        }

        // 3. Criar documentos na coleção profiles/{profileId}
        for (final profile in profilesToMigrate) {
          final profileId = profile['profileId'] as String;
          
          // Verificar se já existe
          final existingProfile = await profilesCollection.doc(profileId).get();
          if (existingProfile.exists) {
            print('  ⚠ Perfil $profileId já existe, pulando...');
            continue;
          }

          await profilesCollection.doc(profileId).set(profile);
          migratedProfiles++;
          print('  ✓ Perfil $profileId migrado para coleção profiles/');
        }

        // 4. Atualizar documento users/{uid} com apenas o resumo
        final activeProfileId = userData['activeProfileId'] as String? ?? uid;
        
        await usersCollection.doc(uid).update({
          'profiles': profileSummaries,
          'activeProfileId': activeProfileId,
          // Remover campos que agora estão em profiles/{profileId}
          'name': FieldValue.delete(),
          'isBand': FieldValue.delete(),
          'photoUrl': FieldValue.delete(),
          'city': FieldValue.delete(),
          'location': FieldValue.delete(),
          'instruments': FieldValue.delete(),
          'genres': FieldValue.delete(),
          'level': FieldValue.delete(),
          'age': FieldValue.delete(),
          'bio': FieldValue.delete(),
          'youtubeLink': FieldValue.delete(),
          'neighborhood': FieldValue.delete(),
          'state': FieldValue.delete(),
          'latitude': FieldValue.delete(),
          'longitude': FieldValue.delete(),
        });

        print('  ✓ Documento users/$uid atualizado com resumos\n');
      } catch (e) {
        print('  ✗ Erro ao migrar usuário $uid: $e\n');
        errors++;
      }
    }

    print('\n=== Migração Concluída ===');
    print('Perfis migrados: $migratedProfiles');
    print('Usuários sem perfil: $skippedProfiles');
    print('Erros: $errors');
    print('\n⚠ IMPORTANTE: Deploy das novas Firestore Rules:');
    print('  firebase deploy --only firestore:rules\n');
  } catch (e) {
    print('✗ Erro fatal: $e');
  }
}
