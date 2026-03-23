import 'package:cloud_firestore/cloud_firestore.dart';

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
      postId: postId,
      authorProfileId: data['authorProfileId'] as String? ?? '',
      authorUid: data['authorUid'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Anônimo',
      authorPhotoUrl: data['authorPhotoUrl'] as String?,
      text: data['text'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      parentCommentId: data['parentCommentId'] as String?,
      replyToName: data['replyToName'] as String?,
      replyToProfileId: data['replyToProfileId'] as String?,
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      likedBy: (data['likedBy'] as List<dynamic>?)?.cast<String>() ?? const [],
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
    );
  }
}
