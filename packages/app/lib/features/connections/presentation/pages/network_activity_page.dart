import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wegig_app/config/app_config.dart';

import '../../../../app/router/app_router.dart';
import '../controllers/network_activity_list_controller.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

class NetworkActivityPage extends ConsumerStatefulWidget {
  const NetworkActivityPage({super.key});

  @override
  ConsumerState<NetworkActivityPage> createState() =>
      _NetworkActivityPageState();
}

enum _NetworkActivitySortOption {
  recent,
  nearby,
}

class _NetworkActivityPageState extends ConsumerState<NetworkActivityPage> {
  final ScrollController _scrollController = ScrollController();
  String? _lastActiveProfileId;
  _NetworkActivitySortOption _sortOption = _NetworkActivitySortOption.recent;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      unawaited(_logAnalyticsEvent(name: 'network_activity_page_viewed'));
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent * 0.8) {
      return;
    }

    unawaited(_requestLoadMore(source: 'scroll'));
  }

  Future<void> _handleRefresh() async {
    await _logAnalyticsEvent(name: 'network_activity_page_refreshed');
    await ref.read(networkActivityListControllerProvider.notifier).refresh();
  }

  void _handleActiveProfileChanged(ProfileEntity? activeProfile) {
    final nextProfileId = activeProfile?.profileId;
    if (_lastActiveProfileId == nextProfileId) {
      return;
    }

    final previousProfileId = _lastActiveProfileId;
    _lastActiveProfileId = nextProfileId;

    if (previousProfileId == null ||
        nextProfileId == null ||
        previousProfileId == nextProfileId) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _sortOption = _NetworkActivitySortOption.recent;
    });

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }

    unawaited(
      _logAnalyticsEvent(
        name: 'network_activity_active_profile_changed',
        parameters: {
          'previous_profile_id': previousProfileId,
          'next_profile_id': nextProfileId,
        },
      ),
    );
  }

  List<PostEntity> _refinePosts(List<PostEntity> posts) {
    final sorted = List<PostEntity>.of(posts);
    switch (_sortOption) {
      case _NetworkActivitySortOption.recent:
        sorted.sort((left, right) => right.createdAt.compareTo(left.createdAt));
      case _NetworkActivitySortOption.nearby:
        sorted.sort((left, right) {
          final leftDistance = left.distanceKm ?? double.infinity;
          final rightDistance = right.distanceKm ?? double.infinity;
          final distanceComparison = leftDistance.compareTo(rightDistance);
          if (distanceComparison != 0) {
            return distanceComparison;
          }

          return right.createdAt.compareTo(left.createdAt);
        });
    }

    return sorted;
  }

  Future<void> _requestLoadMore({required String source}) async {
    final currentState =
        ref.read(networkActivityListControllerProvider).valueOrNull;
    if (currentState == null ||
        currentState.isLoadingMore ||
        !currentState.hasMore ||
        currentState.nextCursor == null) {
      return;
    }

    await _logAnalyticsEvent(
      name: 'network_activity_page_load_more_requested',
      parameters: {
        'source': source,
        'visible_count': currentState.posts.length,
      },
    );

    await ref.read(networkActivityListControllerProvider.notifier).loadMore();
  }

  Future<void> _logAnalyticsEvent({
    required String name,
    Map<String, Object> parameters = const {},
  }) async {
    if (!AppConfig.enableAnalytics) {
      return;
    }

    try {
      final activeProfile = ref.read(activeProfileProvider);
      final enrichedParameters = <String, Object>{
        if (activeProfile != null) 'active_profile_id': activeProfile.profileId,
        if (activeProfile != null)
          'active_profile_type': activeProfile.profileType.value,
        ...parameters,
      };

      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: enrichedParameters,
      );
    } catch (_) {
      // Analytics failure must not affect the network flow.
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeProfile = ref.watch(activeProfileProvider);
    final activityAsync = ref.watch(networkActivityListControllerProvider);

    _lastActiveProfileId ??= activeProfile?.profileId;

    ref.listen<ProfileEntity?>(activeProfileProvider, (previous, next) {
      _handleActiveProfileChanged(next);
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Atividade da rede',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: activeProfile == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Selecione um perfil.'),
              ),
            )
          : activityAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _NetworkActivityLoadError(
                onRetry: () => ref
                    .read(networkActivityListControllerProvider.notifier)
                    .refresh(),
              ),
              data: (state) => RefreshIndicator(
                onRefresh: _handleRefresh,
                color: AppColors.primary,
                backgroundColor: Colors.white,
                child: _buildActivityContent(
                  context: context,
                  state: state,
                ),
              ),
            ),
    );
  }

  Widget _buildActivityContent({
    required BuildContext context,
    required NetworkActivityListState state,
  }) {
    final refinedPosts = _refinePosts(state.posts);

    if (state.posts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 48,
        ),
        children: const [
          Icon(
            Icons.trending_up_rounded,
            size: 56,
            color: AppColors.textHint,
          ),
          SizedBox(height: 16),
          Text(
            'Sua rede ainda não publicou novidades visíveis aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: refinedPosts.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _NetworkActivityHeader(
              count: state.posts.length,
              visibleCount: refinedPosts.length,
              sortOption: _sortOption,
              onSortChanged: (value) {
                if (_sortOption == value) {
                  return;
                }

                setState(() {
                  _sortOption = value;
                });
                unawaited(
                  _logAnalyticsEvent(
                    name: 'network_activity_sort_changed',
                    parameters: {
                      'sort_option': value.name,
                    },
                  ),
                );
              },
            ),
          );
        }

        final itemIndex = index - 1;
        if (itemIndex < refinedPosts.length) {
          final post = refinedPosts[itemIndex];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _NetworkActivityListItem(
              post: post,
              onOpenPost: () {
                unawaited(
                  _logAnalyticsEvent(
                    name: 'network_activity_post_opened',
                    parameters: {
                      'post_id': post.id,
                      'author_profile_id': post.authorProfileId,
                      'source': 'dedicated_page',
                    },
                  ),
                );
                context.pushPostDetail(post.id);
              },
              onOpenProfile: () {
                unawaited(
                  _logAnalyticsEvent(
                    name: 'network_activity_profile_opened',
                    parameters: {
                      'post_id': post.id,
                      'author_profile_id': post.authorProfileId,
                      'source': 'dedicated_page',
                    },
                  ),
                );
                context.pushProfile(post.authorProfileId);
              },
            ),
          );
        }

        return _NetworkActivityFooter(
          hasMore: state.hasMore,
          isLoadingMore: state.isLoadingMore,
          errorMessage: state.errorMessage,
          onRetry: () => unawaited(_requestLoadMore(source: 'retry')),
        );
      },
    );
  }
}

class _NetworkActivityHeader extends StatelessWidget {
  const _NetworkActivityHeader({
    required this.count,
    required this.visibleCount,
    required this.sortOption,
    required this.onSortChanged,
  });

  final int count;
  final int visibleCount;
  final _NetworkActivitySortOption sortOption;
  final ValueChanged<_NetworkActivitySortOption> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Atividade',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            count == 1
                ? '1 publicação carregada até agora.'
                : '$count publicações carregadas até agora.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Recentes'),
                selected: sortOption == _NetworkActivitySortOption.recent,
                onSelected: (_) =>
                    onSortChanged(_NetworkActivitySortOption.recent),
              ),
              ChoiceChip(
                label: const Text('Mais próximos'),
                selected: sortOption == _NetworkActivitySortOption.nearby,
                onSelected: (_) =>
                    onSortChanged(_NetworkActivitySortOption.nearby),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NetworkActivityListItem extends StatelessWidget {
  const _NetworkActivityListItem({
    required this.post,
    required this.onOpenPost,
    required this.onOpenProfile,
  });

  final PostEntity post;
  final VoidCallback onOpenPost;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locationLabel = _networkActivityLocationLabel(post);
    final locationTextStyle = theme.textTheme.bodySmall?.copyWith(
      color: AppColors.textSecondary,
      fontSize: 12,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onOpenPost,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: onOpenProfile,
                  child: _AuthorAvatar(post: post),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: onOpenProfile,
                        child: Text(
                          post.authorName?.trim().isNotEmpty == true
                              ? post.authorName!.trim()
                              : 'Conexão da sua rede',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _ActivityTypeChip(post: post),
                    ],
                  ),
                ),
                Text(
                  _formatDate(post.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _networkActivitySnippet(post),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (locationLabel.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                locationLabel,
                                style: locationTextStyle,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Padding(
                  padding: EdgeInsets.only(bottom: 1),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar({required this.post});

  final PostEntity post;

  @override
  Widget build(BuildContext context) {
    final photoUrl = post.authorPhotoUrl?.trim() ?? '';
    final label = post.authorName?.trim() ?? '';

    if (photoUrl.isEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.primary,
        child: Text(
          _initialForName(label),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: CachedNetworkImage(
        imageUrl: photoUrl,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        placeholder: (context, _) => CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.surface,
        ),
        errorWidget: (context, _, __) => CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primary,
          child: Text(
            _initialForName(label),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityTypeChip extends StatelessWidget {
  const _ActivityTypeChip({required this.post});

  final PostEntity post;

  @override
  Widget build(BuildContext context) {
    final type = post.type.trim().toLowerCase();
    final Color chipColor;
    final IconData chipIcon;

    switch (type) {
      case 'band':
        chipColor = AppColors.bandColor;
        chipIcon = Icons.groups_rounded;
      case 'venue':
        chipColor = AppColors.spaceColor;
        chipIcon = Icons.storefront_rounded;
      case 'event':
        chipColor = AppColors.accent;
        chipIcon = Icons.event_rounded;
      case 'sales':
        chipColor = AppColors.salesColor;
        chipIcon = Icons.sell_rounded;
      case 'hiring':
        chipColor = AppColors.hiringPurple;
        chipIcon = Icons.work_outline_rounded;
      default:
        chipColor = AppColors.textSecondary;
        chipIcon = Icons.article_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chipIcon, size: 10, color: chipColor),
          const SizedBox(width: 3),
          Text(
            _networkActivityTypeLabel(post),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkActivityFooter extends StatelessWidget {
  const _NetworkActivityFooter({
    required this.hasMore,
    required this.isLoadingMore,
    required this.errorMessage,
    required this.onRetry,
  });

  final bool hasMore;
  final bool isLoadingMore;
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null && errorMessage!.trim().isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Center(
          child: Column(
            children: [
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (!hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'Você chegou ao fim da atividade visível da sua rede.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return const SizedBox(height: 8);
  }
}

class _NetworkActivityLoadError extends StatelessWidget {
  const _NetworkActivityLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            const Text(
              'Não foi possível carregar a atividade da rede.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tente novamente para buscar as publicações mais recentes da sua rede.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Recarregar'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();
  return '$day/$month/$year';
}

String _initialForName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  return trimmed[0].toUpperCase();
}

String _networkActivitySnippet(PostEntity post) {
  final title = post.title?.trim() ?? '';
  if (title.isNotEmpty) {
    return title;
  }

  final content = post.content.trim();
  if (content.isNotEmpty) {
    return content;
  }

  if (post.instruments.isNotEmpty) {
    return 'Busca ${post.instruments.join(', ')}';
  }

  return 'Post recente publicado na sua rede.';
}

String _networkActivityTypeLabel(PostEntity post) {
  switch (post.type.trim().toLowerCase()) {
    case 'band':
      return 'Banda procurando conexões';
    case 'venue':
      return 'Espaço em atividade';
    case 'event':
      return 'Evento publicado';
    case 'sales':
      return 'Oferta publicada';
    case 'hiring':
      return 'Oportunidade publicada';
    default:
      return 'Novo post';
  }
}

String _networkActivityLocationLabel(PostEntity post) {
  final city = post.city.trim();
  final distanceKm = post.distanceKm;

  if (city.isEmpty && distanceKm == null) {
    return '';
  }

  final distanceLabel = distanceKm == null
      ? ''
      : distanceKm >= 10
          ? '${distanceKm.toStringAsFixed(0)} km de você'
          : '${distanceKm.toStringAsFixed(1)} km de você';

  if (city.isEmpty) {
    return distanceLabel;
  }

  if (distanceLabel.isEmpty) {
    return city;
  }

  return '$city • $distanceLabel';
}
