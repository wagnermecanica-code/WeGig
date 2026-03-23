// Interest Service - Manages sending and removing interests for posts
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:wegig_app/core/firebase/blocked_profiles.dart';
import 'package:wegig_app/core/firebase/blocked_relations.dart';

class InterestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendInterest({
    required PostEntity post,
    required ProfileEntity activeProfile,
    String? message,
  }) async {
    // 🔒 Bloqueios: não envia interesse para autor bloqueado
    final excluded = await BlockedRelations.getExcludedProfileIds(
      firestore: _firestore,
      profileId: activeProfile.profileId,
      uid: activeProfile.uid,
    );
    if (excluded.contains(post.authorProfileId)) {
      throw StateError('Você não pode interagir com este post');
    }

    // ✅ VERIFICAÇÃO: Evitar duplicatas antes de criar
    final existingInterest = await _firestore
        .collection('interests')
        .where('postId', isEqualTo: post.id)
        .where('interestedProfileId', isEqualTo: activeProfile.profileId)
        .limit(1)
        .get();

    if (existingInterest.docs.isNotEmpty) {
      debugPrint('⚠️ InterestService: Interesse já existe. Limpando stale docs e recriando...');
      for (final doc in existingInterest.docs) {
        await doc.reference.delete();
      }
    }

    final interestData = {
      'postId': post.id,
      'postAuthorProfileId': post.authorProfileId,
      'interestedProfileId': activeProfile.profileId,
      'profileUid': activeProfile.uid,
      'interestedProfileName': activeProfile.name,
      'interestedProfileCity': activeProfile.city,
      'interestedProfileIsBand': activeProfile.isBand,
      'interestedProfilePhotoUrl': activeProfile.photoUrl,
      'message': message ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    };

    await _firestore.collection('interests').add(interestData);
    
    debugPrint('✅ Interest sent to post ${post.id}');
  }

  Future<void> removeInterest({
    required String postId,
    required String profileId,
  }) async {
    final querySnapshot = await _firestore
        .collection('interests')
        .where('postId', isEqualTo: postId)
        .where('interestedProfileId', isEqualTo: profileId)
        .get();

    for (final doc in querySnapshot.docs) {
      await doc.reference.delete();
    }

    debugPrint('✅ Interest removed from post $postId');
  }

  Future<bool> hasInterest({
    required String postId,
    required String profileId,
    String? profileUid,
  }) async {
    var querySnapshot = _firestore
        .collection('interests')
        .where('postId', isEqualTo: postId)
        .where('interestedProfileId', isEqualTo: profileId);

    if (profileUid != null && profileUid.isNotEmpty) {
      querySnapshot =
          querySnapshot.where('profileUid', isEqualTo: profileUid);
    }

    final result = await querySnapshot.limit(1).get();

    return result.docs.isNotEmpty;
  }
}
