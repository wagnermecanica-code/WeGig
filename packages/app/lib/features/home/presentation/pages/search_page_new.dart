// This file contains the implementation of the SearchPageNew widget.
// It is responsible for providing a refined search experience with multiple tabs.
// Ensure that the content is complete and properly formatted.
import 'package:core_ui/models/search_params.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/utils/music_constants.dart';
import 'package:core_ui/widgets/multi_select_field.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

/// Busca refinada com 4 abas (músico, banda, contratação e anúncio)
class SearchPageNew extends StatefulWidget {
  const SearchPageNew({
    required this.searchNotifier,
    required this.onApply,
    this.currentProfileId,
    super.key,
  });

  final ValueNotifier<SearchParams?> searchNotifier;
  final VoidCallback onApply;
  final String? currentProfileId;

  @override
  State<SearchPageNew> createState() => _SearchPageNewState();
}

class _SearchPageNewState extends State<SearchPageNew>
    with SingleTickerProviderStateMixin {
  static const double _maxPrice = 5000;

  late TabController _tabController;

  // Controle de filtro por tipo (aba sozinha não filtra)
  bool _musicianTypeOnly = false;
  bool _bandTypeOnly = false;
  bool _hiringTypeOnly = false;
  bool _salesTypeOnly = false;
  bool _onlyConnections = false;

  // Músico
  String? _musicianLevel;
  final Set<String> _musicianInstruments = <String>{};
  final Set<String> _musicianGenres = <String>{};
  final Set<String> _musicianAvailableFor = <String>{};
  bool _musicianHasYoutube = false;
  bool _musicianHasSpotify = false;
  bool _musicianHasDeezer = false;

  // Banda
  String? _bandLevel;
  final Set<String> _bandInstruments = <String>{};
  final Set<String> _bandGenres = <String>{};
  final Set<String> _bandAvailableFor = <String>{};
  bool _bandHasYoutube = false;
  bool _bandHasSpotify = false;
  bool _bandHasDeezer = false;

  // Contratação
  final Set<String> _hiringEventTypes = <String>{};
  final Set<String> _hiringGigFormats = <String>{};
  final Set<String> _hiringInstruments = <String>{};
  final Set<String> _hiringGenres = <String>{};
  final Set<String> _hiringVenueSetups = <String>{};
  final Set<String> _hiringBudgetRanges = <String>{};
  final Set<String> _hiringAvailableFor = <String>{};

  // Anúncios
  final Set<String> _salesTypes = <String>{};
  RangeValues _priceRange = const RangeValues(0, _maxPrice);
  bool _onlyWithDiscount = false;

  // Opções de anúncio
  static const List<String> _salesTypeOptions = <String>[
    'Venda',
    'Gravação',
    'Ensaios',
    'Aluguel',
    'Show/Evento',
    'Aula/Workshop',
    'Freela',
    'Promoção',
    'Manutenção/Reparo',
    'Outro',
  ];

  @override
  void initState() {
    super.initState();
    final current = widget.searchNotifier.value;
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: _resolveInitialTab(current),
    );
    _tabController.addListener(_handleTabChanged);
    _hydrateFromParams(current);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (!mounted || _tabController.indexIsChanging) {
      return;
    }

    setState(() {});
  }

  int _resolveInitialTab(SearchParams? params) {
    if (params == null) return 0;
    switch (params.postType) {
      case 'band':
        return 1;
      case 'hiring':
        return 2;
      case 'sales':
        return 3;
      case 'musician':
      default:
        return 0;
    }
  }

  void _hydrateFromParams(SearchParams? params) {
    if (params == null) {
      return;
    }

    _onlyConnections = params.onlyConnections;

    switch (params.postType) {
      case 'musician':
        _musicianTypeOnly = true;
        break;
      case 'band':
        _bandTypeOnly = true;
        break;
      case 'hiring':
        _hiringTypeOnly = true;
        break;
      case 'sales':
        _salesTypeOnly = true;
        break;
      default:
        break;
    }

    _musicianLevel = params.level;
    _musicianInstruments
      ..clear()
      ..addAll(params.instruments);
    _musicianGenres
      ..clear()
      ..addAll(params.genres);
    _musicianAvailableFor
      ..clear()
      ..addAll(params.availableFor);
    _musicianHasYoutube = params.hasYoutube ?? false;
    _musicianHasSpotify = params.hasSpotify ?? false;
    _musicianHasDeezer = params.hasDeezer ?? false;

    _bandLevel = params.level;
    _bandInstruments
      ..clear()
      ..addAll(params.instruments);
    _bandGenres
      ..clear()
      ..addAll(params.genres);
    _bandAvailableFor
      ..clear()
      ..addAll(params.availableFor);
    _bandHasYoutube = params.hasYoutube ?? false;
    _bandHasSpotify = params.hasSpotify ?? false;
    _bandHasDeezer = params.hasDeezer ?? false;

    _hiringEventTypes
      ..clear()
      ..addAll(params.eventTypes);
    _hiringGigFormats
      ..clear()
      ..addAll(params.gigFormats);
    _hiringInstruments
      ..clear()
      ..addAll(params.instruments);
    _hiringGenres
      ..clear()
      ..addAll(params.genres);
    _hiringVenueSetups
      ..clear()
      ..addAll(params.venueSetups);
    _hiringBudgetRanges
      ..clear()
      ..addAll(params.budgetRanges);
    _hiringAvailableFor
      ..clear()
      ..addAll(params.availableFor);

    _salesTypes
      ..clear()
      ..addAll(params.salesTypes);
    _priceRange = RangeValues(
      params.minPrice ?? 0,
      params.maxPrice ?? _maxPrice,
    );
    _onlyWithDiscount = params.onlyWithDiscount ?? false;
  }

  String? _currentSelectedPostType() {
    if (_musicianTypeOnly) return 'musician';
    if (_bandTypeOnly) return 'band';
    if (_hiringTypeOnly) return 'hiring';
    if (_salesTypeOnly) return 'sales';
    return null;
  }

  void _toggleExclusivePostType(String type, bool enabled) {
    setState(() {
      _musicianTypeOnly = false;
      _bandTypeOnly = false;
      _hiringTypeOnly = false;
      _salesTypeOnly = false;

      if (enabled) {
        switch (type) {
          case 'musician':
            _musicianTypeOnly = true;
            break;
          case 'band':
            _bandTypeOnly = true;
            break;
          case 'hiring':
            _hiringTypeOnly = true;
            break;
          case 'sales':
            _salesTypeOnly = true;
            break;
          default:
            break;
        }
      }
    });
  }

  void _applyFilters() {
    final current = widget.searchNotifier.value;
    final baseCity = current?.city ?? '';
    final baseDistance = current?.maxDistanceKm ?? 20.0;
    final selectedPostType = _currentSelectedPostType();

    SearchParams next;
    switch (_tabController.index) {
      case 1:
        next = SearchParams(
          city: baseCity,
          maxDistanceKm: baseDistance,
          onlyConnections: _onlyConnections,
          postType: selectedPostType,
          level: _bandLevel,
          instruments: Set.of(_bandInstruments),
          genres: Set.of(_bandGenres),
          availableFor: Set.of(_bandAvailableFor),
          hasYoutube: _bandHasYoutube ? true : null,
          hasSpotify: _bandHasSpotify ? true : null,
          hasDeezer: _bandHasDeezer ? true : null,
        );
        break;
      case 2:
        next = SearchParams(
          city: baseCity,
          maxDistanceKm: baseDistance,
          onlyConnections: _onlyConnections,
          postType: selectedPostType,
          instruments: Set.of(_hiringInstruments),
          genres: Set.of(_hiringGenres),
          availableFor: Set.of(_hiringAvailableFor),
          eventTypes: Set.of(_hiringEventTypes),
          gigFormats: Set.of(_hiringGigFormats),
          venueSetups: Set.of(_hiringVenueSetups),
          budgetRanges: Set.of(_hiringBudgetRanges),
        );
        break;
      case 3:
        next = SearchParams(
          city: baseCity,
          maxDistanceKm: baseDistance,
          onlyConnections: _onlyConnections,
          postType: selectedPostType,
          salesTypes: Set.of(_salesTypes),
          minPrice: _priceRange.start > 0 ? _priceRange.start : null,
          maxPrice: _priceRange.end < _maxPrice ? _priceRange.end : null,
          onlyWithDiscount: _onlyWithDiscount ? true : null,
        );
        break;
      case 0:
      default:
        next = SearchParams(
          city: baseCity,
          maxDistanceKm: baseDistance,
          onlyConnections: _onlyConnections,
          postType: selectedPostType,
          level: _musicianLevel,
          instruments: Set.of(_musicianInstruments),
          genres: Set.of(_musicianGenres),
          availableFor: Set.of(_musicianAvailableFor),
          hasYoutube: _musicianHasYoutube ? true : null,
          hasSpotify: _musicianHasSpotify ? true : null,
          hasDeezer: _musicianHasDeezer ? true : null,
        );
        break;
    }

    widget.searchNotifier.value = next;
    widget.onApply();
  }

  void _clearFilters() {
    final baseCity = widget.searchNotifier.value?.city ?? '';
    final baseDistance = widget.searchNotifier.value?.maxDistanceKm ?? 20.0;

    setState(() {
      _musicianLevel = null;
      _musicianInstruments.clear();
      _musicianGenres.clear();
      _musicianAvailableFor.clear();
      _musicianHasYoutube = false;
      _musicianHasSpotify = false;
      _musicianHasDeezer = false;

      _bandLevel = null;
      _bandInstruments.clear();
      _bandGenres.clear();
      _bandAvailableFor.clear();
      _bandHasYoutube = false;
      _bandHasSpotify = false;
      _bandHasDeezer = false;

      _hiringEventTypes.clear();
      _hiringGigFormats.clear();
      _hiringInstruments.clear();
      _hiringGenres.clear();
      _hiringVenueSetups.clear();
      _hiringBudgetRanges.clear();
      _hiringAvailableFor.clear();

      _salesTypes.clear();
      _priceRange = const RangeValues(0, _maxPrice);
      _onlyWithDiscount = false;

      _musicianTypeOnly = false;
      _bandTypeOnly = false;
      _hiringTypeOnly = false;
      _salesTypeOnly = false;
      _onlyConnections = false;
    });

    _tabController.index = 0;
    widget.searchNotifier.value = SearchParams(
      city: baseCity,
      maxDistanceKm: baseDistance,
      onlyConnections: false,
      postType: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtros'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          TextButton(
            onPressed: _clearFilters,
            child: const Text('Limpar'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: TabBar(
            controller: _tabController,
            isScrollable: false,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(icon: Icon(Iconsax.user)),
              Tab(icon: Icon(Iconsax.people)),
              Tab(icon: Icon(Iconsax.briefcase)),
              Tab(icon: Icon(Iconsax.tag)),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Somente conexões'),
              subtitle: const Text('Mostrar apenas posts seus e da sua rede.'),
              value: _onlyConnections,
              onChanged: (value) => setState(() => _onlyConnections = value),
              activeColor: AppColors.primary,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMusicianTab(),
                _buildBandTab(),
                _buildHiringTab(),
                _buildSalesTab(),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Aplicar filtros'),
                  onPressed: _applyFilters,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicianTab() {
    return _buildMusicianOrBandTab(
      title: 'Músicos',
      typeColor: AppColors.musicianColor,
      level: _musicianLevel,
      onLevelChanged: (value) => setState(() => _musicianLevel = value),
      instruments: _musicianInstruments,
      genres: _musicianGenres,
      availableFor: _musicianAvailableFor,
      onInstrumentsChanged: (value) => setState(() => _musicianInstruments
        ..clear()
        ..addAll(value)),
      onGenresChanged: (value) => setState(() => _musicianGenres
        ..clear()
        ..addAll(value)),
      onAvailableForChanged: (value) => setState(() => _musicianAvailableFor
        ..clear()
        ..addAll(value)),
      hasYoutube: _musicianHasYoutube,
      hasSpotify: _musicianHasSpotify,
      hasDeezer: _musicianHasDeezer,
      onYoutubeChanged: (v) => setState(() => _musicianHasYoutube = v),
      onSpotifyChanged: (v) => setState(() => _musicianHasSpotify = v),
      onDeezerChanged: (v) => setState(() => _musicianHasDeezer = v),
      filterTypeOnly: _musicianTypeOnly,
      onFilterTypeOnlyChanged: (enabled) => _toggleExclusivePostType('musician', enabled),
    );
  }

  Widget _buildBandTab() {
    return _buildMusicianOrBandTab(
      title: 'Bandas',
      typeColor: AppColors.bandColor,
      level: _bandLevel,
      onLevelChanged: (value) => setState(() => _bandLevel = value),
      instruments: _bandInstruments,
      genres: _bandGenres,
      availableFor: _bandAvailableFor,
      onInstrumentsChanged: (value) => setState(() => _bandInstruments
        ..clear()
        ..addAll(value)),
      onGenresChanged: (value) => setState(() => _bandGenres
        ..clear()
        ..addAll(value)),
      onAvailableForChanged: (value) => setState(() => _bandAvailableFor
        ..clear()
        ..addAll(value)),
      hasYoutube: _bandHasYoutube,
      hasSpotify: _bandHasSpotify,
      hasDeezer: _bandHasDeezer,
      onYoutubeChanged: (v) => setState(() => _bandHasYoutube = v),
      onSpotifyChanged: (v) => setState(() => _bandHasSpotify = v),
      onDeezerChanged: (v) => setState(() => _bandHasDeezer = v),
      filterTypeOnly: _bandTypeOnly,
      onFilterTypeOnlyChanged: (enabled) => _toggleExclusivePostType('band', enabled),
    );
  }

  Widget _buildMusicianOrBandTab({
    required String title,
    required Color typeColor,
    required String? level,
    required ValueChanged<String?> onLevelChanged,
    required Set<String> instruments,
    required Set<String> genres,
    required Set<String> availableFor,
    required ValueChanged<Set<String>> onInstrumentsChanged,
    required ValueChanged<Set<String>> onGenresChanged,
    required ValueChanged<Set<String>> onAvailableForChanged,
    required bool hasYoutube,
    required bool hasSpotify,
    required bool hasDeezer,
    required ValueChanged<bool> onYoutubeChanged,
    required ValueChanged<bool> onSpotifyChanged,
    required ValueChanged<bool> onDeezerChanged,
    required bool filterTypeOnly,
    required ValueChanged<bool> onFilterTypeOnlyChanged,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text('Filtrar apenas $title'),
            value: filterTypeOnly,
            onChanged: onFilterTypeOnlyChanged,
            activeColor: typeColor,
          ),
          const Divider(thickness: 0.5, height: 32),
          _buildSectionTitle(title),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            decoration: const InputDecoration(
              labelText: 'Nível',
              border: OutlineInputBorder(),
            ),
            value: level,
            items: <DropdownMenuItem<String?>>[
              const DropdownMenuItem<String?>(value: null, child: Text('Todos')),
              ...MusicConstants.levelOptions
                  .map((e) => DropdownMenuItem<String?>(value: e, child: Text(e)))
                  .toList(),
            ],
            onChanged: onLevelChanged,
          ),
          const SizedBox(height: 16),
          MultiSelectField(
            title: 'Instrumentos',
            placeholder: 'Escolha até 8',
            options: MusicConstants.instrumentOptions,
            selectedItems: instruments,
            maxSelections: 8,
            onSelectionChanged: onInstrumentsChanged,
          ),
          const SizedBox(height: 16),
          MultiSelectField(
            title: 'Gêneros',
            placeholder: 'Escolha até 8',
            options: MusicConstants.genreOptions,
            selectedItems: genres,
            maxSelections: 8,
            onSelectionChanged: onGenresChanged,
          ),
          const SizedBox(height: 16),
          MultiSelectField(
            title: 'Disponível para',
            placeholder: 'Selecione',
            options: MusicConstants.availableForOptions,
            selectedItems: availableFor,
            maxSelections: 6,
            onSelectionChanged: onAvailableForChanged,
          ),
          const SizedBox(height: 16),
          _buildStreamingRow(
            hasYoutube: hasYoutube,
            hasSpotify: hasSpotify,
            hasDeezer: hasDeezer,
            onYoutubeChanged: onYoutubeChanged,
            onSpotifyChanged: onSpotifyChanged,
            onDeezerChanged: onDeezerChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildHiringTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Filtrar apenas Contratação'),
            value: _hiringTypeOnly,
            onChanged: (enabled) => _toggleExclusivePostType('hiring', enabled),
            activeColor: AppColors.hiringColor,
          ),
          const Divider(thickness: 0.5, height: 32),
          _buildSectionTitle('Contratação'),
          const SizedBox(height: 16),
          MultiSelectField(
            title: 'Formato do show',
            placeholder: 'Selecione',
            options: MusicConstants.gigFormatOptions,
            selectedItems: _hiringGigFormats,
            maxSelections: 6,
            onSelectionChanged: (value) => setState(() => _hiringGigFormats
              ..clear()
              ..addAll(value)),
          ),
          const SizedBox(height: 16),
          MultiSelectField(
            title: 'Tipo de evento',
            placeholder: 'Selecione',
            options: MusicConstants.eventTypeOptions,
            selectedItems: _hiringEventTypes,
            maxSelections: 6,
            onSelectionChanged: (value) => setState(() => _hiringEventTypes
              ..clear()
              ..addAll(value)),
          ),
          const SizedBox(height: 16),
          MultiSelectField(
            title: 'Instrumentos',
            placeholder: 'Selecione',
            options: MusicConstants.instrumentOptions,
            selectedItems: _hiringInstruments,
            maxSelections: 10,
            onSelectionChanged: (value) => setState(() => _hiringInstruments
              ..clear()
              ..addAll(value)),
          ),
          const SizedBox(height: 16),
          MultiSelectField(
            title: 'Gêneros',
            placeholder: 'Selecione',
            options: MusicConstants.genreOptions,
            selectedItems: _hiringGenres,
            maxSelections: 10,
            onSelectionChanged: (value) => setState(() => _hiringGenres
              ..clear()
              ..addAll(value)),
          ),
          const SizedBox(height: 16),
          MultiSelectField(
            title: 'Disponível para',
            placeholder: 'Selecione',
            options: MusicConstants.availableForOptions,
            selectedItems: _hiringAvailableFor,
            maxSelections: 6,
            onSelectionChanged: (value) => setState(() => _hiringAvailableFor
              ..clear()
              ..addAll(value)),
          ),
          const SizedBox(height: 16),
          MultiSelectField(
            title: 'Estrutura',
            placeholder: 'Selecione',
            options: MusicConstants.venueSetupOptions,
            selectedItems: _hiringVenueSetups,
            maxSelections: 6,
            onSelectionChanged: (value) => setState(() => _hiringVenueSetups
              ..clear()
              ..addAll(value)),
          ),
          const SizedBox(height: 16),
          MultiSelectField(
            title: 'Orçamento',
            placeholder: 'Selecione',
            options: MusicConstants.budgetRangeOptions,
            selectedItems: _hiringBudgetRanges,
            maxSelections: 6,
            onSelectionChanged: (value) => setState(() => _hiringBudgetRanges
              ..clear()
              ..addAll(value)),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Filtrar apenas Anúncios'),
            value: _salesTypeOnly,
            onChanged: (enabled) => _toggleExclusivePostType('sales', enabled),
            activeColor: AppColors.salesColor,
          ),
          const Divider(thickness: 0.5, height: 32),
          _buildSectionTitle('Anúncios'),
          const SizedBox(height: 16),
          MultiSelectField(
            title: 'Tipo de anúncio',
            placeholder: 'Selecione',
            options: _salesTypeOptions,
            selectedItems: _salesTypes,
            maxSelections: 8,
            onSelectionChanged: (value) => setState(() => _salesTypes
              ..clear()
              ..addAll(value)),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Preço'),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: _maxPrice,
            divisions: 50,
            labels: RangeLabels(
              'R\$ ${_priceRange.start.toStringAsFixed(0)}',
              _priceRange.end >= _maxPrice
                  ? 'R\$ ${_maxPrice.toStringAsFixed(0)}+'
                  : 'R\$ ${_priceRange.end.toStringAsFixed(0)}',
            ),
            onChanged: (value) => setState(() => _priceRange = value),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Até ${_priceRange.end >= _maxPrice ? 'sem limite' : 'R\$ ${_priceRange.end.toStringAsFixed(0)}'}'),
              Text('Mín ${_priceRange.start.toStringAsFixed(0)}'),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Somente com desconto'),
            value: _onlyWithDiscount,
            onChanged: (value) => setState(() => _onlyWithDiscount = value),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamingRow({
    required bool hasYoutube,
    required bool hasSpotify,
    required bool hasDeezer,
    required ValueChanged<bool> onYoutubeChanged,
    required ValueChanged<bool> onSpotifyChanged,
    required ValueChanged<bool> onDeezerChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Streaming'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('YouTube'),
              selected: hasYoutube,
              onSelected: (value) => onYoutubeChanged(value),
              selectedColor: AppColors.primary.withOpacity(0.15),
              checkmarkColor: AppColors.primary,
            ),
            FilterChip(
              label: const Text('Spotify'),
              selected: hasSpotify,
              onSelected: (value) => onSpotifyChanged(value),
              selectedColor: AppColors.primary.withOpacity(0.15),
              checkmarkColor: AppColors.primary,
            ),
            FilterChip(
              label: const Text('Deezer'),
              selected: hasDeezer,
              onSelected: (value) => onDeezerChanged(value),
              selectedColor: AppColors.primary.withOpacity(0.15),
              checkmarkColor: AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}
