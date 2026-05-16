import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:core_ui/features/profile/domain/entities/profile_type.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/utils/app_snackbar.dart';
import 'package:core_ui/utils/music_constants.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:wegig_app/config/app_config.dart';

import '../../../../app/router/app_router.dart';
import '../../domain/entities/entities.dart';
import '../providers/connections_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

class ConnectionSuggestionsPage extends ConsumerStatefulWidget {
  const ConnectionSuggestionsPage({super.key});

  @override
  ConsumerState<ConnectionSuggestionsPage> createState() =>
      _ConnectionSuggestionsPageState();
}

class _ConnectionSuggestionsPageState
    extends ConsumerState<ConnectionSuggestionsPage> {
  static const int _initialFetchLimit = 24;
  static const int _fetchStep = 24;
  static const int _minFilteredProbeLimit = 72;
  static const int _maxFilteredProbeLimit = 240;

  final ScrollController _scrollController = ScrollController();

  String? _lastActiveProfileId;
  List<ConnectionSuggestionEntity> _suggestions = const [];
  bool _isInitialLoading = true;
  bool _isBatchLoading = false;
  bool _hasMoreSuggestions = true;
  String? _errorMessage;
  int _requestedLimit = _initialFetchLimit;
  int _requestEpoch = 0;
  int _pendingLoadRequests = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      unawaited(_logAnalyticsEvent(name: 'connection_suggestions_page_viewed'));
      unawaited(_loadSuggestions(source: 'initial'));
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
    // Avoid false-positive pagination when content does not overflow.
    if (position.maxScrollExtent <= 0) {
      return;
    }

    // Trigger pagination only when user is close to the bottom.
    if (position.extentAfter > 240) {
      return;
    }

    _loadMore(source: 'scroll');
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

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }

    unawaited(
      _logAnalyticsEvent(
        name: 'connection_suggestions_active_profile_changed',
        parameters: {
          'previous_profile_id': previousProfileId,
          'next_profile_id': nextProfileId,
        },
      ),
    );
    _resetPagination(clearSuggestions: true);
    unawaited(_loadSuggestions(source: 'profile_change'));
  }

  Future<void> _handleRefresh() async {
    _resetPagination();
    await _logAnalyticsEvent(name: 'connection_suggestions_page_refreshed');
    await _loadSuggestions(source: 'refresh');
  }

  void _applySuggestionFilters({
    required ConnectionSuggestionFiltersState next,
    required String analyticsEventName,
    Map<String, Object> analyticsParameters = const {},
    required String source,
    bool forceReload = false,
  }) {
    final current = ref.read(connectionSuggestionFiltersProvider);
    final didCriteriaChange =
        !setEquals(current.selectedInstruments, next.selectedInstruments) ||
            !setEquals(current.selectedGenres, next.selectedGenres) ||
            !setEquals(
              current.selectedProfileTypeValues,
              next.selectedProfileTypeValues,
            ) ||
            current.locationFilter != next.locationFilter ||
            current.commonConnectionFilter != next.commonConnectionFilter;
    final didChange =
        didCriteriaChange || current.sortOption != next.sortOption;

    if (!didChange && !forceReload) {
      return;
    }

    ref.read(connectionSuggestionFiltersProvider.notifier).update(next);

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    unawaited(
      _logAnalyticsEvent(
        name: analyticsEventName,
        parameters: analyticsParameters,
      ),
    );

    if (didCriteriaChange || forceReload) {
      _resetPagination(clearSuggestions: true);
      unawaited(_loadSuggestions(source: source));
      return;
    }

    if (_suggestions.isEmpty && !_isInitialLoading && !_isBatchLoading) {
      unawaited(_loadSuggestions(source: source));
    }
  }

  void _handleClearSuggestionFilters() {
    ref.read(connectionSuggestionFiltersProvider.notifier).clear();

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }

    _resetPagination(clearSuggestions: true);
    unawaited(_loadSuggestions(source: 'filters_cleared'));

    unawaited(
        _logAnalyticsEvent(name: 'connection_suggestions_filters_cleared'));
  }

  void _resetPagination({bool clearSuggestions = false}) {
    if (!mounted) {
      _requestedLimit = _initialFetchLimit;
      _hasMoreSuggestions = true;
      if (clearSuggestions) {
        _suggestions = const [];
        _isInitialLoading = true;
        _isBatchLoading = false;
        _errorMessage = null;
      }
      return;
    }

    setState(() {
      _requestedLimit = _initialFetchLimit;
      _hasMoreSuggestions = true;
      if (clearSuggestions) {
        _suggestions = const [];
        _isInitialLoading = true;
        _isBatchLoading = false;
        _errorMessage = null;
      }
    });
  }

  void _loadMore({required String source}) {
    if (_isInitialLoading || _isBatchLoading || !_hasMoreSuggestions) {
      return;
    }

    setState(() {
      _requestedLimit += _fetchStep;
      _isBatchLoading = true;
      _errorMessage = null;
    });

    unawaited(_loadSuggestions(source: '${source}_paginate'));
  }

  Future<void> _loadSuggestions({
    required String source,
  }) async {
    _pendingLoadRequests += 1;
    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) {
      if (!mounted) {
        if (_pendingLoadRequests > 0) {
          _pendingLoadRequests -= 1;
        }
        return;
      }

      setState(() {
        _suggestions = const [];
        _isInitialLoading = false;
        _isBatchLoading = false;
        _hasMoreSuggestions = true;
        _errorMessage = null;
        _requestedLimit = _initialFetchLimit;
      });
      if (_pendingLoadRequests > 0) {
        _pendingLoadRequests -= 1;
      }
      return;
    }

    final requestId = ++_requestEpoch;
    final hasExistingSuggestions = _suggestions.isNotEmpty;

    if (mounted) {
      setState(() {
        _isInitialLoading = !hasExistingSuggestions;
        _isBatchLoading = hasExistingSuggestions;
        _errorMessage = null;
      });
    }

    try {
      await _logAnalyticsEvent(
        name: 'connection_suggestions_load_requested',
        parameters: {
          'source': source,
          'requested_limit': _requestedLimit,
        },
      );

      final useCase = ref.read(loadConnectionSuggestionsUseCaseProvider);
      final filters = ref.read(connectionSuggestionFiltersProvider);
      final fetched = await useCase(
        profileId: activeProfile.profileId,
        profileUid: activeProfile.uid,
        currentCity: activeProfile.city,
        currentProfileType: activeProfile.profileType.value,
        currentLevel: activeProfile.level,
        currentInstruments: activeProfile.instruments ?? const <String>[],
        currentGenres: activeProfile.genres ?? const <String>[],
        limit: _requestedLimit,
        filterProfileTypes: filters.selectedProfileTypeValues.toList(),
        filterInstruments: filters.selectedInstruments.toList(),
        filterGenres: filters.selectedGenres.toList(),
        filterSameCity:
            filters.locationFilter == SuggestionLocationFilter.sameCity,
        filterWithCommonConnections: filters.commonConnectionFilter ==
            SuggestionCommonConnectionFilter.withCommonConnections,
      );
      final excludedProfileIds =
          ref.read(connectionSuggestionExcludedProfileIdsProvider);
      final filtered = fetched
          .where(
            (suggestion) => !excludedProfileIds.contains(
              suggestion.profile.profileId,
            ),
          )
          .toList(growable: false);

      final hadActiveFilterCriteria =
          filters.selectedProfileTypeValues.isNotEmpty ||
              filters.selectedInstruments.isNotEmpty ||
              filters.selectedGenres.isNotEmpty ||
              filters.locationFilter != SuggestionLocationFilter.any ||
              filters.commonConnectionFilter !=
                  SuggestionCommonConnectionFilter.any;
      final previousSuggestionCount = _suggestions.length;
      final isPaginatedLoad = source.endsWith('_paginate');
      final canProbeMoreFilteredSuggestions = hadActiveFilterCriteria &&
          _requestedLimit < _maxFilteredProbeLimit &&
          ((!isPaginatedLoad && filtered.length < _requestedLimit) ||
              filtered.length > previousSuggestionCount ||
              _requestedLimit < _minFilteredProbeLimit);

      if (!mounted || requestId != _requestEpoch) {
        return;
      }

      setState(() {
        _suggestions = filtered;
        _isInitialLoading = false;
        _isBatchLoading = false;
        _hasMoreSuggestions = fetched.length >= _requestedLimit ||
            canProbeMoreFilteredSuggestions;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted || requestId != _requestEpoch) {
        return;
      }

      setState(() {
        _isInitialLoading = false;
        _isBatchLoading = false;
        _errorMessage = 'Não foi possível carregar sugestões.';
      });
    } finally {
      if (_pendingLoadRequests > 0) {
        _pendingLoadRequests -= 1;
      }

      if (mounted &&
          _pendingLoadRequests == 0 &&
          (_isInitialLoading || _isBatchLoading)) {
        setState(() {
          _isInitialLoading = false;
          _isBatchLoading = false;
        });
      }
    }
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
      // Analytics failure must not affect the page.
    }
  }

  String _connectionActionErrorMessage(Object? error) {
    if (error is StateError) {
      return error.message ?? 'Nao foi possivel atualizar a conexao.';
    }

    return 'Nao foi possivel atualizar a conexao.';
  }

  bool _matchesSuggestionFilters({
    required ConnectionSuggestionEntity suggestion,
    required ProfileEntity activeProfile,
    required ConnectionSuggestionFiltersState filters,
  }) {
    final profile = suggestion.profile;

    if (filters.selectedProfileTypeValues.isNotEmpty &&
        !filters.selectedProfileTypeValues
            .contains(profile.profileType.value)) {
      return false;
    }

    if (filters.locationFilter == SuggestionLocationFilter.sameCity &&
        activeProfile.city.trim().isNotEmpty &&
        profile.city.trim().toLowerCase() !=
            activeProfile.city.trim().toLowerCase()) {
      return false;
    }

    if (filters.commonConnectionFilter ==
            SuggestionCommonConnectionFilter.withCommonConnections &&
        suggestion.commonConnectionsCount <= 0) {
      return false;
    }

    if (filters.selectedInstruments.isNotEmpty) {
      final profileInstruments = (profile.instruments ?? const <String>[])
          .map((item) => item.trim().toLowerCase())
          .where((item) => item.isNotEmpty)
          .toSet();
      final selectedInstruments = filters.selectedInstruments
          .map((item) => item.trim().toLowerCase())
          .where((item) => item.isNotEmpty)
          .toSet();
      if (profileInstruments.intersection(selectedInstruments).isEmpty) {
        return false;
      }
    }

    if (filters.selectedGenres.isNotEmpty) {
      final profileGenres = (profile.genres ?? const <String>[])
          .map((item) => item.trim().toLowerCase())
          .where((item) => item.isNotEmpty)
          .toSet();
      final selectedGenres = filters.selectedGenres
          .map((item) => item.trim().toLowerCase())
          .where((item) => item.isNotEmpty)
          .toSet();
      if (profileGenres.intersection(selectedGenres).isEmpty) {
        return false;
      }
    }

    return true;
  }

  List<ConnectionSuggestionEntity> _sortedSuggestions(
    List<ConnectionSuggestionEntity> suggestions,
    ConnectionSuggestionFiltersState filters,
  ) {
    if (filters.sortOption == SuggestionSortOption.relevance) {
      return suggestions;
    }

    final sorted = [...suggestions];
    sorted.sort((left, right) {
      switch (filters.sortOption) {
        case SuggestionSortOption.relevance:
          return right.score.compareTo(left.score);
        case SuggestionSortOption.commonConnections:
          final commonConnectionsComparison = right.commonConnectionsCount
              .compareTo(left.commonConnectionsCount);
          if (commonConnectionsComparison != 0) {
            return commonConnectionsComparison;
          }
          return right.score.compareTo(left.score);
        case SuggestionSortOption.recent:
          final createdAtComparison =
              right.profile.createdAt.compareTo(left.profile.createdAt);
          if (createdAtComparison != 0) {
            return createdAtComparison;
          }
          return right.score.compareTo(left.score);
      }
    });

    return sorted;
  }

  Future<void> _openSingleSelectBottomSheet<T>({
    required String title,
    required List<T> options,
    required T selectedValue,
    required String Function(T value) labelBuilder,
    required void Function(T selected) onSelected,
  }) async {
    final result = await showModalBottomSheet<T>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ...options.map(
                (option) => RadioListTile<T>(
                  value: option,
                  groupValue: selectedValue,
                  activeColor: AppColors.primary,
                  title: Text(labelBuilder(option)),
                  onChanged: (_) => Navigator.of(context).pop(option),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result == null) {
      return;
    }

    onSelected(result);
  }

  Future<void> _openSuggestionFilterBottomSheet({
    required String title,
    required List<String> options,
    required Set<String> selectedValues,
    required void Function(Set<String> selected) onSelected,
  }) async {
    final tempSelected = <String>{...selectedValues};

    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.72,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(<String>{}),
                            child: const Text('Limpar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options[index];
                            final isSelected = tempSelected.contains(option);
                            return CheckboxListTile(
                              dense: true,
                              value: isSelected,
                              activeColor: AppColors.primary,
                              title: Text(option),
                              onChanged: (selected) {
                                setModalState(() {
                                  if (selected == true) {
                                    tempSelected.add(option);
                                  } else {
                                    tempSelected.remove(option);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context)
                                  .pop(<String>{...tempSelected}),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Aplicar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null) {
      return;
    }

    onSelected(result);
  }

  Future<void> _openProfileTypeFilterBottomSheet(
    ConnectionSuggestionFiltersState filters,
  ) async {
    final tempSelection = <String>{...filters.selectedProfileTypeValues};

    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Filtrar por tipo de perfil',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(<String>{}),
                            child: const Text('Limpar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView(
                          children: ProfileType.values.map((profileType) {
                            final value = profileType.value;
                            return CheckboxListTile(
                              dense: true,
                              value: tempSelection.contains(value),
                              activeColor: AppColors.primary,
                              title: Text(profileType.label),
                              onChanged: (selected) {
                                setModalState(() {
                                  if (selected == true) {
                                    tempSelection.add(value);
                                  } else {
                                    tempSelection.remove(value);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context)
                                  .pop(<String>{...tempSelection}),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Aplicar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null) {
      return;
    }

    final currentFilters = ref.read(connectionSuggestionFiltersProvider);
    _applySuggestionFilters(
      next: currentFilters.copyWith(
        selectedProfileTypeValues: {...result},
      ),
      analyticsEventName: 'connection_suggestions_filter_profile_type_changed',
      analyticsParameters: {
        'selected_count': result.length,
      },
      source: 'profile_type_filter_changed',
    );
  }

  Widget _buildSuggestionFiltersRow(ConnectionSuggestionFiltersState filters) {
    final activeFiltersCount = [
      filters.selectedProfileTypeValues.isNotEmpty,
      filters.selectedInstruments.isNotEmpty,
      filters.selectedGenres.isNotEmpty,
      filters.locationFilter != SuggestionLocationFilter.any,
      filters.commonConnectionFilter != SuggestionCommonConnectionFilter.any,
      filters.sortOption != SuggestionSortOption.relevance,
    ].where((isActive) => isActive).length;

    ActionChip buildChip({
      required IconData icon,
      required String label,
      required bool isActive,
      required VoidCallback onPressed,
    }) {
      final foregroundColor = isActive ? Colors.white : AppColors.primary;
      return ActionChip(
        avatar: Icon(icon, size: 15, color: foregroundColor),
        label: Text(
          label,
          style: TextStyle(
            color: foregroundColor,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        backgroundColor:
            isActive ? AppColors.primary : AppColors.primary.withOpacity(0.08),
        side: BorderSide(
          color: isActive
              ? AppColors.primary
              : AppColors.primary.withOpacity(0.22),
        ),
        shape: const StadiumBorder(),
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.setting_4, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Refinar sugestões',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              if (filters.hasAnyFilterActive) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$activeFiltersCount ativos',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (filters.hasAnyFilterActive)
                TextButton.icon(
                  onPressed: _handleClearSuggestionFilters,
                  icon: const Icon(Iconsax.close_circle, size: 14),
                  label: const Text('Limpar'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                buildChip(
                  icon: Iconsax.profile_2user,
                  label: filters.selectedProfileTypeValues.isEmpty
                      ? 'Tipo'
                      : 'Tipo (${filters.selectedProfileTypeValues.length})',
                  isActive: filters.selectedProfileTypeValues.isNotEmpty,
                  onPressed: () => _openProfileTypeFilterBottomSheet(filters),
                ),
                const SizedBox(width: 8),
                buildChip(
                  icon: Iconsax.musicnote,
                  label: filters.selectedInstruments.isEmpty
                      ? 'Instrumentos'
                      : 'Instrumentos (${filters.selectedInstruments.length})',
                  isActive: filters.selectedInstruments.isNotEmpty,
                  onPressed: () => _openSuggestionFilterBottomSheet(
                    title: 'Filtrar por instrumentos',
                    options: MusicConstants.instrumentOptions,
                    selectedValues: filters.selectedInstruments,
                    onSelected: (selected) {
                      final currentFilters =
                          ref.read(connectionSuggestionFiltersProvider);
                      if (setEquals(
                        selected,
                        currentFilters.selectedInstruments,
                      )) {
                        return;
                      }
                      _applySuggestionFilters(
                        next: currentFilters.copyWith(
                          selectedInstruments: {...selected},
                        ),
                        analyticsEventName:
                            'connection_suggestions_filter_instruments_changed',
                        analyticsParameters: {
                          'selected_count': selected.length,
                        },
                        source: 'instrument_filter_changed',
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                buildChip(
                  icon: Iconsax.music_library_2,
                  label: filters.selectedGenres.isEmpty
                      ? 'Gêneros'
                      : 'Gêneros (${filters.selectedGenres.length})',
                  isActive: filters.selectedGenres.isNotEmpty,
                  onPressed: () => _openSuggestionFilterBottomSheet(
                    title: 'Filtrar por gêneros',
                    options: MusicConstants.genreOptions,
                    selectedValues: filters.selectedGenres,
                    onSelected: (selected) {
                      final currentFilters =
                          ref.read(connectionSuggestionFiltersProvider);
                      if (setEquals(selected, currentFilters.selectedGenres)) {
                        return;
                      }
                      _applySuggestionFilters(
                        next: currentFilters.copyWith(
                          selectedGenres: {...selected},
                        ),
                        analyticsEventName:
                            'connection_suggestions_filter_genres_changed',
                        analyticsParameters: {
                          'selected_count': selected.length,
                        },
                        source: 'genre_filter_changed',
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                buildChip(
                  icon: Iconsax.location,
                  label: filters.locationFilter ==
                          SuggestionLocationFilter.sameCity
                      ? 'Mesma cidade'
                      : 'Cidade',
                  isActive:
                      filters.locationFilter != SuggestionLocationFilter.any,
                  onPressed: () =>
                      _openSingleSelectBottomSheet<SuggestionLocationFilter>(
                    title: 'Filtrar por localização',
                    options: SuggestionLocationFilter.values,
                    selectedValue: filters.locationFilter,
                    labelBuilder: (value) {
                      switch (value) {
                        case SuggestionLocationFilter.any:
                          return 'Qualquer cidade';
                        case SuggestionLocationFilter.sameCity:
                          return 'Mesma cidade';
                      }
                    },
                    onSelected: (selected) {
                      final currentFilters =
                          ref.read(connectionSuggestionFiltersProvider);
                      if (selected == currentFilters.locationFilter) {
                        return;
                      }
                      _applySuggestionFilters(
                        next: currentFilters.copyWith(locationFilter: selected),
                        analyticsEventName:
                            'connection_suggestions_filter_location_changed',
                        analyticsParameters: {
                          'value': selected.name,
                        },
                        source: 'location_filter_changed',
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                buildChip(
                  icon: Iconsax.profile_add,
                  label: filters.commonConnectionFilter ==
                          SuggestionCommonConnectionFilter.withCommonConnections
                      ? 'Em comum'
                      : 'Conexões',
                  isActive: filters.commonConnectionFilter !=
                      SuggestionCommonConnectionFilter.any,
                  onPressed: () => _openSingleSelectBottomSheet<
                      SuggestionCommonConnectionFilter>(
                    title: 'Filtrar por conexões em comum',
                    options: SuggestionCommonConnectionFilter.values,
                    selectedValue: filters.commonConnectionFilter,
                    labelBuilder: (value) {
                      switch (value) {
                        case SuggestionCommonConnectionFilter.any:
                          return 'Sem filtro';
                        case SuggestionCommonConnectionFilter
                              .withCommonConnections:
                          return 'Apenas com conexões em comum';
                      }
                    },
                    onSelected: (selected) {
                      final currentFilters =
                          ref.read(connectionSuggestionFiltersProvider);
                      if (selected == currentFilters.commonConnectionFilter) {
                        return;
                      }
                      _applySuggestionFilters(
                        next: currentFilters.copyWith(
                          commonConnectionFilter: selected,
                        ),
                        analyticsEventName:
                            'connection_suggestions_filter_common_connections_changed',
                        analyticsParameters: {
                          'value': selected.name,
                        },
                        source: 'common_connections_filter_changed',
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                buildChip(
                  icon: Iconsax.sort,
                  label: filters.sortOption == SuggestionSortOption.relevance
                      ? 'Relevância'
                      : filters.sortOption ==
                              SuggestionSortOption.commonConnections
                          ? 'Mais conexões'
                          : 'Mais recente',
                  isActive:
                      filters.sortOption != SuggestionSortOption.relevance,
                  onPressed: () =>
                      _openSingleSelectBottomSheet<SuggestionSortOption>(
                    title: 'Ordenar sugestões',
                    options: SuggestionSortOption.values,
                    selectedValue: filters.sortOption,
                    labelBuilder: (value) {
                      switch (value) {
                        case SuggestionSortOption.relevance:
                          return 'Relevância';
                        case SuggestionSortOption.commonConnections:
                          return 'Mais conexões em comum';
                        case SuggestionSortOption.recent:
                          return 'Mais recente';
                      }
                    },
                    onSelected: (selected) {
                      final currentFilters =
                          ref.read(connectionSuggestionFiltersProvider);
                      if (selected == currentFilters.sortOption) {
                        return;
                      }
                      _applySuggestionFilters(
                        next: currentFilters.copyWith(sortOption: selected),
                        analyticsEventName:
                            'connection_suggestions_sort_changed',
                        analyticsParameters: {
                          'value': selected.name,
                        },
                        source: 'sort_changed',
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeProfile = ref.watch(activeProfileProvider);
    final actionState = ref.watch(connectionsActionsProvider);
    final dismissedProfileIds = ref.watch(dismissedSuggestionsProvider);
    final excludedProfileIds =
        ref.watch(connectionSuggestionExcludedProfileIdsProvider);
    final suggestionFilters = ref.watch(connectionSuggestionFiltersProvider);

    _lastActiveProfileId ??= activeProfile?.profileId;

    ref.listen<ProfileEntity?>(activeProfileProvider, (previous, next) {
      _handleActiveProfileChanged(next);
    });

    ref.listen<AsyncValue<void>>(
      connectionsActionsProvider,
      (previous, next) {
        if (!next.hasError || next.isLoading) {
          return;
        }

        if (previous?.error == next.error || !mounted) {
          return;
        }

        AppSnackBar.showError(
          context,
          _connectionActionErrorMessage(next.error),
        );
      },
    );

    final availableSuggestions = _suggestions
        .where(
          (suggestion) =>
              !dismissedProfileIds.contains(suggestion.profile.profileId) &&
              !excludedProfileIds.contains(suggestion.profile.profileId),
        )
        .toList(growable: false);

    final visibleSuggestions = activeProfile == null
        ? availableSuggestions
        : _sortedSuggestions(
            availableSuggestions
                .where(
                  (suggestion) => _matchesSuggestionFilters(
                    suggestion: suggestion,
                    activeProfile: activeProfile,
                    filters: suggestionFilters,
                  ),
                )
                .toList(growable: false),
            suggestionFilters,
          );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Sugestões',
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
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              color: AppColors.primary,
              backgroundColor: Colors.white,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth >= 1000
                      ? 4
                      : constraints.maxWidth >= 700
                          ? 3
                          : 2;
                  final childAspectRatio = crossAxisCount >= 3 ? 0.66 : 0.56;

                  return CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Perfis ordenados pelas afinidades ja calculadas para o seu perfil ativo.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: _buildSuggestionFiltersRow(suggestionFilters),
                        ),
                      ),
                      if (_isInitialLoading && _suggestions.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_errorMessage != null && _suggestions.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _SuggestionsLoadError(
                            message: _errorMessage!,
                            onRetry: () => _loadSuggestions(source: 'retry'),
                          ),
                        )
                      else if (visibleSuggestions.isEmpty && _isBatchLoading)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (visibleSuggestions.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _SuggestionsEmptyState(
                            canLoadMore: suggestionFilters.hasAnyFilterActive &&
                                _hasMoreSuggestions,
                            onLoadMore: () => _loadMore(
                              source: 'filtered_empty',
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: childAspectRatio,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final suggestion = visibleSuggestions[index];
                                return _ConnectionSuggestionCard(
                                  suggestion: suggestion,
                                  isBusy: actionState.isLoading,
                                  onViewProfile: () async {
                                    await _logAnalyticsEvent(
                                      name:
                                          'connection_suggestions_profile_opened',
                                      parameters: {
                                        'target_profile_id':
                                            suggestion.profile.profileId,
                                        'target_profile_type': suggestion
                                            .profile.profileType.value,
                                      },
                                    );

                                    if (!context.mounted) {
                                      return;
                                    }

                                    context.pushProfile(
                                      suggestion.profile.profileId,
                                    );
                                  },
                                  onConnect: () => ref
                                      .read(connectionsActionsProvider.notifier)
                                      .sendRequest(
                                        recipientProfile: suggestion.profile,
                                      ),
                                  onDismiss: () => ref
                                      .read(
                                          dismissedSuggestionsProvider.notifier)
                                      .dismiss(suggestion.profile.profileId),
                                );
                              },
                              childCount: visibleSuggestions.length,
                            ),
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: _SuggestionsPageFooter(
                          hasError: _errorMessage != null &&
                              !_isInitialLoading &&
                              _suggestions.isNotEmpty,
                          hasMoreSuggestions: _hasMoreSuggestions,
                          isLoadingMore: _isBatchLoading,
                          onLoadMore: () => _loadMore(source: 'footer'),
                          onRetry: () => _loadSuggestions(source: 'retry'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}

class _ConnectionSuggestionCard extends ConsumerWidget {
  const _ConnectionSuggestionCard({
    required this.suggestion,
    required this.isBusy,
    required this.onViewProfile,
    required this.onConnect,
    required this.onDismiss,
  });

  final ConnectionSuggestionEntity suggestion;
  final bool isBusy;
  final VoidCallback onViewProfile;
  final Future<void> Function() onConnect;
  final VoidCallback onDismiss;

  static const double _headerH = 68;
  static const double _avatarRadius = 48;
  static const double _borderW = 4;
  static const double _avatarCircleTop = _headerH - (_avatarRadius * 2 * 0.4);
  static const double _avatarContainerTop = _avatarCircleTop - _borderW;
  static const double _stackH =
      _avatarContainerTop + (_avatarRadius + _borderW) * 2;

  IconData _profileTypeIcon(ProfileType profileType) {
    switch (profileType) {
      case ProfileType.band:
        return Iconsax.people;
      case ProfileType.space:
        return Iconsax.building;
      case ProfileType.technician:
        return Iconsax.headphone;
      case ProfileType.contractor:
        return Iconsax.briefcase;
      case ProfileType.musician:
        return Iconsax.user;
    }
  }

  Widget _buildProfileTypeHeaderBadge(ProfileType profileType) {
    const iconLight = Color(0xFFF3F4F6);
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        _profileTypeIcon(profileType),
        size: 16,
        color: iconLight,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(
      effectiveConnectionStatusProvider(suggestion.profile.profileId),
    );
    final activeProfile = ref.watch(activeProfileProvider);
    final canLoadCommonConnections =
        activeProfile != null && suggestion.profile.uid.trim().isNotEmpty;
    final commonConnectionsAsync = canLoadCommonConnections
        ? ref.watch(
            commonConnectionsProvider(
              profileId: activeProfile!.profileId,
              profileUid: activeProfile.uid,
              otherProfileId: suggestion.profile.profileId,
              otherProfileUid: suggestion.profile.uid,
              limit: 3,
            ),
          )
        : const AsyncValue<List<CommonConnectionEntity>>.data(
            <CommonConnectionEntity>[],
          );
    final commonConnectionsData = commonConnectionsAsync.asData?.value;
    final commonConnectionHero =
        (commonConnectionsData != null && commonConnectionsData.isNotEmpty)
            ? commonConnectionsData.first
            : null;

    var commonConnectionsCount = suggestion.commonConnectionsCount;
    if (commonConnectionHero != null && commonConnectionsCount < 1) {
      commonConnectionsCount = 1;
    }
    final commonHeroName = commonConnectionHero?.name.trim();
    final hasCommonHeroName =
        commonHeroName != null && commonHeroName.isNotEmpty;
    final additionalCommonConnections =
        (commonConnectionsCount - 1).clamp(0, 9999);
    final commonConnectionsLabel = hasCommonHeroName
        ? (additionalCommonConnections == 0
            ? '$commonHeroName em comum'
            : additionalCommonConnections == 1
                ? '$commonHeroName + 1 conexão em comum'
                : '$commonHeroName + $additionalCommonConnections conexões em comum')
        : (commonConnectionsCount == 1
            ? '1 conexão em comum'
            : '$commonConnectionsCount conexões em comum');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onViewProfile,
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          SizedBox(
                            height: _stackH,
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  height: _headerH,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          const Color(0xFF111827),
                                          const Color(0xFF374151),
                                          const Color(0xFF6B7280),
                                        ],
                                        stops: [0.0, 0.58, 1.0],
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: 0,
                                          child: IgnorePointer(
                                            child: Container(
                                              height: 1,
                                              color: Colors.white
                                                  .withValues(alpha: 0.18),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          left: 8,
                                          child: _buildProfileTypeHeaderBadge(
                                            suggestion.profile.profileType,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: _avatarContainerTop,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Container(
                                      width: (_avatarRadius + _borderW) * 2,
                                      height: (_avatarRadius + _borderW) * 2,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                      ),
                                      padding: const EdgeInsets.all(_borderW),
                                      child: ClipOval(
                                        child: _SuggestionAvatar(
                                          profile: suggestion.profile,
                                          radius: _avatarRadius,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 5, 12, 4),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    suggestion.profile.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                      height: 1.25,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    suggestion.reason,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textSecondary,
                                      height: 1.25,
                                    ),
                                  ),
                                  if (commonConnectionsCount > 0) ...[
                                    const SizedBox(height: 3),
                                    SizedBox(
                                      width: double.infinity,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          if (commonConnectionHero != null) ...[
                                            CircleAvatar(
                                              radius: 9,
                                              backgroundColor: Colors.white,
                                              child: ClipOval(
                                                child: _CommonConnectionAvatar(
                                                  name:
                                                      commonConnectionHero.name,
                                                  photoUrl: commonConnectionHero
                                                      .photoUrl,
                                                  radius: 9,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                          ],
                                          Flexible(
                                            child: Text(
                                              commonConnectionsLabel,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onDismiss,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: _ConnectionSuggestionActionButton(
              suggestion: suggestion,
              statusAsync: statusAsync,
              isBusy: isBusy,
              onConnect: onConnect,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionSuggestionActionButton extends ConsumerWidget {
  const _ConnectionSuggestionActionButton({
    required this.suggestion,
    required this.statusAsync,
    required this.isBusy,
    required this.onConnect,
  });

  final ConnectionSuggestionEntity suggestion;
  final AsyncValue<ConnectionStatusEntity> statusAsync;
  final bool isBusy;
  final Future<void> Function() onConnect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return statusAsync.when(
      loading: () => _buildButton(
        label: 'Rede',
        onPressed: null,
      ),
      error: (_, __) => _buildButton(
        label: suggestion.profile.allowConnectionRequests
            ? 'Conectar'
            : 'Convites fechados',
        onPressed: suggestion.profile.allowConnectionRequests && !isBusy
            ? onConnect
            : null,
      ),
      data: (status) {
        switch (status.status) {
          case ConnectionRelationshipStatus.none:
            return _buildButton(
              label: suggestion.profile.allowConnectionRequests
                  ? 'Conectar'
                  : 'Convites fechados',
              onPressed: suggestion.profile.allowConnectionRequests && !isBusy
                  ? onConnect
                  : null,
            );
          case ConnectionRelationshipStatus.pendingSent:
            return _buildButton(
              label: 'Convite enviado',
              onPressed: null,
            );
          case ConnectionRelationshipStatus.pendingReceived:
            return _buildButton(
              label: 'Aceitar',
              onPressed: isBusy || status.requestId == null
                  ? null
                  : () => ref
                      .read(connectionsActionsProvider.notifier)
                      .acceptRequest(
                        requestId: status.requestId!,
                        otherProfileId: suggestion.profile.profileId,
                      ),
            );
          case ConnectionRelationshipStatus.connected:
            return _buildButton(
              label: 'Conectado',
              onPressed: null,
            );
        }
      },
    );
  }

  Widget _buildButton({
    required String label,
    required Future<void> Function()? onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        side: const BorderSide(
          width: 1.5,
          color: AppColors.primary,
        ),
        foregroundColor: AppColors.primary,
        padding: EdgeInsets.zero,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _SuggestionsPageFooter extends StatelessWidget {
  const _SuggestionsPageFooter({
    required this.hasError,
    required this.hasMoreSuggestions,
    required this.isLoadingMore,
    required this.onLoadMore,
    required this.onRetry,
  });

  final bool hasError;
  final bool hasMoreSuggestions;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Center(
          child: TextButton(
            onPressed: onRetry,
            child: const Text('Tentar novamente'),
          ),
        ),
      );
    }

    if (!hasMoreSuggestions) {
      return const SizedBox(height: 24);
    }

    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Center(
        child: TextButton.icon(
          onPressed: onLoadMore,
          icon: const Icon(Iconsax.arrow_down_2, size: 18),
          label: const Text('Carregar mais'),
        ),
      ),
    );
  }
}

class _SuggestionsLoadError extends StatelessWidget {
  const _SuggestionsLoadError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Iconsax.warning_2,
              size: 48,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Recarregar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionsEmptyState extends StatelessWidget {
  const _SuggestionsEmptyState({
    required this.canLoadMore,
    required this.onLoadMore,
  });

  final bool canLoadMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Iconsax.user_search,
              size: 54,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 12),
            Text(
              'Sem novas sugestões no momento.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (canLoadMore) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onLoadMore,
                icon: const Icon(Iconsax.arrow_down_2, size: 18),
                label: const Text('Buscar mais perfis compatíveis'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SuggestionAvatar extends StatelessWidget {
  const _SuggestionAvatar({required this.profile, this.radius = 22});

  final ProfileEntity profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final photoUrl = profile.photoUrl;
    final fallback = _AvatarFallback(
      initial: _initialForName(profile.name),
      radius: radius,
    );

    if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: photoUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      );
    }

    return fallback;
  }
}

class _CommonConnectionAvatar extends StatelessWidget {
  const _CommonConnectionAvatar({
    required this.name,
    this.photoUrl,
    this.radius = 7,
  });

  final String name;
  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = photoUrl?.trim() ?? '';
    final initial = _initialForName(name);

    final fallback = Container(
      width: radius * 2,
      height: radius * 2,
      color: AppColors.primary,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.9,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );

    if (trimmedUrl.isEmpty) {
      return fallback;
    }

    return CachedNetworkImage(
      imageUrl: trimmedUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => fallback,
      errorWidget: (_, __, ___) => fallback,
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.initial, required this.radius});

  final String initial;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.65,
          fontWeight: FontWeight.w600,
          color: Colors.white,
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
