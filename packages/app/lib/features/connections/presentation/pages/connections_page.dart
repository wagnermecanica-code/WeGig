import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/utils/app_snackbar.dart';
import 'package:core_ui/utils/location_utils.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:wegig_app/config/app_config.dart';

import '../../../../app/router/app_router.dart';
import '../../domain/entities/entities.dart';
import '../controllers/connections_list_controller.dart';
import '../providers/connections_providers.dart';
import '../../../mensagens_new/presentation/providers/mensagens_new_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

class ConnectionsPage extends ConsumerStatefulWidget {
  const ConnectionsPage({super.key});

  @override
  ConsumerState<ConnectionsPage> createState() => _ConnectionsPageState();
}

enum _ConnectionsSortOption {
  recent,
  alphabetical,
}

class _ConnectionsPageState extends ConsumerState<ConnectionsPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, String> _profileUsernames = <String, String>{};
  final Map<String, String> _profileLocations = <String, String>{};
  String? _lastActiveProfileId;
  bool _isFetchingUsernames = false;
  String _searchQuery = '';
  _ConnectionsSortOption _sortOption = _ConnectionsSortOption.recent;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      unawaited(_logAnalyticsEvent(name: 'connections_page_viewed'));
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final nextQuery = _searchController.text;
    if (_searchQuery == nextQuery) {
      return;
    }

    setState(() {
      _searchQuery = nextQuery;
    });
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
    await _logAnalyticsEvent(name: 'connections_page_refreshed');
    await ref.read(connectionsListControllerProvider.notifier).refresh();
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

    final hadQuery = _searchController.text.isNotEmpty;
    if (hadQuery) {
      _searchController.clear();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _sortOption = _ConnectionsSortOption.recent;
      _profileUsernames.clear();
      _profileLocations.clear();
      if (!hadQuery) {
        _searchQuery = '';
      }
    });

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }

    unawaited(
      _logAnalyticsEvent(
        name: 'connections_active_profile_changed',
        parameters: {
          'previous_profile_id': previousProfileId,
          'next_profile_id': nextProfileId,
        },
      ),
    );
  }

  String _normalizedProfileQuery(String value) {
    return value.trim().toLowerCase().replaceFirst(RegExp('^@'), '');
  }

  int _connectionSearchScore(
    ConnectionEntity connection,
    String currentProfileId,
    String query,
  ) {
    final normalizedQuery = _normalizedProfileQuery(query);
    if (normalizedQuery.isEmpty) {
      return 0;
    }

    final otherProfileId = connection.getOtherProfileId(currentProfileId);
    final username =
        _normalizedProfileQuery(_profileUsernames[otherProfileId] ?? '');
    final name =
        connection.getOtherProfileName(currentProfileId).trim().toLowerCase();

    if (username == normalizedQuery && username.isNotEmpty) {
      return 700;
    }
    if (name == normalizedQuery && name.isNotEmpty) {
      return 650;
    }
    if (username.startsWith(normalizedQuery) && username.isNotEmpty) {
      return 550;
    }
    if (name.startsWith(normalizedQuery) && name.isNotEmpty) {
      return 500;
    }
    if (username.contains(normalizedQuery) && username.isNotEmpty) {
      return 400;
    }
    if (name.contains(normalizedQuery) && name.isNotEmpty) {
      return 350;
    }
    return 0;
  }

  List<ConnectionEntity> _filterConnections(
    List<ConnectionEntity> connections,
    String currentProfileId,
  ) {
    final normalizedQuery = _normalizedProfileQuery(_searchQuery);
    final baseConnections = List<ConnectionEntity>.of(connections);

    if (normalizedQuery.isEmpty) {
      return _sortConnections(baseConnections, currentProfileId);
    }

    final ranked = baseConnections
        .map(
          (connection) => (
            connection: connection,
            score: _connectionSearchScore(
              connection,
              currentProfileId,
              normalizedQuery,
            ),
          ),
        )
        .where((item) => item.score > 0)
        .toList(growable: false);

    ranked.sort((left, right) {
      final scoreComparison = right.score.compareTo(left.score);
      if (scoreComparison != 0) {
        return scoreComparison;
      }

      return right.connection.createdAt.compareTo(left.connection.createdAt);
    });

    return _sortConnections(
      ranked.map((item) => item.connection).toList(growable: false),
      currentProfileId,
    );
  }

  List<ConnectionEntity> _sortConnections(
    List<ConnectionEntity> connections,
    String currentProfileId,
  ) {
    final sorted = List<ConnectionEntity>.of(connections);

    switch (_sortOption) {
      case _ConnectionsSortOption.recent:
        sorted.sort(
          (left, right) => right.createdAt.compareTo(left.createdAt),
        );
      case _ConnectionsSortOption.alphabetical:
        sorted.sort((left, right) {
          final leftName =
              left.getOtherProfileName(currentProfileId).trim().toLowerCase();
          final rightName =
              right.getOtherProfileName(currentProfileId).trim().toLowerCase();
          final comparison = leftName.compareTo(rightName);
          if (comparison != 0) {
            return comparison;
          }

          return right.createdAt.compareTo(left.createdAt);
        });
    }

    return sorted;
  }

  Future<void> _primeSearchMetadata(
    List<ConnectionEntity> connections,
    String currentProfileId,
  ) async {
    if (_isFetchingUsernames) {
      return;
    }

    final missingProfileIds = connections
        .map((connection) =>
            connection.getOtherProfileId(currentProfileId).trim())
        .where((profileId) => profileId.isNotEmpty)
        .where(
          (profileId) =>
              !_profileUsernames.containsKey(profileId) ||
              !_profileLocations.containsKey(profileId),
        )
        .toSet()
        .toList(growable: false);

    if (missingProfileIds.isEmpty) {
      return;
    }

    _isFetchingUsernames = true;

    try {
      final fetched = <String, String>{};
      final fetchedLocations = <String, String>{};
      for (var index = 0; index < missingProfileIds.length; index += 10) {
        final chunk =
            missingProfileIds.skip(index).take(10).toList(growable: false);
        final snapshot = await FirebaseFirestore.instance
            .collection('profiles')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final username = (data['username'] as String?)?.trim() ?? '';
          final location = formatCleanLocation(
            neighborhood: data['neighborhood'] as String?,
            neighbourhood: data['neighbourhood'] as String?,
            city: data['city'] as String?,
            state: data['state'] as String?,
            fallback: '',
          );
          fetched[doc.id] = username;
          fetchedLocations[doc.id] = location;
        }
      }

      if (!mounted || (fetched.isEmpty && fetchedLocations.isEmpty)) {
        return;
      }

      setState(() {
        _profileUsernames.addAll(fetched);
        _profileLocations.addAll(fetchedLocations);
      });
    } catch (_) {
      // Search metadata failure must not affect list rendering.
    } finally {
      _isFetchingUsernames = false;
    }
  }

  Future<void> _requestLoadMore({required String source}) async {
    final currentState =
        ref.read(connectionsListControllerProvider).valueOrNull;
    if (currentState == null ||
        currentState.isLoadingMore ||
        !currentState.hasMore ||
        currentState.nextCursor == null ||
        currentState.nextCursor!.isEmpty) {
      return;
    }

    await _logAnalyticsEvent(
      name: 'connections_page_load_more_requested',
      parameters: {
        'source': source,
        'visible_count': currentState.connections.length,
      },
    );

    await ref.read(connectionsListControllerProvider.notifier).loadMore();
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
    final connectionsAsync = ref.watch(connectionsListControllerProvider);
    final actionState = ref.watch(connectionsActionsProvider);

    _lastActiveProfileId ??= activeProfile?.profileId;

    ref.listen<ProfileEntity?>(activeProfileProvider, (previous, next) {
      _handleActiveProfileChanged(next);
    });

    ref.listen<AsyncValue<void>>(
      connectionsActionsProvider,
      (previous, next) {
        if (next.hasError && !next.isLoading && previous?.error != next.error) {
          AppSnackBar.showError(
              context, _connectionActionErrorMessage(next.error));
          return;
        }

        if (previous?.isLoading == true && !next.isLoading && !next.hasError) {
          ref.read(connectionsListControllerProvider.notifier).refresh();
        }
      },
    );

    ref.listen<AsyncValue<ConnectionsListState>>(
      connectionsListControllerProvider,
      (previous, next) {
        final nextState = next.valueOrNull;
        final profileId = activeProfile?.profileId;
        if (nextState == null || profileId == null) {
          return;
        }

        unawaited(_primeSearchMetadata(nextState.connections, profileId));
      },
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Conexões',
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
          : connectionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _ConnectionsLoadError(
                onRetry: () => ref
                    .read(connectionsListControllerProvider.notifier)
                    .refresh(),
              ),
              data: (state) => RefreshIndicator(
                onRefresh: _handleRefresh,
                color: AppColors.primary,
                backgroundColor: Colors.white,
                child: _buildConnectionsContent(
                  context: context,
                  state: state,
                  activeProfile: activeProfile,
                  actionState: actionState,
                ),
              ),
            ),
    );
  }

  Widget _buildConnectionsContent({
    required BuildContext context,
    required ConnectionsListState state,
    required ProfileEntity? activeProfile,
    required AsyncValue<void> actionState,
  }) {
    if (activeProfile == null) {
      return const SizedBox.shrink();
    }

    final filteredConnections =
        _filterConnections(state.connections, activeProfile.profileId);
    final hasActiveSearch = _normalizedProfileQuery(_searchQuery).isNotEmpty;

    if (state.connections.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 48,
        ),
        children: const [
          Icon(
            Iconsax.profile_2user,
            size: 56,
            color: AppColors.textHint,
          ),
          SizedBox(height: 16),
          Text(
            'Você ainda não tem conexões ativas.',
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
      itemCount: filteredConnections.length + (hasActiveSearch ? 2 : 2),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _ConnectionsPageHeader(
              count: state.connections.length,
              visibleCount: filteredConnections.length,
              hasActiveSearch: hasActiveSearch,
              sortOption: _sortOption,
              searchController: _searchController,
              onClearSearch: _searchController.clear,
              onSortChanged: (value) {
                if (_sortOption == value) {
                  return;
                }

                setState(() {
                  _sortOption = value;
                });
                unawaited(
                  _logAnalyticsEvent(
                    name: 'connections_sort_changed',
                    parameters: {
                      'sort_option': value.name,
                    },
                  ),
                );
              },
            ),
          );
        }

        if (filteredConnections.isEmpty && index == 1) {
          return _ConnectionsSearchEmptyState(
            query: _searchQuery,
          );
        }

        final itemIndex = index - 1;
        if (itemIndex < filteredConnections.length) {
          final connection = filteredConnections[itemIndex];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ConnectionListItem(
              connection: connection,
              currentProfileId: activeProfile.profileId,
              isBusy: actionState.isLoading,
              username: _profileUsernames[
                  connection.getOtherProfileId(activeProfile.profileId)],
              location: _profileLocations[
                  connection.getOtherProfileId(activeProfile.profileId)],
              onOpenProfile: () {
                final otherProfileId = connection.getOtherProfileId(
                  activeProfile.profileId,
                );
                if (otherProfileId.isEmpty) {
                  return;
                }
                unawaited(
                  _logAnalyticsEvent(
                    name: 'connections_profile_opened',
                    parameters: {
                      'other_profile_id': otherProfileId,
                      'source': 'dedicated_page',
                    },
                  ),
                );
                context.pushProfile(otherProfileId);
              },
              onMessage: () => _openConversation(
                context,
                activeProfile,
                connection,
              ),
              onRemove: () => _confirmAndRemoveConnection(
                context,
                connection,
                activeProfile.profileId,
              ),
            ),
          );
        }

        return _ConnectionsPageFooter(
          hasMore: !hasActiveSearch && state.hasMore,
          isLoadingMore: !hasActiveSearch && state.isLoadingMore,
          errorMessage: hasActiveSearch ? null : state.errorMessage,
          onRetry: () => unawaited(_requestLoadMore(source: 'retry')),
        );
      },
    );
  }

  Future<void> _openConversation(
    BuildContext context,
    ProfileEntity activeProfile,
    ConnectionEntity connection,
  ) async {
    final otherProfileId =
        connection.getOtherProfileId(activeProfile.profileId);
    final otherProfileUid =
        connection.getOtherProfileUid(activeProfile.profileId);
    final otherProfileName =
        connection.getOtherProfileName(activeProfile.profileId);

    if (otherProfileId.trim().isEmpty || otherProfileUid.trim().isEmpty) {
      AppSnackBar.showError(
        context,
        'Não foi possível abrir a conversa com este perfil.',
      );
      return;
    }

    try {
      await _logAnalyticsEvent(
        name: 'connections_message_opened',
        parameters: {
          'other_profile_id': otherProfileId,
          'source': 'dedicated_page',
        },
      );

      final conversation =
          await ref.read(getOrCreateConversationNewUseCaseProvider)(
        currentProfileId: activeProfile.profileId,
        currentUid: activeProfile.uid,
        otherProfileId: otherProfileId,
        otherUid: otherProfileUid,
        currentProfileData: {
          'name': activeProfile.name,
          'photoUrl': activeProfile.photoUrl,
        },
        otherProfileData: {
          'name': otherProfileName,
          'photoUrl':
              connection.getOtherProfilePhotoUrl(activeProfile.profileId),
        },
      );

      if (!context.mounted) {
        return;
      }

      context.pushChatNew(
        conversation.id,
        otherUid: otherProfileUid,
        otherProfileId: otherProfileId,
        otherName: otherProfileName,
        otherPhotoUrl:
            connection.getOtherProfilePhotoUrl(activeProfile.profileId),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      AppSnackBar.showError(
        context,
        'Não foi possível abrir a conversa. Tente novamente.',
      );
    }
  }

  Future<void> _confirmAndRemoveConnection(
    BuildContext context,
    ConnectionEntity connection,
    String currentProfileId,
  ) async {
    final name = connection.getOtherProfileName(currentProfileId);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desconectar'),
        content: Text('Deseja remover $name das suas conexões?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Desconectar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _logAnalyticsEvent(
      name: 'connections_disconnect_confirmed',
      parameters: {
        'other_profile_id': connection.getOtherProfileId(currentProfileId),
        'source': 'dedicated_page',
      },
    );

    await ref.read(connectionsActionsProvider.notifier).removeConnection(
          connectionId: connection.id,
          otherProfileId: connection.getOtherProfileId(currentProfileId),
        );
  }
}

class _ConnectionsPageHeader extends StatelessWidget {
  const _ConnectionsPageHeader({
    required this.count,
    required this.visibleCount,
    required this.hasActiveSearch,
    required this.sortOption,
    required this.searchController,
    required this.onClearSearch,
    required this.onSortChanged,
  });

  final int count;
  final int visibleCount;
  final bool hasActiveSearch;
  final _ConnectionsSortOption sortOption;
  final TextEditingController searchController;
  final VoidCallback onClearSearch;
  final ValueChanged<_ConnectionsSortOption> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conexões',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasActiveSearch
                ? visibleCount == 1
                    ? '1 conexão encontrada entre $count carregadas.'
                    : '$visibleCount conexões encontradas entre $count carregadas.'
                : count == 1
                    ? '1 conexão carregada'
                    : '$count conexões carregadas',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar por nome ou @username',
              prefixIcon: const Icon(Iconsax.search_normal_1, size: 18),
              suffixIcon: searchController.text.trim().isEmpty
                  ? null
                  : IconButton(
                      onPressed: onClearSearch,
                      icon: const Icon(Iconsax.close_circle, size: 18),
                    ),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Recentes'),
                selected: sortOption == _ConnectionsSortOption.recent,
                onSelected: (_) => onSortChanged(_ConnectionsSortOption.recent),
              ),
              ChoiceChip(
                label: const Text('Nome A-Z'),
                selected: sortOption == _ConnectionsSortOption.alphabetical,
                onSelected: (_) =>
                    onSortChanged(_ConnectionsSortOption.alphabetical),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConnectionsSearchEmptyState extends StatelessWidget {
  const _ConnectionsSearchEmptyState({
    required this.query,
  });

  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(
              Iconsax.search_status,
              size: 40,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 12),
            const Text(
              'Nenhuma conexão encontrada.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'A busca atual por "$query" não encontrou nome ou username entre as conexões já carregadas.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionListItem extends StatelessWidget {
  const _ConnectionListItem({
    required this.connection,
    required this.currentProfileId,
    required this.isBusy,
    required this.username,
    required this.location,
    required this.onOpenProfile,
    required this.onMessage,
    required this.onRemove,
  });

  final ConnectionEntity connection;
  final String currentProfileId;
  final bool isBusy;
  final String? username;
  final String? location;
  final VoidCallback onOpenProfile;
  final Future<void> Function() onMessage;
  final Future<void> Function() onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = connection.getOtherProfileName(currentProfileId);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpenProfile,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              _ConnectionAvatar(
                label: name,
                photoUrl: connection.getOtherProfilePhotoUrl(currentProfileId),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if ((username ?? '').trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '@${username!.trim()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if ((location ?? '').trim().isNotEmpty)
                      Text(
                        location!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: isBusy ? null : onMessage,
                icon: const Icon(Iconsax.message),
                tooltip: 'Mensagem',
                color: AppColors.primary,
              ),
              IconButton(
                onPressed: isBusy ? null : onRemove,
                icon: const Icon(Icons.link_off_rounded),
                tooltip: 'Desconectar',
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionAvatar extends StatelessWidget {
  const _ConnectionAvatar({
    required this.label,
    this.photoUrl,
  });

  final String label;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = photoUrl?.trim() ?? '';
    final fallback = CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.primary,
      child: Text(
        _initialForName(label),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    if (trimmedUrl.isEmpty) {
      return fallback;
    }

    return CachedNetworkImage(
      imageUrl: trimmedUrl,
      imageBuilder: (_, imageProvider) => CircleAvatar(
        radius: 24,
        backgroundImage: imageProvider,
      ),
      placeholder: (_, __) => fallback,
      errorWidget: (_, __, ___) => fallback,
    );
  }
}

class _ConnectionsPageFooter extends StatelessWidget {
  const _ConnectionsPageFooter({
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
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null && errorMessage!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          children: [
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (!hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'Você chegou ao fim da sua rede atual.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return const SizedBox(height: 20);
  }
}

class _ConnectionsLoadError extends StatelessWidget {
  const _ConnectionsLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.warning_2, size: 52, color: AppColors.error),
            const SizedBox(height: 12),
            const Text(
              'Não foi possível carregar suas conexões.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

String _initialForName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  return trimmed[0].toUpperCase();
}

String _connectionActionErrorMessage(Object? error) {
  if (error is StateError) {
    return error.message ?? 'Não foi possível atualizar a conexão.';
  }

  return 'Não foi possível concluir a ação.';
}
