import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:wegig_app/features/profile/domain/repositories/profile_repository.dart';

class MockProfileRepository implements ProfileRepository {
  // Create profile
  bool createProfileCalled = false;
  ProfileEntity? _createResponse;

  void setupCreateResponse(ProfileEntity profile) {
    _createResponse = profile;
  }

  // Existing profiles
  List<ProfileEntity> _existingProfiles = [];

  void setupExistingProfiles(List<ProfileEntity> profiles) {
    _existingProfiles = profiles;
  }

  // Profile by ID
  final Map<String, ProfileEntity?> _profilesById = {};

  void setupProfileById(String profileId, ProfileEntity? profile) {
    _profilesById[profileId] = profile;
  }

  // Ownership
  bool isProfileOwnerCalled = false;
  String? lastOwnershipCheckProfileId;
  String? lastOwnershipCheckUid;
  final Map<String, bool> _ownershipMap = {};

  void setupOwnership(String profileId, String uid, {required bool isOwner}) {
    _ownershipMap['$profileId-$uid'] = isOwner;
  }

  // Switch active profile
  bool switchActiveProfileCalled = false;
  String? lastSwitchedUid;
  String? lastSwitchedProfileId;

  // Delete profile
  bool deleteProfileCalled = false;
  String? lastDeletedProfileId;
  String? lastDeletedNewActiveProfileId;

  // Active profile
  ProfileEntity? _activeProfile;

  void setupActiveProfile(ProfileEntity? profile) {
    _activeProfile = profile;
  }

  @override
  Future<ProfileEntity> createProfile(ProfileEntity profile) async {
    createProfileCalled = true;
    return _createResponse ?? profile;
  }

  @override
  Future<List<ProfileEntity>> getAllProfiles(String uid) async {
    return _existingProfiles;
  }

  @override
  Future<ProfileEntity?> getProfileById(String profileId) async {
    return _profilesById[profileId];
  }

  @override
  Future<bool> isProfileOwner(String profileId, String uid) async {
    isProfileOwnerCalled = true;
    lastOwnershipCheckProfileId = profileId;
    lastOwnershipCheckUid = uid;
    return _ownershipMap['$profileId-$uid'] ?? false;
  }

  @override
  Future<void> switchActiveProfile(String uid, String newProfileId) async {
    switchActiveProfileCalled = true;
    lastSwitchedUid = uid;
    lastSwitchedProfileId = newProfileId;
  }

  @override
  Future<void> deleteProfile(
    String profileId, {
    String? newActiveProfileId,
  }) async {
    deleteProfileCalled = true;
    lastDeletedProfileId = profileId;
    lastDeletedNewActiveProfileId = newActiveProfileId;
  }

  @override
  Future<ProfileEntity?> getActiveProfile(String uid) async {
    return _activeProfile;
  }

  @override
  Future<ProfileEntity> updateProfile(ProfileEntity profile) async {
    return profile;
  }

  Stream<ProfileEntity?> watchActiveProfile(String uid) {
    return Stream.value(_activeProfile);
  }

  Stream<List<ProfileEntity>> watchAllProfiles(String uid) {
    return Stream.value(_existingProfiles);
  }

  @override
  Future<List<Map<String, dynamic>>> getProfilesSummary(String uid) async {
    return _existingProfiles
        .map((p) => {
              'profileId': p.profileId,
              'name': p.name,
              'isBand': p.isBand,
              'photoUrl': p.photoUrl,
            })
        .toList();
  }
}
