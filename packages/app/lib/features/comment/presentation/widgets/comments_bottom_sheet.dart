import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/utils/app_snackbar.dart';
import 'package:core_ui/utils/debouncer.dart';
import 'package:core_ui/utils/objectionable_content_filter.dart';
import 'package:core_ui/widgets/app_loading_overlay.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:wegig_app/app/router/app_router.dart';
import 'package:wegig_app/core/firebase/blocked_profiles.dart';
import 'package:wegig_app/core/firebase/blocked_relations.dart';
import 'package:wegig_app/features/comment/domain/entities/comment_entity.dart';
import 'package:wegig_app/features/comment/presentation/providers/comment_providers.dart';
import 'package:wegig_app/features/comment/presentation/widgets/comment_item_widget.dart';
import 'package:wegig_app/features/comment/presentation/widgets/comment_likers_bottom_sheet.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';
import 'package:wegig_app/features/report/presentation/providers/report_providers.dart';
import 'package:wegig_app/features/report/presentation/widgets/report_dialog.dart';

/// Bottom sheet estilo TikTok para exibir e adicionar comentários em um post.
///
/// Ocupa ~60% da tela, com lista de comentários em tempo real (stream)
/// e campo de entrada fixo na parte inferior.
class CommentsBottomSheet extends ConsumerStatefulWidget {
  const CommentsBottomSheet({
    required this.post,
    this.highlightCommentId,
    this.parentCommentId,
    super.key,
  });

  /// O post cujos comentários serão exibidos
  final PostEntity post;

  /// Quando definido, o sheet rola até o comentário com esse id e aplica
  /// um destaque temporário (deep link de notificação).
  final String? highlightCommentId;

  /// Id do comentário pai, quando [highlightCommentId] aponta para uma
  /// resposta. Mantido para futuras melhorias de expansão/ordenação.
  final String? parentCommentId;

  /// Abre o bottom sheet de comentários
  static Future<void> show(
    BuildContext context,
    PostEntity post, {
    String? highlightCommentId,
    String? parentCommentId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsBottomSheet(
        post: post,
        highlightCommentId: highlightCommentId,
        parentCommentId: parentCommentId,
      ),
    );
  }

  @override
  ConsumerState<CommentsBottomSheet> createState() =>
      _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends ConsumerState<CommentsBottomSheet> {
  static final RegExp _mentionTokenRegex = RegExp(r'^[a-zA-Z0-9._]*$');
  static final RegExp _mentionRegex = RegExp(r'@([a-zA-Z0-9._]+)');

  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _mentionSearchDebouncer = Debouncer(milliseconds: 250);
  bool _isSending = false;
  bool _isMentionSearching = false;
  int _mentionSearchGeneration = 0;
  _ActiveMention? _activeMention;
  List<_MentionSuggestion> _mentionSuggestions = const [];

  /// Comentário ao qual estamos respondendo (null = comentário normal)
  CommentEntity? _replyingTo;

  /// Chaves por id de comentário para permitir [Scrollable.ensureVisible].
  final Map<String, GlobalKey> _itemKeys = <String, GlobalKey>{};

  /// Id do comentário atualmente destacado (deep link). Limpado após o
  /// período de destaque.
  String? _highlightedCommentId;

  /// Garante que a rolagem para o comentário destacado aconteça apenas
  /// uma vez por abertura.
  bool _didScrollToHighlight = false;
  Timer? _highlightClearTimer;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_handleCommentTextChanged);
    _highlightedCommentId = widget.highlightCommentId;
  }

  @override
  void dispose() {
    _highlightClearTimer?.cancel();
    _textController.removeListener(_handleCommentTextChanged);
    _mentionSearchDebouncer.dispose();
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

  void _handleCommentTextChanged() {
    final activeMention = _extractActiveMention(_textController.value);
    final previousMention = _activeMention;
    _activeMention = activeMention;

    if (activeMention == null) {
      _mentionSearchDebouncer.cancel();
      if (_mentionSuggestions.isNotEmpty || _isMentionSearching) {
        setState(() {
          _mentionSuggestions = const [];
          _isMentionSearching = false;
        });
      }
      return;
    }

    if (previousMention?.query == activeMention.query &&
        _mentionSuggestions.isNotEmpty) {
      return;
    }

    if (!_isMentionSearching) {
      setState(() => _isMentionSearching = true);
    }

    _mentionSearchDebouncer.run(() {
      _searchMentionSuggestions(activeMention.query);
    });
  }

  _ActiveMention? _extractActiveMention(TextEditingValue value) {
    final selection = value.selection;
    if (!selection.isValid || !selection.isCollapsed) return null;

    final cursor = selection.baseOffset;
    if (cursor < 0 || cursor > value.text.length) return null;

    final beforeCursor = value.text.substring(0, cursor);
    final atIndex = beforeCursor.lastIndexOf('@');
    if (atIndex < 0) return null;

    if (atIndex > 0) {
      final previous = beforeCursor[atIndex - 1];
      if (!RegExp(r'\s').hasMatch(previous)) return null;
    }

    final query = beforeCursor.substring(atIndex + 1);
    if (query.contains(RegExp(r'\s'))) return null;
    if (!_mentionTokenRegex.hasMatch(query)) return null;

    return _ActiveMention(start: atIndex, end: cursor, query: query);
  }

  Future<void> _searchMentionSuggestions(String rawQuery) async {
    final generation = ++_mentionSearchGeneration;
    final query = rawQuery.trim().toLowerCase();

    try {
      final activeProfile = ref.read(profileProvider).value?.activeProfile;
      final currentUser = FirebaseAuth.instance.currentUser;
      final activeProfileId = activeProfile?.profileId ?? '';
      final excludedProfileIds = activeProfile == null || currentUser == null
          ? const <String>[]
          : await BlockedRelations.getExcludedProfileIds(
              firestore: FirebaseFirestore.instance,
              profileId: activeProfile.profileId,
              uid: currentUser.uid,
            );

      final results = <_MentionSuggestion>[];
      final seenProfileIds = <String>{};

      void addIfValid(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
        if (results.length >= 8) return;
        final suggestion = _MentionSuggestion.fromFirestore(doc);
        if (suggestion == null) return;
        if (seenProfileIds.contains(suggestion.profileId)) return;
        if (suggestion.profileId == activeProfileId) return;
        if (excludedProfileIds.contains(suggestion.profileId)) return;

        seenProfileIds.add(suggestion.profileId);
        results.add(suggestion);
      }

      final profilesRef = FirebaseFirestore.instance.collection('profiles');

      if (query.isEmpty) {
        final recentSnapshot = await profilesRef
            .orderBy('createdAt', descending: true)
            .limit(30)
            .get();
        for (final doc in recentSnapshot.docs) {
          addIfValid(doc);
        }
      } else {
        final exactSnapshot = await profilesRef
            .where('usernameLowercase', isEqualTo: query)
            .limit(4)
            .get();
        for (final doc in exactSnapshot.docs) {
          addIfValid(doc);
        }

        if (results.length < 8) {
          final prefixSnapshot = await profilesRef
              .orderBy('usernameLowercase')
              .startAt([query])
              .endAt(['$query\uf8ff'])
              .limit(12)
              .get();
          for (final doc in prefixSnapshot.docs) {
            addIfValid(doc);
          }
        }
      }

      if (!mounted || generation != _mentionSearchGeneration) return;
      setState(() {
        _mentionSuggestions = results;
        _isMentionSearching = false;
      });
    } catch (error, stackTrace) {
      debugPrint('❌ Mention search failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted || generation != _mentionSearchGeneration) return;
      setState(() {
        _mentionSuggestions = const [];
        _isMentionSearching = false;
      });
    }
  }

  void _insertMention(_MentionSuggestion suggestion) {
    final value = _textController.value;
    final activeMention = _activeMention ?? _extractActiveMention(value);
    if (activeMention == null) return;

    final replacement = '@${suggestion.username} ';
    final newText = value.text.replaceRange(
      activeMention.start,
      activeMention.end,
      replacement,
    );
    final selectionOffset = activeMention.start + replacement.length;

    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selectionOffset),
    );
    _focusNode.requestFocus();
    setState(() {
      _activeMention = null;
      _mentionSuggestions = const [];
      _isMentionSearching = false;
    });
  }

  Future<_ResolvedCommentMentions> _resolveCommentMentions({
    required String text,
    required String activeProfileId,
    required String activeUid,
  }) async {
    final usernames = _mentionRegex
        .allMatches(text)
        .map((match) => match.group(1)?.trim().toLowerCase() ?? '')
        .where((username) => username.isNotEmpty)
        .toSet()
        .take(10)
        .toList(growable: false);

    if (usernames.isEmpty) return const _ResolvedCommentMentions.empty();

    try {
      final excludedProfileIds = await BlockedRelations.getExcludedProfileIds(
        firestore: FirebaseFirestore.instance,
        profileId: activeProfileId,
        uid: activeUid,
      );
      final profilesRef = FirebaseFirestore.instance.collection('profiles');
      final profileIds = <String>[];
      final uids = <String>[];
      final resolvedUsernames = <String>[];
      final seenProfileIds = <String>{};

      for (final username in usernames) {
        var snapshot = await profilesRef
            .where('usernameLowercase', isEqualTo: username)
            .limit(1)
            .get();

        if (snapshot.docs.isEmpty) {
          snapshot = await profilesRef
              .where('username', isEqualTo: username)
              .limit(1)
              .get();
        }

        if (snapshot.docs.isEmpty) continue;
        final doc = snapshot.docs.first;
        final suggestion = _MentionSuggestion.fromFirestore(doc);
        if (suggestion == null) continue;
        if (suggestion.profileId == activeProfileId) continue;
        if (excludedProfileIds.contains(suggestion.profileId)) continue;
        if (!seenProfileIds.add(suggestion.profileId)) continue;

        profileIds.add(suggestion.profileId);
        uids.add(suggestion.uid);
        resolvedUsernames.add(suggestion.username);
      }

      return _ResolvedCommentMentions(
        profileIds: profileIds,
        uids: uids,
        usernames: resolvedUsernames,
      );
    } catch (error, stackTrace) {
      debugPrint('❌ Comment mention resolution failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return const _ResolvedCommentMentions.empty();
    }
  }

  Future<void> _sendComment() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    final contentError = ObjectionableContentFilter.validate(
      'comentário',
      text,
    );
    if (contentError != null) {
      AppSnackBar.showOverlayError(context, contentError);
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    final activeProfile = ref.read(profileProvider).value?.activeProfile;

    if (currentUser == null || activeProfile == null) {
      if (mounted) {
        AppSnackBar.showOverlayError(context, 'Faça login para comentar');
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
      final mentions = await _resolveCommentMentions(
        text: text,
        activeProfileId: activeProfile.profileId,
        activeUid: currentUser.uid,
      );
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
        mentionedProfileIds: mentions.profileIds,
        mentionedUids: mentions.uids,
        mentionedUsernames: mentions.usernames,
      );

      // Notificação in-app + push é criada pela Cloud Function
      // (sendCommentNotification) ao detectar o novo comentário.

      // Baixar o teclado para que o usuário veja o comentário enviado
      if (mounted) FocusScope.of(context).unfocus();

      HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted) {
        final message = e is ArgumentError
            ? (e.message?.toString() ?? 'Erro ao enviar comentário')
            : 'Erro ao enviar comentário';
        AppSnackBar.showOverlayError(context, message);
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
        AppSnackBar.showOverlayError(context, 'Você precisa estar logado.');
      }
      return;
    }

    if (comment.authorProfileId == activeProfileId) {
      if (mounted) {
        AppSnackBar.showOverlayError(
          context,
          'Não é possível bloquear a si mesmo.',
        );
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
        AppSnackBar.showOverlaySuccess(
          context,
          'Perfil bloqueado com sucesso.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showOverlayError(context, 'Erro ao bloquear perfil.');
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
        AppSnackBar.showOverlayError(context, 'Erro ao excluir comentário');
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
        AppSnackBar.showOverlayError(context, 'Erro ao curtir comentário');
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
        repliesByParent.putIfAbsent(c.parentCommentId!, () => []).add(c);
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

  /// Agenda rolagem até o comentário destacado (deep link) na primeira vez
  /// em que ele estiver presente na lista renderizada.
  void _scheduleHighlightScroll(List<CommentEntity> threaded) {
    if (_didScrollToHighlight) return;
    final target = widget.highlightCommentId;
    if (target == null || target.isEmpty) return;
    if (!threaded.any((c) => c.id == target)) return;

    _didScrollToHighlight = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final key = _itemKeys[target];
      final ctx = key?.currentContext;
      if (ctx == null) return;
      try {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: 0.2,
        );
      } catch (_) {
        // Lista pode não estar pronta ainda; o destaque ainda fica visível
        // por alguns segundos para o usuário localizar o comentário.
      }
      _highlightClearTimer?.cancel();
      _highlightClearTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() => _highlightedCommentId = null);
      });
    });
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

                      // Deep link: agendar rolagem até o comentário alvo
                      // assim que a lista estiver na tela.
                      _scheduleHighlightScroll(threaded);

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
                          final itemKey = _itemKeys.putIfAbsent(
                            comment.id,
                            () => GlobalKey(
                              debugLabel: 'comment_${comment.id}',
                            ),
                          );
                          final isHighlighted =
                              _highlightedCommentId == comment.id;

                          return AnimatedContainer(
                            key: itemKey,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                            color: isHighlighted
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : Colors.transparent,
                            child: CommentItemWidget(
                              comment: comment,
                              isOwnComment: isOwn,
                              canDelete: canDelete,
                              isReply: comment.isReply,
                              isLiked: activeProfileId.isNotEmpty &&
                                  comment.isLikedBy(activeProfileId),
                              likeCount: comment.likeCount,
                              onDelete: canDelete
                                  ? () => _deleteComment(comment)
                                  : null,
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
                              onMentionTap: (username) {
                                Navigator.pop(context);
                                context.pushProfileByUsername(username);
                              },
                            ),
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
                    if (_activeMention != null &&
                        (_mentionSuggestions.isNotEmpty || _isMentionSearching))
                      _MentionSuggestionsPanel(
                        suggestions: _mentionSuggestions,
                        isLoading: _isMentionSearching,
                        onSelect: _insertMention,
                      ),
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
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!),
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

class _ActiveMention {
  const _ActiveMention({
    required this.start,
    required this.end,
    required this.query,
  });

  final int start;
  final int end;
  final String query;
}

class _MentionSuggestion {
  const _MentionSuggestion({
    required this.profileId,
    required this.uid,
    required this.name,
    required this.username,
    this.photoUrl,
  });

  final String profileId;
  final String uid;
  final String name;
  final String username;
  final String? photoUrl;

  static _MentionSuggestion? fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final username = (data['username'] as String? ?? '').trim();
    if (username.isEmpty) return null;

    return _MentionSuggestion(
      profileId: doc.id,
      uid: data['uid'] as String? ?? '',
      name: data['name'] as String? ?? 'Usuário',
      username: username.replaceAll('@', ''),
      photoUrl: data['photoUrl'] as String?,
    );
  }
}

class _ResolvedCommentMentions {
  const _ResolvedCommentMentions({
    required this.profileIds,
    required this.uids,
    required this.usernames,
  });

  const _ResolvedCommentMentions.empty()
      : profileIds = const [],
        uids = const [],
        usernames = const [];

  final List<String> profileIds;
  final List<String> uids;
  final List<String> usernames;
}

class _MentionSuggestionsPanel extends StatelessWidget {
  const _MentionSuggestionsPanel({
    required this.suggestions,
    required this.isLoading,
    required this.onSelect,
  });

  final List<_MentionSuggestion> suggestions;
  final bool isLoading;
  final ValueChanged<_MentionSuggestion> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: isLoading && suggestions.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: AppRadioPulseLoader(
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: Colors.grey.shade100,
              ),
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                final photoUrl = suggestion.photoUrl?.trim() ?? '';
                final hasRemotePhoto = photoUrl.startsWith('http://') ||
                    photoUrl.startsWith('https://');

                return InkWell(
                  onTap: () => onSelect(suggestion),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          backgroundImage: hasRemotePhoto
                              ? CachedNetworkImageProvider(photoUrl)
                              : null,
                          child: hasRemotePhoto
                              ? null
                              : const Icon(
                                  Icons.person,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                suggestion.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '@${suggestion.username}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
