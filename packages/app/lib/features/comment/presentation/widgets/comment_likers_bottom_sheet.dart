import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/widgets/app_loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wegig_app/app/router/app_router.dart';
import 'package:wegig_app/core/cache/image_cache_manager.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';

/// Bottom sheet que exibe a lista de perfis que curtiram um comentário.
///
/// Recebe a lista de profileIds ([likedBy]) e carrega os dados de cada perfil
/// via [ProfileRemoteDataSource.getProfileById].
class CommentLikersBottomSheet extends ConsumerStatefulWidget {
  const CommentLikersBottomSheet({
    required this.likedByProfileIds,
    super.key,
  });

  final List<String> likedByProfileIds;

  /// Abre o bottom sheet de quem curtiu
  static Future<void> show(
    BuildContext context,
    List<String> likedByProfileIds,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          CommentLikersBottomSheet(likedByProfileIds: likedByProfileIds),
    );
  }

  @override
  ConsumerState<CommentLikersBottomSheet> createState() =>
      _CommentLikersBottomSheetState();
}

class _CommentLikersBottomSheetState
    extends ConsumerState<CommentLikersBottomSheet> {
  final List<_LikerProfile> _likers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final dataSource = ref.read(profileRemoteDataSourceProvider);

    final futures = widget.likedByProfileIds.map((profileId) async {
      try {
        final profile = await dataSource.getProfileById(profileId);
        if (profile != null) {
          return _LikerProfile(
            profileId: profile.profileId,
            name: profile.name,
            photoUrl: profile.photoUrl,
          );
        }
      } catch (_) {
        // Perfil pode ter sido deletado — ignorar
      }
      return null;
    });

    final results = await Future.wait(futures);
    final likers = results.whereType<_LikerProfile>().toList(growable: false);

    if (mounted) {
      setState(() {
        _likers.addAll(likers);
        _isLoading = false;
      });
      _warmProfilePhotos(likers);
    }
  }

  void _warmProfilePhotos(List<_LikerProfile> likers) {
    final urls = likers
        .map((liker) => liker.photoUrl?.trim() ?? '')
        .where((url) => url.isNotEmpty)
        .toSet()
        .take(12);

    for (final url in urls) {
      unawaited(_cacheProfilePhoto(url));
    }
  }

  Future<void> _cacheProfilePhoto(String url) async {
    try {
      await WeGigImageCacheManager.instance.downloadFile(url);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

    // Responsivo: horizontal padding escala com largura da tela
    final horizontalPadding = screenWidth < 360 ? 12.0 : 16.0;
    // Título escala para telas muito pequenas
    final titleFontSize = screenWidth < 360 ? 16.0 : 18.0;
    // Avatar radius escala
    final avatarRadius = screenWidth < 360 ? 18.0 : 20.0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.5,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
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

            // Título
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                children: [
                  const Icon(Icons.favorite, size: 20, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Curtidas (${widget.likedByProfileIds.length})',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
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

            // Lista de perfis
            if (_isLoading && _likers.isEmpty)
              Padding(
                padding: EdgeInsets.only(
                  top: 32,
                  bottom: bottomPadding > 0 ? bottomPadding : 32,
                ),
                child: const Center(
                  child: AppRadioPulseLoader(
                    size: 44,
                    color: AppColors.primary,
                  ),
                ),
              )
            else if (_likers.isEmpty && !_isLoading)
              Padding(
                padding: EdgeInsets.only(
                  top: 32,
                  bottom: bottomPadding > 0 ? bottomPadding : 32,
                ),
                child: const Center(
                  child: Text(
                    'Nenhuma curtida ainda',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.only(
                    bottom: bottomPadding > 0 ? bottomPadding : 16,
                  ),
                  itemCount: _likers.length,
                  itemBuilder: (context, index) {
                    final liker = _likers[index];
                    final photoUrl = liker.photoUrl?.trim() ?? '';
                    final avatarSize = avatarRadius * 2;
                    final fallbackAvatar = CircleAvatar(
                      radius: avatarRadius,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.person,
                        size: avatarRadius,
                        color: AppColors.primary,
                      ),
                    );

                    return ListTile(
                      leading: photoUrl.isEmpty
                          ? fallbackAvatar
                          : ClipOval(
                              child: CachedNetworkImage(
                                cacheManager: WeGigImageCacheManager.instance,
                                imageUrl: photoUrl,
                                width: avatarSize,
                                height: avatarSize,
                                fit: BoxFit.cover,
                                memCacheWidth: avatarSize.ceil() * 2,
                                memCacheHeight: avatarSize.ceil() * 2,
                                fadeInDuration: Duration.zero,
                                placeholder: (_, __) => fallbackAvatar,
                                errorWidget: (_, __, ___) => fallbackAvatar,
                              ),
                            ),
                      title: Text(
                        liker.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        // Pop também o comments bottom sheet
                        if (Navigator.of(context).canPop()) {
                          Navigator.pop(context);
                        }
                        context.pushProfile(liker.profileId);
                      },
                      dense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 2,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Modelo simples para dados de perfil do liker
class _LikerProfile {
  const _LikerProfile({
    required this.profileId,
    required this.name,
    this.photoUrl,
  });

  final String profileId;
  final String name;
  final String? photoUrl;
}
