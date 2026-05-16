import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/utils/app_snackbar.dart';
import 'package:core_ui/widgets/app_loading_overlay.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../domain/entities/entities.dart';
import '../providers/mensagens_new_providers.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';

/// Bottom sheet estilo Instagram para encaminhar um post para uma conversa.
///
/// Exibe a lista de conversas recentes do usuário, com busca,
/// e permite enviar o post como mensagem do tipo `sharedPost`.
class SharePostBottomSheet extends ConsumerStatefulWidget {
  const SharePostBottomSheet({
    required this.post,
    super.key,
  });

  /// O post a ser compartilhado
  final PostEntity post;

  /// Abre o bottom sheet e retorna true se o post foi enviado
  static Future<bool?> show(BuildContext context, PostEntity post) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SharePostBottomSheet(post: post),
    );
  }

  @override
  ConsumerState<SharePostBottomSheet> createState() =>
      _SharePostBottomSheetState();
}

class _SharePostBottomSheetState extends ConsumerState<SharePostBottomSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _sendingToConversationId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeProfile = ref.watch(activeProfileProvider);
    if (activeProfile == null) {
      return const SizedBox.shrink();
    }

    final conversationsAsync = ref.watch(
      conversationsNewStreamProvider(
        profileId: activeProfile.profileId,
        profileUid: activeProfile.uid,
        limit: 50,
      ),
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Título
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Iconsax.send_1, size: 20, color: AppColors.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Enviar para...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context, false),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Preview do post
          _buildPostPreview(),

          const Divider(height: 1),

          // Campo de busca
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Buscar conversa...',
                hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                prefixIcon: Icon(Iconsax.search_normal,
                    size: 18, color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surfaceContainerHighest,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Lista de conversas
          Expanded(
            child: conversationsAsync.when(
              data: (conversations) {
                // Filtrar por busca
                final filtered = _searchQuery.isEmpty
                    ? conversations
                    : conversations.where((c) {
                        final other = c.getOtherParticipantData(
                            activeProfile.profileId);
                        final name = c.isGroup
                            ? (c.groupName ?? '')
                            : (other?.name ?? '');
                        return name.toLowerCase().contains(_searchQuery);
                      }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Iconsax.message,
                            size: 48, color: AppColors.textHint),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Nenhuma conversa encontrada'
                              : 'Sem resultados para "$_searchQuery"',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final conv = filtered[index];
                    return _buildConversationTile(conv, activeProfile);
                  },
                );
              },
              loading: () => const Center(
                child: AppRadioPulseLoader(size: 44),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Erro ao carregar conversas',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostPreview() {
    final post = widget.post;
    final firstPhoto = post.photoUrls.isNotEmpty
        ? post.photoUrls.first
        : post.photoUrl;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Thumbnail
          if (firstPhoto != null && firstPhoto.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: firstPhoto,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                memCacheWidth: 96,
                memCacheHeight: 96,
                placeholder: (_, __) => Container(
                  width: 48,
                  height: 48,
                  color: AppColors.surfaceVariant,
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: AppColors.surfaceVariant,
                  child: const Icon(Iconsax.image, size: 20),
                ),
              ),
            )
          else
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _postTypeColor(post.type).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_postTypeIcon(post.type),
                  size: 20, color: _postTypeColor(post.type)),
            ),
          const SizedBox(width: 10),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title ?? post.authorName ?? 'Post',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  post.content,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(
    ConversationNewEntity conv,
    dynamic activeProfile,
  ) {
    final isGroup = conv.isGroup || conv.participantProfiles.length > 2;
    final other = conv.getOtherParticipantData(activeProfile.profileId);
    final name = isGroup
        ? (conv.groupName ?? 'Grupo')
        : (other?.name ?? 'Usuário');
    final photoUrl = isGroup ? conv.groupPhotoUrl : other?.photoUrl;
    final isSending = _sendingToConversationId == conv.id;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: _buildAvatar(name, photoUrl, isGroup),
      title: Text(
        name,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: conv.lastMessage.isNotEmpty
          ? Text(
              conv.lastMessage,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: isSending
          ? const SizedBox(
              width: 24,
              height: 24,
              child: AppRadioPulseLoader(size: 24),
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Enviar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
      onTap: isSending ? null : () => _sendPostToConversation(conv),
    );
  }

  Widget _buildAvatar(String name, String? photoUrl, bool isGroup) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.surfaceVariant,
      child: photoUrl != null && photoUrl.isNotEmpty
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: photoUrl,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                memCacheWidth: 88,
                memCacheHeight: 88,
                placeholder: (_, __) => _buildAvatarPlaceholder(name, isGroup),
                errorWidget: (_, __, ___) =>
                    _buildAvatarPlaceholder(name, isGroup),
              ),
            )
          : _buildAvatarPlaceholder(name, isGroup),
    );
  }

  Widget _buildAvatarPlaceholder(String name, bool isGroup) {
    if (isGroup) {
      return Icon(Iconsax.people, size: 20, color: AppColors.textSecondary);
    }
    return Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  Future<void> _sendPostToConversation(ConversationNewEntity conv) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) return;

    setState(() => _sendingToConversationId = conv.id);
    HapticFeedback.lightImpact();

    try {
      final post = widget.post;
      final firstPhoto = post.photoUrls.isNotEmpty
          ? post.photoUrls.first
          : post.photoUrl;

      final postData = <String, dynamic>{
        'postId': post.id,
        'postType': post.type,
        'postContent': post.content,
        if (post.title != null) 'postTitle': post.title,
        if (post.authorName != null) 'postAuthorName': post.authorName,
        if (post.authorPhotoUrl != null)
          'postAuthorPhotoUrl': post.authorPhotoUrl,
        if (firstPhoto != null) 'postFirstPhotoUrl': firstPhoto,
        'postCity': post.city,
        if (post.instruments.isNotEmpty) 'postInstruments': post.instruments,
        if (post.genres.isNotEmpty) 'postGenres': post.genres,
      };

      final useCase = ref.read(sendSharedPostMessageNewUseCaseProvider);

      await useCase(
        conversationId: conv.id,
        senderId: currentUser.uid,
        senderProfileId: activeProfile.profileId,
        postData: postData,
        senderName: activeProfile.name,
        senderPhotoUrl: activeProfile.photoUrl,
      );

      HapticFeedback.mediumImpact();

      if (mounted) {
        Navigator.pop(context, true);
        AppSnackBar.showSuccess(context, 'Post enviado!');
      }
    } catch (e) {
      setState(() => _sendingToConversationId = null);
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao enviar post');
      }
    }
  }

  /// Ícone correspondente ao tipo de post
  static IconData _postTypeIcon(String type) {
    switch (type) {
      case 'musician':
        return Iconsax.user;
      case 'band':
        return Iconsax.people;
      case 'hiring':
        return Iconsax.briefcase;
      case 'sales':
        return Iconsax.tag;
      default:
        return Iconsax.note_1;
    }
  }

  /// Cor correspondente ao tipo de post
  static Color _postTypeColor(String type) {
    switch (type) {
      case 'musician':
        return AppColors.musicianColor;
      case 'band':
        return AppColors.bandColor;
      case 'hiring':
        return AppColors.hiringColor;
      case 'sales':
        return AppColors.salesColor;
      default:
        return AppColors.primary;
    }
  }
}
