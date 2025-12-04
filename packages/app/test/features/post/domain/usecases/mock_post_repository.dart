import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:wegig_app/features/post/domain/repositories/post_repository.dart';

class MockPostRepository implements PostRepository {
  // Create post
  bool createPostCalled = false;
  PostEntity? _createResponse;

  void setupCreateResponse(PostEntity post) {
    _createResponse = post;
  }

  // Delete post
  bool deletePostCalled = false;
  String? lastDeletedPostId;
  String? _deleteFailure;

  void setupDeleteFailure(String errorMessage) {
    _deleteFailure = errorMessage;
  }

  // Get post by ID
  final Map<String, PostEntity?> _postsById = {};

  void setupPostById(String postId, PostEntity? post) {
    _postsById[postId] = post;
  }

  // Ownership
  bool isPostOwnerCalled = false;
  String? lastOwnershipCheckPostId;
  String? lastOwnershipCheckProfileId;
  final Map<String, bool> _ownershipMap = {};
  String? _ownershipCheckFailure;

  void setupOwnership(String postId, String profileId,
      {required bool isOwner}) {
    _ownershipMap['$postId-$profileId'] = isOwner;
  }

  void setupOwnershipCheckFailure(String errorMessage) {
    _ownershipCheckFailure = errorMessage;
  }

  // Nearby posts
  List<PostEntity> _nearbyPosts = [];

  void setupNearbyPosts(List<PostEntity> posts) {
    _nearbyPosts = posts;
  }

  // Interested profiles
  final Map<String, List<String>> _interestedProfiles = {};
  String? _interestedProfilesFailure;
  bool toggleInterestCalled = false;
  bool? _toggleInterestResponse;
  String? _toggleInterestFailure;

  void setupInterestedProfiles(String postId, List<String> profiles) {
    _interestedProfiles[postId] = profiles;
  }

  void setupInterestedProfilesFailure(String errorMessage) {
    _interestedProfilesFailure = errorMessage;
  }

  void setupToggleInterestResponse(bool result) {
    _toggleInterestResponse = result;
  }

  void setupToggleInterestFailure(String errorMessage) {
    _toggleInterestFailure = errorMessage;
  }

  @override
  Future<PostEntity> createPost(PostEntity post) async {
    createPostCalled = true;
    return _createResponse ?? post;
  }

  @override
  Future<void> deletePost(String postId, String profileId) async {
    deletePostCalled = true;
    lastDeletedPostId = postId;
    if (_deleteFailure != null) {
      throw Exception(_deleteFailure);
    }
  }

  @override
  Future<PostEntity?> getPostById(String postId) async {
    return _postsById[postId];
  }

  @override
  Future<bool> isPostOwner(String postId, String profileId) async {
    isPostOwnerCalled = true;
    lastOwnershipCheckPostId = postId;
    lastOwnershipCheckProfileId = profileId;

    if (_ownershipCheckFailure != null) {
      throw Exception(_ownershipCheckFailure);
    }

    return _ownershipMap['$postId-$profileId'] ?? false;
  }

  @override
  Future<List<PostEntity>> getNearbyPosts({
    required double latitude,
    required double longitude,
    required double radiusKm,
    int limit = 50,
  }) async {
    return _nearbyPosts;
  }

  @override
  Future<PostEntity> updatePost(PostEntity post) async {
    return post;
  }

  @override
  Future<bool> hasInterest(String postId, String profileId) async {
    if (_toggleInterestResponse != null) {
      return !_toggleInterestResponse!;
    }
    return _interestedProfiles[postId]?.contains(profileId) ?? false;
  }

  @override
  Future<void> addInterest(String postId, String profileId) async {
    toggleInterestCalled = true;

    if (_toggleInterestFailure != null) {
      throw Exception(_toggleInterestFailure);
    }

    if (_interestedProfiles[postId] == null) {
      _interestedProfiles[postId] = [];
    }
    if (!_interestedProfiles[postId]!.contains(profileId)) {
      _interestedProfiles[postId]!.add(profileId);
    }
  }

  @override
  Future<void> removeInterest(String postId, String profileId) async {
    toggleInterestCalled = true;

    if (_toggleInterestFailure != null) {
      throw Exception(_toggleInterestFailure);
    }

    _interestedProfiles[postId]?.remove(profileId);
  }

  @override
  Future<List<String>> getInterestedProfiles(String postId) async {
    if (_interestedProfilesFailure != null) {
      throw Exception(_interestedProfilesFailure);
    }

    return _interestedProfiles[postId] ?? [];
  }

  @override
  Future<List<PostEntity>> getAllPosts(String uid) async {
    return _postsById.values
        .whereType<PostEntity>()
        .where((p) => p.authorUid == uid)
        .toList();
  }

  @override
  Future<List<PostEntity>> getPostsByProfile(String profileId) async {
    return _postsById.values
        .whereType<PostEntity>()
        .where((p) => p.authorProfileId == profileId)
        .toList();
  }

  @override
  Stream<List<PostEntity>> watchPosts(String uid) {
    return Stream.value(_postsById.values
        .whereType<PostEntity>()
        .where((p) => p.authorUid == uid)
        .toList());
  }

  @override
  Stream<List<PostEntity>> watchPostsByProfile(String profileId) {
    return Stream.value(_postsById.values
        .whereType<PostEntity>()
        .where((p) => p.authorProfileId == profileId)
        .toList());
  }
}
