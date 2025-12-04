// Interest Service - Manages sending and removing interests for posts
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:flutter/foundation.dart';

class InterestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendInterest({
    required PostEntity post,
    required ProfileEntity activeProfile,
    String? message,
  }) async {
    final interestData = {
      'postId': post.id,
      'postAuthorProfileId': post.authorProfileId,
      'interestedProfileId': activeProfile.profileId,
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
  }) async {
    final querySnapshot = await _firestore
        .collection('interests')
        .where('postId', isEqualTo: postId)
        .where('interestedProfileId', isEqualTo: profileId)
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }
}
