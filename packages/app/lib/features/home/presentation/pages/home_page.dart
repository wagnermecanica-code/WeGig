// WEGIG – HOME PAGE (2025, Flutter 3.24+, Dart 3.5+, Riverpod 3.x)
// Arquitetura: Instagram-style multi-profile, busca por área, mapa, carrossel flutuante, filtros, interesse otimista
// Design System: AppColors, AppTheme, WIREFRAME.md
// Refactored: Extracted sub-features (Map, Search, Feed) for better maintainability

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wegig_app/core/cache/image_cache_manager.dart';
import 'package:collection/collection.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_ui/utils/debouncer.dart';
import 'package:core_ui/utils/geo_utils.dart';
import 'package:core_ui/utils/price_calculator.dart';
import 'package:core_ui/utils/deep_link_generator.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wegig_app/app/router/app_router.dart';
import 'package:wegig_app/config/app_config.dart';
import 'package:wegig_app/core/firebase/blocked_relations.dart';
import 'package:wegig_app/features/home/data/datasources/gps_cache_service.dart';
import 'package:wegig_app/features/home/presentation/providers/map_center_provider.dart';
import 'package:wegig_app/features/home/presentation/widgets/feed/interest_service.dart';
import 'package:wegig_app/features/home/presentation/widgets/map/map_controller.dart';
import 'package:wegig_app/features/home/presentation/widgets/map/marker_builder.dart';
import 'package:wegig_app/features/home/presentation/widgets/search/search_service.dart';
import 'package:wegig_app/features/post/data/models/interest_document.dart';
import 'package:wegig_app/features/post/presentation/providers/interest_providers.dart';
import 'package:wegig_app/features/post/presentation/widgets/interest_options_dialog.dart';
import 'package:wegig_app/features/post/presentation/providers/post_providers.dart';
import 'package:wegig_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:wegig_app/features/notifications_new/presentation/providers/notifications_new_providers.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';
import 'package:wegig_app/features/report/presentation/providers/report_providers.dart';
import 'package:wegig_app/features/report/presentation/widgets/report_dialog.dart';
import 'package:wegig_app/features/connections/domain/entities/entities.dart';
import 'package:wegig_app/features/connections/presentation/providers/connections_providers.dart';
import 'package:wegig_app/features/home/presentation/widgets/feedback/feedback_bottom_sheet.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({
    super.key,
    this.searchNotifier,
    this.onOpenSearch,
    this.refreshNotifier,
  });
  final ValueNotifier<SearchParams?>? searchNotifier;
  final VoidCallback? onOpenSearch;
  final ValueNotifier<int>? refreshNotifier;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with
        AutomaticKeepAliveClientMixin<HomePage>,
        TickerProviderStateMixin,
        WidgetsBindingObserver {
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Services (extracted sub-features)
  final MapControllerWrapper _mapControllerWrapper = MapControllerWrapper();
  late final MarkerBuilder _markerBuilder;
  final SearchService _searchService = SearchService();
  // ignore: unused_field
  final InterestService _interestService = InterestService();
  final Debouncer _searchDebouncer = Debouncer(milliseconds: 300);

  // State
  List<PostEntity> _visiblePosts = [];
  Set<String> _excludedProfileIds = <String>{};
  Set<String> _connectedProfileIds = <String>{};
  StreamSubscription<List<String>>? _excludedProfileIdsSub;
  Set<Marker> _markers = {};
  String? _activePostId;
  bool _isCenteringLocation = false;
  bool _isRebuildingMarkers = false;
  DateTime? _lastMarkerRebuild;
  ProviderSubscription<AsyncValue<PostState>>? _postsSubscription;
  ProviderSubscription<ProfileEntity?>? _profileSubscription;
  ProviderSubscription<AsyncValue<List<ConnectionEntity>>>?
      _connectionsSubscription;
  Completer<GoogleMapController>? _mapControllerCompleter;
  List<PostEntity> _cachedPosts = <PostEntity>[];
  LatLng? _currentMapCenter;
  double? _currentVisibleRadiusKm;
  String? _mapAreaLabel;
  bool _isDisposed = false;
  bool _isRequestingLocationPermission =
      false; // ✅ FIX: Evita race condition de GPS

  // PageView Controller para carrossel horizontal
  late final PageController _pageController;
  bool _isProgrammaticScroll = false; // Evita loops de sync
  bool _isUserScrolling = false; // ✅ Detecta interação manual do usuário
  DateTime? _lastCarouselInteraction; // ✅ Timestamp da última interação
  DateTime?
      _lastProgrammaticScrollEnd; // ✅ Timestamp do fim do último scroll programático
  Map<String, PostEntity> _pendingPostsBuffer =
      {}; // ✅ Buffer com unicidade por ID
  bool _hasPendingUpdate = false; // ✅ Flag de update pendente
  Timer? _pendingUpdateTimer; // ✅ Timer para debounce de updates pendentes
  Timer? _markerSelectionTimer;
  ScrollDirection _lastUserScrollDirection =
      ScrollDirection.idle; // ✅ Direção do scroll do usuário

  // ✅ Auto-refresh ao voltar para o app (evita feed “travado” em cache)
  DateTime? _lastAutoRefreshAt;

  // ✅ Debouncing refinado para scroll programático (500ms após drag manual)
  static const _programmaticScrollDebounceMs = 500;

  // ✅ NOVO: Throttle para onMapIdle (evita chamadas excessivas durante movimento)
  DateTime? _lastMapIdleCall;
  static const _mapIdleThrottleMs = 350;
  bool _isProcessingMapIdle = false;
  String? _lastProcessedBoundsKey;
  DateTime? _lastProcessedBoundsAt;
  bool _markerWarmupScheduled = false;
  String? _lastMarkerRenderSignature;

  ProfileEntity? get _activeProfile =>
      ref.read(profileProvider).value?.activeProfile;

  @override
  bool get wantKeepAlive => true;

  Future<List<Map<String, dynamic>>> _fetchAddressSuggestions(
      String query) async {
    if (!mounted) return [];

    try {
      return await _searchService.fetchAddressSuggestions(query);
    } catch (e) {
      debugPrint('⚠️ Erro ao buscar endereços: $e');
      return [];
    }
  }

  void _onAddressSelected(Map<String, dynamic> suggestion) {
    if (_isDisposed || !mounted) return;

    final coordinates = _searchService.parseAddressCoordinates(suggestion);
    if (coordinates != null && _mapControllerWrapper.controller != null) {
      _mapControllerWrapper.animateToPosition(coordinates, 14);

      // Formato limpo para o texto exibido (igual ao das sugestões)
      final address = suggestion['address'] as Map<String, dynamic>? ?? {};
      final road = (address['road'] ?? address['pedestrian'] ?? '') as String;
      final houseNumber = (address['house_number'] ?? '') as String;
      final neighbourhood = (address['neighbourhood'] ??
          address['suburb'] ??
          address['quarter'] ??
          '') as String;
      final city = (address['city'] ??
          address['town'] ??
          address['village'] ??
          address['municipality'] ??
          '') as String;
      final state = (address['state'] ?? '') as String;

      final streetLine =
          [road, houseNumber].where((e) => e.isNotEmpty).join(', ');
      final List<String> secondaryParts = [];
      if (neighbourhood.isNotEmpty) secondaryParts.add(neighbourhood);
      if (city.isNotEmpty) secondaryParts.add(city);
      if (state.isNotEmpty) secondaryParts.add(state);

      final cleanDisplay = [streetLine, secondaryParts.join(' • ')]
          .where((e) => e.isNotEmpty)
          .join(' • ');

      _searchController.text = cleanDisplay.isNotEmpty
          ? cleanDisplay
          : _searchService.getDisplayName(suggestion) ?? '';
      _searchFocusNode.unfocus();
    }
  }
  // ========================= CICLO DE VIDA =========================

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(viewportFraction: 0.88);
    // ✅ Listener refinado para detectar scroll do usuário via position
    _pageController.addListener(_onPageControllerUpdate);
    _markerBuilder = MarkerBuilder();
    _initializePage();
    widget.refreshNotifier?.addListener(_onExternalRefresh);
    _initializePostListener();
    _initializeProfileListener();
    _initializeExcludedProfileIdsListener();
    _initializeConnectionsListener();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || _isDisposed) return;

    // Ao entrar em background: liberar cache de markers (bitmaps custosos)
    // para reduzir `phys_footprint` e diminuir chance de jetsam no iOS 26.
    // Os markers são re-gerados sob demanda no retorno ao foreground.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _markerBuilder.clearCaches();
      return;
    }

    if (state != AppLifecycleState.resumed) return;

    // Evita invalidar em loop quando o app alterna rapidamente entre foreground/background.
    final now = DateTime.now();
    final last = _lastAutoRefreshAt;
    if (last != null && now.difference(last) < const Duration(seconds: 20)) {
      return;
    }
    _lastAutoRefreshAt = now;

    ref.invalidate(postNotifierProvider);
    _scheduleVisiblePostsRefresh();
  }

  /// ✅ Listener do PageController para detecção refinada de scroll
  void _onPageControllerUpdate() {
    if (!mounted || !_pageController.hasClients) return;

    final position = _pageController.position;

    // Detecta direção do scroll do usuário
    if (position.userScrollDirection != ScrollDirection.idle) {
      _lastUserScrollDirection = position.userScrollDirection;

      // Se não é scroll programático, marca como interação do usuário
      if (!_isProgrammaticScroll) {
        _isUserScrolling = true;
        _lastCarouselInteraction = DateTime.now();
      }
    }
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshNotifier != widget.refreshNotifier) {
      oldWidget.refreshNotifier?.removeListener(_onExternalRefresh);
      widget.refreshNotifier?.addListener(_onExternalRefresh);
    }
  }

  @override
  void dispose() {
    // ✅ FIX: Dispose all controllers to prevent memory leaks
    // NOTA: Não usar ref.read() no dispose - causa "Cannot use ref after disposed"
    WidgetsBinding.instance.removeObserver(this);
    _postsSubscription?.close();
    _profileSubscription?.close();
    _connectionsSubscription?.close();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mapControllerWrapper.dispose();
    _searchDebouncer.dispose(); // ✅ Cancela Timer pendente
    _markerBuilder.dispose();
    _pendingUpdateTimer?.cancel(); // ✅ Cancela timer de updates pendentes
    _markerSelectionTimer?.cancel();
    _excludedProfileIdsSub?.cancel();
    _pageController.removeListener(
        _onPageControllerUpdate); // ✅ Remove listener antes do dispose
    _pageController.dispose(); // ✅ Dispose do PageController
    widget.searchNotifier?.removeListener(_onSearchChanged);
    widget.refreshNotifier?.removeListener(_onExternalRefresh);
    _isDisposed = true;
    super.dispose();
  }

  void _initializeExcludedProfileIdsListener() {
    _excludedProfileIdsSub?.cancel();
    final activeProfile = ref.read(activeProfileProvider);
    final profileId = activeProfile?.profileId?.trim();
    final uid = activeProfile?.uid?.trim();

    if (profileId == null || profileId.isEmpty) {
      _excludedProfileIds = <String>{};
      return;
    }

    // Seed quickly to avoid briefly showing excluded content.
    unawaited(_refreshExcludedProfileIdsOnce(profileId, uid: uid));

    _excludedProfileIdsSub = BlockedRelations.watchExcludedProfileIds(
      firestore: FirebaseFirestore.instance,
      profileId: profileId,
      uid: uid,
    ).listen(
      (excluded) {
        if (!mounted || _isDisposed) return;
        final next = excluded.toSet();
        if (const SetEquality<String>().equals(_excludedProfileIds, next))
          return;

        setState(() {
          _excludedProfileIds = next;
        });
        _scheduleVisiblePostsRefresh();
      },
      onError: (e, _) {
        debugPrint(
            '⚠️ HomePage: Falha ao observar excludedProfileIds (non-critical): $e');
      },
    );
  }

  Future<void> _refreshExcludedProfileIdsOnce(String profileId,
      {String? uid}) async {
    try {
      final excluded = await BlockedRelations.getExcludedProfileIds(
        firestore: FirebaseFirestore.instance,
        profileId: profileId,
        uid: uid,
      );
      if (!mounted || _isDisposed) return;
      setState(() {
        _excludedProfileIds = excluded.toSet();
      });
      _scheduleVisiblePostsRefresh();
    } catch (e) {
      debugPrint(
          '⚠️ HomePage: Falha ao carregar excludedProfileIds (non-critical): $e');
    }
  }

  List<PostEntity> _filterExcludedPosts(List<PostEntity> posts) {
    if (_excludedProfileIds.isEmpty || posts.isEmpty) return posts;
    return posts
        .where((p) => !_excludedProfileIds.contains(p.authorProfileId))
        .toList();
  }

  List<PostEntity> _filterExpiredPosts(List<PostEntity> posts) {
    if (posts.isEmpty) return posts;
    final now = DateTime.now();

    return posts.where((post) {
      // Para posts "sales", a validade é promoEndDate; para outros, expiresAt
      // Fallback: se ausente, assume 30 dias após createdAt
      final DateTime effectiveExpiry;
      if (post.type == 'sales') {
        effectiveExpiry = post.promoEndDate ??
            post.expiresAt ??
            post.createdAt.add(const Duration(days: 30));
      } else {
        effectiveExpiry =
            post.expiresAt ?? post.createdAt.add(const Duration(days: 30));
      }
      return effectiveExpiry.isAfter(now);
    }).toList();
  }

  void _initializePostListener() {
    _postsSubscription?.close();
    _postsSubscription = ref.listenManual(
      postNotifierProvider,
      (previous, next) {
        if (next.hasValue) {
          _cachedPosts =
              _filterExpiredPosts(next.value?.posts ?? const <PostEntity>[]);
          _scheduleVisiblePostsRefresh();
        } else if (next.hasError) {
          _cachedPosts = <PostEntity>[];
        }
      },
    );

    final initialState = ref.read(postNotifierProvider);
    if (initialState.hasValue) {
      _cachedPosts = _filterExpiredPosts(
          initialState.value?.posts ?? const <PostEntity>[]);
      _scheduleVisiblePostsRefresh();
    } else if (initialState.hasError) {
      _cachedPosts = <PostEntity>[];
    }
  }

  void _initializeProfileListener() {
    _profileSubscription?.close();
    _profileSubscription = ref.listenManual<ProfileEntity?>(
      activeProfileProvider,
      (previous, nextProfile) {
        final previousId = previous?.profileId;
        final nextId = nextProfile?.profileId;

        if (nextId == null || nextId == previousId) return;

        // ✅ Blocking is per-profile.
        // HomePage is kept alive (IndexedStack), so we must re-subscribe when
        // the active profile changes; otherwise exclusions from the previous
        // profile would incorrectly affect the new one.
        _initializeExcludedProfileIdsListener();
        _initializeConnectionsListener();

        ref.read(mapCenterProvider.notifier).reset(nextId);
        _primeInitialCameraTarget(nextProfile);

        // ✅ IMPORTANT: HomePage keeps state alive (IndexedStack + keepAlive).
        // When the active profile changes but the visible posts list (ids/order)
        // stays the same, the page would not refresh derived UI (distances,
        // "is my post" flags, etc) because updates were only triggered on
        // posts list changes.
        if (!mounted || _isDisposed) return;

        setState(() {
          _updatePostDistances();
        });

        // Re-run map filtering logic in case profile-dependent filters apply.
        _scheduleVisiblePostsRefresh();
      },
    );

    final initialProfile = ref.read(activeProfileProvider);
    if (initialProfile != null) {
      _primeInitialCameraTarget(initialProfile);
    }
  }

  void _initializeConnectionsListener() {
    _connectionsSubscription?.close();

    final activeProfile = ref.read(activeProfileProvider);
    final profileId = activeProfile?.profileId.trim();
    final profileUid = activeProfile?.uid.trim();

    if (profileId == null ||
        profileId.isEmpty ||
        profileUid == null ||
        profileUid.isEmpty) {
      if (_connectedProfileIds.isNotEmpty && mounted && !_isDisposed) {
        setState(() {
          _connectedProfileIds = <String>{};
        });
      } else {
        _connectedProfileIds = <String>{};
      }
      return;
    }

    final provider = myConnectionsStreamProvider(
      profileId: profileId,
      profileUid: profileUid,
    );

    _connectionsSubscription =
        ref.listenManual<AsyncValue<List<ConnectionEntity>>>(
      provider,
      (previous, next) {
        final nextIds = (next.valueOrNull ?? const <ConnectionEntity>[])
            .map((connection) => connection.getOtherProfileId(profileId))
            .where((otherProfileId) => otherProfileId.trim().isNotEmpty)
            .toSet();

        if (const SetEquality<String>().equals(_connectedProfileIds, nextIds)) {
          return;
        }

        if (!mounted || _isDisposed) {
          _connectedProfileIds = nextIds;
          return;
        }

        setState(() {
          _connectedProfileIds = nextIds;
        });
        _scheduleVisiblePostsRefresh();
      },
    );

    final initialValue = ref.read(provider);
    final initialIds = (initialValue.valueOrNull ?? const <ConnectionEntity>[])
        .map((connection) => connection.getOtherProfileId(profileId))
        .where((otherProfileId) => otherProfileId.trim().isNotEmpty)
        .toSet();
    _connectedProfileIds = initialIds;
  }

  void _scheduleVisiblePostsRefresh() {
    if (_isDisposed || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_onMapIdle());
    });
  }

  Future<void> _initializePage() async {
    // Cloud-based Map Styling é usado via cloudMapId - não precisa carregar estilo local
    await _initializeMap();
    _scheduleMarkerWarmup();
    widget.searchNotifier?.addListener(_onSearchChanged);

    // ⚠️ MIGRAÇÃO REMOVIDA - causava loop de aumento de preços
    // A migração foi removida porque a lógica estava invertida:
    // o código já salva o preço ORIGINAL no Firestore, mas a migração
    // assumia que era o preço FINAL e tentava "recuperar" o original,
    // causando inflação progressiva a cada visualização/edição.
  }

  // ========================= MÉTODOS DE LÓGICA =========================

  /// Conta quantos filtros estão ativos no momento
  int _getActiveFiltersCount() {
    final params = widget.searchNotifier?.value;
    if (params == null) return 0;

    int count = 0;

    // Filtros de músicos/bandas
    if (params.level != null) count++;
    if (params.instruments.isNotEmpty) count++;
    if (params.genres.isNotEmpty) count++;
    if (params.availableFor.isNotEmpty) count++;
    if (params.eventTypes.isNotEmpty) count++;
    if (params.gigFormats.isNotEmpty) count++;
    if (params.venueSetups.isNotEmpty) count++;
    if (params.budgetRanges.isNotEmpty) count++;
    if (params.hasYoutube == true) count++;
    if (params.hasSpotify == true) count++;
    if (params.hasDeezer == true) count++;
    if (params.onlyConnections) count++;
    // postType só é definido quando o toggle "Filtrar apenas" está ativo
    if (params.postType != null && params.postType!.isNotEmpty) count++;

    // Filtros de anúncios
    if (params.salesTypes.isNotEmpty) count++;
    if (params.minPrice != null) count++;
    if (params.maxPrice != null) count++;
    if (params.onlyWithDiscount == true) count++;

    // Filtro de username
    if (params.searchUsername != null && params.searchUsername!.isNotEmpty)
      count++;

    return count;
  }

  void _onSearchChanged() {
    debugPrint(
        '🔍 HomePage._onSearchChanged: searchNotifier.value = ${widget.searchNotifier?.value}');
    if (mounted) {
      _onMapIdle();
    }
  }

  void _onExternalRefresh() {
    if (!mounted) return;
    ref.invalidate(postNotifierProvider);
    if (_pageController.hasClients && _visiblePosts.isNotEmpty) {
      // Scroll suave para o primeiro card antes do refresh
      _isProgrammaticScroll = true;
      _pageController
          .animateToPage(
            0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          )
          .whenComplete(() => _isProgrammaticScroll = false);
    }
    _scheduleVisiblePostsRefresh();
    unawaited(_centerOnUserLocation());
  }

  /// Calcula distância entre post e perfil ativo
  double? _calculatePostDistance(PostEntity post) {
    final profile = _activeProfile;
    final postLocation = post.location;
    if (profile == null) return null;

    return calculateDistanceBetweenGeoPoints(profile.location, postLocation);
  }

  /// Atualiza distâncias de todos os posts visíveis
  void _updatePostDistances() {
    if (_activeProfile == null) return;

    _visiblePosts = _visiblePosts.map((post) {
      final distance = _calculatePostDistance(post);
      return post.copyWith(distanceKm: distance);
    }).toList();
  }

  Future<void> _rebuildMarkers({bool force = false}) async {
    if (!mounted || _isRebuildingMarkers) return;

    final renderSignature = _buildMarkerRenderSignature();
    if (!force && renderSignature == _lastMarkerRenderSignature) {
      debugPrint(
          '🗺️ _rebuildMarkers: Pulando rebuild (assinatura inalterada)');
      return;
    }

    if (_visiblePosts.isEmpty) {
      _lastMarkerRenderSignature = renderSignature;
      if (_markers.isEmpty) return;

      setState(() => _markers = <Marker>{});
      debugPrint('🗺️ _rebuildMarkers: Limpando marcadores vazios');
      return;
    }

    // ✅ OTIMIZAÇÃO: Debounce reduzido para 300ms (era 500ms)
    final now = DateTime.now();
    if (!force &&
        _lastMarkerRebuild != null &&
        now.difference(_lastMarkerRebuild!).inMilliseconds < 300) {
      debugPrint(
          '🗺️ _rebuildMarkers: Pulando rebuild (debounce ${now.difference(_lastMarkerRebuild!).inMilliseconds}ms)');
      return;
    }

    debugPrint(
        '🗺️ _rebuildMarkers: Iniciando rebuild de ${_visiblePosts.length} posts...');
    _isRebuildingMarkers = true;
    _lastMarkerRebuild = now;

    await _markerBuilder.primeForPosts(
      _visiblePosts,
      activePostId: _activePostId,
      maxPosts: 6,
    );

    // ✅ OTIMIZAÇÃO: Cache inteligente no MarkerBuilder evita reconstruções
    final markers = await _markerBuilder.buildMarkersForPosts(
      _visiblePosts,
      _activePostId,
      _onMarkerTapped,
    );

    if (mounted) {
      // ✅ OTIMIZAÇÃO: Usa Future.microtask para agendar rebuild pós-frame
      Future.microtask(() {
        if (mounted && !_isDisposed) {
          setState(() => _markers = markers);
          _lastMarkerRenderSignature = renderSignature;
          debugPrint(
              '🗺️ _rebuildMarkers: Marcadores atualizados (${markers.length}) [cache: ${_markerBuilder.cacheStats}]');
        }
      });
    }

    _isRebuildingMarkers = false;
  }

  Future<void> _onMarkerTapped(PostEntity post) async {
    if (!mounted) return;

    final newActivePostId = _activePostId == post.id ? null : post.id;

    setState(() {
      _activePostId = newActivePostId;
    });

    if (_activePostId != null) {
      // ✅ Anima para a posição do post mantendo o zoom atual (sem zoom in)
      await _mapControllerWrapper.animateToPosition(
        geoPointToLatLng(post.location),
        _mapControllerWrapper.currentZoom,
      );

      // ✅ Sync: Marcador → Card - anima o PageView para o card correspondente
      final postIndex = _visiblePosts.indexWhere((p) => p.id == post.id);
      if (postIndex != -1 && _pageController.hasClients) {
        _isProgrammaticScroll = true;
        await _pageController.animateToPage(
          postIndex,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
        _isProgrammaticScroll = false;
      }
    }

    // Reconstrói marcadores com novo estado ativo
    await _rebuildMarkers(force: true);
  }

  /// ✅ Sync: Card → Marcador - chamado quando o PageView muda de página
  void _onPageChanged(int index) {
    if (_isProgrammaticScroll || !mounted) return;
    if (index < 0 || index >= _visiblePosts.length) return;

    final post = _visiblePosts[index];

    // ✅ Registra interação do usuário
    _lastCarouselInteraction = DateTime.now();

    _scheduleMarkerSelectionUpdate(post);
  }

  void _closeCard() {
    if (!mounted) return;
    setState(() => _activePostId = null);
    // Reconstrói marcadores para remover estado ativo
    _rebuildMarkers(force: true);
  }

  void _scheduleMarkerSelectionUpdate(
    PostEntity post, {
    Duration delay = Duration.zero,
  }) {
    _markerSelectionTimer?.cancel();
    _markerSelectionTimer = Timer(delay, () {
      if (!mounted || _isDisposed) return;
      if (_activePostId == post.id) return;

      setState(() {
        _activePostId = post.id;
      });

      _mapControllerWrapper.animateToPosition(
        geoPointToLatLng(post.location),
        _mapControllerWrapper.currentZoom,
      );

      unawaited(_rebuildMarkers(force: true));
    });
  }

  /// Centraliza mapa no GPS do usuário com fallbacks
  /// Ordem: Cache → GPS atual (10s) → LastKnown → Perfil
  Future<void> _centerOnUserLocation() async {
    if (!mounted || _isCenteringLocation) return;

    try {
      setState(() => _isCenteringLocation = true);

      final controller = await _waitForMapController();
      if (controller == null) {
        AppSnackBar.showInfo(context, 'Aguarde o mapa carregar...');
        return;
      }

      LatLng? targetPos;

      // Estratégia 1: Cache GPS (<24h) - instantâneo
      if (_mapControllerWrapper.currentPosition != null) {
        targetPos = _mapControllerWrapper.currentPosition;
        debugPrint('📍 Usando posição em cache');
      } else {
        // Estratégia 2: GPS atual com timeout de 10s
        final permission = await Geolocator.checkPermission();
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();

        if (permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever &&
            serviceEnabled) {
          try {
            debugPrint('📍 Obtendo GPS atual...');
            final position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            ).timeout(const Duration(seconds: 10));

            targetPos = LatLng(position.latitude, position.longitude);
            if (mounted) {
              setState(
                  () => _mapControllerWrapper.setCurrentPosition(targetPos!));
            }
            await GpsCacheService.updateCache(targetPos);
            debugPrint('✅ GPS atual obtido');
            AppSnackBar.showSuccess(context, 'Localização atualizada');
          } catch (timeoutError) {
            debugPrint('⚠️ GPS timeout, tentando fallback...');

            // Estratégia 3: LastKnown do Geolocator
            final lastPosition = await Geolocator.getLastKnownPosition();
            if (lastPosition != null) {
              targetPos = LatLng(lastPosition.latitude, lastPosition.longitude);
              if (mounted) {
                setState(
                    () => _mapControllerWrapper.setCurrentPosition(targetPos!));
              }
              debugPrint('📍 Usando última posição conhecida');
              AppSnackBar.showInfo(
                  context, 'GPS timeout. Usando última localização.');
            } else {
              // Estratégia 4: Localização do perfil (sempre disponível)
              final profile = _activeProfile;
              final profileLocation = profile?.location;
              if (profileLocation != null) {
                targetPos = geoPointToLatLng(profileLocation);
                debugPrint('📍 Usando localização do perfil');
                AppSnackBar.showInfo(
                    context, 'GPS indisponível. Usando local do perfil.');
              }
            }
          }
        } else {
          // Permissões negadas ou GPS desativado - ir direto para perfil
          final profile = _activeProfile;
          final profileLocation = profile?.location;
          if (profileLocation != null) {
            targetPos = geoPointToLatLng(profileLocation);
            debugPrint('📍 GPS não disponível, usando perfil');

            if (!serviceEnabled) {
              AppSnackBar.showWarning(
                  context, 'GPS desativado. Ative nas configurações.');
            } else {
              AppSnackBar.showWarning(
                  context, 'Permissão de localização necessária');
            }
          }
        }
      }

      // Centralizar no mapa
      if (targetPos != null) {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(targetPos, 14),
        );
      } else {
        AppSnackBar.showError(context, 'Não foi possível obter localização');
      }
    } catch (e) {
      debugPrint('❌ Erro ao centralizar: $e');

      if (!e.toString().contains('channel-error')) {
        AppSnackBar.showError(context, 'Erro ao obter localização');
      }
    } finally {
      if (mounted) {
        setState(() => _isCenteringLocation = false);
      } else {
        _isCenteringLocation = false;
      }
    }
  }

  // ...existing code...

  Future<void> _sendInterestNotification(PostEntity post) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final activeProfile = _activeProfile;

    if (currentUser == null || activeProfile == null) {
      throw Exception('Usuário não autenticado ou perfil não ativo.');
    }

    // ✅ VALIDAÇÃO CRÍTICA: Verificar se post tem authorUid
    String authorUid = post.authorUid;

    if (authorUid.isEmpty) {
      debugPrint(
          '⚠️ AVISO: post.authorUid vazio, tentando recuperar do Firestore...');

      try {
        // Tentar recarregar o post do Firestore para obter authorUid
        final postDoc = await FirebaseFirestore.instance
            .collection('posts')
            .doc(post.id)
            .get();

        if (!postDoc.exists) {
          throw Exception('Post ${post.id} não encontrado no Firestore');
        }

        final postData = postDoc.data()!;
        authorUid = postData['authorUid'] as String? ?? '';

        if (authorUid.isEmpty) {
          throw Exception('Post ${post.id} não tem authorUid no Firestore');
        }

        debugPrint('✅ authorUid recuperado do Firestore: $authorUid');
      } catch (e) {
        debugPrint('❌ Erro ao recuperar authorUid: $e');
        throw Exception('Post sem informações de autor válidas');
      }
    }

    // Validar campos obrigatórios
    if (post.id.isEmpty) throw Exception('postId está vazio');
    if (post.authorProfileId.isEmpty)
      throw Exception('postAuthorProfileId está vazio');
    if (activeProfile.profileId.isEmpty)
      throw Exception('interestedProfileId está vazio');
    if (activeProfile.name.isEmpty)
      throw Exception('interestedProfileName está vazio');

    debugPrint('✅ Criando documento de interesse:');
    debugPrint('  - postId: ${post.id}');
    debugPrint('  - postAuthorUid: $authorUid');
    debugPrint('  - postAuthorProfileId: ${post.authorProfileId}');
    debugPrint('  - interestedProfileId: ${activeProfile.profileId}');

    // ✅ Usar factory padronizada para garantir estrutura consistente
    final interestData = InterestDocumentFactory.create(
      postId: post.id,
      postAuthorUid: authorUid,
      postAuthorProfileId: post.authorProfileId,
      currentUserUid: currentUser.uid,
      activeProfileUid: activeProfile.uid,
      activeProfileId: activeProfile.profileId,
      activeProfileName: activeProfile.name,
      activeProfileUsername: activeProfile.username,
      activeProfilePhotoUrl: activeProfile.photoUrl,
    );

    await FirebaseFirestore.instance.collection('interests').add(interestData);

    debugPrint('✅ Documento de interesse criado com sucesso');

    // ⚠️ REMOVIDO: Notificação duplicada - a Cloud Function `sendInterestNotification`
    // já cria a notificação automaticamente via trigger onCreate em interests/{interestId}
  }

  double? _calculateDistanceToPost(PostEntity post, ProfileEntity profile) {
    try {
      return calculateDistanceBetweenGeoPoints(
        post.location,
        profile.location,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _sendInterestOptimistically(PostEntity post) async {
    if (!mounted) return;

    // ✅ LOG 1: Validação prévia
    debugPrint('🔍 _sendInterestOptimistically: postId=${post.id}');
    debugPrint('🔍 authorProfileId=${post.authorProfileId}');
    debugPrint('🔍 authorUid=${post.authorUid}');

    // ✅ VALIDAÇÃO PRÉVIA: Verificar se post tem dados necessários
    if (post.id.isEmpty) {
      AppSnackBar.showError(context, 'Erro: Post inválido (ID vazio)');
      return;
    }
    if (post.authorProfileId.isEmpty) {
      AppSnackBar.showError(context, 'Erro: Post sem autor');
      return;
    }

    // ✅ MUDANÇA: Usar provider global ao invés de Set local
    final interestNotifier = ref.read(interestNotifierProvider.notifier);

    // ✅ Verificar se já não demonstrou interesse (evitar duplicatas)
    if (interestNotifier.hasInterest(post.id)) {
      AppSnackBar.showInfo(context, 'Você já demonstrou interesse neste post');
      return;
    }

    final isSalesPost = post.type == 'sales';

    try {
      // ✅ Chamar provider global (Optimistic Update já incluído)
      // A Cloud Function `sendInterestNotification` cria a notificação automaticamente
      // quando o documento é adicionado na collection `interests`
      await interestNotifier.addInterest(
        postId: post.id,
        postAuthorUid: post.authorUid,
        postAuthorProfileId: post.authorProfileId,
      );

      // ⚠️ REMOVIDO: Notificação duplicada - a Cloud Function já cria a notificação
      // via trigger onCreate em interests/{interestId}

      if (mounted) {
        AppSnackBar.showSuccess(
          context,
          isSalesPost ? 'Anúncio salvo!' : 'Interesse enviado!',
        );
      }

      debugPrint('Interesse registrado com sucesso para post ${post.id}');
    } catch (e, stackTrace) {
      debugPrint('❌ Erro ao enviar interesse: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        // Mensagem de erro específica baseada no tipo de exceção
        String errorMessage = 'Erro ao enviar interesse';
        if (e.toString().contains('authorUid') ||
            e.toString().contains('autor')) {
          errorMessage = 'Erro: Post sem informações de autor';
        } else if (e.toString().contains('permission')) {
          errorMessage = 'Erro: Sem permissão para criar interesse';
        } else if (e.toString().contains('network') ||
            e.toString().contains('connection')) {
          errorMessage = 'Erro: Verifique sua conexão com a internet';
        }

        AppSnackBar.showError(context, errorMessage);
      }
    }
  }

  /// Remove interesse de um post (Abordagem Otimista)
  Future<void> _removeInterestOptimistically(PostEntity post) async {
    if (!mounted) return;

    try {
      // ✅ MUDANÇA: Usar provider global
      await ref.read(interestNotifierProvider.notifier).removeInterest(
            postId: post.id,
          );

      if (mounted) {
        AppSnackBar.showInfo(context, 'Interesse removido');
      }

      debugPrint('Interesse removido com sucesso do Firestore');
    } catch (e, stackTrace) {
      debugPrint('❌ Erro ao remover interesse: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        String errorMessage = 'Erro ao remover interesse';
        if (e.toString().contains('permission')) {
          errorMessage = 'Erro: Sem permissão para remover interesse';
        } else if (e.toString().contains('not-found')) {
          errorMessage = 'Interesse não encontrado';
        }

        AppSnackBar.showError(context, errorMessage);
      }
    }
  }

  void _showInterestOptionsDialog(PostEntity post) {
    HapticFeedback.mediumImpact();
    final hasInterest = ref.read(interestNotifierProvider).contains(post.id);
    final isOwner = post.authorProfileId == _activeProfile?.profileId;

    showInterestOptionsDialog(
      context: context,
      post: post,
      isInterestSent: hasInterest,
      isOwner: isOwner,
      onSendInterest: () => _sendInterestOptimistically(post),
      onRemoveInterest: () => _removeInterestOptimistically(post),
      onDeletePost: () => _confirmDeletePost(post),
      onViewProfile: () => context.pushProfile(post.authorProfileId),
    );
  }

  /// Compartilha post usando deep link (mesmo padrão do PostFeed)
  void _sharePostWithDeepLink(PostEntity post) {
    HapticFeedback.lightImpact();
    final text = DeepLinkGenerator.generatePostShareMessage(
      postId: post.id,
      authorName: post.authorName ?? 'Anônimo',
      postType: post.type,
      city: post.city,
      neighborhood: post.neighborhood,
      state: post.state,
      content: post.content,
      instruments: post.instruments,
      genres: post.genres,
      title: post.title,
      salesType: post.salesType,
      price: post.price,
      discountMode: post.discountMode,
      discountValue: post.discountValue,
    );
    SharePlus.instance.share(ShareParams(text: text));
  }

  void _confirmDeletePost(PostEntity post) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deletar Post'),
        content: const Text(
            'Tem certeza que deseja deletar este post? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deletePost(post);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost(PostEntity post) async {
    try {
      // Mostrar loading
      AppSnackBar.showInfo(context, 'Deletando post...');

      // Deletar TODAS as fotos do Storage se existirem (carrossel)
      for (final photoUrl in post.photoUrls) {
        if (photoUrl.isNotEmpty) {
          try {
            final ref = FirebaseStorage.instance.refFromURL(photoUrl);
            await ref.delete();
            debugPrint('✅ Foto deletada: $photoUrl');
          } catch (e) {
            debugPrint('⚠️ Erro ao deletar foto: $e');
          }
        }
      }
      // Fallback: deletar photoUrl antigo se existir e não estiver em photoUrls
      if (post.photoUrl != null &&
          post.photoUrl!.isNotEmpty &&
          !post.photoUrls.contains(post.photoUrl)) {
        try {
          final ref = FirebaseStorage.instance.refFromURL(post.photoUrl!);
          await ref.delete();
        } catch (e) {
          debugPrint('⚠️ Erro ao deletar foto legada: $e');
        }
      }

      // Deletar post do Firestore
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(post.id)
          .delete();

      if (mounted) {
        // Remover imediatamente das listas locais para refletir no carrossel/mapa
        setState(() {
          _cachedPosts = _cachedPosts.where((p) => p.id != post.id).toList();
          _visiblePosts = _visiblePosts.where((p) => p.id != post.id).toList();
          _pendingPostsBuffer.remove(post.id);
          _hasPendingUpdate = _pendingPostsBuffer.isNotEmpty;

          if (_activePostId == post.id) {
            _activePostId =
                _visiblePosts.isNotEmpty ? _visiblePosts.first.id : null;
          }

          _updatePostDistances();
        });

        // Garantir que o PageView fique em um índice válido após a remoção
        if (_pageController.hasClients && _visiblePosts.isNotEmpty) {
          final targetIndex =
              _visiblePosts.indexWhere((p) => p.id == _activePostId);
          _pageController.jumpToPage(targetIndex >= 0 ? targetIndex : 0);
        }

        // Atualiza marcadores e provedor para sincronizar demais assinantes
        _rebuildMarkers(force: true);
        ref.invalidate(postNotifierProvider);
        AppSnackBar.showSuccess(context, 'Post deletado com sucesso');
      }
    } catch (e) {
      debugPrint('Erro ao deletar post: $e');
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao deletar post: $e');
      }
    }
  }

  // ========================= UI BUILD =========================

  Widget _buildNotificationsAction() {
    final activeProfile = ref.watch(activeProfileProvider);
    final authUid = ref.watch(currentUserProvider)?.uid;
    final isProfileReadyForQueries = activeProfile != null &&
        authUid != null &&
        activeProfile.uid == authUid;

    if (!isProfileReadyForQueries) {
      return IconButton(
        icon: const Icon(Iconsax.notification),
        tooltip: 'Notificações',
        onPressed: () => context.pushNotificationsNew(),
      );
    }

    final unreadCountAsync = ref.watch(
      unreadNotificationCountNewStreamProvider(
        activeProfile.profileId,
        activeProfile.uid,
      ),
    );

    return unreadCountAsync.when(
      loading: () => IconButton(
        icon: const Icon(Iconsax.notification),
        tooltip: 'Notificações',
        onPressed: () => context.pushNotificationsNew(),
      ),
      error: (_, __) => IconButton(
        icon: const Icon(Iconsax.notification),
        tooltip: 'Notificações',
        onPressed: () => context.pushNotificationsNew(),
      ),
      data: (unreadCount) => IconButton(
        tooltip: 'Notificações',
        onPressed: () => context.pushNotificationsNew(),
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Iconsax.notification),
            if (unreadCount > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.badgeRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlyConnectionsChip() {
    return Material(
      elevation: 3,
      color: Colors.transparent,
      child: InputChip(
        avatar: const Icon(
          Iconsax.people,
          size: 16,
          color: AppColors.primary,
        ),
        label: const Text('Somente conexoes'),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.18),
        ),
        deleteIcon: const Icon(Iconsax.close_circle, size: 16),
        onPressed: widget.onOpenSearch,
        onDeleted: _clearOnlyConnectionsFilter,
      ),
    );
  }

  void _clearOnlyConnectionsFilter() {
    final notifier = widget.searchNotifier;
    final params = notifier?.value;

    if (notifier == null || params == null || !params.onlyConnections) {
      return;
    }

    notifier.value = params.copyWith(onlyConnections: false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final onlyConnectionsActive =
        widget.searchNotifier?.value?.onlyConnections ?? false;

    return Theme(
      data: AppTheme.light,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textSecondary,
          elevation: 2,
          title: Image.asset(
            'assets/Logo/LogoWeGig.png',
            height: 53.6,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('⚠️ Erro ao carregar logo WeGig: $error');
              return const SizedBox.shrink();
            },
          ),
          centerTitle: true,
          actions: [
            _buildNotificationsAction(),
            Stack(
              children: [
                IconButton(
                  icon: Icon(
                    Iconsax.filter,
                    color: onlyConnectionsActive ? AppColors.primary : null,
                  ),
                  tooltip: 'Filtros de busca',
                  onPressed: widget.onOpenSearch,
                ),
                // Badge counter - só aparece se houver filtros ativos
                // ✅ FIX: IgnorePointer para não interceptar toques no IconButton
                if (_getActiveFiltersCount() > 0)
                  Positioned(
                    left: 4,
                    top: 4,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.salesColor,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${_getActiveFiltersCount()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: Stack(
          children: [
            _buildMapView(),
            // Máscara Airbnb - Vinheta nas bordas com gradientes visíveis
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 1.2,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.25),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            // Sombra superior para search bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 120,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.45),
                        Colors.white.withValues(alpha: 0.20),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            // Sombra inferior para carousel
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 280,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.5),
                        Colors.white.withValues(alpha: 0.20),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 32,
              left: 16,
              right: 16,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(24),
                child: TypeAheadField<Map<String, dynamic>>(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  suggestionsCallback: _fetchAddressSuggestions,
                  builder: (context, controller, focusNode) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        hintText:
                            'Buscar localização (cidade, bairro, endereço...)',
                        prefixIcon: const Icon(Iconsax.location,
                            color: AppColors.primary),
                        suffixIcon: controller.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Iconsax.close_circle,
                                    color: AppColors.textSecondary),
                                onPressed: () {
                                  controller.clear();
                                  focusNode.unfocus();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                    );
                  },
                  itemBuilder:
                      (BuildContext context, Map<String, dynamic> suggestion) {
                    final address =
                        suggestion['address'] as Map<String, dynamic>? ?? {};

                    // Extrai os componentes com fallback
                    final road = (address['road'] ??
                        address['pedestrian'] ??
                        '') as String;
                    final houseNumber =
                        (address['house_number'] ?? '') as String;
                    final neighbourhood = (address['neighbourhood'] ??
                        address['suburb'] ??
                        address['quarter'] ??
                        '') as String;
                    final city = (address['city'] ??
                        address['town'] ??
                        address['village'] ??
                        address['municipality'] ??
                        '') as String;
                    final state = (address['state'] ?? '') as String;

                    // Monta a linha principal (rua + número)
                    final streetLine = [road, houseNumber]
                        .where((e) => e.isNotEmpty)
                        .join(', ');

                    // Monta a linha secundária (bairro • cidade • estado)
                    final List<String> secondaryParts = [];
                    if (neighbourhood.isNotEmpty)
                      secondaryParts.add(neighbourhood);
                    if (city.isNotEmpty) secondaryParts.add(city);
                    if (state.isNotEmpty) secondaryParts.add(state);

                    final secondaryLine = secondaryParts.join(' • ');

                    return ListTile(
                      leading: const Icon(Iconsax.location,
                          color: AppColors.primary, size: 20),
                      title: Text(
                        streetLine.isNotEmpty
                            ? streetLine
                            : (suggestion['display_name'] as String?)
                                    ?.split(',')
                                    .first ??
                                'Localização',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: secondaryLine.isNotEmpty
                          ? Text(
                              secondaryLine,
                              style: TextStyle(
                                  color: Colors.grey[700], fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                    );
                  },
                  onSelected: _onAddressSelected,
                  emptyBuilder: (context) => const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Nenhum endereço encontrado'),
                  ),
                ),
              ),
            ),
            // Botão de feedback discreto abaixo do campo de busca
            Positioned(
              top: 88,
              left: 16,
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(16),
                color: AppColors.primary.withAlpha(180),
                child: InkWell(
                  onTap: () => FeedbackBottomSheet.show(context),
                  borderRadius: BorderRadius.circular(16),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Text(
                      'Feedback',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (onlyConnectionsActive)
              Positioned(
                top: 88,
                right: 16,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: _buildOnlyConnectionsChip(),
                ),
              ),
            // Botão de centralizar na localização do usuário (alinhado com card)
            Positioned(
              right: 16,
              bottom: 231, // 10% mais alto
              child: Material(
                elevation: 8,
                shape: const CircleBorder(),
                color: Colors.white,
                child: InkWell(
                  onTap: _isCenteringLocation ? null : _centerOnUserLocation,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 52,
                    height: 52,
                    padding: const EdgeInsets.all(12),
                    child: _isCenteringLocation
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: AppRadioPulseLoader(
                              size: 28,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(
                            Iconsax.gps,
                            color: AppColors.primary,
                            size: 28,
                          ),
                  ),
                ),
              ),
            ),
            // ✅ Carrossel horizontal de cards (sempre visível quando há posts)
            if (_visiblePosts.isNotEmpty) _buildFloatingCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    final initial = _mapControllerWrapper.currentPosition ??
        const LatLng(-23.55052, -46.633308);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth ||
            !constraints.hasBoundedHeight ||
            constraints.maxWidth <= 0 ||
            constraints.maxHeight <= 0) {
          return const SizedBox.shrink();
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(0),
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: GoogleMap(
              key: const ValueKey('home_map_cloud_only'),
              initialCameraPosition: CameraPosition(
                target: initial,
                zoom: _mapControllerWrapper.currentZoom,
              ),
              cloudMapId: Platform.isAndroid
                  ? AppConfig.googleMapIdAndroid
                  : AppConfig.googleMapIdIOS,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              onMapCreated: (c) async {
                _mapControllerWrapper.setController(c);
                _mapControllerCompleter ??= Completer<GoogleMapController>();
                if (!_mapControllerCompleter!.isCompleted) {
                  _mapControllerCompleter!.complete(c);
                }

                debugPrint('✅ Map criado com cloudMapId');

                await WidgetsBinding.instance.endOfFrame;
                if (_mapControllerWrapper.controller != null && mounted) {
                  unawaited(_onMapIdle());
                }
              },
              markers: _markers,
              onCameraMove: (pos) {
                _mapControllerWrapper.setCurrentZoom(pos.zoom);
              },
              onCameraIdle: () async {
                // ✅ OTIMIZAÇÃO: throttle + proteção contra chamadas concorrentes
                final now = DateTime.now();
                if (_lastMapIdleCall != null &&
                    now.difference(_lastMapIdleCall!).inMilliseconds <
                        _mapIdleThrottleMs) {
                  return;
                }
                if (_isProcessingMapIdle) return;
                _lastMapIdleCall = now;

                // Pequeno delay para aguardar estabilização
                await Future<void>.delayed(const Duration(milliseconds: 150));
                if (mounted && _mapControllerWrapper.controller != null) {
                  try {
                    await _onMapIdle();
                  } catch (e) {
                    if (!e.toString().contains('channel-error')) {
                      debugPrint('Erro em onCameraIdle: $e');
                    }
                  }
                }
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _onMapIdle() async {
    if (_isDisposed || !mounted) return;
    if (_isProcessingMapIdle) return;
    final controller = _mapControllerWrapper.controller;
    if (controller == null) return;

    _isProcessingMapIdle = true;

    final allPosts = _filterExcludedPosts(
      _filterExpiredPosts(List<PostEntity>.from(_cachedPosts)),
    );
    debugPrint(
        '🗺️ _onMapIdle: Total de posts disponíveis: ${allPosts.length}');

    try {
      final bounds = await controller.getVisibleRegion();
      if (_isDisposed || !mounted) return;

      final boundsKey = _toBoundsKey(bounds);
      final now = DateTime.now();
      if (_lastProcessedBoundsKey == boundsKey &&
          _lastProcessedBoundsAt != null &&
          now.difference(_lastProcessedBoundsAt!).inMilliseconds < 700) {
        return;
      }
      _lastProcessedBoundsKey = boundsKey;
      _lastProcessedBoundsAt = now;

      debugPrint(
          '🗺️ Bounds do mapa: NE=${bounds.northeast}, SW=${bounds.southwest}');

      final center = LatLng(
        (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
        (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
      );
      final radiusKm = calculateDistance(
        center,
        LatLng(bounds.northeast.latitude, bounds.northeast.longitude),
      );
      final mapAreaLabel = _formatMapAreaLabel(center);

      if (mounted && !_isDisposed) {
        setState(() {
          _currentMapCenter = center;
          _currentVisibleRadiusKm = radiusKm.isFinite ? radiusKm : null;
          _mapAreaLabel = mapAreaLabel;
          _mapControllerWrapper.setLastSearchBounds(bounds);
        });
      }

      final visibleRaw = allPosts.where(
        (post) {
          if (_excludedProfileIds.contains(post.authorProfileId)) return false;
          final postLocation = post.location;
          if (postLocation == null) return false;
          return _latLngInBounds(geoPointToLatLng(postLocation), bounds) &&
              _matchesFilters(post);
        },
      ).toList();

      // ✅ ORDENAÇÃO POR POSIÇÃO NA TELA: Ordena posts pela coordenada X real na viewport
      // Isso garante sincronia perfeita entre carrossel (esquerda→direita) e marcadores visuais
      final visible = await _sortPostsByScreenPosition(visibleRaw, controller);

      debugPrint('🗺️ Posts visíveis após filtros: ${visible.length}');

      final visibleIds = visible.map((p) => p.id).toList();
      final currentVisibleIds = _visiblePosts.map((p) => p.id).toList();

      // ✅ Compara ORDEM e IDs (não apenas IDs) - a ordem pode mudar mesmo com os mesmos posts
      final hasChanges =
          !const ListEquality<String>().equals(visibleIds, currentVisibleIds);

      if (hasChanges) {
        if (_isDisposed || !mounted) return;

        // ✅ CORREÇÃO CRÍTICA: Preserva o POST ATIVO (não o índice!)
        // Obtém o ID do post atualmente exibido no carrossel
        final currentPageIndex = _pageController.hasClients
            ? (_pageController.page?.round() ?? 0)
                .clamp(0, _visiblePosts.length - 1)
            : 0;

        // Identifica o post que ESTÁ sendo exibido no carrossel agora
        final currentlyDisplayedPost =
            _visiblePosts.isNotEmpty && currentPageIndex < _visiblePosts.length
                ? _visiblePosts[currentPageIndex]
                : null;
        final currentlyDisplayedId = currentlyDisplayedPost?.id;

        // Verifica se o post atualmente exibido ainda está na nova lista
        final currentPostStillVisible = currentlyDisplayedId != null &&
            visible.any((p) => p.id == currentlyDisplayedId);

        // ✅ Se o post atual ainda está visível, mantém ele; senão, escolhe o mais próximo
        String? preservedPostId;
        if (currentPostStillVisible) {
          preservedPostId = currentlyDisplayedId;
          debugPrint(
              '🎠 _onMapIdle: Post atual $currentlyDisplayedId permanece visível');
        } else if (visible.isNotEmpty) {
          // Post atual saiu da área - escolhe o primeiro da lista ordenada
          preservedPostId = visible.first.id;
          debugPrint(
              '🎠 _onMapIdle: Post anterior saiu, novo post: $preservedPostId');
        }

        // ✅ Atualiza lista preservando o POST específico (não o índice)
        _updateVisiblePostsSmoothly(visible, preservedPostId);

        await _rebuildMarkers();
      }
    } catch (e) {
      debugPrint('Erro ao obter bounds do mapa: $e');
      if (!mounted || _isDisposed) return;
      if (_visiblePosts.isEmpty) {
        // ✅ Fallback: ordena por longitude quando não há controller
        final visible = _sortPostsByLongitude(_filterExcludedPosts(allPosts));

        // ✅ CORREÇÃO: Preserva o POST ativo (não o índice)
        final currentPageIndex = _pageController.hasClients
            ? (_pageController.page?.round() ?? 0)
                .clamp(0, _visiblePosts.length - 1)
            : 0;

        final currentlyDisplayedPost =
            _visiblePosts.isNotEmpty && currentPageIndex < _visiblePosts.length
                ? _visiblePosts[currentPageIndex]
                : null;
        final currentlyDisplayedId = currentlyDisplayedPost?.id;

        final currentPostStillVisible = currentlyDisplayedId != null &&
            visible.any((p) => p.id == currentlyDisplayedId);

        String? preservedPostId;
        if (currentPostStillVisible) {
          preservedPostId = currentlyDisplayedId;
        } else if (visible.isNotEmpty) {
          preservedPostId = visible.first.id;
        }

        _updateVisiblePostsSmoothly(visible, preservedPostId);

        await _rebuildMarkers();
      }
    } finally {
      _isProcessingMapIdle = false;
    }
  }

  String _toBoundsKey(LatLngBounds bounds) {
    String f(double v) => v.toStringAsFixed(5);
    return '${f(bounds.northeast.latitude)},${f(bounds.northeast.longitude)}|'
        '${f(bounds.southwest.latitude)},${f(bounds.southwest.longitude)}';
  }

  /// ✅ Ordena posts pela coordenada X real na tela usando projeção do mapa
  /// Garante que o carrossel reflita exatamente a ordem esquerda → direita visual dos marcadores
  Future<List<PostEntity>> _sortPostsByScreenPosition(
    List<PostEntity> posts,
    GoogleMapController controller,
  ) async {
    if (posts.isEmpty) return posts;
    if (posts.length == 1) return posts;

    try {
      // Projeta em paralelo para reduzir custo no canal de plataforma.
      final projections = await Future.wait(
        posts.map((post) async {
          final location = post.location;
          if (location == null) return null;
          final latLng = geoPointToLatLng(location);
          final screenCoord = await controller.getScreenCoordinate(latLng);
          return (post: post, screenX: screenCoord.x.toDouble());
        }),
      );

      final postsWithScreenX =
          projections.whereType<({PostEntity post, double screenX})>().toList();

      // Ordena por coordenada X crescente (esquerda → direita)
      postsWithScreenX.sort((a, b) => a.screenX.compareTo(b.screenX));

      final sorted = postsWithScreenX.map((e) => e.post).toList();
      debugPrint(
          '🎠 _sortPostsByScreenPosition: ${sorted.length} posts ordenados por posição X na tela');
      return sorted;
    } catch (e) {
      debugPrint(
          '⚠️ _sortPostsByScreenPosition: Erro na projeção, usando fallback por longitude: $e');
      // Fallback: ordena por longitude se a projeção falhar
      return _sortPostsByLongitude(posts);
    }
  }

  /// ✅ Fallback: ordena posts por longitude (oeste → leste)
  List<PostEntity> _sortPostsByLongitude(List<PostEntity> posts) {
    final sorted = List<PostEntity>.from(posts)
      ..sort((a, b) {
        final aLng = a.location?.longitude ?? 0;
        final bLng = b.location?.longitude ?? 0;
        return aLng.compareTo(bLng);
      });
    debugPrint(
        '🎠 _sortPostsByLongitude: ${sorted.length} posts ordenados por longitude');
    return sorted;
  }

  /// ✅ Verifica se houve interação recente com o carrossel (últimos 800ms)
  bool _isRecentCarouselInteraction() {
    if (_lastCarouselInteraction == null) return false;
    return DateTime.now().difference(_lastCarouselInteraction!).inMilliseconds <
        800;
  }

  /// ✅ Verifica se está em período de debounce após scroll programático
  bool _isInProgrammaticDebounce() {
    if (_lastProgrammaticScrollEnd == null) return false;
    return DateTime.now()
            .difference(_lastProgrammaticScrollEnd!)
            .inMilliseconds <
        _programmaticScrollDebounceMs;
  }

  /// ✅ Adiciona posts ao buffer pendente com unicidade por ID
  void _addToPendingBuffer(List<PostEntity> posts) {
    for (final post in posts) {
      _pendingPostsBuffer[post.id] = post;
    }
    _hasPendingUpdate = true;

    // Cancela timer anterior e agenda novo
    _pendingUpdateTimer?.cancel();
    _pendingUpdateTimer = Timer(const Duration(milliseconds: 300), () async {
      if (mounted && !_isUserScrolling && !_isInProgrammaticDebounce()) {
        await _applyPendingUpdates();
      }
    });
  }

  /// ✅ Atualiza lista de posts visíveis de forma suave, PRESERVANDO o post ativo SEM FLICK
  void _updateVisiblePostsSmoothly(
      List<PostEntity> newPosts, String? preservedPostId) {
    if (!mounted) return;

    newPosts = _filterExcludedPosts(newPosts);

    // ✅ Se usuário está scrollando ou em debounce, adiciona ao buffer
    if (_isUserScrolling || _isInProgrammaticDebounce()) {
      debugPrint(
          '🎠 _updateVisiblePostsSmoothly: Usuário scrollando ou debounce ativo, adicionando ao buffer');
      _addToPendingBuffer(newPosts);
      return;
    }

    // ✅ Usa diffing otimizado para verificar se precisa atualizar
    final currentIds = _visiblePosts.map((p) => p.id).toList();
    final newIds = newPosts.map((p) => p.id).toList();

    // Verifica se a lista é idêntica
    if (const ListEquality<String>().equals(currentIds, newIds) &&
        _activePostId == preservedPostId) {
      debugPrint(
          '🎠 _updateVisiblePostsSmoothly: Lista idêntica, pulando rebuild');
      return;
    }

    final currentPageIndex =
        _pageController.hasClients ? (_pageController.page?.round() ?? 0) : 0;

    // ✅ Encontra o novo índice do post preservado na lista ORDENADA (mantém ordenação por X)
    int targetPageIndex = 0;
    String? finalActiveId = preservedPostId;

    if (preservedPostId != null && newPosts.isNotEmpty) {
      final preservedIndex =
          newPosts.indexWhere((p) => p.id == preservedPostId);
      if (preservedIndex >= 0) {
        targetPageIndex = preservedIndex;
      } else {
        // Post não encontrado - usa o post no índice atual ou o mais próximo
        targetPageIndex = currentPageIndex.clamp(0, newPosts.length - 1);
        finalActiveId = newPosts[targetPageIndex].id;
      }
    } else if (newPosts.isNotEmpty) {
      targetPageIndex = currentPageIndex.clamp(0, newPosts.length - 1);
      finalActiveId = newPosts[targetPageIndex].id;
    }

    final needsNavigation =
        currentPageIndex != targetPageIndex && newPosts.isNotEmpty;

    debugPrint(
        '🎠 _updateVisiblePostsSmoothly: Atualizando (${currentIds.length}→${newIds.length} posts), activeId=$finalActiveId, índice $currentPageIndex→$targetPageIndex, navegar=$needsNavigation');

    // ✅ ESTRATÉGIA ANTI-FLICK DEFINITIVA:
    // 1. Se NÃO precisa navegar: apenas atualiza a lista (sem flick)
    // 2. Se PRECISA navegar: usa animação suave ao invés de jumpToPage

    if (!needsNavigation) {
      // ✅ Caso simples: apenas atualiza a lista, sem navegação
      setState(() {
        _visiblePosts = newPosts;
        _updatePostDistances();
        _activePostId = finalActiveId;
      });
    } else if (_pageController.hasClients) {
      // ✅ Precisa navegar: usa animação curta para suavizar a transição
      _isProgrammaticScroll = true;

      setState(() {
        _visiblePosts = newPosts;
        _updatePostDistances();
        _activePostId = finalActiveId;
      });

      // ✅ Usa animateToPage com duração muito curta para transição suave
      // Isso evita o "salto" visual do jumpToPage
      _pageController
          .animateToPage(
        targetPageIndex,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      )
          .then((_) {
        _isProgrammaticScroll = false;
        _lastProgrammaticScrollEnd = DateTime.now();
        debugPrint(
            '🎠 _updateVisiblePostsSmoothly: Animou para índice $targetPageIndex');
      });
    }
  }

  /// ✅ Aplica updates pendentes após o usuário parar de scrollar
  Future<void> _applyPendingUpdates() async {
    if (!_hasPendingUpdate || _pendingPostsBuffer.isEmpty) return;
    if (!mounted || _isUserScrolling || _isInProgrammaticDebounce()) return;

    final controller = _mapControllerWrapper.controller;
    final rawPosts = _filterExcludedPosts(_pendingPostsBuffer.values.toList());

    // ✅ Ordenação por posição na tela
    List<PostEntity> sortedPosts;
    if (controller != null) {
      sortedPosts = await _sortPostsByScreenPosition(rawPosts, controller);
      debugPrint(
          '🎠 _applyPendingUpdates: ${sortedPosts.length} posts ordenados por posição na tela');
    } else {
      sortedPosts = _sortPostsByLongitude(rawPosts);
      debugPrint(
          '🎠 _applyPendingUpdates: ${sortedPosts.length} posts ordenados por longitude (fallback)');
    }

    // ✅ Verifica se a nova lista é idêntica
    final currentIds = _visiblePosts.map((p) => p.id).toList();
    final newIds = sortedPosts.map((p) => p.id).toList();

    if (const ListEquality<String>().equals(currentIds, newIds)) {
      debugPrint('🎠 _applyPendingUpdates: Lista idêntica, ignorando');
      _hasPendingUpdate = false;
      _pendingPostsBuffer.clear();
      return;
    }

    // ✅ CORREÇÃO CRÍTICA: Preserva o POST atualmente visível (não o índice!)
    final currentPageIndex = _pageController.hasClients
        ? (_pageController.page?.round() ?? 0)
            .clamp(0, _visiblePosts.length - 1)
        : 0;

    final currentlyDisplayedPost =
        _visiblePosts.isNotEmpty && currentPageIndex < _visiblePosts.length
            ? _visiblePosts[currentPageIndex]
            : null;
    final currentlyDisplayedId = currentlyDisplayedPost?.id;

    // Verifica se o post atualmente exibido ainda está na nova lista
    final currentPostStillVisible = currentlyDisplayedId != null &&
        sortedPosts.any((p) => p.id == currentlyDisplayedId);

    String? preservedPostId;
    if (currentPostStillVisible) {
      preservedPostId = currentlyDisplayedId;
      debugPrint(
          '🎠 _applyPendingUpdates: Preservando post $currentlyDisplayedId');
    } else if (sortedPosts.isNotEmpty) {
      preservedPostId = sortedPosts.first.id;
      debugPrint(
          '🎠 _applyPendingUpdates: Post anterior saiu, novo: $preservedPostId');
    }

    // ✅ Limpa buffer ANTES de aplicar
    _hasPendingUpdate = false;
    _pendingPostsBuffer.clear();

    // ✅ Chama _updateVisiblePostsSmoothly que já lida com navegação
    _updateVisiblePostsSmoothly(sortedPosts, preservedPostId);

    unawaited(_rebuildMarkers());
  }

  void _scheduleMarkerWarmup() {
    if (_markerWarmupScheduled) return;
    _markerWarmupScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDisposed) return;
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        if (!mounted || _isDisposed) return;
        unawaited(_markerBuilder.initialize());
      });
    });
  }

  String _buildMarkerRenderSignature() {
    final ids = _visiblePosts.map((post) => post.id).toList()..sort();
    return '${_activePostId ?? ''}|${ids.join(',')}';
  }

  bool _latLngInBounds(LatLng p, LatLngBounds b) {
    return (p.latitude >= b.southwest.latitude &&
            p.latitude <= b.northeast.latitude) &&
        (p.longitude >= b.southwest.longitude &&
            p.longitude <= b.northeast.longitude);
  }

  String _formatMapAreaLabel(LatLng center) {
    final searchText = _searchController.text.trim();
    if (searchText.isNotEmpty) {
      return searchText;
    }

    // Usa o post mais próximo para inferir um nome real (bairro ou cidade)
    final nearestPost = _findNearestPost(center);
    final radiusKm = _currentVisibleRadiusKm;
    final currentZoom = _mapControllerWrapper.currentZoom;

    if (nearestPost != null) {
      final neighborhood = nearestPost.neighborhood?.trim();
      final city = nearestPost.city.trim();
      final state = abbreviateState(nearestPost.state);

      // Preferir bairro em zooms mais próximos ou raios pequenos
      final preferNeighborhood =
          (radiusKm != null && radiusKm <= 5) || currentZoom >= 14;

      if (preferNeighborhood &&
          neighborhood != null &&
          neighborhood.isNotEmpty) {
        final parts = <String>[neighborhood];
        if (city.isNotEmpty) parts.add(city);
        if (state.isNotEmpty) parts.add(state);
        final label = parts.join(' · ');
        if (label.isNotEmpty) return label;
      }

      final cityParts = <String>[];
      if (city.isNotEmpty) cityParts.add(city);
      if (state.isNotEmpty) cityParts.add(state);
      if (cityParts.isNotEmpty) {
        return cityParts.join(' · ');
      }
    }

    final lat = center.latitude.toStringAsFixed(3);
    final lng = center.longitude.toStringAsFixed(3);
    return 'Centro do mapa ($lat, $lng)';
  }

  PostEntity? _findNearestPost(LatLng target) {
    PostEntity? nearest;
    var bestDistance = double.infinity;
    final candidates = _visiblePosts.isNotEmpty ? _visiblePosts : _cachedPosts;

    for (final post in candidates) {
      final loc = post.location;
      if (loc == null) continue;
      final dist = calculateDistance(target, geoPointToLatLng(loc));
      if (dist < bestDistance) {
        bestDistance = dist;
        nearest = post;
      }
    }

    return nearest;
  }

  Widget _buildFloatingCard() {
    // ✅ Carrossel horizontal de cards com PageView
    if (_visiblePosts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: SizedBox(
          height: 200, // Altura fixa do card original
          // ✅ NotificationListener para detectar scroll manual do usuário
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                // ✅ Só marca como interação do usuário se não for programático
                if (!_isProgrammaticScroll && !_isInProgrammaticDebounce()) {
                  _isUserScrolling = true;
                  _lastCarouselInteraction = DateTime.now();
                  debugPrint('🎠 ScrollStart: Usuário iniciou scroll manual');
                }
              } else if (notification is ScrollEndNotification) {
                // ✅ Verifica se era scroll do usuário antes de resetar
                if (_isUserScrolling) {
                  _lastCarouselInteraction = DateTime.now();
                  debugPrint('🎠 ScrollEnd: Usuário finalizou scroll manual');

                  final currentPage = _pageController.page?.round() ?? 0;
                  if (currentPage >= 0 && currentPage < _visiblePosts.length) {
                    _scheduleMarkerSelectionUpdate(
                      _visiblePosts[currentPage],
                      delay: const Duration(milliseconds: 90),
                    );
                  }

                  // ✅ Agenda aplicação de updates pendentes com debounce maior
                  // para garantir que o scroll terminou completamente
                  _pendingUpdateTimer?.cancel();
                  _pendingUpdateTimer =
                      Timer(const Duration(milliseconds: 600), () async {
                    if (mounted && !_isProgrammaticScroll) {
                      _isUserScrolling = false;
                      _lastProgrammaticScrollEnd = DateTime.now();
                      await _applyPendingUpdates();
                    }
                  });
                } else {
                  _isUserScrolling = false;
                }
              } else if (notification is ScrollUpdateNotification) {
                // ✅ Atualiza timestamp e sincroniza pin em tempo real durante o arrasto
                if (_isUserScrolling) {
                  _lastCarouselInteraction = DateTime.now();
                }
              }
              return false; // Permite que a notificação continue propagando
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: _visiblePosts.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final post = _visiblePosts[index];
                final isActive = post.id == _activePostId;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: PostCard(
                    key: ValueKey(
                        'post_card_${post.id}'), // ✅ Key estável para evitar rebuilds
                    post: post,
                    isActive: isActive,
                    currentActiveProfileId: _activeProfile?.profileId,
                    isInterestSent:
                        ref.watch(interestNotifierProvider).contains(post.id),
                    onOpenOptions: () => _showInterestOptionsDialog(post),
                    onClose: _closeCard,
                    allPosts: _visiblePosts,
                    postIndex: index,
                    mapCenterLabel: _mapAreaLabel,
                    visibleRadiusKm: _currentVisibleRadiusKm,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Inicializa posição do mapa na ordem: GPS atual → Perfil → Cache GPS
  Future<void> _initializeMap() async {
    // ✅ FIX: Evita chamadas concorrentes que causam "A request for location permissions is already running"
    if (_isRequestingLocationPermission) {
      debugPrint(
          '⚠️ _initializeMap: Permissão de GPS já em andamento, aguardando...');
      return;
    }

    try {
      debugPrint('📍 _initializeMap: Iniciando...');
      _isRequestingLocationPermission = true;

      // Estratégia 1: Tentar GPS atual (instantâneo, sem timeout)
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        var permission = await Geolocator.checkPermission();

        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever) {
          try {
            final position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            ).timeout(const Duration(seconds: 3));

            final gpsPos = LatLng(position.latitude, position.longitude);
            if (mounted) {
              setState(() => _mapControllerWrapper.setCurrentPosition(gpsPos));
            }
            await GpsCacheService.updateCache(gpsPos);
            debugPrint('✅ _initializeMap: GPS atual obtido');
            return;
          } catch (e) {
            debugPrint('⚠️ _initializeMap: GPS timeout/erro: $e');
          }
        }
      }

      // Estratégia 2: Usar localização do perfil (SEMPRE disponível)
      final profile = _activeProfile;
      final profileLocation = profile?.location;
      if (profileLocation != null) {
        final profilePos = geoPointToLatLng(profileLocation);
        if (mounted) {
          setState(() => _mapControllerWrapper.setCurrentPosition(profilePos));
        }
        debugPrint('✅ _initializeMap: Usando localização do perfil');
        return;
      }

      // Estratégia 3: Fallback para cache GPS (<24h)
      final cachedPos = await GpsCacheService.getLastKnownPosition();
      if (mounted) {
        setState(() => _mapControllerWrapper.setCurrentPosition(cachedPos));
      }
      debugPrint('✅ _initializeMap: Usando cache GPS');
    } catch (e) {
      debugPrint('❌ _initializeMap: Erro inesperado: $e');

      // Último recurso: localização do perfil
      final profile = _activeProfile;
      final profileLocation = profile?.location;
      if (profileLocation != null && mounted) {
        setState(() => _mapControllerWrapper
            .setCurrentPosition(geoPointToLatLng(profileLocation)));
      }
    } finally {
      _isRequestingLocationPermission = false;
    }
  }

  void _primeInitialCameraTarget(ProfileEntity? profile) {
    if (profile == null) return;
    final location = profile.location;
    if (location == null) return;
    if (_mapControllerWrapper.currentPosition == null) {
      _mapControllerWrapper.setCurrentPosition(geoPointToLatLng(location));
    }
  }

  Future<GoogleMapController?> _waitForMapController() async {
    if (_mapControllerWrapper.controller != null) {
      return _mapControllerWrapper.controller;
    }
    try {
      final completer =
          _mapControllerCompleter ??= Completer<GoogleMapController>();
      return await completer.future;
    } catch (_) {
      return null;
    }
  }

  bool _matchesFilters(PostEntity post) {
    final params = widget.searchNotifier?.value;
    if (params == null) return true;

    if (params.onlyConnections && !_matchesConnectionsFilter(post)) {
      return false;
    }

    debugPrint(
        '🔍 HomePage._matchesFilters: Checking post ${post.id} (type: ${post.type})');
    debugPrint(
        '🔍 Params: postType=${params.postType}, salesTypes=${params.salesTypes}, minPrice=${params.minPrice}, maxPrice=${params.maxPrice}');

    final hasSalesFilters = params.salesTypes.isNotEmpty ||
        params.minPrice != null ||
        params.maxPrice != null ||
        params.onlyWithDiscount == true;
    final hasHiringFilters = params.eventTypes.isNotEmpty ||
        params.gigFormats.isNotEmpty ||
        params.venueSetups.isNotEmpty ||
        params.budgetRanges.isNotEmpty;

    final isSalesContext = params.postType == 'sales' || hasSalesFilters;
    final isHiringContext = params.postType == 'hiring' || hasHiringFilters;

    // ✅ FILTROS DE SALES (Anúncios)
    if (isSalesContext) {
      debugPrint('🔍 Applying SALES filters');

      // Tipo deve ser 'sales'
      if (post.type != 'sales') {
        debugPrint('🔍 Post rejected: type is ${post.type}, expected sales');
        return false;
      }

      // Tipo de anúncio (Gravação, Ensaios, etc)
      if (params.salesTypes.isNotEmpty) {
        if (!params.salesTypes.contains(post.salesType)) {
          debugPrint(
              '🔍 Post rejected: salesType is ${post.salesType}, expected one of ${params.salesTypes}');
          return false;
        }
      }

      // Faixa de preço mínima
      if (params.minPrice != null && params.minPrice! > 0) {
        if (post.price == null || post.price! < params.minPrice!) {
          debugPrint(
              '🔍 Post rejected: price ${post.price} < minPrice ${params.minPrice}');
          return false;
        }
      }

      // Faixa de preço máxima
      if (params.maxPrice != null && params.maxPrice! < 5000) {
        if (post.price == null || post.price! > params.maxPrice!) {
          debugPrint(
              '🔍 Post rejected: price ${post.price} > maxPrice ${params.maxPrice}');
          return false;
        }
      }

      // Apenas com desconto
      if (params.onlyWithDiscount == true) {
        final hasDiscount = post.discountMode != null &&
            post.discountMode!.isNotEmpty &&
            post.discountMode != 'none' &&
            post.discountValue != null &&
            post.discountValue! > 0;
        if (!hasDiscount) {
          debugPrint(
              '🔍 Post rejected: no valid discount (mode: ${post.discountMode}, value: ${post.discountValue})');
          return false;
        }
      }

      debugPrint('🔍 Post ${post.id} PASSED sales filters');
      return true;
    }

    // ✅ FILTROS DE CONTRATAÇÃO (Hiring)
    if (isHiringContext) {
      debugPrint('🔍 Applying HIRING filters');
      if (post.type != 'hiring') {
        debugPrint('🔍 Post rejected: type is ${post.type}, expected hiring');
        return false;
      }

      if (params.eventTypes.isNotEmpty) {
        if (post.eventType == null ||
            !params.eventTypes.contains(post.eventType)) {
          debugPrint('🔍 Post rejected: eventType mismatch');
          return false;
        }
      }

      if (params.gigFormats.isNotEmpty) {
        if (post.gigFormat == null ||
            !params.gigFormats.contains(post.gigFormat)) {
          debugPrint('🔍 Post rejected: gigFormat mismatch');
          return false;
        }
      }

      if (params.instruments.isNotEmpty) {
        final hasInstrumentMatch =
            post.instruments.any(params.instruments.contains);
        if (!hasInstrumentMatch) {
          debugPrint('🔍 Post rejected: instrument mismatch');
          return false;
        }
      }

      if (params.genres.isNotEmpty) {
        final hasGenreMatch = post.genres.any(params.genres.contains);
        if (!hasGenreMatch) {
          debugPrint('🔍 Post rejected: genre mismatch');
          return false;
        }
      }

      if (params.venueSetups.isNotEmpty) {
        final hasVenueMatch = post.venueSetup.any(params.venueSetups.contains);
        if (!hasVenueMatch) {
          debugPrint('🔍 Post rejected: venueSetup mismatch');
          return false;
        }
      }

      if (params.budgetRanges.isNotEmpty) {
        if (post.budgetRange == null ||
            !params.budgetRanges.contains(post.budgetRange)) {
          debugPrint('🔍 Post rejected: budgetRange mismatch');
          return false;
        }
      }

      if (params.availableFor.isNotEmpty) {
        final hasAvailableForMatch =
            post.availableFor.any(params.availableFor.contains);
        if (!hasAvailableForMatch) {
          debugPrint('🔍 Post rejected: availableFor mismatch');
          return false;
        }
      }

      if (params.hasYoutube == true &&
          (post.youtubeLink == null || post.youtubeLink!.isEmpty)) {
        debugPrint('🔍 Post rejected: no YouTube link');
        return false;
      }

      if (params.hasSpotify == true &&
          (post.spotifyLink == null || post.spotifyLink!.isEmpty)) {
        debugPrint('🔍 Post rejected: no Spotify link');
        return false;
      }

      if (params.hasDeezer == true &&
          (post.deezerLink == null || post.deezerLink!.isEmpty)) {
        debugPrint('🔍 Post rejected: no Deezer link');
        return false;
      }

      debugPrint('🔍 Post ${post.id} PASSED hiring filters');
      return true;
    }

    // ✅ FILTROS DE MÚSICOS/BANDAS
    debugPrint('🔍 Applying MUSICIAN/BAND filters');

    // Filtro: tipo de post (Banda ou Músico)
    if (params.postType != null && params.postType!.isNotEmpty) {
      if (post.type != params.postType) {
        debugPrint('🔍 Post rejected: type mismatch');
        return false;
      }
    }

    // Filtro: nível
    if (params.level != null && params.level!.isNotEmpty) {
      if (post.level != params.level) {
        debugPrint('🔍 Post rejected: level mismatch');
        return false;
      }
    }

    // Filtro: YouTube
    if (params.hasYoutube ?? false) {
      if (post.youtubeLink == null || post.youtubeLink!.isEmpty) {
        debugPrint('🔍 Post rejected: no YouTube link');
        return false;
      }
    }

    if (params.hasSpotify ?? false) {
      if (post.spotifyLink == null || post.spotifyLink!.isEmpty) {
        debugPrint('🔍 Post rejected: no Spotify link');
        return false;
      }
    }

    if (params.hasDeezer ?? false) {
      if (post.deezerLink == null || post.deezerLink!.isEmpty) {
        debugPrint('🔍 Post rejected: no Deezer link');
        return false;
      }
    }

    // Filtro: gêneros
    if (params.genres.isNotEmpty) {
      final hasGenreMatch = post.genres.any(
        params.genres.contains,
      );
      if (!hasGenreMatch) {
        debugPrint('🔍 Post rejected: genre mismatch');
        return false;
      }
    }

    // Filtro: instrumentos
    if (params.instruments.isNotEmpty) {
      final postInstruments =
          post.type == 'musician' ? post.instruments : post.seekingMusicians;
      final hasInstrumentMatch = postInstruments.any(
        params.instruments.contains,
      );
      if (!hasInstrumentMatch) {
        debugPrint('🔍 Post rejected: instrument mismatch');
        return false;
      }
    }

    // Filtro: availableFor (disponível para)
    if (params.availableFor.isNotEmpty) {
      if (post.availableFor.isEmpty) {
        debugPrint('🔍 Post rejected: empty availableFor');
        return false;
      }
      final hasAvailableForMatch =
          post.availableFor.any(params.availableFor.contains);
      if (!hasAvailableForMatch) {
        debugPrint('🔍 Post rejected: availableFor mismatch');
        return false;
      }
    }

    debugPrint('🔍 Post ${post.id} PASSED musician/band filters');
    return true;
  }

  bool _matchesConnectionsFilter(PostEntity post) {
    final activeProfileId = _activeProfile?.profileId;
    if (activeProfileId == null || activeProfileId.isEmpty) {
      return false;
    }

    if (post.authorProfileId == activeProfileId) {
      return true;
    }

    return _connectedProfileIds.contains(post.authorProfileId);
  }
}

// ============================================================================
// PostCard - Card flutuante com botão fechar
// ============================================================================
class PostCard extends StatelessWidget {
  const PostCard({
    required this.post,
    required this.isActive,
    required this.isInterestSent,
    required this.onOpenOptions,
    required this.allPosts,
    required this.postIndex,
    super.key,
    this.currentActiveProfileId,
    this.onClose,
    this.mapCenterLabel,
    this.visibleRadiusKm,
  });
  final PostEntity post;
  final bool isActive;
  final String? currentActiveProfileId;
  final bool isInterestSent;
  final VoidCallback onOpenOptions;
  final VoidCallback? onClose;

  /// Lista completa de posts para navegação no carrossel vertical
  final List<PostEntity> allPosts;

  /// Índice do post atual na lista
  final int postIndex;
  final String? mapCenterLabel;
  final double? visibleRadiusKm;

  @override
  Widget build(BuildContext context) {
    final primaryColor = switch (post.type) {
      'band' => AppColors.accent,
      'sales' => AppColors.salesColor,
      'hiring' => AppColors.hiringColor,
      _ => AppColors.musicianColor,
    };
    final lightColor = primaryColor.withValues(alpha: 0.1);
    const textSecondary = AppColors.textSecondary;

    final isOwner = post.authorProfileId.isNotEmpty &&
        post.authorProfileId == currentActiveProfileId;
    final avatarUrl = (post.activeProfilePhotoUrl != null &&
            post.activeProfilePhotoUrl!.isNotEmpty)
        ? post.activeProfilePhotoUrl!
        : (post.authorPhotoUrl != null && post.authorPhotoUrl!.isNotEmpty
            ? post.authorPhotoUrl!
            : null);
    final profileName =
        (post.activeProfileName != null && post.activeProfileName!.isNotEmpty)
            ? post.activeProfileName!
            : (post.authorName != null && post.authorName!.isNotEmpty
                ? post.authorName!
                : 'Perfil');

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
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      debugPrint('📍 PostCard: Tap na foto do post ${post.id}');
                      context.pushPostFeed(
                        allPosts,
                        initialIndex: postIndex,
                        mapCenterLabel: mapCenterLabel,
                        visibleRadiusKm: visibleRadiusKm,
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
                        child: (post.firstPhotoUrl != null &&
                                post.firstPhotoUrl!.isNotEmpty)
                            ? CachedNetworkImage(
                                imageUrl: post.firstPhotoUrl!,
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
                                          : (post.type == 'sales'
                                              ? Iconsax.bookmark
                                              : (post.type == 'hiring'
                                                  ? Iconsax.briefcase
                                                  : Iconsax.user)),
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
                                        : (post.type == 'sales'
                                            ? Iconsax.bookmark
                                            : (post.type == 'hiring'
                                                ? Iconsax.briefcase
                                                : Iconsax.user)),
                                    size: 40,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
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
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            debugPrint(
                                '📍 PostCard: Tap no nome do perfil ${post.authorProfileId}');
                            context.pushProfile(post.authorProfileId);
                          },
                          child: Row(
                            children: [
                              _ProfileAvatar(photoUrl: avatarUrl),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  profileName,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    decoration: TextDecoration.none,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Botão interesse ou menu
                      if (isOwner)
                        GestureDetector(
                          onTap: onOpenOptions,
                          child: const Icon(Iconsax.more,
                              color: textSecondary, size: 22),
                        )
                      else
                        GestureDetector(
                          onTap: onOpenOptions,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isInterestSent
                                  ? Colors.pink.withValues(alpha: 0.15)
                                  : AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isInterestSent
                                  ? (post.type == 'sales'
                                      ? Iconsax.tag5
                                      : Iconsax.heart5)
                                  : (post.type == 'sales'
                                      ? Iconsax.tag
                                      : Iconsax.heart),
                              size: 18,
                              color: isInterestSent
                                  ? Colors.pink
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // ✅ Header clicável: Tipo/Título
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      debugPrint(
                          '📍 PostCard: Tap no header do post ${post.id}');
                      context.pushPostFeed(allPosts, initialIndex: postIndex);
                    },
                    child: Row(
                      children: [
                        Icon(
                          post.type == 'sales'
                              ? Iconsax.tag
                              : (post.type == 'band'
                                  ? Iconsax.search_favorite
                                  : (post.type == 'hiring'
                                      ? Iconsax.briefcase
                                      : Iconsax.musicnote)),
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            post.type == 'sales'
                                ? (post.title ?? 'Anúncio')
                                : (post.type == 'band'
                                    ? 'Busca músico'
                                    : (post.type == 'hiring'
                                        ? (post.eventType?.isNotEmpty == true
                                            ? 'Contratação ${post.eventType}'
                                            : 'Contratação')
                                        : 'Busca banda')),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              decoration: TextDecoration.none,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // ✅ Conteúdo condicional: Sales vs Hiring vs Musician/Band
                  if (post.type == 'sales')
                    _buildSalesContent()
                  else if (post.type == 'hiring')
                    _buildHiringSummary(
                      primaryColor: primaryColor,
                      textSecondary: textSecondary,
                      context: context,
                    )
                  else ...[
                    // Instrumentos em scroll horizontal
                    if (post.type == 'musician' && post.instruments.isNotEmpty)
                      _buildHorizontalChips(
                        icon: Iconsax.music,
                        items: post.instruments,
                        color: AppColors.primary,
                      )
                    else if (post.type == 'band' &&
                        post.seekingMusicians.isNotEmpty)
                      _buildHorizontalChips(
                        icon: Iconsax.search_favorite,
                        items: post.seekingMusicians,
                        color: AppColors.primary,
                      ),
                    const SizedBox(height: 3),
                    // Nível
                    if (post.level.isNotEmpty)
                      _buildInfoRow(Iconsax.star, post.level, AppColors.primary,
                          textSecondary),
                    // Mensagem do post
                    if (post.content.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Iconsax.message,
                              size: 16, color: textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: MentionText(
                              text: post.content,
                              style: const TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                                height: 1.35,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              onMentionTap: (username) {
                                context.pushProfileByUsername(username);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                  const Spacer(),
                  // Footer: distância + tempo
                  Row(
                    children: [
                      Icon(Iconsax.location,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 3),
                      Text(
                        '${post.distanceKm?.toStringAsFixed(1) ?? '0.0'}km',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Iconsax.clock, size: 16, color: textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        _formatDaysAgo(post.createdAt),
                        style: const TextStyle(
                          fontSize: 14,
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
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
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
      height: 34,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 4),
              itemBuilder: (context, index) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    items[index],
                    style: TextStyle(
                      fontSize: 14,
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

  Widget _buildHiringSummary({
    required Color primaryColor,
    required Color textSecondary,
    required BuildContext context,
  }) {
    final dateLabel = _formatEventDate(post.eventDate);
    final eventChips = [
      if (post.eventType?.isNotEmpty == true) post.eventType!,
      if (post.gigFormat?.isNotEmpty == true) post.gigFormat!,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(Iconsax.calendar, dateLabel, primaryColor, textSecondary),
        if (eventChips.isNotEmpty) ...[
          const SizedBox(height: 3),
          _buildHorizontalChips(
            icon: Iconsax.briefcase,
            items: eventChips,
            color: AppColors.primary,
          ),
        ],
        if (post.content.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Iconsax.message, size: 16, color: textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: MentionText(
                  text: post.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.35,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  onMentionTap: (username) {
                    context.pushProfileByUsername(username);
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ✅ Conteúdo específico para Sales
  Widget _buildSalesContent() {
    // ✅ USAR PriceCalculator PARA CALCULOS CONSISTENTES
    final priceData = PriceCalculator.getPriceDisplayData(post);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Se há desconto, mostra preço original riscado + badge de desconto
        if (priceData.hasDiscount) ...[
          Row(
            children: [
              Icon(Iconsax.percentage_circle,
                  size: 14, color: Colors.grey[600]),
              const SizedBox(width: 8),

              // ✅ CORREÇÃO: Preço ORIGINAL riscado (post.price = preço sem desconto)
              Expanded(
                child: Text(
                  _truncatePrice(
                      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ')
                          .format(priceData.originalPrice)),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    decoration: TextDecoration.lineThrough,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: 8),
              const Text('•', style: TextStyle(color: Colors.grey)),
              const SizedBox(width: 8),

              // Badge de desconto
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  priceData.discountLabel!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],

        // ✅ CORREÇÃO: Preço FINAL destacado (calculado aplicando desconto)
        Row(
          children: [
            Icon(
              priceData.isFree ? Iconsax.gift : Iconsax.dollar_circle,
              size: 16,
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                priceData.isFree
                    ? 'Grátis'
                    : _truncatePrice(
                        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ')
                            .format(priceData.finalPrice)),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // 3. Conteúdo/mensagem do post
        if (post.content.isNotEmpty)
          Text(
            post.content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  String _formatEventDate(DateTime? date) {
    if (date == null) return 'Data a combinar';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // ✅ Função para truncar preço se for muito longo
  String _truncatePrice(String price) {
    // Se o preço for menor que 15 caracteres, retorna como está
    if (price.length <= 15) return price;

    // Para preços muito longos, formata de forma mais compacta
    final numericValue = post.price ?? 0.0;

    if (numericValue >= 1000000) {
      // Para milhões: R$ 1,2M
      final millions = numericValue / 1000000;
      return 'R\$ ${millions.toStringAsFixed(1)}M';
    } else if (numericValue >= 1000) {
      // Para milhares: R$ 1,2K
      final thousands = numericValue / 1000;
      return 'R\$ ${thousands.toStringAsFixed(1)}K';
    }

    // Para valores menores, usa formatação padrão mas trunca se necessário
    return price.length > 15 ? '${price.substring(0, 12)}...' : price;
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.photoUrl});

  final String? photoUrl;

  Widget _placeholder() {
    return const CircleAvatar(
      backgroundColor: AppColors.surfaceContainerHighest,
      child: Icon(Iconsax.music, color: Colors.white54, size: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (photoUrl == null || photoUrl!.isEmpty) {
      return SizedBox(width: 32, height: 32, child: _placeholder());
    }

    return SizedBox(
      width: 32,
      height: 32,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          fit: BoxFit.cover,
          placeholder: (_, __) => _placeholder(),
          errorWidget: (_, __, ___) => _placeholder(),
        ),
      ),
    );
  }
}
