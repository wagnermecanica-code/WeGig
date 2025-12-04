// WEGIG – HOME PAGE (2025, Flutter 3.24+, Dart 3.5+, Riverpod 3.x)
// Arquitetura: Instagram-style multi-profile, busca por área, mapa, carrossel flutuante, filtros, interesse otimista
// Design System: AppColors, AppTheme, WIREFRAME.md
// Refactored: Extracted sub-features (Map, Search, Feed) for better maintainability

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:core_ui/models/search_params.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/theme/app_theme.dart';
import 'package:iconsax/iconsax.dart';
import 'package:core_ui/utils/geo_utils.dart';
import 'package:core_ui/utils/debouncer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wegig_app/app/router/app_router.dart';
import 'package:wegig_app/features/home/presentation/providers/map_center_provider.dart';
import 'package:wegig_app/features/home/presentation/widgets/feed/interest_service.dart';
import 'package:wegig_app/features/home/presentation/widgets/map/map_controller.dart';
import 'package:wegig_app/features/home/presentation/widgets/map/marker_builder.dart';
import 'package:wegig_app/features/home/presentation/widgets/search/search_service.dart';
import 'package:wegig_app/features/notifications/domain/services/notification_service.dart';
import 'package:wegig_app/features/post/presentation/pages/post_detail_page.dart';
import 'package:wegig_app/features/post/presentation/pages/post_page.dart';
import 'package:wegig_app/features/post/presentation/providers/post_providers.dart';
import 'package:wegig_app/features/profile/presentation/pages/view_profile_page.dart';
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
  final InterestService _interestService = InterestService();
  final Debouncer _searchDebouncer = Debouncer(milliseconds: 300);
  
  // State
  List<PostEntity> _visiblePosts = [];
  final Set<String> _sentInterests = <String>{};
  Set<Marker> _markers = {};
  String? _activePostId;
  bool _isCenteringLocation = false;
  bool _isRebuildingMarkers = false;
  DateTime? _lastMarkerRebuild;
  ProviderSubscription<AsyncValue<PostState>>? _postsSubscription;
  ProviderSubscription<AsyncValue<ProfileState>>? _profileSubscription;
  Completer<GoogleMapController>? _mapControllerCompleter;
  bool _isCenteringProfileCamera = false;
  bool _hasCenteredOnce = false;
  List<PostEntity> _cachedPosts = <PostEntity>[];
  bool _isDisposed = false;
  
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
      _searchController.text = _searchService.getDisplayName(suggestion) ?? '';
      _searchFocusNode.unfocus();
    }
  }
  // ========================= CICLO DE VIDA =========================

  @override
  void initState() {
    super.initState();
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
    ref.read(mapCenterProvider.notifier).resetAll();
    _postsSubscription?.close();
    _profileSubscription?.close();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mapControllerWrapper.dispose();
    _searchDebouncer.dispose(); // ✅ Cancela Timer pendente
    _markerBuilder.dispose();
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

        _hasCenteredOnce = false;
        ref.read(mapCenterProvider.notifier).reset(nextId);
        _primeInitialCameraTarget(nextProfile);
        unawaited(_maybeCenterOnActiveProfile(force: true));
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
    await _mapControllerWrapper.loadMapStyle();
    await _determinePosition();
    widget.searchNotifier?.addListener(_onSearchChanged);
  }

  // ========================= MÉTODOS DE LÓGICA =========================

  void _onSearchChanged() {
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
      await _mapControllerWrapper.animateToPosition(
        geoPointToLatLng(post.location),
        15,
      );
    }

    // Reconstrói marcadores com novo estado ativo
    await _rebuildMarkers(force: true);
  }

  void _closeCard() {
    if (!mounted) return;
    setState(() => _activePostId = null);
    // Reconstrói marcadores para remover estado ativo
    _rebuildMarkers(force: true);
  }

  Future<void> _centerOnUserLocation() async {
    if (!mounted || _isCenteringLocation) return;

    try {
      setState(() => _isCenteringLocation = true);

      final controller = await _waitForMapController();
      if (controller == null) {
        AppSnackBar.showInfo(context, 'Aguarde o mapa carregar...');
        return;
      }

      // Verificar permissões primeiro
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        AppSnackBar.showWarning(context, 'Permissão de localização necessária');
        return;
      }

      // Verificar se serviços de localização estão ativos
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppSnackBar.showWarning(context, 'GPS desativado. Ative nas configurações.');
        return;
      }

      LatLng? targetPos;

      // Estratégia 1: Usar posição atual em cache se disponível e recente
      if (_mapControllerWrapper.currentPosition != null) {
        targetPos = _mapControllerWrapper.currentPosition;
        debugPrint('📍 Usando posição em cache');
      } else {
        // Estratégia 2: Tentar obter posição atual com timeout
        debugPrint('📍 Obtendo localização do usuário...');

        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          ).timeout(const Duration(seconds: 8));
          targetPos = LatLng(position.latitude, position.longitude);
          if (mounted) {
            setState(() => _mapControllerWrapper.setCurrentPosition(targetPos!));
          }
          debugPrint(
              '📍 Localização obtida: ${targetPos.latitude}, ${targetPos.longitude}');
        } catch (timeoutError) {
          // Estratégia 3: Fallback para última posição conhecida
          debugPrint(
              '⚠️ Timeout ao obter localização, tentando última posição conhecida...');
          final lastPosition = await Geolocator.getLastKnownPosition();

          if (lastPosition != null) {
            targetPos = LatLng(lastPosition.latitude, lastPosition.longitude);
            if (mounted) {
              setState(() => _mapControllerWrapper.setCurrentPosition(targetPos!));
            }
            debugPrint('📍 Usando última posição conhecida');

            AppSnackBar.showInfo(context, 'Usando última localização conhecida');
          } else {
            // Estratégia 4: Fallback para posição atual do mapa se disponível
            debugPrint(
                '⚠️ Nenhuma localização conhecida, tentando posição do mapa...');
            if (_mapControllerWrapper.controller != null) {
              try {
                final cameraPosition = await _mapControllerWrapper.controller!.getVisibleRegion();
                // Usar o centro do mapa atual
                final centerLat = (cameraPosition.northeast.latitude +
                        cameraPosition.southwest.latitude) /
                    2;
                final centerLng = (cameraPosition.northeast.longitude +
                        cameraPosition.southwest.longitude) /
                    2;
                targetPos = LatLng(centerLat, centerLng);
                debugPrint('📍 Centralizando na posição atual do mapa');

                AppSnackBar.showInfo(context, 'GPS indisponível. Movendo para área atual do mapa.');
              } catch (e) {
                // Estratégia 5: Usar posição padrão de SP como último recurso
                targetPos = const LatLng(-23.55052, -46.633308);
                debugPrint('📍 Usando posição padrão (São Paulo)');

                AppSnackBar.showWarning(context, 'GPS indisponível. Ative o GPS para ver sua localização.');
              }
            } else {
              // Sem mapa disponível, usar SP como padrão
              targetPos = const LatLng(-23.55052, -46.633308);
              debugPrint('📍 Usando posição padrão (São Paulo)');
            }
          }
        }
      }

      // Centralizar no mapa
      if (targetPos != null) {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(targetPos, 14),
        );
        debugPrint('✅ Mapa centralizado com sucesso');
      }
    } catch (e) {
      debugPrint('❌ Erro ao centralizar no usuário: $e');

      // Mensagem amigável baseada no tipo de erro
      var errorMessage = 'Erro ao obter localização';
      if (e.toString().contains('TimeoutException')) {
        errorMessage = 'GPS não respondeu. Tente novamente.';
      } else if (e.toString().contains('Location services are disabled')) {
        errorMessage = 'Serviços de localização desativados';
      } else if (e.toString().contains('denied')) {
        errorMessage = 'Permissão de localização negada';
      }

      // Não mostrar snackbar para erro de canal - é esperado durante inicialização
      if (!e.toString().contains('channel-error')) {
        AppSnackBar.showError(context, errorMessage);
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

    await FirebaseFirestore.instance.collection('interests').add({
      'postId': post.id,
      'postAuthorUid': post.authorUid,
      'postAuthorProfileId': post.authorProfileId,
      'interestedUid': currentUser.uid,
      'interestedProfileId': activeProfile.profileId,
      'interestedProfileName': activeProfile.name, // ✅ Cloud Function expects this field
      'interestedProfilePhotoUrl': activeProfile.photoUrl, // ✅ Used in notification
      'interestedName': activeProfile.name, // ⚠️ Deprecated but kept for backwards compat
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });

    final distance = _calculateDistanceToPost(post, activeProfile);

    await ref.read(notificationServiceProvider).createInterestReceivedNotification(
          postId: post.id,
          postOwnerProfileId: post.authorProfileId,
          postOwnerUid: post.authorUid,
          interestedProfileId: activeProfile.profileId,
          interestedUserName: activeProfile.name,
          interestedUserPhoto: activeProfile.photoUrl ?? '',
          interestedUserUsername: activeProfile.username,
          city: post.city,
          distanceKm: distance,
        );
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
    setState(() => _sentInterests.add(post.id));

    AppSnackBar.showSuccess(context, 'Interesse enviado! 🎵');

    try {
      await _sendInterestNotification(post);
    } catch (e) {
      debugPrint('Erro no envio otimista de interesse: $e');
      if (mounted) {
        setState(() => _sentInterests.remove(post.id));
        AppSnackBar.showError(context, 'Erro ao enviar interesse: $e');
      }
    }
  }

  Future<void> _removeInterestOptimistically(PostEntity post) async {
    if (!mounted) return;
    setState(() => _sentInterests.remove(post.id));

    AppSnackBar.showInfo(context, 'Interesse removido');

    try {
      final activeProfile = _activeProfile;
      if (activeProfile == null) throw 'Perfil ativo não encontrado';

      final notificationsQuery = await FirebaseFirestore.instance
          .collection('notifications')
          .where('type', isEqualTo: 'interest')
          .where('senderProfileId', isEqualTo: activeProfile.profileId)
          .where('postId', isEqualTo: post.id)
          .get();

      for (final doc in notificationsQuery.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Erro ao remover interesse: $e');
      if (mounted) {
        setState(() => _sentInterests.add(post.id));
        AppSnackBar.showError(context, 'Erro ao remover interesse: $e');
      }
    }
  }

  void _showInterestOptionsDialog(PostEntity post) {
    final isInterestSent = _sentInterests.contains(post.id);
    final isOwner = post.authorProfileId.isNotEmpty &&
        post.authorProfileId == _activeProfile?.profileId;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Opções para o dono do post
            if (isOwner) ...[
              ListTile(
                leading: const Icon(Icons.edit, color: AppColors.primary),
                title: const Text('Editar Post'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final result = await Navigator.of(context).push<bool?>(
                    MaterialPageRoute<bool?>(
                      builder: (_) => PostPage(
                        postType: post.type,
                        existingPostData: {
                          'postId': post.id,
                          'content': post.content,
                          'instruments': post.instruments,
                          'genres': post.genres,
                          'seekingMusicians': post.seekingMusicians,
                          'level': post.level,
                          'photoUrl': post.photoUrl,
                          'youtubeLink': post.youtubeLink,
                          'location': GeoPoint(
                              post.location.latitude, post.location.longitude),
                          'city': post.city,
                        },
                      ),
                    ),
                  );
                  if (result == true) {
                    // Recarregar posts
                    ref.invalidate(postNotifierProvider);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.trash, color: Colors.red),
                title: const Text('Deletar Post'),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeletePost(post);
                },
              ),
            ]
            // Opções para outros usuários
            else ...[
              if (isInterestSent)
                ListTile(
                  leading: const Icon(Iconsax.heart, color: Colors.red),
                  title: const Text('Remover Interesse'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _removeInterestOptimistically(post);
                  },
                )
              else
                ListTile(
                  leading: const Icon(Iconsax.heart5, color: Colors.pink),
                  title: const Text('Demonstrar Interesse'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _sendInterestOptimistically(post);
                  },
                ),
              ListTile(
                leading: const Icon(Iconsax.user, color: AppColors.primary),
                title: const Text('Ver Perfil'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.pushProfile(post.authorProfileId);
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePost(PostEntity post) {
    showDialog(
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

      // Deletar foto do Storage se existir
      if (post.photoUrl != null && post.photoUrl!.isNotEmpty) {
        try {
          final ref = FirebaseStorage.instance.refFromURL(post.photoUrl!);
          await ref.delete();
        } catch (e) {
          debugPrint('Erro ao deletar foto: $e');
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
    final postsAsync = ref.watch(postNotifierProvider);
    final profileAsync = ref.watch(profileProvider);

    // Recalcular distâncias quando o perfil ativo mudar
    profileAsync.whenData((profileState) {
      if (profileState.activeProfile != null && _visiblePosts.isNotEmpty) {
        // Usar WidgetsBinding para evitar setState durante build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(_updatePostDistances);
          }
        });
      }
    });

    return Theme(
      data: AppTheme.light,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFE47911), // Brand Orange
          foregroundColor: const Color(0xFFFAFAFA), // Off-white
          elevation: 2,
          leading: IconButton(
            icon: const Icon(Iconsax.filter),
            tooltip: 'Filtros de busca',
            onPressed: widget.onOpenSearch,
          ),
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
        ),
        body: postsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE47911)),
            ),
          ),
          error: (err, stack) {
            debugPrintStack(stackTrace: stack, label: err.toString());
            return Center(child: Text('Erro ao carregar posts: $err'));
          },
          data: (posts) {
            return Stack(
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
                            prefixIcon: const Icon(Iconsax.location),
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
                      itemBuilder: (context, suggestion) {
                        return ListTile(
                          leading: const Icon(Iconsax.location),
                          title: Text(
                              (suggestion['display_name'] as String?) ?? ''),
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
                // Botão "Buscar nessa área" (aparece quando usuário move o mapa)
                if (_mapControllerWrapper.showSearchAreaButton)
                  Positioned(
                    top: 110,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(24),
                        child: InkWell(
                          onTap: () async {
                            setState(() => _mapControllerWrapper.setShowSearchAreaButton(false));
                            if (_mapControllerWrapper.controller != null) {
                              _mapControllerWrapper.setLastSearchBounds(
                                  await _mapControllerWrapper.controller!.getVisibleRegion());
                              await _onMapIdle();
                            }
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE47911), // Brand Orange
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Iconsax.search_normal,
                                    color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Buscar nessa área',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Card flutuante (só aparece quando um pin é clicado)
                if (_activePostId != null) _buildFloatingCard(),
              ],
            );
          },
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
        style:
            _mapControllerWrapper.mapStyle, // Usando GoogleMap.style ao invés de setMapStyle deprecated
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
          await Future.delayed(const Duration(milliseconds: 300));

          if (_mapControllerWrapper.controller != null && mounted) {
            try {
              _mapControllerWrapper.setLastSearchBounds(await _mapControllerWrapper.controller!.getVisibleRegion());
              await _onMapIdle();
            } catch (e) {
              debugPrint('Erro ao inicializar mapa: $e');
              // Tentar novamente após mais delay
              await Future.delayed(const Duration(milliseconds: 500));
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

          await _maybeCenterOnActiveProfile();
        },
        markers: _markers,
        onCameraMove: (pos) {
          _mapControllerWrapper.setCurrentZoom(pos.zoom);
        },
        onCameraIdle: () async {
          // Debounce para evitar chamadas excessivas
          await Future.delayed(const Duration(milliseconds: 300));
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

      if (!_boundsEqual(bounds, _mapControllerWrapper.lastSearchBounds)) {
        if (_isDisposed || !mounted) {
          return;
        }
        if (mounted) {
          setState(() => _mapControllerWrapper.setShowSearchAreaButton(true));
        }
      }

      final visible = allPosts.where(
        (post) {
          final postLocation = post.location;
          return _latLngInBounds(geoPointToLatLng(postLocation), bounds) &&
              _matchesFilters(post);
        },
      ).toList();

      debugPrint('🗺️ Posts visíveis após filtros: ${visible.length}');

      final visibleIds = visible.map((p) => p.id).toSet();
      final currentVisibleIds = _visiblePosts.map((p) => p.id).toSet();

      if (!const SetEquality().equals(visibleIds, currentVisibleIds)) {
        if (_isDisposed || !mounted) return;

        setState(() {
          _visiblePosts = visible;
          _updatePostDistances();
        });
        await _rebuildMarkers();
      }
    } catch (e) {
      debugPrint('Erro ao obter bounds do mapa: $e');
      if (!mounted || _isDisposed) return;
      if (_visiblePosts.isEmpty) {
        setState(() {
          _visiblePosts = allPosts;
          _updatePostDistances();
        });
        await _rebuildMarkers();
      }
    }
  }

  bool _boundsEqual(LatLngBounds a, LatLngBounds? b) {
    if (b == null) return false;
    const threshold = 0.01;
    return (a.northeast.latitude - b.northeast.latitude).abs() < threshold &&
        (a.northeast.longitude - b.northeast.longitude).abs() < threshold &&
        (a.southwest.latitude - b.southwest.latitude).abs() < threshold &&
        (a.southwest.longitude - b.southwest.longitude).abs() < threshold;
  }

  bool _latLngInBounds(LatLng p, LatLngBounds b) {
    return (p.latitude >= b.southwest.latitude &&
            p.latitude <= b.northeast.latitude) &&
        (p.longitude >= b.southwest.longitude &&
            p.longitude <= b.northeast.longitude);
  }

  Widget _buildFloatingCard() {
    // Encontrar o post ativo
    final activePost =
        _visiblePosts.firstWhereOrNull((p) => p.id == _activePostId);

    if (activePost == null) {
      return const SizedBox.shrink();
    }

    // Card flutuante sobre o mapa (sem Positioned)
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
        child: PostCard(
          post: activePost,
          isActive: true,
          currentActiveProfileId: _activeProfile?.profileId,
          isInterestSent: _sentInterests.contains(activePost.id),
          onOpenOptions: () => _showInterestOptionsDialog(activePost),
          onClose: _closeCard,
        ),
      ),
    );
  }

  Future<void> _determinePosition() async {
    try {
      debugPrint(
          '📍 _determinePosition: Iniciando verificação de localização...');

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint(
            '⚠️ _determinePosition: Serviços de localização desativados');
        return;
      }

      var permission = await Geolocator.checkPermission();
      debugPrint('📍 _determinePosition: Permissão atual: $permission');

      if (permission == LocationPermission.denied) {
        debugPrint('📍 _determinePosition: Solicitando permissão...');
        permission = await Geolocator.requestPermission();
        debugPrint('📍 _determinePosition: Nova permissão: $permission');

        if (permission == LocationPermission.denied) {
          debugPrint('⚠️ _determinePosition: Permissão negada pelo usuário');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ _determinePosition: Permissão negada permanentemente');
        return;
      }

      debugPrint('📍 _determinePosition: Obtendo posição atual...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));

      debugPrint(
          '✅ _determinePosition: Posição obtida: ${position.latitude}, ${position.longitude}');

      final newPos = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _mapControllerWrapper.setCurrentPosition(newPos);
        });

        // Animar câmera apenas se o mapa já estiver pronto
        if (_mapControllerWrapper.controller != null && !_hasCenteredOnce) {
          await _mapControllerWrapper.controller!
            .animateCamera(CameraUpdate.newLatLng(newPos));
          _hasCenteredOnce = true;
          debugPrint(
            '✅ _determinePosition: Câmera animada para posição inicial');
        }
      }
    } catch (e) {
      debugPrint('❌ _determinePosition: Erro ao obter localização: $e');

      // Tentar usar última posição conhecida como fallback
      try {
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null && mounted) {
          debugPrint('📍 _determinePosition: Usando última posição conhecida');
          setState(() {
            _mapControllerWrapper.setCurrentPosition(LatLng(lastPosition.latitude, lastPosition.longitude));
          });
        }
      } catch (e2) {
        debugPrint('❌ _determinePosition: Erro ao obter última posição: $e2');
      }
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

  Future<void> _maybeCenterOnActiveProfile({bool force = false}) async {
    if (_isDisposed || !mounted || _isCenteringProfileCamera) return;
    final profile = _activeProfile;
    final location = profile?.location;
    if (profile == null || location == null) return;

    final profileId = profile.profileId;
    final mapCenterNotifier = ref.read(mapCenterProvider.notifier);
    final alreadyCentered = mapCenterNotifier.hasCentered(profileId);
    final shouldCenter = force || !alreadyCentered || !_hasCenteredOnce;

    if (!shouldCenter) {
      return;
    }

    final controller = await _waitForMapController();
    if (controller == null) return;

    _isCenteringProfileCamera = true;
    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          geoPointToLatLng(location),
          _mapControllerWrapper.currentZoom,
        ),
      );
      mapCenterNotifier.markCentered(profileId);
      _hasCenteredOnce = true;
    } finally {
      _isCenteringProfileCamera = false;
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

    // Filtro: tipo de post (Banda ou Músico)
    if (params.postType != null && params.postType!.isNotEmpty) {
      if (post.type != params.postType) return false;
    }

    // Filtro: nível
    if (params.level != null && params.level!.isNotEmpty) {
      if (post.level != params.level) return false;
    }

    // Filtro: YouTube
    if (params.hasYoutube ?? false) {
      if (post.youtubeLink == null || post.youtubeLink!.isEmpty) return false;
    }

    // Filtro: gêneros
    if (params.genres.isNotEmpty) {
      final hasGenreMatch = post.genres.any(
        params.genres.contains,
      );
      if (!hasGenreMatch) return false;
    }

    // Filtro: instrumentos
    if (params.instruments.isNotEmpty) {
      final postInstruments =
          post.type == 'musician' ? post.instruments : post.seekingMusicians;
      final hasInstrumentMatch = postInstruments.any(
        params.instruments.contains,
      );
      if (!hasInstrumentMatch) return false;
    }

    // Filtro: availableFor (disponível para)
    if (params.availableFor != null && params.availableFor!.isNotEmpty) {
      // Verifica se o post tem algum item da lista availableFor que corresponda
      if (post.availableFor.isEmpty) return false;
      final hasAvailableForMatch = post.availableFor.contains(params.availableFor);
      if (!hasAvailableForMatch) return false;
    }

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
    final primaryColor =
        post.type == 'band' ? AppColors.accent : AppColors.primary;
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
                    onTap: () {
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
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
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
                                    color: primaryColor,
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
                                  : primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isInterestSent
                                  ? Iconsax.heart5
                                  : Iconsax.heart,
                              size: 18,
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
                      context.pushPostDetail(post.id);
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
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                              decoration: TextDecoration.none,
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
                  // Mensagem do post
                  if (post.content.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                  const Spacer(),
                  // Footer: distância + tempo
                  Row(
                    children: [
                        Icon(Iconsax.location,
                          size: 16, color: primaryColor),
                      const SizedBox(width: 3),
                      Text(
                        '${post.distanceKm?.toStringAsFixed(1) ?? '0.0'}km',
                        style: TextStyle(
                          fontSize: 14,
                          color: primaryColor,
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
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.photoUrl});

  final String? photoUrl;

  Widget _placeholder() {
    return const CircleAvatar(
      backgroundColor: AppColors.surfaceVariant,
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
