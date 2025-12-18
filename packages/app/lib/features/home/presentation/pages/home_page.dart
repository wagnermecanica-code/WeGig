// WEGIG – HOME PAGE (2025, Flutter 3.24+, Dart 3.5+, Riverpod 3.x)
// Arquitetura: Instagram-style multi-profile, busca por área, mapa, carrossel flutuante, filtros, interesse otimista
// Design System: AppColors, AppTheme, WIREFRAME.md
// Refactored: Extracted sub-features (Map, Search, Feed) for better maintainability

import 'dart:async';
import 'dart:io' show Platform;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wegig_app/core/cache/image_cache_manager.dart';
import 'package:collection/collection.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_ui/utils/debouncer.dart';
import 'package:core_ui/utils/geo_utils.dart';
import 'package:core_ui/utils/price_calculator.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wegig_app/app/router/app_router.dart';
import 'package:wegig_app/config/app_config.dart';
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
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';

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
  with AutomaticKeepAliveClientMixin<HomePage>, TickerProviderStateMixin {
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
  Set<Marker> _markers = {};
  String? _activePostId;
  bool _isCenteringLocation = false;
  bool _isRebuildingMarkers = false;
  DateTime? _lastMarkerRebuild;
  ProviderSubscription<AsyncValue<PostState>>? _postsSubscription;
  ProviderSubscription<AsyncValue<ProfileState>>? _profileSubscription;
  Completer<GoogleMapController>? _mapControllerCompleter;
  List<PostEntity> _cachedPosts = <PostEntity>[];
  bool _isDisposed = false;
  bool _isRequestingLocationPermission = false; // ✅ FIX: Evita race condition de GPS
  
  // PageView Controller para carrossel horizontal
  late final PageController _pageController;
  bool _isProgrammaticScroll = false; // Evita loops de sync
  
    ProfileEntity? get _activeProfile =>
      ref.read(profileProvider).value?.activeProfile;

    @override
    bool get wantKeepAlive => true;

  Future<List<Map<String, dynamic>>> _fetchAddressSuggestions(String query) async {
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

      final streetLine = [road, houseNumber].where((e) => e.isNotEmpty).join(', ');
      final List<String> secondaryParts = [];
      if (neighbourhood.isNotEmpty) secondaryParts.add(neighbourhood);
      if (city.isNotEmpty) secondaryParts.add(city);
      if (state.isNotEmpty) secondaryParts.add(state);

      final cleanDisplay = [streetLine, secondaryParts.join(' • ')].where((e) => e.isNotEmpty).join(' • ');

      _searchController.text = cleanDisplay.isNotEmpty ? cleanDisplay : _searchService.getDisplayName(suggestion) ?? '';
      _searchFocusNode.unfocus();
    }
  }
  // ========================= CICLO DE VIDA =========================

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    _markerBuilder = MarkerBuilder();
    _initializePage();
    widget.refreshNotifier?.addListener(_onExternalRefresh);
    _initializePostListener();
    _initializeProfileListener();
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
    _postsSubscription?.close();
    _profileSubscription?.close();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mapControllerWrapper.dispose();
    _searchDebouncer.dispose(); // ✅ Cancela Timer pendente
    _markerBuilder.dispose();
    _pageController.dispose(); // ✅ Dispose do PageController
    widget.searchNotifier?.removeListener(_onSearchChanged);
    widget.refreshNotifier?.removeListener(_onExternalRefresh);
    _isDisposed = true;
    super.dispose();
  }

  void _initializePostListener() {
    _postsSubscription?.close();
    _postsSubscription = ref.listenManual(
      postNotifierProvider,
      (previous, next) {
        if (next.hasValue) {
          _cachedPosts = next.value?.posts ?? const <PostEntity>[];
          _scheduleVisiblePostsRefresh();
        } else if (next.hasError) {
          _cachedPosts = <PostEntity>[];
        }
      },
    );

    final initialState = ref.read(postNotifierProvider);
    if (initialState.hasValue) {
      _cachedPosts = initialState.value?.posts ?? const <PostEntity>[];
      _scheduleVisiblePostsRefresh();
    } else if (initialState.hasError) {
      _cachedPosts = <PostEntity>[];
    }
  }

  void _initializeProfileListener() {
    _profileSubscription?.close();
    _profileSubscription = ref.listenManual(
      profileProvider,
      (previous, next) {
        final previousId = previous?.valueOrNull?.activeProfile?.profileId;
        final nextProfile = next.valueOrNull?.activeProfile;
        final nextId = nextProfile?.profileId;

        if (nextId == null || nextId == previousId) return;

        ref.read(mapCenterProvider.notifier).reset(nextId);
        _primeInitialCameraTarget(nextProfile);
      },
    );

    final initialProfile = ref.read(profileProvider).valueOrNull?.activeProfile;
    if (initialProfile != null) {
      _primeInitialCameraTarget(initialProfile);
    }
  }

  void _scheduleVisiblePostsRefresh() {
    if (_isDisposed || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_onMapIdle());
    });
  }

  Future<void> _initializePage() async {
    // Pré-carrega cache de marcadores customizados (alta qualidade)
    await _markerBuilder.initialize();
    // Cloud-based Map Styling é usado via cloudMapId - não precisa carregar estilo local
    await _initializeMap();
    widget.searchNotifier?.addListener(_onSearchChanged);
    
    // ⚠️ MIGRAÇÃO REMOVIDA - causava loop de aumento de preços
    // A migração foi removida porque a lógica estava invertida:
    // o código já salva o preço ORIGINAL no Firestore, mas a migração
    // assumia que era o preço FINAL e tentava "recuperar" o original,
    // causando inflação progressiva a cada visualização/edição.
  }

  // ========================= MÉTODOS DE LÓGICA =========================

  void _onSearchChanged() {
    debugPrint('🔍 HomePage._onSearchChanged: searchNotifier.value = ${widget.searchNotifier?.value}');
    if (mounted) {
      setState(_onMapIdle);
    }
  }

  void _onExternalRefresh() {
    if (!mounted) return;
    ref.invalidate(postNotifierProvider);
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

    // Debounce: evitar rebuilds mais frequentes que 500ms
    final now = DateTime.now();
    if (!force &&
        _lastMarkerRebuild != null &&
        now.difference(_lastMarkerRebuild!).inMilliseconds < 500) {
      debugPrint('🗺️ _rebuildMarkers: Pulando rebuild (debounce ${now.difference(_lastMarkerRebuild!).inMilliseconds}ms)');
      return;
    }

    debugPrint('🗺️ _rebuildMarkers: Iniciando rebuild de ${_visiblePosts.length} posts...');
    _isRebuildingMarkers = true;
    _lastMarkerRebuild = now;

    final markers = await _markerBuilder.buildMarkersForPosts(
      _visiblePosts,
      _activePostId,
      _onMarkerTapped,
    );

    if (mounted) {
      setState(() => _markers = markers);
      debugPrint('🗺️ _rebuildMarkers: Marcadores atualizados (${markers.length})');
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
    
    setState(() {
      _activePostId = post.id;
    });
    
    // ✅ Anima o mapa para a posição do post mantendo o zoom atual
    _mapControllerWrapper.animateToPosition(
      geoPointToLatLng(post.location),
      _mapControllerWrapper.currentZoom,
    );
    
    // Reconstrói marcadores com novo estado ativo
    _rebuildMarkers(force: true);
  }

  void _closeCard() {
    if (!mounted) return;
    setState(() => _activePostId = null);
    // Reconstrói marcadores para remover estado ativo
    _rebuildMarkers(force: true);
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
              setState(() => _mapControllerWrapper.setCurrentPosition(targetPos!));
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
                setState(() => _mapControllerWrapper.setCurrentPosition(targetPos!));
              }
              debugPrint('📍 Usando última posição conhecida');
              AppSnackBar.showInfo(context, 'GPS timeout. Usando última localização.');
            } else {
              // Estratégia 4: Localização do perfil (sempre disponível)
              final profile = _activeProfile;
              final profileLocation = profile?.location;
              if (profileLocation != null) {
                targetPos = geoPointToLatLng(profileLocation);
                debugPrint('📍 Usando localização do perfil');
                AppSnackBar.showInfo(context, 'GPS indisponível. Usando local do perfil.');
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
              AppSnackBar.showWarning(context, 'GPS desativado. Ative nas configurações.');
            } else {
              AppSnackBar.showWarning(context, 'Permissão de localização necessária');
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
      debugPrint('⚠️ AVISO: post.authorUid vazio, tentando recuperar do Firestore...');
      
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
    if (post.authorProfileId.isEmpty) throw Exception('postAuthorProfileId está vazio');
    if (activeProfile.profileId.isEmpty) throw Exception('interestedProfileId está vazio');
    if (activeProfile.name.isEmpty) throw Exception('interestedProfileName está vazio');

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
        if (e.toString().contains('authorUid') || e.toString().contains('autor')) {
          errorMessage = 'Erro: Post sem informações de autor';
        } else if (e.toString().contains('permission')) {
          errorMessage = 'Erro: Sem permissão para criar interesse';
        } else if (e.toString().contains('network') || e.toString().contains('connection')) {
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
    final isInterestSent = ref.read(interestNotifierProvider).contains(post.id);
    final isOwner = post.authorProfileId.isNotEmpty &&
        post.authorProfileId == _activeProfile?.profileId;

    showInterestOptionsDialog(
      context: context,
      post: post,
      isInterestSent: isInterestSent,
      isOwner: isOwner,
      onSendInterest: () => _sendInterestOptimistically(post),
      onRemoveInterest: () => _removeInterestOptimistically(post),
      onDeletePost: () => _confirmDeletePost(post),
      onViewProfile: () => context.pushProfile(post.authorProfileId),
      onPostEdited: () => ref.invalidate(postNotifierProvider),
    );
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

      // Recarregar posts
      if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Theme(
      data: AppTheme.light,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFE47911), // Brand Orange
          foregroundColor: const Color(0xFFFAFAFA), // Off-white
          elevation: 2,
          title: Image.asset(
            'assets/Logo/WeGig.png',
            height: 53.6, // 46.6 * 1.15 = 53.59 (arredondado para 53.6)
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('⚠️ Erro ao carregar logo WeGig: $error');
              return const SizedBox.shrink();
            },
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Iconsax.filter),
              tooltip: 'Filtros de busca',
              onPressed: widget.onOpenSearch,
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
                            prefixIcon: const Icon(Iconsax.location, color: AppColors.primary),
                            suffixIcon: controller.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Iconsax.close_circle, color: AppColors.textSecondary),
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
                      itemBuilder: (BuildContext context, Map<String, dynamic> suggestion) {
                        final address = suggestion['address'] as Map<String, dynamic>? ?? {};

                        // Extrai os componentes com fallback
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

                        // Monta a linha principal (rua + número)
                        final streetLine = [road, houseNumber].where((e) => e.isNotEmpty).join(', ');

                        // Monta a linha secundária (bairro • cidade • estado)
                        final List<String> secondaryParts = [];
                        if (neighbourhood.isNotEmpty) secondaryParts.add(neighbourhood);
                        if (city.isNotEmpty) secondaryParts.add(city);
                        if (state.isNotEmpty) secondaryParts.add(state);

                        final secondaryLine = secondaryParts.join(' • ');

                        return ListTile(
                          leading: const Icon(Iconsax.location, color: AppColors.primary, size: 20),
                          title: Text(
                            streetLine.isNotEmpty ? streetLine : (suggestion['display_name'] as String?)?.split(',').first ?? 'Localização',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: secondaryLine.isNotEmpty
                              ? Text(
                                  secondaryLine,
                                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
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
                // Botão de centralizar na localização do usuário (alinhado com card)
                Positioned(
                  right: 16,
                  bottom: 231, // 10% mais alto
                  child: Material(
                    elevation: 8,
                    shape: const CircleBorder(),
                    color: Colors.white,
                    child: InkWell(
                      onTap:
                          _isCenteringLocation ? null : _centerOnUserLocation,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 52,
                        height: 52,
                        padding: const EdgeInsets.all(12),
                        child: _isCenteringLocation
                            ? const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary),
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
    final initial = _mapControllerWrapper.currentPosition ?? const LatLng(-23.55052, -46.633308);
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(0), // Airbnb style - cantos arredondados sutis
      child: GoogleMap(
        key: const ValueKey('home_map'), // Previne rebuilds desnecessários
        initialCameraPosition: CameraPosition(
          target: initial,
          zoom: _mapControllerWrapper.currentZoom,
        ),
        cloudMapId: Platform.isAndroid
            ? AppConfig.googleMapIdAndroid
            : AppConfig.googleMapIdIOS, // Cloud-based Map Styling
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

          // Style já aplicado via GoogleMap.style property
          debugPrint('✅ Map criado com style customizado');

          // Aguardar mapa estar completamente pronto
          await Future<void>.delayed(const Duration(milliseconds: 300));

          if (_mapControllerWrapper.controller != null && mounted) {
            try {
              _mapControllerWrapper.setLastSearchBounds(await _mapControllerWrapper.controller!.getVisibleRegion());
              await _onMapIdle();
            } catch (e) {
              debugPrint('Erro ao inicializar mapa: $e');
              // Tentar novamente após mais delay
              await Future<void>.delayed(const Duration(milliseconds: 500));
              if (_mapControllerWrapper.controller != null && mounted) {
                try {
                  _mapControllerWrapper.setLastSearchBounds(await _mapControllerWrapper.controller!.getVisibleRegion());
                  await _onMapIdle();
                } catch (e2) {
                  debugPrint('Erro ao inicializar mapa (2ª tentativa): $e2');
                }
              }
            }
          }
        },
        markers: _markers,
        onCameraMove: (pos) {
          _mapControllerWrapper.setCurrentZoom(pos.zoom);
        },
        onCameraIdle: () async {
          // Debounce para evitar chamadas excessivas
          await Future<void>.delayed(const Duration(milliseconds: 300));
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
    );
  }

  Future<void> _onMapIdle() async {
    if (_isDisposed || !mounted) return;
    final controller = _mapControllerWrapper.controller;
    if (controller == null) return;

    final allPosts = List<PostEntity>.from(_cachedPosts);
    debugPrint('🗺️ _onMapIdle: Total de posts disponíveis: ${allPosts.length}');

    try {
      final bounds = await controller.getVisibleRegion();
      if (_isDisposed || !mounted) return;
      debugPrint(
          '🗺️ Bounds do mapa: NE=${bounds.northeast}, SW=${bounds.southwest}');

      final visible = allPosts.where(
        (post) {
          final postLocation = post.location;
          if (postLocation == null) return false;
          return _latLngInBounds(geoPointToLatLng(postLocation), bounds) &&
              _matchesFilters(post);
        },
      ).toList();

      debugPrint('🗺️ Posts visíveis após filtros: ${visible.length}');

      final visibleIds = visible.map((p) => p.id).toSet();
      final currentVisibleIds = _visiblePosts.map((p) => p.id).toSet();

      if (!const SetEquality<String>().equals(visibleIds, currentVisibleIds)) {
        if (_isDisposed || !mounted) return;

        setState(() {
          _visiblePosts = visible;
          _updatePostDistances();
          // ✅ Auto-seleciona o primeiro post quando a lista muda
          if (visible.isNotEmpty) {
            _activePostId = visible.first.id;
          } else {
            _activePostId = null;
          }
        });
        
        // ✅ Reseta o PageController para a primeira página
        if (_pageController.hasClients && visible.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _pageController.hasClients) {
              _pageController.jumpToPage(0);
            }
          });
        }
        
        await _rebuildMarkers();
      }
    } catch (e) {
      debugPrint('Erro ao obter bounds do mapa: $e');
      if (!mounted || _isDisposed) return;
      if (_visiblePosts.isEmpty) {
        setState(() {
          _visiblePosts = allPosts;
          _updatePostDistances();
          // ✅ Auto-seleciona o primeiro post quando a lista muda
          if (allPosts.isNotEmpty) {
            _activePostId = allPosts.first.id;
          } else {
            _activePostId = null;
          }
        });
        
        // ✅ Reseta o PageController para a primeira página
        if (_pageController.hasClients && allPosts.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _pageController.hasClients) {
              _pageController.jumpToPage(0);
            }
          });
        }
        
        await _rebuildMarkers();
      }
    }
  }

  bool _latLngInBounds(LatLng p, LatLngBounds b) {
    return (p.latitude >= b.southwest.latitude &&
            p.latitude <= b.northeast.latitude) &&
        (p.longitude >= b.southwest.longitude &&
            p.longitude <= b.northeast.longitude);
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
                  post: post,
                  isActive: isActive,
                  currentActiveProfileId: _activeProfile?.profileId,
                  isInterestSent: ref.watch(interestNotifierProvider).contains(post.id),
                  onOpenOptions: () => _showInterestOptionsDialog(post),
                  onClose: _closeCard,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Inicializa posição do mapa na ordem: GPS atual → Perfil → Cache GPS
  Future<void> _initializeMap() async {
    // ✅ FIX: Evita chamadas concorrentes que causam "A request for location permissions is already running"
    if (_isRequestingLocationPermission) {
      debugPrint('⚠️ _initializeMap: Permissão de GPS já em andamento, aguardando...');
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
        setState(() => _mapControllerWrapper.setCurrentPosition(
          geoPointToLatLng(profileLocation)
        ));
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
      final completer = _mapControllerCompleter ??=
          Completer<GoogleMapController>();
      return await completer.future;
    } catch (_) {
      return null;
    }
  }

  bool _matchesFilters(PostEntity post) {
    final params = widget.searchNotifier?.value;
    if (params == null) return true;

    debugPrint('🔍 HomePage._matchesFilters: Checking post ${post.id} (type: ${post.type})');
    debugPrint('🔍 Params: postType=${params.postType}, salesTypes=${params.salesTypes}, minPrice=${params.minPrice}, maxPrice=${params.maxPrice}');

    // ✅ FILTROS DE SALES (Anúncios)
    if (params.postType == 'sales') {
      debugPrint('🔍 Applying SALES filters');
      
      // Tipo deve ser 'sales'
      if (post.type != 'sales') {
        debugPrint('🔍 Post rejected: type is ${post.type}, expected sales');
        return false;
      }
      
      // Tipo de anúncio (Gravação, Ensaios, etc)
      if (params.salesTypes.isNotEmpty) {
        if (!params.salesTypes.contains(post.salesType)) {
          debugPrint('🔍 Post rejected: salesType is ${post.salesType}, expected one of ${params.salesTypes}');
          return false;
        }
      }
      
      // Faixa de preço mínima
      if (params.minPrice != null && params.minPrice! > 0) {
        if (post.price == null || post.price! < params.minPrice!) {
          debugPrint('🔍 Post rejected: price ${post.price} < minPrice ${params.minPrice}');
          return false;
        }
      }
      
      // Faixa de preço máxima
      if (params.maxPrice != null && params.maxPrice! < 5000) {
        if (post.price == null || post.price! > params.maxPrice!) {
          debugPrint('🔍 Post rejected: price ${post.price} > maxPrice ${params.maxPrice}');
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
          debugPrint('🔍 Post rejected: no valid discount (mode: ${post.discountMode}, value: ${post.discountValue})');
          return false;
        }
      }
      
      // Apenas promoções ativas (não expiradas)
      if (params.onlyActivePromos == true) {
        final now = DateTime.now();
        final hasActivePromo = post.promoStartDate != null && 
                              post.promoEndDate != null && 
                              post.promoStartDate!.isBefore(now) && 
                              post.promoEndDate!.isAfter(now);
        if (!hasActivePromo) {
          debugPrint('🔍 Post rejected: promo not active (start: ${post.promoStartDate}, end: ${post.promoEndDate}, now: $now)');
          return false;
        }
      }
      
      debugPrint('🔍 Post ${post.id} PASSED sales filters');
      return true;
    }

    // ✅ FILTROS DE MÚSICOS/BANDAS (existente)
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
    if (params.availableFor != null && params.availableFor!.isNotEmpty) {
      if (post.availableFor.isEmpty) {
        debugPrint('🔍 Post rejected: empty availableFor');
        return false;
      }
      final hasAvailableForMatch = post.availableFor.contains(params.availableFor);
      if (!hasAvailableForMatch) {
        debugPrint('🔍 Post rejected: availableFor mismatch');
        return false;
      }
    }

    debugPrint('🔍 Post ${post.id} PASSED musician/band filters');
    return true;
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
    final primaryColor = post.type == 'band' ? AppColors.accent : AppColors.primary;
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
    final profileName = (post.activeProfileName != null &&
        post.activeProfileName!.isNotEmpty)
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
                      context.pushPostDetail(post.id);
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
                            (post.firstPhotoUrl != null && post.firstPhotoUrl!.isNotEmpty)
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
                                              : (post.type == 'sales' ? Iconsax.bookmark : Iconsax.user),
                                          size: 40,
                                          color: AppColors.primary,
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
                                            : (post.type == 'sales' ? Iconsax.bookmark : Iconsax.user),
                                        size: 40,
                                        color: AppColors.primary,
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
                            debugPrint('📍 PostCard: Tap no nome do perfil ${post.authorProfileId}');
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
                                  ? (post.type == 'sales' ? Iconsax.tag5 : Iconsax.heart5)
                                  : (post.type == 'sales' ? Iconsax.tag : Iconsax.heart),
                              size: 18,
                              color: isInterestSent ? Colors.pink : AppColors.primary,
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
                      debugPrint('📍 PostCard: Tap no header do post ${post.id}');
                      context.pushPostDetail(post.id);
                    },
                    child: Row(
                      children: [
                        Icon(
                          post.type == 'sales' 
                              ? Iconsax.tag 
                              : (post.type == 'band' ? Iconsax.search_favorite : Iconsax.musicnote),
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            post.type == 'sales'
                                ? (post.title ?? 'Anúncio')
                                : (post.type == 'band' ? 'Busca músico' : 'Busca banda'),
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
                  // ✅ Conteúdo condicional: Sales vs Musician/Band
                  if (post.type == 'sales')
                    _buildSalesContent()
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
                      _buildInfoRow(Iconsax.star, post.level,
                          AppColors.primary, textSecondary),
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
                        const Icon(Iconsax.clock,
                          size: 16, color: textSecondary),
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
              Icon(Iconsax.percentage_circle, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 8),

              // ✅ CORREÇÃO: Preço ORIGINAL riscado (post.price = preço sem desconto)
              Expanded(
                child: Text(
                  _truncatePrice(NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ').format(priceData.originalPrice)),
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
            const Icon(Iconsax.dollar_circle, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _truncatePrice(NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ').format(priceData.finalPrice)),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
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
