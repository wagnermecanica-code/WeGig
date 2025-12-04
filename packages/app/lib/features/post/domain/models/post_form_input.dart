import 'package:cloud_firestore/cloud_firestore.dart';

/// Data object that represents the values collected in the post form.
///
/// UI widgets should populate this structure and hand it to the
/// PostNotifier, which is responsible for orchestrating uploads,
/// validations and persistence.
class PostFormInput {
  const PostFormInput({
    this.postId,
    required this.type,
    required this.content,
    required this.location,
    required this.city,
    this.neighborhood,
    this.state,
    required this.level,
    required this.genres,
    required this.selectedInstruments,
    required this.availableFor,
    this.youtubeLink,
    this.localPhotoPath,
    this.existingPhotoUrl,
    this.createdAt,
    this.expiresAt,
  });

  /// When null we are creating a new post.
  final String? postId;
  final String type;
  final String content;
  final GeoPoint location;
  final String city;
  final String? neighborhood;
  final String? state;
  final String level;
  final List<String> genres;
  final List<String> selectedInstruments;
  final List<String> availableFor;
  final String? youtubeLink;
  final String? localPhotoPath;
  final String? existingPhotoUrl;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  bool get isEditing => postId != null;
}
