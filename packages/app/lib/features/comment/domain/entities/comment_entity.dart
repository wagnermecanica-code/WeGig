import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/utils/utf16_sanitizer.dart';

/// Entidade de domínio para comentários de posts.
///
/// Armazenado como subcoleção: posts/{postId}/comments/{commentId}
class CommentEntity {
  const CommentEntity({
    required this.id,
    required this.postId,
    required this.authorProfileId,
    required this.authorUid,
    required this.authorName,
    this.authorPhotoUrl,
    required this.text,
    required this.createdAt,
    this.parentCommentId,
    this.replyToName,
    this.replyToProfileId,
    this.likeCount = 0,
    this.likedBy = const [],
    this.mentionedProfileIds = const [],
    this.mentionedUids = const [],
    this.mentionedUsernames = const [],
  });

  final String id;
  final String postId;
  final String authorProfileId;
  final String authorUid;
  final String authorName;
  final String? authorPhotoUrl;
  final String text;
  final DateTime createdAt;

  /// Se for uma resposta, ID do comentário pai
  final String? parentCommentId;

  /// Nome do perfil a quem está respondendo
  final String? replyToName;

  /// ProfileId de quem está sendo respondido
  final String? replyToProfileId;

  /// Quantidade de curtidas neste comentário
  final int likeCount;

  /// Lista de profileIds que curtiram este comentário
  final List<String> likedBy;

  /// ProfileIds mencionados no texto via @username.
  final List<String> mentionedProfileIds;

  /// UIDs dos perfis mencionados no texto via @username.
  final List<String> mentionedUids;

  /// Usernames mencionados no texto, sem o prefixo @.
  final List<String> mentionedUsernames;

  /// Indica se é uma resposta a outro comentário
  bool get isReply => parentCommentId != null && parentCommentId!.isNotEmpty;

  /// Verifica se um perfil específico curtiu este comentário
  bool isLikedBy(String profileId) => likedBy.contains(profileId);

  /// From Firestore Document (subcoleção posts/{postId}/comments/{commentId})
  factory CommentEntity.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, {
    required String postId,
  }) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception('Comment data is null');
    }

    return CommentEntity(
      id: snapshot.id,
      postId: _safe(postId),
      authorProfileId: _safe(data['authorProfileId'] as String? ?? ''),
      authorUid: _safe(data['authorUid'] as String? ?? ''),
      authorName: _safe(data['authorName'] as String? ?? 'Anônimo'),
      authorPhotoUrl: _safeOrNull(data['authorPhotoUrl'] as String?),
      text: _safe(data['text'] as String? ?? ''),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      parentCommentId: _safeOrNull(data['parentCommentId'] as String?),
      replyToName: _safeOrNull(data['replyToName'] as String?),
      replyToProfileId: _safeOrNull(data['replyToProfileId'] as String?),
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      likedBy: _safeList((data['likedBy'] as List<dynamic>?)?.cast<String>()),
      mentionedProfileIds: _safeList(
        (data['mentionedProfileIds'] as List<dynamic>?)?.cast<String>(),
      ),
      mentionedUids: _safeList(
        (data['mentionedUids'] as List<dynamic>?)?.cast<String>(),
      ),
      mentionedUsernames: _safeList(
        (data['mentionedUsernames'] as List<dynamic>?)?.cast<String>(),
      ),
    );
  }

  /// To Firestore Document
  Map<String, dynamic> toFirestore() {
    return {
      'authorProfileId': authorProfileId,
      'authorUid': authorUid,
      'authorName': authorName,
      if (authorPhotoUrl != null) 'authorPhotoUrl': authorPhotoUrl,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      if (parentCommentId != null) 'parentCommentId': parentCommentId,
      if (replyToName != null) 'replyToName': replyToName,
      if (replyToProfileId != null) 'replyToProfileId': replyToProfileId,
      if (mentionedProfileIds.isNotEmpty)
        'mentionedProfileIds': mentionedProfileIds,
      if (mentionedUids.isNotEmpty) 'mentionedUids': mentionedUids,
      if (mentionedUsernames.isNotEmpty)
        'mentionedUsernames': mentionedUsernames,
    };
  }

  CommentEntity copyWith({
    String? id,
    String? postId,
    String? authorProfileId,
    String? authorUid,
    String? authorName,
    String? authorPhotoUrl,
    String? text,
    DateTime? createdAt,
    String? parentCommentId,
    String? replyToName,
    String? replyToProfileId,
    int? likeCount,
    List<String>? likedBy,
    List<String>? mentionedProfileIds,
    List<String>? mentionedUids,
    List<String>? mentionedUsernames,
  }) {
    return CommentEntity(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorProfileId: authorProfileId ?? this.authorProfileId,
      authorUid: authorUid ?? this.authorUid,
      authorName: authorName ?? this.authorName,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      replyToName: replyToName ?? this.replyToName,
      replyToProfileId: replyToProfileId ?? this.replyToProfileId,
      likeCount: likeCount ?? this.likeCount,
      likedBy: likedBy ?? this.likedBy,
      mentionedProfileIds: mentionedProfileIds ?? this.mentionedProfileIds,
      mentionedUids: mentionedUids ?? this.mentionedUids,
      mentionedUsernames: mentionedUsernames ?? this.mentionedUsernames,
    );
  }
}

String _safe(String value) => Utf16Sanitizer.removeInvalidSurrogates(value);

String? _safeOrNull(String? value) =>
    Utf16Sanitizer.removeInvalidSurrogatesOrNull(value);

List<String> _safeList(List<String>? values) =>
    Utf16Sanitizer.removeInvalidSurrogatesFromList(values) ?? const <String>[];
