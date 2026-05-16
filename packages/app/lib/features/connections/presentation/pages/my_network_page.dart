import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:core_ui/features/profile/domain/entities/profile_type.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/utils/app_snackbar.dart';
import 'package:core_ui/utils/debouncer.dart';
import 'package:core_ui/utils/location_utils.dart';
import 'package:core_ui/utils/music_constants.dart';
import 'package:core_ui/widgets/app_loading_overlay.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:wegig_app/config/app_config.dart';
import 'package:wegig_app/core/firebase/blocked_relations.dart';

import '../../../../app/router/app_router.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../mensagens_new/presentation/pages/chat_new_page.dart';
import '../../../mensagens_new/presentation/providers/mensagens_new_providers.dart';
import '../../../profile/presentation/pages/view_profile_page.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/entities.dart';
import '../providers/connections_providers.dart';

class MyNetworkPage extends ConsumerStatefulWidget {
  const MyNetworkPage({
    required this.currentTabIndexListenable,
    this.tabIndex = 1,
    super.key,
  });

  final ValueListenable<int> currentTabIndexListenable;
  final int tabIndex;

  @override
  ConsumerState<MyNetworkPage> createState() => _MyNetworkPageState();
}

enum _SuggestionLocationFilter {
  any,
  sameCity,
}

enum _SuggestionCommonConnectionFilter {
  any,
  withCommonConnections,
}

enum _SuggestionSortOption {
  relevance,
  commonConnections,
  recent,
}

class _MyNetworkPageState extends ConsumerState<MyNetworkPage>
    with WidgetsBindingObserver {
  final TextEditingController _profileSearchController =
      TextEditingController();
  final Debouncer _profileSearchDebouncer = Debouncer(milliseconds: 350);
  List<ProfileEntity> _profileSearchResults = <ProfileEntity>[];
  final Map<String, String> _connectionProfileLocations = <String, String>{};
  final Set<String> _selectedSuggestionInstruments = <String>{};
  final Set<String> _selectedSuggestionGenres = <String>{};
  final Set<ProfileType> _selectedSuggestionProfileTypes = <ProfileType>{};

  bool _isVisible = true;
  bool _isRefreshing = false;
  bool _isSearchingProfiles = false;
  bool _isFetchingConnectionLocations = false;
  String? _profileSearchError;
  String? _lastBadgeResetProfileId;
  String? _lastMetadataProfileId;
  _SuggestionLocationFilter _suggestionLocationFilter =
      _SuggestionLocationFilter.any;
  _SuggestionCommonConnectionFilter _suggestionCommonConnectionFilter =
      _SuggestionCommonConnectionFilter.any;
  _SuggestionSortOption _suggestionSortOption = _SuggestionSortOption.relevance;

  @override
  void initState() {
    super.initState();
    _hydrateSuggestionFiltersFromShared();
    WidgetsBinding.instance.addObserver(this);
    _isVisible = widget.currentTabIndexListenable.value == widget.tabIndex;
    widget.currentTabIndexListenable.addListener(_handleTabIndexChanged);
    _profileSearchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.currentTabIndexListenable.removeListener(_handleTabIndexChanged);
    _profileSearchController.removeListener(_onSearchTextChanged);
    _profileSearchController.dispose();
    _profileSearchDebouncer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _isVisible = widget.currentTabIndexListenable.value == widget.tabIndex;
    }
  }

  void _handleTabIndexChanged() {
    if (!mounted) {
      return;
    }
    final isVisibleNow =
        widget.currentTabIndexListenable.value == widget.tabIndex;
    if (_isVisible == isVisibleNow) {
      return;
    }
    setState(() {
      _isVisible = isVisibleNow;
    });
    if (isVisibleNow) {
      _markNetworkBadgeSeen(ref);
    }
  }

  void _onSearchTextChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
    _profileSearchDebouncer.run(() {
      if (!mounted) {
        return;
      }
      _searchProfiles(_profileSearchController.text);
    });
  }

  String _normalizedProfileQuery(String value) {
    return _normalizeSearchText(
      value,
      removeAtPrefix: true,
    );
  }

  String _normalizeSearchText(
    String value, {
    bool removeAtPrefix = false,
  }) {
    var normalized = value.trim().toLowerCase();
    if (removeAtPrefix) {
      normalized = normalized.replaceAll(RegExp(r'^@+'), '');
    }

    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');
    return _stripDiacritics(normalized);
  }

  String _stripDiacritics(String input) {
    const replacements = <String, String>{
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
      'ñ': 'n',
    };

    final buffer = StringBuffer();
    for (final char in input.split('')) {
      buffer.write(replacements[char] ?? char);
    }
    return buffer.toString();
  }

  void _clearProfileSearch() {
    _profileSearchController.clear();
    _profileSearchDebouncer.cancel();
    setState(() {
      _profileSearchResults.clear();
      _profileSearchError = null;
      _isSearchingProfiles = false;
    });
  }

  bool _areLocalSuggestionFiltersSynced(
    ConnectionSuggestionFiltersState sharedFilters,
  ) {
    return setEquals(
          _selectedSuggestionInstruments,
          sharedFilters.selectedInstruments,
        ) &&
        setEquals(_selectedSuggestionGenres, sharedFilters.selectedGenres) &&
        setEquals(
          _selectedSuggestionProfileTypes.map((type) => type.value).toSet(),
          sharedFilters.selectedProfileTypeValues,
        ) &&
        _suggestionLocationFilter ==
            (sharedFilters.locationFilter == SuggestionLocationFilter.sameCity
                ? _SuggestionLocationFilter.sameCity
                : _SuggestionLocationFilter.any) &&
        _suggestionCommonConnectionFilter ==
            (sharedFilters.commonConnectionFilter ==
                    SuggestionCommonConnectionFilter.withCommonConnections
                ? _SuggestionCommonConnectionFilter.withCommonConnections
                : _SuggestionCommonConnectionFilter.any) &&
        _suggestionSortOption ==
            switch (sharedFilters.sortOption) {
              SuggestionSortOption.commonConnections =>
                _SuggestionSortOption.commonConnections,
              SuggestionSortOption.recent => _SuggestionSortOption.recent,
              SuggestionSortOption.relevance => _SuggestionSortOption.relevance,
            };
  }

  void _hydrateSuggestionFiltersFromShared([
    ConnectionSuggestionFiltersState? sharedFilters,
  ]) {
    final ConnectionSuggestionFiltersState filters;
    if (sharedFilters != null) {
      filters = sharedFilters;
    } else {
      filters = ref.read(connectionSuggestionFiltersProvider);
    }

    _selectedSuggestionInstruments
      ..clear()
      ..addAll(filters.selectedInstruments);
    _selectedSuggestionGenres
      ..clear()
      ..addAll(filters.selectedGenres);
    _selectedSuggestionProfileTypes
      ..clear()
      ..addAll(
        ProfileType.values.where(
          (type) => filters.selectedProfileTypeValues.contains(type.value),
        ),
      );
    _suggestionLocationFilter =
        filters.locationFilter == SuggestionLocationFilter.sameCity
            ? _SuggestionLocationFilter.sameCity
            : _SuggestionLocationFilter.any;
    _suggestionCommonConnectionFilter = filters.commonConnectionFilter ==
            SuggestionCommonConnectionFilter.withCommonConnections
        ? _SuggestionCommonConnectionFilter.withCommonConnections
        : _SuggestionCommonConnectionFilter.any;
    _suggestionSortOption = switch (filters.sortOption) {
      SuggestionSortOption.commonConnections =>
        _SuggestionSortOption.commonConnections,
      SuggestionSortOption.recent => _SuggestionSortOption.recent,
      SuggestionSortOption.relevance => _SuggestionSortOption.relevance,
    };
  }

  void _syncLocalSuggestionFiltersFromShared(
    ConnectionSuggestionFiltersState sharedFilters,
  ) {
    if (_areLocalSuggestionFiltersSynced(sharedFilters)) {
      return;
    }

    setState(() => _hydrateSuggestionFiltersFromShared(sharedFilters));
  }

  void _syncSuggestionFiltersToSharedIfNeeded() {
    final notifier = ref.read(connectionSuggestionFiltersProvider.notifier);
    final current = ref.read(connectionSuggestionFiltersProvider);

    final next = ConnectionSuggestionFiltersState(
      selectedInstruments: {..._selectedSuggestionInstruments},
      selectedGenres: {..._selectedSuggestionGenres},
      selectedProfileTypeValues:
          _selectedSuggestionProfileTypes.map((type) => type.value).toSet(),
      locationFilter:
          _suggestionLocationFilter == _SuggestionLocationFilter.sameCity
              ? SuggestionLocationFilter.sameCity
              : SuggestionLocationFilter.any,
      commonConnectionFilter: _suggestionCommonConnectionFilter ==
              _SuggestionCommonConnectionFilter.withCommonConnections
          ? SuggestionCommonConnectionFilter.withCommonConnections
          : SuggestionCommonConnectionFilter.any,
      sortOption: switch (_suggestionSortOption) {
        _SuggestionSortOption.commonConnections =>
          SuggestionSortOption.commonConnections,
        _SuggestionSortOption.recent => SuggestionSortOption.recent,
        _SuggestionSortOption.relevance => SuggestionSortOption.relevance,
      },
    );

    final didChange =
        !setEquals(current.selectedInstruments, next.selectedInstruments) ||
            !setEquals(current.selectedGenres, next.selectedGenres) ||
            !setEquals(
              current.selectedProfileTypeValues,
              next.selectedProfileTypeValues,
            ) ||
            current.locationFilter != next.locationFilter ||
            current.commonConnectionFilter != next.commonConnectionFilter ||
            current.sortOption != next.sortOption;

    if (!didChange) {
      return;
    }

    notifier.update(next);
  }

  bool _matchesSuggestionFilters(ConnectionSuggestionEntity suggestion) {
    final profile = suggestion.profile;
    final activeProfile = ref.read(activeProfileProvider);

    if (_selectedSuggestionProfileTypes.isNotEmpty &&
        !_selectedSuggestionProfileTypes.contains(profile.profileType)) {
      return false;
    }

    if (_suggestionLocationFilter == _SuggestionLocationFilter.sameCity &&
        activeProfile != null &&
        activeProfile.city.trim().isNotEmpty &&
        profile.city.trim().toLowerCase() !=
            activeProfile.city.trim().toLowerCase()) {
      return false;
    }

    if (_suggestionCommonConnectionFilter ==
            _SuggestionCommonConnectionFilter.withCommonConnections &&
        suggestion.commonConnectionsCount <= 0) {
      return false;
    }

    if (_selectedSuggestionInstruments.isNotEmpty) {
      final profileInstruments = (profile.instruments ?? const <String>[])
          .map((item) => item.trim().toLowerCase())
          .where((item) => item.isNotEmpty)
          .toSet();
      final selectedInstruments = _selectedSuggestionInstruments
          .map((item) => item.trim().toLowerCase())
          .where((item) => item.isNotEmpty)
          .toSet();
      if (profileInstruments.intersection(selectedInstruments).isEmpty) {
        return false;
      }
    }

    if (_selectedSuggestionGenres.isNotEmpty) {
      final profileGenres = (profile.genres ?? const <String>[])
          .map((item) => item.trim().toLowerCase())
          .where((item) => item.isNotEmpty)
          .toSet();
      final selectedGenres = _selectedSuggestionGenres
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
  ) {
    if (_suggestionSortOption == _SuggestionSortOption.relevance) {
      return suggestions;
    }

    final sorted = [...suggestions];

    sorted.sort((left, right) {
      switch (_suggestionSortOption) {
        case _SuggestionSortOption.relevance:
          return right.score.compareTo(left.score);
        case _SuggestionSortOption.commonConnections:
          final commonConnectionsComparison = right.commonConnectionsCount
              .compareTo(left.commonConnectionsCount);
          if (commonConnectionsComparison != 0) {
            return commonConnectionsComparison;
          }
          return right.score.compareTo(left.score);
        case _SuggestionSortOption.recent:
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
    required Future<void> Function(T selected) onSelected,
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

    await onSelected(result);
  }

  String _locationFilterLabel() {
    switch (_suggestionLocationFilter) {
      case _SuggestionLocationFilter.any:
        return 'Localização: Qualquer cidade';
      case _SuggestionLocationFilter.sameCity:
        return 'Localização: Mesma cidade';
    }
  }

  String _commonConnectionFilterLabel() {
    switch (_suggestionCommonConnectionFilter) {
      case _SuggestionCommonConnectionFilter.any:
        return 'Relação em comum: Sem filtro';
      case _SuggestionCommonConnectionFilter.withCommonConnections:
        return 'Relação em comum: Com conexões';
    }
  }

  String _sortOptionLabel() {
    switch (_suggestionSortOption) {
      case _SuggestionSortOption.relevance:
        return 'Ordenação: Relevância';
      case _SuggestionSortOption.commonConnections:
        return 'Ordenação: Mais conexões';
      case _SuggestionSortOption.recent:
        return 'Ordenação: Mais recente';
    }
  }

  Future<void> _openSuggestionFilterBottomSheet({
    required String title,
    required List<String> options,
    required Set<String> selectedValues,
    required String analyticsEvent,
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
                            onPressed: () {
                              setModalState(() {
                                tempSelected.clear();
                              });
                            },
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

    if (result == null || !mounted) {
      return;
    }

    if (!setEquals(result, selectedValues)) {
      setState(() {
        selectedValues
          ..clear()
          ..addAll(result);
      });
      _syncSuggestionFiltersToSharedIfNeeded();
      await _logAnalyticsEvent(
        name: analyticsEvent,
        parameters: {
          'selected_count': result.length,
        },
      );
    }
  }

  Future<void> _openProfileTypeFilterBottomSheet() async {
    final selectedLabels =
        _selectedSuggestionProfileTypes.map((type) => type.label).toSet();

    final tempSelection = <String>{...selectedLabels};

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
                            onPressed: () {
                              setModalState(() => tempSelection.clear());
                            },
                            child: const Text('Limpar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView(
                          children: ProfileType.values.map((profileType) {
                            final label = profileType.label;
                            return CheckboxListTile(
                              dense: true,
                              value: tempSelection.contains(label),
                              activeColor: AppColors.primary,
                              title: Text(label),
                              onChanged: (selected) {
                                setModalState(() {
                                  if (selected == true) {
                                    tempSelection.add(label);
                                  } else {
                                    tempSelection.remove(label);
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

    if (result == null || !mounted) {
      return;
    }

    final selectedTypes = ProfileType.values
        .where((profileType) => result.contains(profileType.label))
        .toSet();

    if (!setEquals(selectedTypes, _selectedSuggestionProfileTypes)) {
      setState(() {
        _selectedSuggestionProfileTypes
          ..clear()
          ..addAll(selectedTypes);
      });
      _syncSuggestionFiltersToSharedIfNeeded();
      await _logAnalyticsEvent(
        name: 'my_network_filter_profile_type_changed',
        parameters: {
          'selected_count': selectedTypes.length,
        },
      );
    }
  }

  Widget _buildSuggestionFiltersRow() {
    final hasAnyFilterActive = _selectedSuggestionInstruments.isNotEmpty ||
        _selectedSuggestionGenres.isNotEmpty ||
        _selectedSuggestionProfileTypes.isNotEmpty ||
        _suggestionLocationFilter != _SuggestionLocationFilter.any ||
        _suggestionCommonConnectionFilter !=
            _SuggestionCommonConnectionFilter.any ||
        _suggestionSortOption != _SuggestionSortOption.relevance;

    final activeFiltersCount = [
      _selectedSuggestionInstruments.isNotEmpty,
      _selectedSuggestionGenres.isNotEmpty,
      _selectedSuggestionProfileTypes.isNotEmpty,
      _suggestionLocationFilter != _SuggestionLocationFilter.any,
      _suggestionCommonConnectionFilter !=
          _SuggestionCommonConnectionFilter.any,
      _suggestionSortOption != _SuggestionSortOption.relevance,
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
              if (hasAnyFilterActive) ...[
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
              if (hasAnyFilterActive)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedSuggestionInstruments.clear();
                      _selectedSuggestionGenres.clear();
                      _selectedSuggestionProfileTypes.clear();
                      _suggestionLocationFilter = _SuggestionLocationFilter.any;
                      _suggestionCommonConnectionFilter =
                          _SuggestionCommonConnectionFilter.any;
                      _suggestionSortOption = _SuggestionSortOption.relevance;
                    });
                    _syncSuggestionFiltersToSharedIfNeeded();
                    _logAnalyticsEvent(name: 'my_network_filters_cleared');
                  },
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
                  label: _selectedSuggestionProfileTypes.isEmpty
                      ? 'Tipo'
                      : 'Tipo (${_selectedSuggestionProfileTypes.length})',
                  isActive: _selectedSuggestionProfileTypes.isNotEmpty,
                  onPressed: _openProfileTypeFilterBottomSheet,
                ),
                const SizedBox(width: 8),
                buildChip(
                  icon: Iconsax.musicnote,
                  label: _selectedSuggestionInstruments.isEmpty
                      ? 'Instrumentos'
                      : 'Instrumentos (${_selectedSuggestionInstruments.length})',
                  isActive: _selectedSuggestionInstruments.isNotEmpty,
                  onPressed: () => _openSuggestionFilterBottomSheet(
                    title: 'Filtrar por instrumentos',
                    options: MusicConstants.instrumentOptions,
                    selectedValues: _selectedSuggestionInstruments,
                    analyticsEvent: 'my_network_filter_instruments_changed',
                  ),
                ),
                const SizedBox(width: 8),
                buildChip(
                  icon: Iconsax.music_library_2,
                  label: _selectedSuggestionGenres.isEmpty
                      ? 'Gêneros'
                      : 'Gêneros (${_selectedSuggestionGenres.length})',
                  isActive: _selectedSuggestionGenres.isNotEmpty,
                  onPressed: () => _openSuggestionFilterBottomSheet(
                    title: 'Filtrar por gêneros',
                    options: MusicConstants.genreOptions,
                    selectedValues: _selectedSuggestionGenres,
                    analyticsEvent: 'my_network_filter_genres_changed',
                  ),
                ),
                const SizedBox(width: 8),
                buildChip(
                  icon: Iconsax.location,
                  label: _suggestionLocationFilter ==
                          _SuggestionLocationFilter.sameCity
                      ? 'Mesma cidade'
                      : 'Cidade',
                  isActive: _suggestionLocationFilter !=
                      _SuggestionLocationFilter.any,
                  onPressed: () =>
                      _openSingleSelectBottomSheet<_SuggestionLocationFilter>(
                    title: 'Filtrar por localização',
                    options: _SuggestionLocationFilter.values,
                    selectedValue: _suggestionLocationFilter,
                    labelBuilder: (value) {
                      switch (value) {
                        case _SuggestionLocationFilter.any:
                          return 'Qualquer cidade';
                        case _SuggestionLocationFilter.sameCity:
                          return 'Mesma cidade';
                      }
                    },
                    onSelected: (selected) async {
                      if (!mounted) return;
                      setState(() => _suggestionLocationFilter = selected);
                      _syncSuggestionFiltersToSharedIfNeeded();
                      await _logAnalyticsEvent(
                        name: 'my_network_filter_location_changed',
                        parameters: {
                          'value': selected.name,
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                buildChip(
                  icon: Iconsax.profile_add,
                  label: _suggestionCommonConnectionFilter ==
                          _SuggestionCommonConnectionFilter
                              .withCommonConnections
                      ? 'Em comum'
                      : 'Conexões',
                  isActive: _suggestionCommonConnectionFilter !=
                      _SuggestionCommonConnectionFilter.any,
                  onPressed: () => _openSingleSelectBottomSheet<
                      _SuggestionCommonConnectionFilter>(
                    title: 'Filtrar por relação em comum',
                    options: _SuggestionCommonConnectionFilter.values,
                    selectedValue: _suggestionCommonConnectionFilter,
                    labelBuilder: (value) {
                      switch (value) {
                        case _SuggestionCommonConnectionFilter.any:
                          return 'Sem filtro';
                        case _SuggestionCommonConnectionFilter
                              .withCommonConnections:
                          return 'Com conexões em comum';
                      }
                    },
                    onSelected: (selected) async {
                      if (!mounted) return;
                      setState(
                          () => _suggestionCommonConnectionFilter = selected);
                      _syncSuggestionFiltersToSharedIfNeeded();
                      await _logAnalyticsEvent(
                        name: 'my_network_filter_common_connections_changed',
                        parameters: {
                          'value': selected.name,
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                buildChip(
                  icon: Iconsax.sort,
                  label:
                      _suggestionSortOption == _SuggestionSortOption.relevance
                          ? 'Relevância'
                          : _suggestionSortOption ==
                                  _SuggestionSortOption.commonConnections
                              ? 'Mais conexões'
                              : 'Mais recentes',
                  isActive:
                      _suggestionSortOption != _SuggestionSortOption.relevance,
                  onPressed: () =>
                      _openSingleSelectBottomSheet<_SuggestionSortOption>(
                    title: 'Ordenar sugestões',
                    options: _SuggestionSortOption.values,
                    selectedValue: _suggestionSortOption,
                    labelBuilder: (value) {
                      switch (value) {
                        case _SuggestionSortOption.relevance:
                          return 'Relevância';
                        case _SuggestionSortOption.commonConnections:
                          return 'Mais conexões em comum';
                        case _SuggestionSortOption.recent:
                          return 'Mais recente';
                      }
                    },
                    onSelected: (selected) async {
                      if (!mounted) return;
                      setState(() => _suggestionSortOption = selected);
                      _syncSuggestionFiltersToSharedIfNeeded();
                      await _logAnalyticsEvent(
                        name: 'my_network_filter_sort_changed',
                        parameters: {
                          'value': selected.name,
                        },
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

  int _profileSearchTextScore(ProfileEntity profile, String query) {
    final normalizedQuery = _normalizedProfileQuery(query);
    final username = _normalizedProfileQuery(profile.username ?? '');
    final name = _normalizeSearchText(profile.name);

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

  int _compareProfileSearchResults(
    _RankedProfileSearchResult left,
    _RankedProfileSearchResult right,
  ) {
    final textScoreComparison = right.textScore.compareTo(left.textScore);
    if (textScoreComparison != 0) {
      return textScoreComparison;
    }

    final relationshipComparison =
        right.relationshipScore.compareTo(left.relationshipScore);
    if (relationshipComparison != 0) {
      return relationshipComparison;
    }

    final leftName = left.profile.name.trim().toLowerCase();
    final rightName = right.profile.name.trim().toLowerCase();
    final nameComparison = leftName.compareTo(rightName);
    if (nameComparison != 0) {
      return nameComparison;
    }

    final leftUsername = _normalizedProfileQuery(left.profile.username ?? '');
    final rightUsername = _normalizedProfileQuery(right.profile.username ?? '');
    return leftUsername.compareTo(rightUsername);
  }

  Future<List<ProfileEntity>> _rankProfileSearchResults({
    required List<ProfileEntity> profiles,
    required ProfileEntity activeProfile,
    required String query,
  }) async {
    if (profiles.length <= 1) {
      return profiles;
    }

    final preliminarilySorted = [...profiles]..sort(
        (left, right) => _compareProfileSearchResults(
          _RankedProfileSearchResult(
            profile: left,
            textScore: _profileSearchTextScore(left, query),
          ),
          _RankedProfileSearchResult(
            profile: right,
            textScore: _profileSearchTextScore(right, query),
          ),
        ),
      );

    final prioritizedProfiles = preliminarilySorted.take(12).toList();
    final remainingProfiles = preliminarilySorted.skip(12).toList();
    final getConnectionStatus = ref.read(getConnectionStatusUseCaseProvider);

    final rankedProfiles = await Future.wait(
      prioritizedProfiles.map((profile) async {
        var relationshipScore = 0;

        try {
          final status = await getConnectionStatus(
            profileId: activeProfile.profileId,
            profileUid: activeProfile.uid,
            otherProfileId: profile.profileId,
          );

          relationshipScore = switch (status.status) {
            ConnectionRelationshipStatus.pendingReceived => 4,
            ConnectionRelationshipStatus.connected => 3,
            ConnectionRelationshipStatus.pendingSent => 2,
            ConnectionRelationshipStatus.none => 1,
          };
        } catch (_) {}

        return _RankedProfileSearchResult(
          profile: profile,
          textScore: _profileSearchTextScore(profile, query),
          relationshipScore: relationshipScore,
        );
      }),
    );

    rankedProfiles.sort(_compareProfileSearchResults);

    return [
      ...rankedProfiles.map((result) => result.profile),
      ...remainingProfiles,
    ];
  }

  Future<void> _primeConnectionLocations(
    List<ConnectionEntity> connections,
    String currentProfileId,
  ) async {
    if (_isFetchingConnectionLocations) {
      return;
    }

    final missingProfileIds = connections
        .map((connection) =>
            connection.getOtherProfileId(currentProfileId).trim())
        .where((profileId) => profileId.isNotEmpty)
        .where(
            (profileId) => !_connectionProfileLocations.containsKey(profileId))
        .toSet()
        .toList(growable: false);

    if (missingProfileIds.isEmpty) {
      return;
    }

    _isFetchingConnectionLocations = true;

    try {
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
          fetchedLocations[doc.id] = formatCleanLocation(
            neighborhood: data['neighborhood'] as String?,
            neighbourhood: data['neighbourhood'] as String?,
            city: data['city'] as String?,
            state: data['state'] as String?,
            fallback: '',
          );
        }
      }

      if (!mounted || fetchedLocations.isEmpty) {
        return;
      }

      setState(() {
        _connectionProfileLocations.addAll(fetchedLocations);
      });
    } catch (_) {
      // Metadata failures must not block overview rendering.
    } finally {
      _isFetchingConnectionLocations = false;
    }
  }

  Widget _buildProfileSearchContent() {
    final query = _profileSearchController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _profileSearchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Nome ou @usuario',
            prefixText: query.startsWith('@') || query.isEmpty ? null : '@',
            border: const OutlineInputBorder(),
            suffixIcon: _isSearchingProfiles
                ? Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      height: 16,
                      width: 16,
                      child: AppRadioPulseLoader(size: 16),
                    ),
                  )
                : (query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _clearProfileSearch,
                      )
                    : null),
            errorText: _profileSearchError,
          ),
        ),
        const SizedBox(height: 12),
        if (_isSearchingProfiles && _profileSearchResults.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: AppRadioPulseLoader(size: 24)),
          )
        else if (query.isNotEmpty && _profileSearchResults.isEmpty)
          const Text('Nada encontrado.')
        else if (_profileSearchResults.isNotEmpty)
          _ProfileSearchSuggestionsGrid(
            profiles: _profileSearchResults,
            isBusy: ref.watch(connectionsActionsProvider).isLoading,
            onOpenProfile: (profile) {
              _logAnalyticsEvent(
                name: 'profile_search_result_opened',
                parameters: {
                  'target_profile_id': profile.profileId,
                  'target_profile_type': profile.profileType.value,
                },
              );
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => ViewProfilePage(
                    profileId: profile.profileId,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Future<void> _searchProfiles(String rawQuery) async {
    if (!mounted) {
      return;
    }

    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) {
      return;
    }

    final trimmed = _normalizedProfileQuery(rawQuery);
    if (trimmed.isEmpty) {
      setState(() {
        _profileSearchResults = <ProfileEntity>[];
        _profileSearchError = null;
        _isSearchingProfiles = false;
      });
      return;
    }

    setState(() {
      _isSearchingProfiles = true;
      _profileSearchError = null;
    });

    final firestore = FirebaseFirestore.instance;
    final profilesRef = firestore.collection('profiles');
    final currentUid = ref.read(currentUserProvider)?.uid;
    final excluded = currentUid == null
        ? const <String>[]
        : await BlockedRelations.getExcludedProfileIds(
            firestore: firestore,
            profileId: activeProfile.profileId,
            uid: currentUid,
          );

    final List<ProfileEntity> collected = <ProfileEntity>[];
    final Set<String> seen = <String>{};

    void addProfile(ProfileEntity profile) {
      if (profile.profileId == activeProfile.profileId) {
        return;
      }
      if (excluded.contains(profile.profileId)) {
        return;
      }
      if (!seen.add(profile.profileId)) {
        return;
      }
      collected.add(profile);
    }

    Future<void> addFromSnapshot(
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) async {
      for (final doc in snapshot.docs) {
        addProfile(ProfileEntity.fromFirestore(doc));
      }
    }

    try {
      await addFromSnapshot(
        await profilesRef
            .where('usernameLowercase', isEqualTo: trimmed)
            .limit(8)
            .get(),
      );

      await addFromSnapshot(
        await profilesRef.where('username', isEqualTo: trimmed).limit(8).get(),
      );

      await addFromSnapshot(
        await profilesRef
            .orderBy('usernameLowercase')
            .startAt(<String>[trimmed])
            .endAt(<String>['${trimmed}\uf8ff'])
            .limit(8)
            .get(),
      );

      await addFromSnapshot(
        await profilesRef
            .orderBy('username')
            .startAt(<String>[trimmed])
            .endAt(<String>['${trimmed}\uf8ff'])
            .limit(8)
            .get(),
      );

      try {
        await addFromSnapshot(
          await profilesRef
              .where('nameLowercase', isEqualTo: trimmed)
              .limit(8)
              .get(),
        );
      } catch (_) {}

      try {
        await addFromSnapshot(
          await profilesRef
              .orderBy('nameLowercase')
              .startAt(<String>[trimmed])
              .endAt(<String>['${trimmed}\uf8ff'])
              .limit(8)
              .get(),
        );
      } catch (_) {}

      if (collected.length < 8) {
        try {
          await addFromSnapshot(
            await profilesRef
                .orderBy('nameLowercase')
                .startAt(<String>[trimmed])
                .endAt(<String>['${trimmed}\uf8ff'])
                .limit(20)
                .get(),
          );
        } catch (_) {}
      }

      if (collected.length < 8) {
        try {
          final recentProfilesSnapshot = await profilesRef
              .orderBy('createdAt', descending: true)
              .limit(120)
              .get();

          for (final doc in recentProfilesSnapshot.docs) {
            if (collected.length >= 20) {
              break;
            }

            final profile = ProfileEntity.fromFirestore(doc);
            final normalizedName = _normalizeSearchText(profile.name);
            if (!normalizedName.contains(trimmed)) {
              continue;
            }

            addProfile(profile);
          }
        } catch (_) {}
      }

      if (!mounted ||
          _normalizedProfileQuery(_profileSearchController.text) != trimmed) {
        return;
      }

      final rankedResults = await _rankProfileSearchResults(
        profiles: collected,
        activeProfile: activeProfile,
        query: trimmed,
      );

      if (!mounted ||
          _normalizedProfileQuery(_profileSearchController.text) != trimmed) {
        return;
      }

      setState(() {
        _profileSearchResults = rankedResults;
        _isSearchingProfiles = false;
      });
    } catch (e) {
      if (!mounted ||
          _normalizedProfileQuery(_profileSearchController.text) != trimmed) {
        return;
      }

      setState(() {
        _profileSearchError = 'Erro ao buscar perfis';
        _isSearchingProfiles = false;
        _profileSearchResults = <ProfileEntity>[];
      });
      debugPrint('❌ [MINHA_REDE] profile search error: $e');
    }
  }

  Widget _buildProfileSearchAction(ProfileEntity profile) {
    final statusAsync = ref.watch(
      effectiveConnectionStatusProvider(profile.profileId),
    );
    final isBusy = ref.watch(connectionsActionsProvider).isLoading;

    return statusAsync.when(
      loading: () => const SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (status) {
        switch (status.status) {
          case ConnectionRelationshipStatus.none:
            if (!profile.allowConnectionRequests) {
              return Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              );
            }
            return GestureDetector(
              onTap: isBusy
                  ? null
                  : () => ref
                      .read(connectionsActionsProvider.notifier)
                      .sendRequest(recipientProfile: profile),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isBusy ? Colors.grey[300] : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            );
          case ConnectionRelationshipStatus.pendingReceived:
            if (status.requestId == null) {
              return const SizedBox.shrink();
            }
            return GestureDetector(
              onTap: isBusy
                  ? null
                  : () => ref
                      .read(connectionsActionsProvider.notifier)
                      .acceptRequest(
                        requestId: status.requestId!,
                        otherProfileId: profile.profileId,
                      ),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isBusy ? Colors.grey[300] : const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            );
          case ConnectionRelationshipStatus.pendingSent:
            return Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.clock, color: Colors.grey[400], size: 18),
            );
          case ConnectionRelationshipStatus.connected:
            return Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.profile_2user,
                color: Colors.grey[400],
                size: 18,
              ),
            );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeProfile = ref.watch(activeProfileProvider);
    final actionState = ref.watch(connectionsActionsProvider);
    final currentUser = ref.watch(currentUserProvider);

    ref.listen<AsyncValue<void>>(connectionsActionsProvider, (previous, next) {
      if (!next.hasError || next.isLoading || !context.mounted) {
        return;
      }

      if (previous?.error == next.error) {
        return;
      }

      AppSnackBar.showError(context, _errorMessage(next.error));
    });

    ref.listen<ConnectionSuggestionFiltersState>(
      connectionSuggestionFiltersProvider,
      (previous, next) {
        if (!mounted) {
          return;
        }

        _syncLocalSuggestionFiltersFromShared(next);
      },
    );

    if (activeProfile == null) {
      return const Scaffold(
        body: Center(
          child: Text('Selecione um perfil para acessar Minha Rede.'),
        ),
      );
    }

    if (_isVisible && _lastBadgeResetProfileId != activeProfile.profileId) {
      _lastBadgeResetProfileId = activeProfile.profileId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _markNetworkBadgeSeen(ref);
      });
    }

    if (_lastMetadataProfileId != activeProfile.profileId) {
      _lastMetadataProfileId = activeProfile.profileId;
      _connectionProfileLocations.clear();
      _selectedSuggestionInstruments.clear();
      _selectedSuggestionGenres.clear();
      _selectedSuggestionProfileTypes.clear();
      _suggestionLocationFilter = _SuggestionLocationFilter.any;
      _suggestionCommonConnectionFilter = _SuggestionCommonConnectionFilter.any;
      _suggestionSortOption = _SuggestionSortOption.relevance;
    }

    final statsAsync = ref.watch(
      connectionStatsStreamProvider(activeProfile.profileId),
    );
    final receivedAsync = ref.watch(
      pendingReceivedRequestsStreamProvider(
        profileId: activeProfile.profileId,
        profileUid: activeProfile.uid,
      ),
    );
    final sentAsync = ref.watch(
      pendingSentRequestsStreamProvider(
        profileId: activeProfile.profileId,
        profileUid: activeProfile.uid,
      ),
    );
    final excludedSuggestionProfileIds = ref.watch(
      connectionSuggestionExcludedProfileIdsProvider,
    );
    final suggestionsAsync = ref.watch(connectionSuggestionsProvider);
    final suggestionBuckets = suggestionsAsync.valueOrNull == null
        ? null
        : _buildSuggestionBuckets(
            activeProfile,
            _sortedSuggestions(suggestionsAsync.valueOrNull!),
            excludedProfileIds: excludedSuggestionProfileIds,
            matcher: _matchesSuggestionFilters,
          );
    final totalConnections = statsAsync.valueOrNull?.totalConnections;
    final networkActivityAsync = ref.watch(
      networkActivityOverviewPreviewStreamProvider(
        profileId: activeProfile.profileId,
        profileUid: activeProfile.uid,
      ),
    );
    final connectionsAsync = ref.watch(
      myConnectionsOverviewPreviewStreamProvider(
        profileId: activeProfile.profileId,
        profileUid: activeProfile.uid,
      ),
    );
    Widget buildSuggestionBucketsState({
      required Widget Function(_SuggestionBuckets buckets) dataBuilder,
      required String debugLabel,
      required String errorMessage,
    }) {
      if (suggestionBuckets != null) {
        return dataBuilder(suggestionBuckets);
      }

      return suggestionsAsync.when(
        data: (suggestions) => dataBuilder(
          _buildSuggestionBuckets(
            activeProfile,
            _sortedSuggestions(suggestions),
            excludedProfileIds: excludedSuggestionProfileIds,
            matcher: _matchesSuggestionFilters,
          ),
        ),
        loading: () => const _SectionLoader(),
        error: (e, st) {
          debugPrint('❌ [MINHA_REDE] $debugLabel: $e\n$st');
          return _SectionError(message: errorMessage);
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Rede'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _handleRefresh(activeProfile),
        color: AppColors.primary,
        backgroundColor: Colors.white,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            statsAsync.when(
              data: (stats) => _StatsCard(stats: stats),
              loading: () => const _SectionLoader(),
              error: (e, st) {
                debugPrint('❌ [MINHA_REDE] statsAsync error: $e\n$st');
                return const _SectionError(
                  message: 'Não foi possível carregar os indicadores da rede.',
                );
              },
            ),
            receivedAsync.when(
              data: (requests) {
                if (requests.isEmpty) {
                  return const SizedBox.shrink();
                }

                return _SectionCard(
                  icon: Icons.inbox_rounded,
                  title: 'Convites recebidos',
                  trailing: TextButton(
                    onPressed: () => context.pushPendingReceivedRequests(),
                    child: const Text('Ver tudo'),
                  ),
                  child: _RequestList(
                    requests: requests.take(2).toList(growable: false),
                    emptyMessage: 'Nenhum convite pendente para aceitar.',
                    actionLabel: 'Aceitar',
                    secondaryActionLabel: 'Recusar',
                    isBusy: actionState.isLoading,
                    onOpenProfile: (request) =>
                        context.pushProfile(request.requesterProfileId),
                    onPrimaryAction: (request) => ref
                        .read(connectionsActionsProvider.notifier)
                        .acceptRequest(
                          requestId: request.id,
                          otherProfileId: request.requesterProfileId,
                        ),
                    onSecondaryAction: (request) => ref
                        .read(connectionsActionsProvider.notifier)
                        .declineRequest(
                          requestId: request.id,
                          otherProfileId: request.requesterProfileId,
                        ),
                    titleBuilder: (request) => request.requesterName,
                    subtitleBuilder: _receivedRequestSubtitle,
                    avatarPhotoUrlBuilder: (request) =>
                        request.requesterPhotoUrl,
                  ),
                );
              },
              loading: () => const _SectionLoader(),
              error: (e, st) {
                debugPrint('❌ [MINHA_REDE] receivedAsync error: $e\n$st');
                return const _SectionError(
                  message: 'Não foi possível carregar os convites recebidos.',
                );
              },
            ),
            const SizedBox(height: 16),
            sentAsync.when(
              data: (requests) {
                if (requests.isEmpty) {
                  return const SizedBox.shrink();
                }

                return _SectionCard(
                  icon: Icons.call_made_rounded,
                  title: 'Convites enviados',
                  trailing: TextButton(
                    onPressed: () => context.pushPendingSentRequests(),
                    child: const Text('Ver tudo'),
                  ),
                  child: _RequestList(
                    requests: requests.take(2).toList(growable: false),
                    emptyMessage: 'Nenhum convite enviado aguardando resposta.',
                    actionLabel: 'Cancelar',
                    isBusy: actionState.isLoading,
                    onOpenProfile: (request) =>
                        context.pushProfile(request.recipientProfileId),
                    onPrimaryAction: (request) => ref
                        .read(connectionsActionsProvider.notifier)
                        .cancelRequest(
                          requestId: request.id,
                          otherProfileId: request.recipientProfileId,
                        ),
                    titleBuilder: (request) => request.recipientName,
                    subtitleBuilder: _sentRequestSubtitle,
                    avatarPhotoUrlBuilder: (request) =>
                        request.recipientPhotoUrl,
                  ),
                );
              },
              loading: () => const _SectionLoader(),
              error: (e, st) {
                debugPrint('❌ [MINHA_REDE] sentAsync error: $e\n$st');
                return const _SectionError(
                  message: 'Não foi possível carregar os convites enviados.',
                );
              },
            ),
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.people_outline_rounded,
              title: 'Conexões',
              trailing: TextButton(
                onPressed: () {
                  _logAnalyticsEvent(
                    name: 'my_network_connections_cta_tapped',
                    parameters: const {
                      'source': 'overview',
                    },
                  );
                  context.pushConnections();
                },
                child: const Text('Ver todas'),
              ),
              child: connectionsAsync.when(
                data: (connections) {
                  unawaited(
                    _primeConnectionLocations(
                      connections,
                      activeProfile.profileId,
                    ),
                  );

                  return _ConnectionsList(
                    connections: connections,
                    totalCount: totalConnections,
                    currentProfileId: activeProfile.profileId,
                    isBusy: actionState.isLoading,
                    locationsByProfileId: _connectionProfileLocations,
                    onOpenProfile: (connection) {
                      final otherProfileId = connection.getOtherProfileId(
                        activeProfile.profileId,
                      );
                      if (otherProfileId.isEmpty) {
                        return;
                      }

                      _logAnalyticsEvent(
                        name: 'connections_profile_opened',
                        parameters: {
                          'other_profile_id': otherProfileId,
                          'source': 'overview_preview',
                        },
                      );
                      context.pushProfile(otherProfileId);
                    },
                    onMessage: (connection) => _openConversation(
                      context,
                      ref,
                      currentProfileId: activeProfile.profileId,
                      currentProfileUid: currentUser?.uid ?? activeProfile.uid,
                      currentProfileName: activeProfile.name,
                      currentProfilePhotoUrl: activeProfile.photoUrl,
                      otherProfileId: connection.getOtherProfileId(
                        activeProfile.profileId,
                      ),
                      otherProfileUid: connection.getOtherProfileUid(
                        activeProfile.profileId,
                      ),
                      otherProfileName: connection.getOtherProfileName(
                        activeProfile.profileId,
                      ),
                      otherProfilePhotoUrl: connection.getOtherProfilePhotoUrl(
                        activeProfile.profileId,
                      ),
                      activeProfileType: activeProfile.profileType.value,
                      source: 'overview_preview',
                    ),
                    onRemove: (connection) => ref
                        .read(connectionsActionsProvider.notifier)
                        .removeConnection(
                          connectionId: connection.id,
                          otherProfileId: connection.getOtherProfileId(
                            activeProfile.profileId,
                          ),
                        ),
                  );
                },
                loading: () => const _OverviewPreviewLoadingState(
                  icon: Icons.people_outline_rounded,
                  title: 'Carregando conexões',
                ),
                error: (e, st) {
                  debugPrint('❌ [MINHA_REDE] connectionsAsync error: $e\n$st');
                  return _OverviewPreviewErrorState(
                    title: 'Erro ao carregar conexões.',
                    onRetry: () => _handleRefresh(activeProfile),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.trending_up_rounded,
              title: 'Atividade da rede',
              trailing: TextButton(
                onPressed: () {
                  _logAnalyticsEvent(
                    name: 'my_network_activity_cta_tapped',
                    parameters: const {
                      'source': 'overview',
                    },
                  );
                  context.pushNetworkActivity();
                },
                child: const Text('Ver tudo'),
              ),
              child: networkActivityAsync.when(
                data: (posts) => _NetworkActivityList(
                  posts: posts,
                  previewLimit: networkActivityOverviewPreviewLimit,
                  onOpenPost: (post) {
                    _logAnalyticsEvent(
                      name: 'network_activity_post_opened',
                      parameters: {
                        'post_id': post.id,
                        'author_profile_id': post.authorProfileId,
                        'source': 'overview_preview',
                      },
                    );
                    context.pushPostDetail(post.id);
                  },
                  onViewProfile: (post) {
                    _logAnalyticsEvent(
                      name: 'network_activity_profile_opened',
                      parameters: {
                        'post_id': post.id,
                        'author_profile_id': post.authorProfileId,
                        'source': 'overview_preview',
                      },
                    );
                    context.pushProfile(post.authorProfileId);
                  },
                ),
                loading: () => const _OverviewPreviewLoadingState(
                  icon: Icons.trending_up_rounded,
                  title: 'Carregando atividade',
                ),
                error: (e, st) {
                  debugPrint(
                    '❌ [MINHA_REDE] networkActivityAsync error: $e\n$st',
                  );
                  return _OverviewPreviewErrorState(
                    title: 'Erro ao carregar atividade.',
                    onRetry: () => _handleRefresh(activeProfile),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.explore_outlined,
              title: 'Descobrir',
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
              child: buildSuggestionBucketsState(
                dataBuilder: (buckets) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _CompactSectionLabel('Buscar perfis'),
                    _buildProfileSearchContent(),
                    const SizedBox(height: 16),
                    const _CompactSectionLabel('Sugestões'),
                    const SizedBox(height: 8),
                    _buildSuggestionFiltersRow(),
                    const SizedBox(height: 10),
                    if (buckets.experiences.isNotEmpty)
                      _NetworkingExperiencesSection(
                        activeProfile: activeProfile,
                        experiences: buckets.experiences,
                        isBusy: actionState.isLoading,
                        compact: true,
                        onViewProfile: (suggestion) {
                          _logAnalyticsEvent(
                            name: 'networking_experience_profile_opened',
                            parameters: {
                              'target_profile_id': suggestion.profile.profileId,
                              'target_profile_type':
                                  suggestion.profile.profileType.value,
                            },
                          );
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => ViewProfilePage(
                                profileId: suggestion.profile.profileId,
                              ),
                            ),
                          );
                        },
                        onConnect: (suggestion) => ref
                            .read(connectionsActionsProvider.notifier)
                            .sendRequest(recipientProfile: suggestion.profile),
                        onDismiss: (suggestion) => ref
                            .read(dismissedSuggestionsProvider.notifier)
                            .dismiss(suggestion.profile.profileId),
                      ),
                    if (buckets.experiences.isNotEmpty &&
                        buckets.generalSuggestions.isNotEmpty)
                      const SizedBox(height: 16),
                    if (buckets.generalSuggestions.isNotEmpty)
                      _SuggestionsList(
                        suggestions: buckets.generalSuggestions,
                        maxVisibleCount: _selectedSuggestionInstruments
                                    .isNotEmpty ||
                                _selectedSuggestionGenres.isNotEmpty ||
                                _selectedSuggestionProfileTypes.isNotEmpty ||
                                _suggestionLocationFilter !=
                                    _SuggestionLocationFilter.any ||
                                _suggestionCommonConnectionFilter !=
                                    _SuggestionCommonConnectionFilter.any ||
                                _suggestionSortOption !=
                                    _SuggestionSortOption.relevance
                            ? null
                            : 4,
                        isBusy: actionState.isLoading,
                        onViewProfile: (suggestion) {
                          _logAnalyticsEvent(
                            name: 'connection_suggestion_profile_opened',
                            parameters: {
                              'target_profile_id': suggestion.profile.profileId,
                              'target_profile_type':
                                  suggestion.profile.profileType.value,
                            },
                          );
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (_) => ViewProfilePage(
                                profileId: suggestion.profile.profileId,
                              ),
                            ),
                          );
                        },
                        onConnect: (suggestion) => ref
                            .read(connectionsActionsProvider.notifier)
                            .sendRequest(recipientProfile: suggestion.profile),
                        onDismiss: (suggestion) => ref
                            .read(dismissedSuggestionsProvider.notifier)
                            .dismiss(suggestion.profile.profileId),
                      ),
                    if (buckets.experiences.isNotEmpty ||
                        buckets.generalSuggestions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            _logAnalyticsEvent(
                              name: 'my_network_suggestions_view_all_tapped',
                            );
                            context.pushConnectionSuggestions();
                          },
                          icon: const Icon(Iconsax.arrow_right_3, size: 18),
                          label: const Text('Ver tudo'),
                        ),
                      ),
                    ],
                    if (buckets.experiences.isEmpty &&
                        buckets.generalSuggestions.isEmpty)
                      Text(
                        _selectedSuggestionInstruments.isNotEmpty ||
                                _selectedSuggestionGenres.isNotEmpty ||
                                _selectedSuggestionProfileTypes.isNotEmpty ||
                                _suggestionLocationFilter !=
                                    _SuggestionLocationFilter.any ||
                                _suggestionCommonConnectionFilter !=
                                    _SuggestionCommonConnectionFilter.any
                            ? 'Nenhuma sugestão para os filtros selecionados.'
                            : 'Sem novas sugestões.',
                      ),
                  ],
                ),
                debugLabel: 'discover error',
                errorMessage: 'Não foi possível carregar a descoberta.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRefresh(ProfileEntity activeProfile) async {
    if (_isRefreshing) {
      return;
    }

    _isRefreshing = true;

    _markNetworkBadgeSeen(ref);

    ref.invalidate(connectionStatsStreamProvider(activeProfile.profileId));
    ref.invalidate(
      pendingReceivedRequestsStreamProvider(
        profileId: activeProfile.profileId,
        profileUid: activeProfile.uid,
      ),
    );
    ref.invalidate(
      pendingSentRequestsStreamProvider(
        profileId: activeProfile.profileId,
        profileUid: activeProfile.uid,
      ),
    );
    ref.invalidate(connectionSuggestionsProvider);
    ref.invalidate(
      networkActivityOverviewPreviewStreamProvider(
        profileId: activeProfile.profileId,
        profileUid: activeProfile.uid,
      ),
    );
    ref.invalidate(
      myConnectionsOverviewPreviewStreamProvider(
        profileId: activeProfile.profileId,
        profileUid: activeProfile.uid,
      ),
    );

    await Future<void>.delayed(Duration.zero);

    unawaited(_refreshNetworkContent(activeProfile));
  }

  Future<void> _refreshNetworkContent(ProfileEntity activeProfile) async {
    try {
      await Future.wait<void>([
        ref.refresh(
            connectionStatsStreamProvider(activeProfile.profileId).future),
        ref.refresh(
          pendingReceivedRequestsStreamProvider(
            profileId: activeProfile.profileId,
            profileUid: activeProfile.uid,
          ).future,
        ),
        ref.refresh(
          pendingSentRequestsStreamProvider(
            profileId: activeProfile.profileId,
            profileUid: activeProfile.uid,
          ).future,
        ),
        ref.refresh(connectionSuggestionsProvider.future),
        ref.refresh(
          networkActivityOverviewPreviewStreamProvider(
            profileId: activeProfile.profileId,
            profileUid: activeProfile.uid,
          ).future,
        ),
        ref.refresh(
          myConnectionsOverviewPreviewStreamProvider(
            profileId: activeProfile.profileId,
            profileUid: activeProfile.uid,
          ).future,
        ),
      ]);
    } finally {
      _isRefreshing = false;
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
      // Analytics failure must not affect the page flow.
    }
  }
}

class _SuggestionsList extends ConsumerWidget {
  const _SuggestionsList({
    required this.suggestions,
    required this.isBusy,
    required this.onViewProfile,
    required this.onConnect,
    this.maxVisibleCount,
    this.onDismiss,
  });

  final List<ConnectionSuggestionEntity> suggestions;
  final bool isBusy;
  final void Function(ConnectionSuggestionEntity suggestion) onViewProfile;
  final Future<void> Function(ConnectionSuggestionEntity suggestion) onConnect;
  final int? maxVisibleCount;
  final void Function(ConnectionSuggestionEntity suggestion)? onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dismissedProfileIds = ref.watch(dismissedSuggestionsProvider);
    var visibleSuggestions = suggestions
        .where(
          (suggestion) => !dismissedProfileIds.contains(
            suggestion.profile.profileId,
          ),
        )
        .toList(growable: false);

    if (maxVisibleCount != null &&
        visibleSuggestions.length > maxVisibleCount!) {
      visibleSuggestions =
          visibleSuggestions.take(maxVisibleCount!).toList(growable: false);
    }

    if (visibleSuggestions.isEmpty) {
      return const Text(
        'Sem novas sugestões.',
      );
    }

    return _AnimatedSuggestionWrap(
      suggestions: visibleSuggestions,
      isBusy: isBusy,
      onViewProfile: onViewProfile,
      onConnect: onConnect,
      onDismiss: onDismiss,
    );
  }
}

class _ProfileSearchSuggestionsGrid extends StatelessWidget {
  const _ProfileSearchSuggestionsGrid({
    required this.profiles,
    required this.isBusy,
    required this.onOpenProfile,
  });

  final List<ProfileEntity> profiles;
  final bool isBusy;
  final void Function(ProfileEntity profile) onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final rawWidth = (constraints.maxWidth - spacing) / 2;
        // Guard contra constraints transientes (0/NaN/infinity) durante
        // resume de background — sem isso, SizedBox fica sem size finita
        // e RenderWrap lança "RenderBox was not laid out".
        if (!rawWidth.isFinite || rawWidth <= 0) {
          return const SizedBox.shrink();
        }
        final cardWidth = rawWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: profiles.map((profile) {
            return SizedBox(
              width: cardWidth,
              child: _ProfileSearchSuggestionCard(
                profile: profile,
                isBusy: isBusy,
                onOpenProfile: () => onOpenProfile(profile),
              ),
            );
          }).toList(growable: false),
        );
      },
    );
  }
}

class _ProfileSearchSuggestionCard extends ConsumerWidget {
  const _ProfileSearchSuggestionCard({
    required this.profile,
    required this.isBusy,
    required this.onOpenProfile,
  });

  final ProfileEntity profile;
  final bool isBusy;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestion = ConnectionSuggestionEntity(
      profile: profile,
      score: 0,
      reason: _buildSearchReason(profile),
      commonConnectionsCount: 0,
    );
    final statusAsync = ref.watch(
      effectiveConnectionStatusProvider(profile.profileId),
    );
    final activeProfile = ref.watch(activeProfileProvider);
    final canLoadCommonConnections =
        activeProfile != null && profile.uid.trim().isNotEmpty;
    final commonConnectionsCountAsync = canLoadCommonConnections
        ? ref.watch(
            commonConnectionsProvider(
              profileId: activeProfile!.profileId,
              profileUid: activeProfile.uid,
              otherProfileId: profile.profileId,
              otherProfileUid: profile.uid,
              limit: 3,
            ),
          )
        : const AsyncValue<List<CommonConnectionEntity>>.data(
            <CommonConnectionEntity>[],
          );
    final commonConnectionsCountOverride =
        commonConnectionsCountAsync.asData?.value.length;
    final commonConnectionsData = commonConnectionsCountAsync.asData?.value;
    final commonConnectionHero =
        (commonConnectionsData != null && commonConnectionsData.isNotEmpty)
            ? commonConnectionsData.first
            : null;

    return statusAsync.when(
      loading: () => _SuggestionCard(
        suggestion: suggestion,
        commonConnectionsCountOverride: commonConnectionsCountOverride,
        commonConnectionHero: commonConnectionHero,
        isBusy: true,
        isActionEnabled: false,
        onViewProfile: onOpenProfile,
        onConnect: () async {},
        actionLabel: 'Rede',
      ),
      error: (_, __) => _SuggestionCard(
        suggestion: suggestion,
        commonConnectionsCountOverride: commonConnectionsCountOverride,
        commonConnectionHero: commonConnectionHero,
        isBusy: false,
        isActionEnabled: false,
        onViewProfile: onOpenProfile,
        onConnect: () async {},
        actionLabel: 'Indisponível',
      ),
      data: (status) {
        switch (status.status) {
          case ConnectionRelationshipStatus.none:
            if (!profile.allowConnectionRequests) {
              return _SuggestionCard(
                suggestion: suggestion,
                commonConnectionsCountOverride: commonConnectionsCountOverride,
                commonConnectionHero: commonConnectionHero,
                isBusy: false,
                isActionEnabled: false,
                onViewProfile: onOpenProfile,
                onConnect: () async {},
                actionLabel: 'Convites fechados',
              );
            }

            return _SuggestionCard(
              suggestion: suggestion,
              commonConnectionsCountOverride: commonConnectionsCountOverride,
              commonConnectionHero: commonConnectionHero,
              isBusy: isBusy,
              isActionEnabled: true,
              onViewProfile: onOpenProfile,
              onConnect: () => ref
                  .read(connectionsActionsProvider.notifier)
                  .sendRequest(recipientProfile: profile),
              actionLabel: 'Conectar',
            );
          case ConnectionRelationshipStatus.pendingReceived:
            final requestId = status.requestId;
            return _SuggestionCard(
              suggestion: suggestion,
              commonConnectionsCountOverride: commonConnectionsCountOverride,
              commonConnectionHero: commonConnectionHero,
              isBusy: isBusy,
              isActionEnabled: requestId != null,
              onViewProfile: onOpenProfile,
              onConnect: requestId == null
                  ? () async {}
                  : () => ref
                      .read(connectionsActionsProvider.notifier)
                      .acceptRequest(
                        requestId: requestId,
                        otherProfileId: profile.profileId,
                      ),
              actionLabel: 'Aceitar',
            );
          case ConnectionRelationshipStatus.pendingSent:
            return _SuggestionCard(
              suggestion: suggestion,
              commonConnectionsCountOverride: commonConnectionsCountOverride,
              commonConnectionHero: commonConnectionHero,
              isBusy: false,
              isActionEnabled: false,
              onViewProfile: onOpenProfile,
              onConnect: () async {},
              actionLabel: 'Convite enviado',
            );
          case ConnectionRelationshipStatus.connected:
            return _SuggestionCard(
              suggestion: suggestion,
              commonConnectionsCountOverride: commonConnectionsCountOverride,
              commonConnectionHero: commonConnectionHero,
              isBusy: false,
              isActionEnabled: false,
              onViewProfile: onOpenProfile,
              onConnect: () async {},
              actionLabel: 'Conectado',
            );
        }
      },
    );
  }

  String _buildSearchReason(ProfileEntity profile) {
    final username = profile.username?.trim() ?? '';
    final location = formatCleanLocation(
      neighborhood: profile.neighborhood,
      city: profile.city,
      state: profile.state,
      fallback: '',
    );
    final parts = <String>[
      if (username.isNotEmpty) '@$username',
      if (location.isNotEmpty) location,
    ];

    if (parts.isNotEmpty) {
      return parts.join('\n');
    }

    final bio = profile.bio?.trim() ?? '';
    if (bio.isNotEmpty) {
      return bio;
    }

    return profile.profileType.label;
  }
}

class _AnimatedSuggestionWrap extends ConsumerStatefulWidget {
  const _AnimatedSuggestionWrap({
    required this.suggestions,
    required this.isBusy,
    required this.onViewProfile,
    required this.onConnect,
    this.onDismiss,
    this.reasonTextBuilder,
    this.actionLabelBuilder,
  });

  final List<ConnectionSuggestionEntity> suggestions;
  final bool isBusy;
  final void Function(ConnectionSuggestionEntity suggestion) onViewProfile;
  final Future<void> Function(ConnectionSuggestionEntity suggestion) onConnect;
  final void Function(ConnectionSuggestionEntity suggestion)? onDismiss;
  final String? Function(ConnectionSuggestionEntity suggestion)?
      reasonTextBuilder;
  final String Function(ConnectionSuggestionEntity suggestion)?
      actionLabelBuilder;

  @override
  ConsumerState<_AnimatedSuggestionWrap> createState() =>
      _AnimatedSuggestionWrapState();
}

class _AnimatedSuggestionWrapState
    extends ConsumerState<_AnimatedSuggestionWrap> {
  static const _dismissDuration = Duration(milliseconds: 220);

  final Set<String> _removingProfileIds = <String>{};

  Future<void> _handleConnect(ConnectionSuggestionEntity suggestion) async {
    final onDismiss = widget.onDismiss;
    final profileId = suggestion.profile.profileId;
    if (_removingProfileIds.contains(profileId)) {
      return;
    }

    if (onDismiss == null) {
      await widget.onConnect(suggestion);
      if (!mounted) {
        return;
      }

      final actionState = ref.read(connectionsActionsProvider);
      if (actionState.hasError) {
        return;
      }

      return;
    }

    setState(() {
      _removingProfileIds.add(profileId);
    });

    await Future<void>.delayed(_dismissDuration);
    if (!mounted) {
      return;
    }

    onDismiss(suggestion);

    if (!mounted) {
      return;
    }

    setState(() {
      _removingProfileIds.remove(profileId);
    });

    try {
      await widget.onConnect(suggestion);
    } catch (_) {
      if (mounted) {
        ref.read(dismissedSuggestionsProvider.notifier).remove(profileId);
      }
      rethrow;
    }

    if (!mounted) {
      return;
    }

    final actionState = ref.read(connectionsActionsProvider);
    if (actionState.hasError) {
      ref.read(dismissedSuggestionsProvider.notifier).remove(profileId);
    }
  }

  Future<void> _handleDismiss(ConnectionSuggestionEntity suggestion) async {
    final onDismiss = widget.onDismiss;
    if (onDismiss == null) {
      return;
    }

    final profileId = suggestion.profile.profileId;
    if (_removingProfileIds.contains(profileId)) {
      return;
    }

    setState(() {
      _removingProfileIds.add(profileId);
    });

    await Future<void>.delayed(_dismissDuration);
    if (!mounted) {
      return;
    }

    onDismiss(suggestion);

    if (!mounted) {
      return;
    }

    setState(() {
      _removingProfileIds.remove(profileId);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Grid 2 colunas (até 4 cards visíveis) — aspecto compacto,
    // alinhado ao padrão anterior de descoberta.
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final rawWidth = (constraints.maxWidth - spacing) / 2;
        if (!rawWidth.isFinite || rawWidth <= 0) {
          return const SizedBox.shrink();
        }
        final cardWidth = rawWidth;
        final activeProfile = ref.watch(activeProfileProvider);
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: widget.suggestions.map((suggestion) {
            final profileId = suggestion.profile.profileId;
            final isRemoving = _removingProfileIds.contains(profileId);
            final canLoadCommonConnections = activeProfile != null &&
                suggestion.profile.uid.trim().isNotEmpty;
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
            final commonConnectionHero = (commonConnectionsData != null &&
                    commonConnectionsData.isNotEmpty)
                ? commonConnectionsData.first
                : null;

            return SizedBox(
              width: cardWidth,
              child: AnimatedOpacity(
                duration: _dismissDuration,
                curve: Curves.easeOut,
                opacity: isRemoving ? 0 : 1,
                child: AnimatedScale(
                  duration: _dismissDuration,
                  curve: Curves.easeOut,
                  scale: isRemoving ? 0.96 : 1,
                  child: _SuggestionCard(
                    suggestion: suggestion,
                    commonConnectionHero: commonConnectionHero,
                    isBusy: widget.isBusy || isRemoving,
                    isActionEnabled: true,
                    onViewProfile: () => widget.onViewProfile(suggestion),
                    onConnect: () => _handleConnect(suggestion),
                    onDismiss: widget.onDismiss != null
                        ? () => _handleDismiss(suggestion)
                        : null,
                    reasonText: widget.reasonTextBuilder?.call(suggestion),
                    actionLabel: widget.actionLabelBuilder?.call(suggestion) ??
                        'Conectar',
                  ),
                ),
              ),
            );
          }).toList(growable: false),
        );
      },
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.suggestion,
    required this.isBusy,
    required this.isActionEnabled,
    required this.onViewProfile,
    required this.onConnect,
    this.onDismiss,
    this.reasonText,
    this.actionLabel = 'Conectar',
    this.commonConnectionsCountOverride,
    this.commonConnectionHero,
  });

  final ConnectionSuggestionEntity suggestion;
  final bool isBusy;
  final bool isActionEnabled;
  final VoidCallback onViewProfile;
  final Future<void> Function() onConnect;
  final VoidCallback? onDismiss;
  final String? reasonText;
  final String actionLabel;
  final int? commonConnectionsCountOverride;
  final CommonConnectionEntity? commonConnectionHero;

  static const double _headerH = 58.0;
  static const double _avatarRadius = 38.0;
  static const double _borderW = 3.0;
  // 40% of avatar circle overlaps header
  static const double _avatarCircleTop = _headerH - (_avatarRadius * 2 * 0.4);
  static const double _avatarContainerTop = _avatarCircleTop - _borderW;
  static const double _stackH =
      _avatarContainerTop + (_avatarRadius + _borderW) * 2;
  static const double _bodyH = 90.0;

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
      width: 28,
      height: 28,
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
        size: 15,
        color: iconLight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Clamp textScaler para evitar overflow do card com acessibilidade alta.
    final mq = MediaQuery.of(context);
    final clampedScaler = mq.textScaler.clamp(
      minScaleFactor: 1.0,
      maxScaleFactor: 1.15,
    );
    var commonConnectionsCount =
        commonConnectionsCountOverride ?? suggestion.commonConnectionsCount;
    final commonHero = commonConnectionHero;
    if (commonHero != null && commonConnectionsCount < 1) {
      commonConnectionsCount = 1;
    }
    final commonHeroName = commonHero?.name.trim();
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

    return MediaQuery(
      data: mq.copyWith(textScaler: clampedScaler),
      child: Container(
        constraints: const BoxConstraints(minHeight: _stackH + _bodyH + 44),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: _stackH + _bodyH,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onViewProfile,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
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
                                            top: 7,
                                            left: 7,
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
                                          child: _EntityAvatar(
                                            photoUrl:
                                                suggestion.profile.photoUrl,
                                            label: suggestion.profile.name,
                                            radius: _avatarRadius,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: _bodyH,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      suggestion.profile.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: false,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      reasonText ?? suggestion.reason,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: AppColors.textSecondary,
                                        height: 1.2,
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
                                            if (commonHero != null) ...[
                                              ClipOval(
                                                child: _EntityAvatar(
                                                  photoUrl: commonHero.photoUrl,
                                                  label: commonHero.name,
                                                  radius: 9,
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
                                                  fontSize: 10,
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
                  if (onDismiss != null)
                    Positioned(
                      top: 7,
                      right: 7,
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
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              child: OutlinedButton(
                onPressed: isBusy || !isActionEnabled ? null : onConnect,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  side: const BorderSide(
                    width: 1.5,
                    color: AppColors.primary,
                  ),
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  actionLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
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
    return _EntityAvatar(
      photoUrl: profile.photoUrl,
      label: profile.name,
      radius: radius,
    );
  }
}

class _NetworkingExperiencesSection extends ConsumerWidget {
  const _NetworkingExperiencesSection({
    required this.activeProfile,
    required this.experiences,
    required this.isBusy,
    required this.onViewProfile,
    required this.onConnect,
    this.compact = false,
    this.onDismiss,
  });

  final ProfileEntity activeProfile;
  final List<_NetworkingExperience> experiences;
  final bool isBusy;
  final bool compact;
  final void Function(ConnectionSuggestionEntity suggestion) onViewProfile;
  final Future<void> Function(ConnectionSuggestionEntity suggestion) onConnect;
  final void Function(ConnectionSuggestionEntity suggestion)? onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dismissedProfileIds = ref.watch(dismissedSuggestionsProvider);
    final visibleExperiences = experiences.where((experience) {
      return experience.suggestions.any(
        (suggestion) => !dismissedProfileIds.contains(
          suggestion.profile.profileId,
        ),
      );
    }).toList(growable: false);

    if (visibleExperiences.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) ...[
          Text(
            'Experiências de networking para o seu perfil',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            _networkingSectionIntro(activeProfile),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
        ],
        ...visibleExperiences.map(
          (experience) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _NetworkingExperienceCard(
              experience: experience,
              isBusy: isBusy,
              onViewProfile: onViewProfile,
              onConnect: onConnect,
              onDismiss: onDismiss,
            ),
          ),
        ),
      ],
    );
  }
}

class _NetworkingExperienceCard extends ConsumerWidget {
  const _NetworkingExperienceCard({
    required this.experience,
    required this.isBusy,
    required this.onViewProfile,
    required this.onConnect,
    this.onDismiss,
  });

  final _NetworkingExperience experience;
  final bool isBusy;
  final void Function(ConnectionSuggestionEntity suggestion) onViewProfile;
  final Future<void> Function(ConnectionSuggestionEntity suggestion) onConnect;
  final void Function(ConnectionSuggestionEntity suggestion)? onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dismissedProfileIds = ref.watch(dismissedSuggestionsProvider);
    final visibleSuggestions = experience.suggestions
        .where(
          (suggestion) => !dismissedProfileIds.contains(
            suggestion.profile.profileId,
          ),
        )
        .toList(growable: false);

    if (visibleSuggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: experience.accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: experience.accentColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: experience.accentColor.withValues(alpha: 0.18),
                foregroundColor: experience.accentColor,
                child: Icon(experience.icon, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      experience.title,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      experience.description,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _AnimatedSuggestionWrap(
            suggestions: visibleSuggestions,
            isBusy: isBusy,
            onViewProfile: onViewProfile,
            onConnect: onConnect,
            onDismiss: onDismiss,
            reasonTextBuilder: (suggestion) => _networkingExperienceReason(
              experience: experience,
              suggestion: suggestion,
            ),
            actionLabelBuilder: (_) => experience.ctaLabel,
          ),
        ],
      ),
    );
  }
}

class _NetworkActivityList extends StatelessWidget {
  const _NetworkActivityList({
    required this.posts,
    required this.previewLimit,
    required this.onOpenPost,
    required this.onViewProfile,
  });

  final List<PostEntity> posts;
  final int previewLimit;
  final void Function(PostEntity post) onOpenPost;
  final void Function(PostEntity post) onViewProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (posts.isEmpty) {
      return const _OverviewPreviewEmptyState(
        icon: Icons.trending_up_rounded,
        title: 'Sem novidades',
      );
    }

    final locationTextStyle = theme.textTheme.bodySmall?.copyWith(
      color: AppColors.textSecondary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          posts.length >= previewLimit
              ? '$previewLimit mais recentes'
              : '${posts.length} recentes',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onOpenPost(post),
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
                            onTap: () => onViewProfile(post),
                            child: _PostAuthorAvatar(post: post),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () => onViewProfile(post),
                                  child: Text(
                                    post.authorName?.trim().isNotEmpty == true
                                        ? post.authorName!.trim()
                                        : 'Conexao da sua rede',
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
                      Builder(
                        builder: (context) {
                          final locationLabel =
                              _networkActivityLocationLabel(post);

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _networkActivitySnippet(post),
                                      maxLines: 2,
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
                              Padding(
                                padding: const EdgeInsets.only(bottom: 1),
                                child: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PostAuthorAvatar extends StatelessWidget {
  const _PostAuthorAvatar({required this.post});

  final PostEntity post;

  @override
  Widget build(BuildContext context) {
    return _EntityAvatar(
      photoUrl: post.authorPhotoUrl,
      label: post.authorName ?? '',
      radius: 20,
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

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});

  final ConnectionStatsEntity stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: _MetricItem(
                icon: Icons.people_outline_rounded,
                label: 'Conexões',
                value: stats.totalConnections,
                color: AppColors.primary,
              ),
            ),
            Container(width: 1, height: 40, color: AppColors.divider),
            Expanded(
              child: _MetricItem(
                icon: Icons.call_received_rounded,
                label: 'Recebidos',
                value: stats.pendingReceived,
                color: AppColors.success,
              ),
            ),
            Container(width: 1, height: 40, color: AppColors.divider),
            Expanded(
              child: _MetricItem(
                icon: Icons.call_made_rounded,
                label: 'Enviados',
                value: stats.pendingSent,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(
          '$value',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _RankedProfileSearchResult {
  const _RankedProfileSearchResult({
    required this.profile,
    required this.textScore,
    this.relationshipScore = 0,
  });

  final ProfileEntity profile;
  final int textScore;
  final int relationshipScore;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.icon,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(16),
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _CompactSectionLabel extends StatelessWidget {
  const _CompactSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _OverviewPreviewLoadingState extends StatelessWidget {
  const _OverviewPreviewLoadingState({
    required this.icon,
    required this.title,
    this.message,
  });

  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (message != null && message!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    message!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewPreviewEmptyState extends StatelessWidget {
  const _OverviewPreviewEmptyState({
    required this.icon,
    required this.title,
    this.message,
  });

  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textHint, size: 22),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OverviewPreviewErrorState extends StatelessWidget {
  const _OverviewPreviewErrorState({
    required this.title,
    required this.onRetry,
    this.message,
  });

  final String title;
  final Future<void> Function() onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 22,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => unawaited(onRetry()),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _RequestList extends StatelessWidget {
  const _RequestList({
    required this.requests,
    required this.emptyMessage,
    required this.actionLabel,
    required this.isBusy,
    required this.onOpenProfile,
    required this.onPrimaryAction,
    required this.titleBuilder,
    required this.subtitleBuilder,
    this.avatarPhotoUrlBuilder,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final List<ConnectionRequestEntity> requests;
  final String emptyMessage;
  final String actionLabel;
  final String? secondaryActionLabel;
  final bool isBusy;
  final void Function(ConnectionRequestEntity request) onOpenProfile;
  final Future<void> Function(ConnectionRequestEntity request) onPrimaryAction;
  final Future<void> Function(ConnectionRequestEntity request)?
      onSecondaryAction;
  final String Function(ConnectionRequestEntity request) titleBuilder;
  final String Function(ConnectionRequestEntity request) subtitleBuilder;
  final String? Function(ConnectionRequestEntity request)?
      avatarPhotoUrlBuilder;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Text(emptyMessage);
    }

    final theme = Theme.of(context);
    final hasSecondary =
        secondaryActionLabel != null && onSecondaryAction != null;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onOpenProfile(request),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    _EntityAvatar(
                      photoUrl: avatarPhotoUrlBuilder?.call(request),
                      label: titleBuilder(request),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titleBuilder(request),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitleBuilder(request),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (hasSecondary)
                      IconButton.outlined(
                        onPressed:
                            isBusy ? null : () => onSecondaryAction!(request),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: secondaryActionLabel,
                        iconSize: 20,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(36, 36),
                          side: BorderSide(
                            color: AppColors.error.withValues(alpha: 0.5),
                          ),
                          foregroundColor: AppColors.error,
                        ),
                      ),
                    if (hasSecondary) const SizedBox(width: 4),
                    hasSecondary
                        ? IconButton.filledTonal(
                            onPressed:
                                isBusy ? null : () => onPrimaryAction(request),
                            icon: const Icon(Icons.check_rounded),
                            tooltip: actionLabel,
                            iconSize: 20,
                            style: IconButton.styleFrom(
                              minimumSize: const Size(36, 36),
                              backgroundColor:
                                  AppColors.salesBlue.withValues(alpha: 0.18),
                              foregroundColor: AppColors.salesBlue,
                            ),
                          )
                        : IconButton.outlined(
                            onPressed:
                                isBusy ? null : () => onPrimaryAction(request),
                            icon: const Icon(Icons.close_rounded),
                            tooltip: actionLabel,
                            iconSize: 20,
                            style: IconButton.styleFrom(
                              minimumSize: const Size(36, 36),
                              side: BorderSide(
                                color: AppColors.error.withValues(alpha: 0.5),
                              ),
                              foregroundColor: AppColors.error,
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ConnectionsList extends StatelessWidget {
  const _ConnectionsList({
    required this.connections,
    required this.currentProfileId,
    required this.isBusy,
    required this.locationsByProfileId,
    required this.onOpenProfile,
    required this.onMessage,
    required this.onRemove,
    this.totalCount,
  });

  final List<ConnectionEntity> connections;
  final int? totalCount;
  final String currentProfileId;
  final bool isBusy;
  final Map<String, String> locationsByProfileId;
  final void Function(ConnectionEntity connection) onOpenProfile;
  final void Function(ConnectionEntity connection) onMessage;
  final void Function(ConnectionEntity connection) onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (totalCount != null)
          Text(
            totalCount! > connections.length
                ? 'Mostrando ${connections.length} de $totalCount conexoes.'
                : 'Mostrando ${connections.length} conexoes ativas.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        if (totalCount != null) const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: connections.length,
          itemBuilder: (context, index) {
            final connection = connections[index];
            final name = connection.getOtherProfileName(currentProfileId);
            final otherProfileId =
                connection.getOtherProfileId(currentProfileId);
            final location = locationsByProfileId[otherProfileId]?.trim() ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onOpenProfile(connection),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        _EntityAvatar(
                          photoUrl: connection.getOtherProfilePhotoUrl(
                            currentProfileId,
                          ),
                          label: name,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 12,
                                    color: AppColors.textHint,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      location.isNotEmpty
                                          ? location
                                          : 'Localizacao indisponivel',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed:
                              isBusy ? null : () => onMessage(connection),
                          icon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                          ),
                          tooltip: 'Mensagem',
                          iconSize: 20,
                          color: AppColors.primary,
                        ),
                        IconButton(
                          onPressed: isBusy ? null : () => onRemove(connection),
                          icon: const Icon(Icons.link_off_rounded),
                          tooltip: 'Remover conexao',
                          iconSize: 20,
                          color: AppColors.textHint,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

Future<void> _openConversation(
  BuildContext context,
  WidgetRef ref, {
  required String currentProfileId,
  required String currentProfileUid,
  required String currentProfileName,
  String? currentProfilePhotoUrl,
  required String otherProfileId,
  required String otherProfileUid,
  required String otherProfileName,
  required String activeProfileType,
  required String source,
  String? otherProfilePhotoUrl,
}) async {
  if (otherProfileId.trim().isEmpty || otherProfileUid.trim().isEmpty) {
    AppSnackBar.showError(
      context,
      'Não foi possível abrir a conversa com este perfil.',
    );
    return;
  }

  try {
    if (AppConfig.enableAnalytics) {
      try {
        await FirebaseAnalytics.instance.logEvent(
          name: 'connection_chat_opened',
          parameters: {
            'active_profile_id': currentProfileId,
            'active_profile_type': activeProfileType,
            'target_profile_id': otherProfileId,
            'source': source,
          },
        );
      } catch (_) {
        // Analytics failure must not affect conversation navigation.
      }
    }

    final conversation =
        await ref.read(getOrCreateConversationNewUseCaseProvider)(
      currentProfileId: currentProfileId,
      currentUid: currentProfileUid,
      otherProfileId: otherProfileId,
      otherUid: otherProfileUid,
      currentProfileData: {
        'name': currentProfileName,
        'photoUrl': currentProfilePhotoUrl,
      },
      otherProfileData: {
        'name': otherProfileName,
        'photoUrl': otherProfilePhotoUrl,
      },
    );

    if (!context.mounted) return;

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ChatNewPage(
          conversationId: conversation.id,
          otherUid: otherProfileUid,
          otherProfileId: otherProfileId,
          otherName: otherProfileName,
          otherPhotoUrl: otherProfilePhotoUrl ?? '',
        ),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    AppSnackBar.showError(
      context,
      'Não foi possível abrir a conversa. Tente novamente.',
    );
  }
}

class _SectionLoader extends StatelessWidget {
  const _SectionLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(message);
  }
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();
  return '$day/$month/$year';
}

String _errorMessage(Object? error) {
  if (error is StateError) {
    return error.message;
  }
  return 'Não foi possível concluir a ação.';
}

String _initialForName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  return trimmed[0].toUpperCase();
}

String _receivedRequestSubtitle(ConnectionRequestEntity request) {
  return 'Quer entrar na sua rede • enviado em ${_formatDate(request.createdAt)}';
}

String _sentRequestSubtitle(ConnectionRequestEntity request) {
  return 'Aguardando resposta desde ${_formatDate(request.createdAt)}';
}

void _markNetworkBadgeSeen(WidgetRef ref) {
  final activeProfile = ref.read(activeProfileProvider);
  if (activeProfile == null) {
    return;
  }

  unawaited(
    ref
        .read(networkBadgeSeenAtProvider(activeProfile.profileId).notifier)
        .markSeen(),
  );
}

class _EntityAvatar extends StatelessWidget {
  const _EntityAvatar({
    required this.label,
    this.photoUrl,
    this.radius = 22,
  });

  final String label;
  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = photoUrl?.trim() ?? '';
    final initial = _initialForName(label);
    final fallback = CircleAvatar(
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

    if (trimmedUrl.isEmpty) return fallback;

    return CachedNetworkImage(
      imageUrl: trimmedUrl,
      imageBuilder: (_, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
      ),
      placeholder: (_, __) => fallback,
      errorWidget: (_, __, ___) => fallback,
    );
  }
}

_SuggestionBuckets _buildSuggestionBuckets(
  ProfileEntity activeProfile,
  List<ConnectionSuggestionEntity> suggestions, {
  required Set<String> excludedProfileIds,
  bool Function(ConnectionSuggestionEntity suggestion)? matcher,
}) {
  final availableSuggestions = suggestions
      .where(
        (suggestion) =>
            suggestion.profile.profileId != activeProfile.profileId &&
            !excludedProfileIds.contains(suggestion.profile.profileId) &&
            (matcher?.call(suggestion) ?? true),
      )
      .toList(growable: false);

  final experiences = _buildNetworkingExperiences(
    activeProfile,
    availableSuggestions,
  );
  final experienceSuggestionIds = experiences
      .expand((experience) => experience.suggestions)
      .map((suggestion) => suggestion.profile.profileId)
      .toSet();

  final generalSuggestions = availableSuggestions
      .where(
        (suggestion) =>
            !experienceSuggestionIds.contains(suggestion.profile.profileId),
      )
      .toList(growable: false);

  return _SuggestionBuckets(
    experiences: experiences,
    generalSuggestions: generalSuggestions,
  );
}

class _SuggestionBuckets {
  const _SuggestionBuckets({
    required this.experiences,
    required this.generalSuggestions,
  });

  final List<_NetworkingExperience> experiences;
  final List<ConnectionSuggestionEntity> generalSuggestions;
}

List<_NetworkingExperience> _buildNetworkingExperiences(
  ProfileEntity activeProfile,
  List<ConnectionSuggestionEntity> suggestions,
) {
  final availableSuggestions = suggestions
      .where(
        (suggestion) => suggestion.profile.profileId != activeProfile.profileId,
      )
      .toList(growable: false);

  if (availableSuggestions.isEmpty) {
    return const <_NetworkingExperience>[];
  }

  final experiences = <_NetworkingExperience>[];
  final usedProfileIds = <String>{};
  const neutralSuggestionAccent = Color(0xFF6B7280);

  void addExperience({
    required String title,
    required String description,
    required IconData icon,
    required Color accentColor,
    required String ctaLabel,
    required bool Function(ProfileEntity profile) matcher,
  }) {
    final matches = availableSuggestions
        .where(
          (suggestion) =>
              matcher(suggestion.profile) &&
              !usedProfileIds.contains(suggestion.profile.profileId),
        )
        .take(2)
        .toList(growable: false);

    if (matches.isEmpty) {
      return;
    }

    usedProfileIds.addAll(matches.map((item) => item.profile.profileId));
    experiences.add(
      _NetworkingExperience(
        title: title,
        description: description,
        icon: icon,
        accentColor: accentColor,
        ctaLabel: ctaLabel,
        suggestions: matches,
      ),
    );
  }

  if (activeProfile.isMusician) {
    addExperience(
      title: 'Bandas para somar no repertório',
      description:
          'Perfis com mais chance de render ensaio, formação ou colaboração de palco agora.',
      icon: Icons.groups_rounded,
      accentColor: neutralSuggestionAccent,
      ctaLabel: 'Conectar',
      matcher: (profile) => profile.isBandProfile,
    );
    addExperience(
      title: 'Espaços para circular melhor',
      description:
          'Casas, estúdios e pontos musicais com afinidade para ampliar sua presença local.',
      icon: Icons.storefront_rounded,
      accentColor: neutralSuggestionAccent,
      ctaLabel: 'Conectar',
      matcher: (profile) => profile.isSpace,
    );
  } else if (activeProfile.isBandProfile) {
    addExperience(
      title: 'Músicos para fortalecer a formação',
      description:
          'Perfis com fit para completar line-up, alternar instrumentação ou entrar em collabs.',
      icon: Icons.music_note_rounded,
      accentColor: neutralSuggestionAccent,
      ctaLabel: 'Conectar',
      matcher: (profile) => profile.isMusician,
    );
    addExperience(
      title: 'Espaços para agenda e parceria',
      description:
          'Lugares que podem virar palco, base de ensaio, ação de lançamento ou conexão comercial.',
      icon: Icons.location_city_rounded,
      accentColor: neutralSuggestionAccent,
      ctaLabel: 'Conectar',
      matcher: (profile) => profile.isSpace,
    );
  } else if (activeProfile.isSpace) {
    addExperience(
      title: 'Bandas para movimentar a programação',
      description:
          'Conexões com potencial para agenda, curadoria, eventos autorais e noites recorrentes.',
      icon: Icons.campaign_rounded,
      accentColor: neutralSuggestionAccent,
      ctaLabel: 'Conectar',
      matcher: (profile) => profile.isBandProfile,
    );
    addExperience(
      title: 'Músicos para ativações e comunidades',
      description:
          'Perfis que podem gerar workshops, pocket shows, aulas, jams e relacionamento local.',
      icon: Icons.people_alt_rounded,
      accentColor: neutralSuggestionAccent,
      ctaLabel: 'Conectar',
      matcher: (profile) => profile.isMusician,
    );
  }

  if (experiences.isEmpty) {
    addExperience(
      title: 'Conexões com maior potencial agora',
      description:
          'Sugestões organizadas para transformar afinidade musical em próxima conversa útil.',
      icon: Icons.hub_rounded,
      accentColor: neutralSuggestionAccent,
      ctaLabel: 'Conectar',
      matcher: (_) => true,
    );
  }

  return experiences;
}

String _networkingSectionIntro(ProfileEntity activeProfile) {
  if (activeProfile.isMusician) {
    return 'Uma leitura mais prática da sua rede para encontrar bandas e espaços que façam sentido para a sua fase musical.';
  }
  if (activeProfile.isBandProfile) {
    return 'Uma seleção pensada para ampliar formação, agenda e alcance da banda sem sair do fluxo de Minha Rede.';
  }
  if (activeProfile.isSpace) {
    return 'Uma curadoria para transformar o seu espaço em ponto de encontro entre artistas, bandas e oportunidades locais.';
  }
  return 'Perfis com mais potencial de gerar a próxima conversa relevante na sua rede.';
}

String _networkingExperienceReason({
  required _NetworkingExperience experience,
  required ConnectionSuggestionEntity suggestion,
}) {
  return suggestion.reason;
}

class _NetworkingExperience {
  const _NetworkingExperience({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.ctaLabel,
    required this.suggestions,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final String ctaLabel;
  final List<ConnectionSuggestionEntity> suggestions;
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
