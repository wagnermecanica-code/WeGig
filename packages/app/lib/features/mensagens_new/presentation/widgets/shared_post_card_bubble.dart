import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../domain/entities/entities.dart';

/// Card de post compartilhado exibido dentro do chat bubble.
///
/// Mostra uma miniatura do post com:
/// - Foto do post (se houver)
/// - Nome do autor
/// - Preview do conteúdo (2 linhas)
/// - Cidade
/// - Tappable → navega para o PostDetailPage
class SharedPostCardBubble extends StatelessWidget {
  const SharedPostCardBubble({
    required this.message,
    required this.isMine,
    this.onPostTap,
    super.key,
  });

  final MessageNewEntity message;
  final bool isMine;
  final void Function(String postId)? onPostTap;

  Map<String, dynamic> get _meta => message.metadata;
  String get _postId => _meta['postId'] as String? ?? '';
  String get _postType => _meta['postType'] as String? ?? '';
  String get _postContent => _meta['postContent'] as String? ?? '';
  String? get _postTitle => _meta['postTitle'] as String?;
  String? get _postAuthorName => _meta['postAuthorName'] as String?;
  String? get _postAuthorPhotoUrl => _meta['postAuthorPhotoUrl'] as String?;
  String? get _postFirstPhotoUrl => _meta['postFirstPhotoUrl'] as String?;
  String get _postCity => _meta['postCity'] as String? ?? '';

  String get _typeLabel {
    switch (_postType) {
      case 'musician':
        return 'Músico';
      case 'band':
        return 'Banda';
      case 'hiring':
        return 'Contratante';
      case 'sales':
        return 'Venda';
      default:
        return 'Post';
    }
  }

  Color get _typeColor {
    switch (_postType) {
      case 'musician':
        return AppColors.musicianColor;
      case 'band':
        return AppColors.accent;
      case 'hiring':
        return AppColors.success;
      case 'sales':
        return Colors.orange;
      default:
        return AppColors.musicianColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _postId.isNotEmpty ? () => onPostTap?.call(_postId) : null,
      child: Container(
        margin: const EdgeInsets.all(4),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: isMine
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMine
                ? Colors.white.withValues(alpha: 0.2)
                : AppColors.border,
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Imagem do post (se houver)
            if (_postFirstPhotoUrl != null && _postFirstPhotoUrl!.isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(11)),
                child: CachedNetworkImage(
                  imageUrl: _postFirstPhotoUrl!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  memCacheWidth: 520,
                  placeholder: (_, __) => Container(
                    height: 120,
                    color: AppColors.surfaceVariant,
                    child: const Center(
                      child:
                          CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 120,
                    color: AppColors.surfaceVariant,
                    child: Icon(Iconsax.image,
                        color: AppColors.textHint, size: 28),
                  ),
                ),
              ),

            // Conteúdo
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Autor + tipo
                  Row(
                    children: [
                      // Avatar do autor
                      if (_postAuthorPhotoUrl != null &&
                          _postAuthorPhotoUrl!.isNotEmpty)
                        ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: _postAuthorPhotoUrl!,
                            width: 20,
                            height: 20,
                            fit: BoxFit.cover,
                            memCacheWidth: 40,
                            memCacheHeight: 40,
                            errorWidget: (_, __, ___) =>
                                _buildAuthorPlaceholder(),
                          ),
                        )
                      else
                        _buildAuthorPlaceholder(),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _postAuthorName ?? 'Anônimo',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isMine
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Badge de tipo
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _typeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _typeLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isMine
                                ? Colors.white.withValues(alpha: 0.9)
                                : _typeColor,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Título (se sales)
                  if (_postTitle != null && _postTitle!.isNotEmpty) ...[
                    Text(
                      _postTitle!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isMine ? Colors.white : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                  ],

                  // Conteúdo
                  Text(
                    _postContent,
                    style: TextStyle(
                      fontSize: 12,
                      color: isMine
                          ? Colors.white.withValues(alpha: 0.85)
                          : AppColors.textSecondary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Cidade
                  if (_postCity.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Iconsax.location,
                          size: 12,
                          color: isMine
                              ? Colors.white60
                              : AppColors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _postCity,
                            style: TextStyle(
                              fontSize: 11,
                              color: isMine
                                  ? Colors.white60
                                  : AppColors.textHint,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // "Toque para abrir"
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Iconsax.export_1,
                        size: 11,
                        color: isMine
                            ? Colors.white54
                            : AppColors.accent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Toque para abrir',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isMine
                              ? Colors.white54
                              : AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorPlaceholder() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          (_postAuthorName ?? '?').isNotEmpty
              ? (_postAuthorName ?? '?')[0].toUpperCase()
              : '?',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
