import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wegig_app/features/comment/data/datasources/comment_remote_datasource.dart';
import 'package:wegig_app/features/comment/data/repositories/comment_repository_impl.dart';
import 'package:wegig_app/features/comment/domain/entities/comment_entity.dart';
import 'package:wegig_app/features/comment/domain/repositories/comment_repository.dart';

part 'comment_providers.g.dart';

/// Provider para o datasource de comentários
@riverpod
CommentRemoteDatasource commentRemoteDatasource(CommentRemoteDatasourceRef ref) {
  return CommentRemoteDatasourceImpl();
}

/// Provider para o repositório de comentários
@riverpod
CommentRepository commentRepository(CommentRepositoryRef ref) {
  final datasource = ref.watch(commentRemoteDatasourceProvider);
  return CommentRepositoryImpl(remoteDatasource: datasource);
}

/// Provider de stream para assistir comentários em tempo real
@riverpod
Stream<List<CommentEntity>> commentsStream(CommentsStreamRef ref, String postId) {
  final repository = ref.watch(commentRepositoryProvider);
  ref.onDispose(() {
    debugPrint('🧹 commentsStream disposed for postId: $postId');
  });
  return repository.watchComments(postId);
}

/// Provider para buscar commentCount de um post (para exibir o contador)
@riverpod
Stream<int> commentCountStream(CommentCountStreamRef ref, String postId) {
  final repository = ref.watch(commentRepositoryProvider);
  return repository.watchComments(postId).map((comments) => comments.length);
}

/// Provider para buscar forwardCount de um post (para exibir o contador)
@riverpod
Stream<int> forwardCountStream(ForwardCountStreamRef ref, String postId) {
  return FirebaseFirestore.instance
      .collection('posts')
      .doc(postId)
      .snapshots()
      .map((doc) => (doc.data()?['forwardCount'] as num?)?.toInt() ?? 0);
}
