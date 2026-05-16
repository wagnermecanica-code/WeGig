class CommonConnectionEntity {
  const CommonConnectionEntity({
    required this.profileId,
    required this.uid,
    required this.name,
    this.photoUrl,
    this.username,
  });

  final String profileId;
  final String uid;
  final String name;
  final String? photoUrl;
  final String? username;
}