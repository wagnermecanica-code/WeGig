import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/widgets/mention_text.dart';
import 'package:flutter/material.dart';
import 'package:wegig_app/app/router/app_router.dart';
import 'package:wegig_app/features/post/presentation/pages/post_detail_page.dart';
import 'package:wegig_app/features/profile/presentation/pages/view_profile_page.dart';
import 'package:iconsax/iconsax.dart';

/// Widget de card de post para feed
/// Design: Foto à esquerda (35%), conteúdo à direita (65%)
/// Usado em home_page carrossel
class FeedPostCard extends StatelessWidget {
  const FeedPostCard({
    required this.post,
    required this.isActive,
    required this.isInterestSent,
    required this.onOpenOptions,
    super.key,
    this.currentActiveProfileId,
    this.onClose,
  });
  final PostEntity post;
  final bool isActive;
  final String? currentActiveProfileId;
  final bool isInterestSent;
  final VoidCallback onOpenOptions;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        post.type == 'band' ? AppColors.accent : AppColors.primary;
    final lightColor = primaryColor.withValues(alpha: 0.1);
    const textSecondary = AppColors.textSecondary;

    final isOwner = post.authorProfileId.isNotEmpty &&
        post.authorProfileId == currentActiveProfileId;

    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Foto à esquerda (35% da largura) com botão fechar
          Expanded(
            flex: 35,
            child: Stack(
              children: [
                Hero(
                  tag: 'post-photo-${post.id}',
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => PostDetailPage(postId: post.id),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child:
                            (post.photoUrl != null && post.photoUrl!.isNotEmpty)
                                ? CachedNetworkImage(
                                    imageUrl: post.photoUrl!,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 400,
                                    placeholder: (_, __) =>
                                        Container(color: lightColor),
                                    errorWidget: (_, __, ___) => ColoredBox(
                                      color: lightColor,
                                      child: Center(
                                        child: Icon(
                                          post.type == 'band'
                                              ? Iconsax.people
                                              : Iconsax.user,
                                          size: 40,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                  )
                                : ColoredBox(
                                    color: lightColor,
                                    child: Center(
                                      child: Icon(
                                        post.type == 'band'
                                            ? Iconsax.people
                                            : Iconsax.user,
                                        size: 40,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                      ),
                    ),
                  ),
                ),
                // Botão fechar no canto superior esquerdo
                if (onClose != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: onClose,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.close_circle,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Conteúdo à direita (65% da largura)
          Expanded(
            flex: 65,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome do perfil + botões
                  Row(
                    children: [
                      Icon(Iconsax.profile_circle,
                          size: 16, color: primaryColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => ViewProfilePage(
                                  userId: post.authorUid,
                                  profileId: post.authorProfileId,
                                ),
                              ),
                            );
                          },
                          child: FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('profiles')
                                .doc(post.authorProfileId)
                                .get(),
                            builder: (context, snapshot) {
                              final profileName = snapshot.hasData
                                  ? ((snapshot.data!.data()
                                              as Map<String, dynamic>?)?['name']
                                          as String?) ??
                                      'Perfil'
                                  : 'Perfil';
                              return Text(
                                profileName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: primaryColor,
                                  decoration: TextDecoration.underline,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                        ),
                      ),
                      // Botão interesse ou menu
                      if (isOwner)
                        GestureDetector(
                          onTap: onOpenOptions,
                          child: const Icon(Iconsax.more,
                              color: textSecondary, size: 20),
                        )
                      else
                        GestureDetector(
                          onTap: onOpenOptions,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isInterestSent
                                  ? Colors.pink.withValues(alpha: 0.15)
                                  : primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isInterestSent
                                  ? Iconsax.heart5
                                  : Iconsax.heart,
                              size: 16,
                              color:
                                  isInterestSent ? Colors.pink : primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Header clicável
                  GestureDetector(
                    onTap: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => PostDetailPage(postId: post.id),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(
                          post.type == 'band'
                              ? Iconsax.search_favorite
                              : Iconsax.musicnote,
                          size: 12,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            post.type == 'band'
                                ? 'Busca músico'
                                : 'Busca banda',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Instrumentos em scroll horizontal
                  if (post.type == 'musician' && post.instruments.isNotEmpty)
                    _buildHorizontalChips(
                      icon: Iconsax.music,
                      items: post.instruments,
                      color: primaryColor,
                    )
                  else if (post.type == 'band' &&
                      post.seekingMusicians.isNotEmpty)
                    _buildHorizontalChips(
                      icon: Iconsax.search_favorite,
                      items: post.seekingMusicians,
                      color: primaryColor,
                    ),
                  const SizedBox(height: 3),
                  // Nível
                  if (post.level.isNotEmpty)
                    _buildInfoRow(Iconsax.star, post.level,
                        primaryColor, textSecondary),
                  // Gêneros em scroll horizontal
                  if (post.genres.isNotEmpty)
                    _buildHorizontalChips(
                      icon: Iconsax.music_library_2,
                      items: post.genres,
                      color: primaryColor,
                    ),
                  // Mensagem do post
                  if (post.content.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Iconsax.message,
                            size: 11, color: textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: MentionText(
                            text: post.content,
                            style: const TextStyle(
                              fontSize: 9,
                              color: textSecondary,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            onMentionTap: (username) {
                              context.pushProfileByUsername(username);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Spacer(),
                  // Footer: distância + tempo
                  Row(
                    children: [
                      Icon(Iconsax.location,
                          size: 11, color: primaryColor),
                      const SizedBox(width: 3),
                      Text(
                        '${post.distanceKm?.toStringAsFixed(1) ?? '0.0'}km',
                        style: TextStyle(
                          fontSize: 11,
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Iconsax.clock,
                          size: 11, color: textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        _formatDaysAgo(post.createdAt),
                        style: const TextStyle(
                          fontSize: 10,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String text, Color iconColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 11, color: iconColor),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalChips({
    required IconData icon,
    required List<String> items,
    required Color color,
  }) {
    return SizedBox(
      height: 22,
      child: Row(
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 4),
              itemBuilder: (context, index) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    items[index],
                    style: TextStyle(
                      fontSize: 9,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8), // Margem segura direita
        ],
      ),
    );
  }

  String _formatDaysAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    return '${diff.inMinutes}m';
  }
}
