import 'dart:math' as math;

import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/utils/app_snackbar.dart';
import 'package:core_ui/widgets/app_loading_overlay.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../domain/entities/comment_entity.dart';
import '../providers/comment_providers.dart';
import '../widgets/comment_item_widget.dart';
import '../widgets/comment_likers_bottom_sheet.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';
import 'package:wegig_app/app/router/app_router.dart';
import 'package:wegig_app/features/report/presentation/widgets/report_dialog.dart';
import 'package:wegig_app/features/report/presentation/providers/report_providers.dart';
import 'package:wegig_app/core/firebase/blocked_profiles.dart';
import 'package:wegig_app/core/firebase/blocked_relations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Bottom sheet estilo TikTok para exibir e adicionar comentários em um post.
///
/// Ocupa ~60% da tela, com lista de comentários em tempo real (stream)
/// e campo de entrada fixo na parte inferior.
class CommentsBottomSheet extends ConsumerStatefulWidget {
  const CommentsBottomSheet({
    required this.post,
    super.key,
  });

  /// O post cujos comentários serão exibidos
  final PostEntity post;

  /// Abre o bottom sheet de comentários
  static Future<void> show(BuildContext context, PostEntity post) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsBottomSheet(post: post),
    );
  }

  @override
  ConsumerState<CommentsBottomSheet> createState() =>
      _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends ConsumerState<CommentsBottomSheet> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSending = false;

  /// Comentário ao qual estamos respondendo (null = comentário normal)
  CommentEntity? _replyingTo;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Ativa modo de resposta para um comentário
  void _startReply(CommentEntity comment) {
    setState(() {
      // Se o comentário já é uma resposta, respondemos ao pai (thread flat)
      _replyingTo = comment;
    });
    _focusNode.requestFocus();
  }

  /// Cancela o modo de resposta
  void _cancelReply() {
    setState(() => _replyingTo = null);
  }

  Future<void> _sendComment() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    final activeProfile = ref.read(profileProvider).value?.activeProfile;

    if (currentUser == null || activeProfile == null) {
      if (mounted) {
        AppSnackBar.showError(context, 'Faça login para comentar');
      }
      return;
    }

    setState(() => _isSending = true);
    _textController.clear();

    // Capturar dados de resposta antes de limpar o estado
    final replyingTo = _replyingTo;
    final parentCommentId = replyingTo != null
        ? (replyingTo.isReply ? replyingTo.parentCommentId : replyingTo.id)
        : null;
    final replyToName = replyingTo?.authorName;
    final replyToProfileId = replyingTo?.authorProfileId;

    // Limpar modo de resposta
    if (replyingTo != null) {
      setState(() => _replyingTo = null);
    }

    try {
      final repository = ref.read(commentRepositoryProvider);
      await repository.addComment(
        postId: widget.post.id,
        authorProfileId: activeProfile.profileId,
        authorUid: currentUser.uid,
        authorName: activeProfile.name,
        authorPhotoUrl: activeProfile.photoUrl,
        text: text,
        parentCommentId: parentCommentId,
        replyToName: replyToName,
        replyToProfileId: replyToProfileId,
      );

      // Notificação in-app + push é criada pela Cloud Function
      // (sendCommentNotification) ao detectar o novo comentário.

      // Baixar o teclado para que o usuário veja o comentário enviado
      if (mounted) FocusScope.of(context).unfocus();

      HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao enviar comentário');
        // Restaurar texto e modo de resposta se falhou
        _textController.text = text;
        setState(() => _replyingTo = replyingTo);
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // Notificação de comentário é criada pela Cloud Function
  // (sendCommentNotification) — in-app + push, consistente com interest/message.

  /// Exibe menu de opções ao segurar (long press) um comentário.
  ///
  /// - Dono do comentário ou do post: opção Excluir
  /// - Outros perfis: opções Denunciar e Bloquear
  void _showCommentOptions(
    CommentEntity comment, {
    required bool canDelete,
    required bool isOwnComment,
  }) {
    final activeProfile = ref.read(profileProvider).value?.activeProfile;
    final activeProfileId = activeProfile?.profileId ?? '';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),

                // Excluir (dono do comentário ou do post)
                if (canDelete)
                  ListTile(
                    leading: const Icon(Iconsax.trash, color: Colors.red),
                    title: const Text(
                      'Excluir comentário',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _deleteComment(comment);
                    },
                  ),

                // Denunciar (quem NÃO é dono do comentário)
                if (!isOwnComment) ...[
                  ListTile(
                    leading: Icon(Iconsax.flag, color: Colors.orange.shade700),
                    title: const Text('Denunciar'),
                    onTap: () {
                      Navigator.pop(ctx);
                      showReportDialog(
                        context: context,
                        targetType: ReportTargetType.profile,
                        targetId: comment.authorProfileId,
                        targetName: comment.authorName,
                        ownerUid: comment.authorUid,
                        ownerProfileId: comment.authorProfileId,
                        ownerName: comment.authorName,
                        ownerPhotoUrl: comment.authorPhotoUrl,
                      );
                    },
                  ),

                  // Bloquear (quem NÃO é dono do comentário)
                  ListTile(
                    leading: const Icon(Iconsax.user_remove, color: Colors.red),
                    title: const Text('Bloquear'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _blockCommentAuthor(
                        comment: comment,
                        activeProfileId: activeProfileId,
                      );
                    },
                  ),
                ],

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Bloqueia o autor de um comentário.
  Future<void> _blockCommentAuthor({
    required CommentEntity comment,
    required String activeProfileId,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bloquear perfil?'),
        content: Text(
          'Você não verá mais conteúdo de "${comment.authorName}" '
          'no feed e busca.\n\nDeseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Bloquear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        AppSnackBar.showError(context, 'Você precisa estar logado.');
      }
      return;
    }

    if (comment.authorProfileId == activeProfileId) {
      if (mounted) {
        AppSnackBar.showError(context, 'Não é possível bloquear a si mesmo.');
      }
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;

      await BlockedProfiles.add(
        firestore: firestore,
        blockerProfileId: activeProfileId,
        blockedProfileId: comment.authorProfileId,
      );

      try {
        await BlockedRelations.create(
          firestore: firestore,
          blockedByProfileId: activeProfileId,
          blockedProfileId: comment.authorProfileId,
          blockedByUid: currentUser.uid,
          blockedUid: comment.authorUid,
        );
      } catch (e) {
        debugPrint('⚠️ blocks edge write failed (non-critical): $e');
      }

      if (mounted) {
        AppSnackBar.showSuccess(context, 'Perfil bloqueado com sucesso.');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao bloquear perfil.');
      }
    }
  }

  Future<void> _deleteComment(CommentEntity comment) async {
    // Verificar se tem respostas (para mensagem de confirmação mais clara)
    int replyCount = 0;
    if (!comment.isReply) {
      final currentComments =
          ref.read(commentsStreamProvider(widget.post.id)).valueOrNull ?? [];
      replyCount =
          currentComments.where((c) => c.parentCommentId == comment.id).length;
    }

    final confirmMessage = replyCount > 0
        ? 'Este comentário tem $replyCount ${replyCount == 1 ? 'resposta que também será excluída' : 'respostas que também serão excluídas'}.'
        : 'Tem certeza que deseja excluir este comentário?';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir comentário'),
        content: Text(confirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(commentRepositoryProvider);

      // Se é um comentário-pai, deletar também todas as respostas (cascade)
      if (!comment.isReply) {
        final currentComments =
            ref.read(commentsStreamProvider(widget.post.id)).valueOrNull ?? [];
        final childReplies = currentComments
            .where((c) => c.parentCommentId == comment.id)
            .toList();

        for (final reply in childReplies) {
          await repository.deleteComment(
            postId: widget.post.id,
            commentId: reply.id,
          );
        }
      }

      await repository.deleteComment(
        postId: widget.post.id,
        commentId: comment.id,
      );
      HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao excluir comentário');
      }
    }
  }

  /// Alterna curtida (like/unlike) em um comentário
  Future<void> _toggleLike(
    CommentEntity comment,
    String activeProfileId,
  ) async {
    try {
      final repository = ref.read(commentRepositoryProvider);
      await repository.toggleLike(
        postId: widget.post.id,
        commentId: comment.id,
        profileId: activeProfileId,
      );
      HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao curtir comentário');
      }
    }
  }

  /// Agrupa comentários em threads: comentários-pai primeiro, respostas abaixo.
  /// Mantém ordem cronológica de pais, e respostas ordenadas por createdAt.
  List<CommentEntity> _buildThreadedList(List<CommentEntity> comments) {
    // Separar pais e respostas
    final parents = <CommentEntity>[];
    final repliesByParent = <String, List<CommentEntity>>{};

    for (final c in comments) {
      if (c.isReply && c.parentCommentId != null) {
        repliesByParent
            .putIfAbsent(c.parentCommentId!, () => [])
            .add(c);
      } else {
        parents.add(c);
      }
    }

    // Ordenar respostas por createdAt
    for (final replies in repliesByParent.values) {
      replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    // Intercalar: pai → respostas → próximo pai
    final result = <CommentEntity>[];
    for (final parent in parents) {
      result.add(parent);
      final replies = repliesByParent[parent.id];
      if (replies != null) {
        result.addAll(replies);
      }
    }

    // Respostas órfãs (pai deletado) — exibir no final como normais
    final allParentIds = parents.map((p) => p.id).toSet();
    for (final entry in repliesByParent.entries) {
      if (!allParentIds.contains(entry.key)) {
        result.addAll(entry.value);
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsStreamProvider(widget.post.id));
    final activeProfile = ref.watch(profileProvider).value?.activeProfile;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final bottomPadding = mediaQuery.padding.bottom;
    final screenHeight = mediaQuery.size.height;
    final sheetHeight = screenHeight * 0.65;

    // Se o comentário que estávamos respondendo foi deletado, cancelar reply
    if (_replyingTo != null) {
      final currentComments = commentsAsync.valueOrNull;
      if (currentComments != null &&
          !currentComments.any((c) => c.id == _replyingTo!.id)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _replyingTo = null);
        });
      }
    }

    // A bottom sheet principal fica fixa. A barra de input flutua por cima,
    // empurrada pelo teclado via AnimatedPadding.
    return SizedBox(
      height: sheetHeight,
      child: Stack(
        children: [
          // ── 1. Bottom sheet de comentários ──
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),

                // Título com contagem
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text(
                        'Comentários',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      commentsAsync.when(
                        data: (comments) => Text(
                          '(${comments.length})',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 16),

                // Lista de comentários com threads
                Expanded(
                  child: commentsAsync.when(
                    data: (comments) {
                      if (comments.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Iconsax.message_text,
                                size: 48,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Seja o primeiro a comentar!',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final threaded = _buildThreadedList(comments);

                      return ListView.builder(
                        // Espaço extra para a barra de input não cobrir o botão "Responder"
                        padding: const EdgeInsets.only(bottom: 120),
                        itemCount: threaded.length,
                        itemBuilder: (context, index) {
                          final comment = threaded[index];
                          final activeProfileId =
                              activeProfile?.profileId ?? '';
                          final isOwn = activeProfileId.isNotEmpty &&
                              comment.authorProfileId == activeProfileId;
                          final isPostOwner = activeProfileId.isNotEmpty &&
                              widget.post.authorProfileId == activeProfileId;
                          final canDelete = isOwn || isPostOwner;

                          return CommentItemWidget(
                            comment: comment,
                            isOwnComment: isOwn,
                            canDelete: canDelete,
                            isReply: comment.isReply,
                            isLiked: activeProfileId.isNotEmpty &&
                                comment.isLikedBy(activeProfileId),
                            likeCount: comment.likeCount,
                            onDelete:
                                canDelete ? () => _deleteComment(comment) : null,
                            onReply: () => _startReply(comment),
                            onToggleLike: activeProfileId.isNotEmpty
                                ? () => _toggleLike(comment, activeProfileId)
                                : null,
                            onViewLikers: comment.likeCount > 0
                                ? () => CommentLikersBottomSheet.show(
                                      context,
                                      comment.likedBy,
                                    )
                                : null,
                            onLongPress: () => _showCommentOptions(
                              comment,
                              canDelete: canDelete,
                              isOwnComment: isOwn,
                            ),
                            onTapProfile: () {
                              Navigator.pop(context);
                              context.pushProfile(comment.authorProfileId);
                            },
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: AppRadioPulseLoader(
                        size: 44,
                        color: AppColors.primary,
                      ),
                    ),
                    error: (error, _) => Center(
                      child: Text(
                        'Erro ao carregar comentários',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 2. Barra de input flutuante (sobe com o teclado) ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: bottomInset > 0
                    ? math.max(0, bottomInset - bottomPadding)
                    : 0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Indicador de resposta ──
                    if (_replyingTo != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: Colors.grey[50],
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.undo,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Respondendo a ${_replyingTo!.authorName}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: _cancelReply,
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    // ── Campo de texto + botão enviar ──
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        bottomInset > 0 ? 8 : bottomPadding + 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              focusNode: _focusNode,
                              textCapitalization: TextCapitalization.sentences,
                              maxLines: 3,
                              minLines: 1,
                              decoration: InputDecoration(
                                hintText: _replyingTo != null
                                    ? 'Responder a ${_replyingTo!.authorName}...'
                                    : 'Adicione um comentário...',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _isSending
                              ? const SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: AppRadioPulseLoader(
                                        size: 20,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                )
                              : IconButton(
                                  onPressed: _sendComment,
                                  icon: const Icon(
                                    Iconsax.send_15,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  constraints: const BoxConstraints(),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void debugPrint(String message) {
    // ignore: avoid_print
    print(message);
  }
}
