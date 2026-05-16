import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/utils/deep_link_generator.dart';
import 'package:core_ui/utils/price_calculator.dart';
import 'package:core_ui/utils/location_utils.dart';
import 'package:core_ui/widgets/app_loading_overlay.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wegig_app/app/router/app_router.dart';
import 'package:wegig_app/features/post/presentation/providers/interest_providers.dart';
import 'package:wegig_app/features/post/presentation/providers/post_cache_provider.dart';
import 'package:wegig_app/features/post/presentation/widgets/interest_options_dialog.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';
import 'package:wegig_app/features/report/presentation/providers/report_providers.dart';
import 'package:wegig_app/features/report/presentation/widgets/report_dialog.dart';
import 'package:wegig_app/features/post/presentation/pages/post_page.dart';
import 'package:wegig_app/features/mensagens_new/presentation/pages/chat_new_page.dart';
import 'package:wegig_app/features/mensagens_new/presentation/providers/mensagens_new_providers.dart';
import 'package:wegig_app/features/mensagens_new/presentation/widgets/share_post_bottom_sheet.dart';
import 'package:wegig_app/features/comment/presentation/widgets/comments_bottom_sheet.dart';
import 'package:wegig_app/features/comment/presentation/providers/comment_providers.dart';
import 'package:wegig_app/core/firebase/blocked_relations.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// Carrossel vertical de posts estilo TikTok/Reels.
///
/// Mostra cards fullscreen com informações do post.
/// Navegação vertical entre posts via swipe.
/// Seção expansível com detalhes completos.
/// Double-tap para curtir.
class PostFeedPage extends ConsumerStatefulWidget {
  const PostFeedPage({
    required this.posts,
    this.initialIndex = 0,
    this.mapCenterLabel,
    this.visibleRadiusKm,
    super.key,
  });

  final List<PostEntity> posts;
  final int initialIndex;
  final String? mapCenterLabel;
  final double? visibleRadiusKm;

  @override
  ConsumerState<PostFeedPage> createState() => _PostFeedPageState();
}

class _PostFeedPageState extends ConsumerState<PostFeedPage>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late int _currentIndex;

  // Animação do coração (double-tap like)
  bool _showHeartAnimation = false;
  late final AnimationController _heartAnimationController;
  late final Animation<double> _heartScaleAnimation;
  late final Animation<double> _heartOpacityAnimation;

  // Cache de interesse
  final Map<String, bool> _interestCache = {};
  final Map<String, int> _interestCountCache = {};
  bool _isProcessingInterest = false;

  // Gesture de arrastar para voltar
  double _backDragDistance = 0;
  bool _backDragTriggered = false;
  static const double _backDragThreshold = 80;

  void _handleBackDragUpdate(DragUpdateDetails details) {
    if (details.delta.dx <= 0) return;

    _backDragDistance += details.delta.dx;
    if (!_backDragTriggered && _backDragDistance >= _backDragThreshold) {
      _backDragTriggered = true;
      final navigator = Navigator.of(context);
      HapticFeedback.selectionClick();
      navigator.maybePop();
      _resetBackDrag();
    }
  }

  void _handleBackDragEnd(DragEndDetails details) {
    _resetBackDrag();
  }

  void _resetBackDrag() {
    _backDragDistance = 0;
    _backDragTriggered = false;
  }

  // Pre-cache de imagens
  final Set<int> _precachedIndices = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.posts.length - 1);
    _pageController = PageController(initialPage: _currentIndex);

    // Animação do coração
    _heartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _heartScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 30,
      ),
    ]).animate(_heartAnimationController);

    _heartOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_heartAnimationController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _precacheAdjacentImages(_currentIndex);
      _loadInterestStatus(_currentIndex);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _heartAnimationController.dispose();
    super.dispose();
  }

  void _precacheAdjacentImages(int centerIndex) {
    for (var i = centerIndex - 1; i <= centerIndex + 1; i++) {
      if (i >= 0 && i < widget.posts.length && !_precachedIndices.contains(i)) {
        _precachedIndices.add(i);
        final post = widget.posts[i];
        final url = post.photoUrls.isNotEmpty
            ? post.photoUrls.first
            : (post.photoUrl ?? post.firstPhotoUrl ?? '');
        if (url.isNotEmpty && url.startsWith('http') && mounted) {
          precacheImage(CachedNetworkImageProvider(url), context)
              .catchError((_) {});
        }
      }
    }
  }

  Future<void> _loadInterestStatus(int index) async {
    if (!mounted) return;
    if (index < 0 || index >= widget.posts.length) return;
    final post = widget.posts[index];
    final activeProfile = ref.read(activeProfileProvider);

    // Carregar contagem de interessados se ainda não tiver
    if (!_interestCountCache.containsKey(post.id)) {
      try {
        final countSnapshot = await FirebaseFirestore.instance
            .collection('interests')
            .where('postId', isEqualTo: post.id)
            .count()
            .get();

        if (mounted) {
          setState(
              () => _interestCountCache[post.id] = countSnapshot.count ?? 0);
        }
      } catch (e) {
        debugPrint('Erro ao carregar contagem de interessados: $e');
      }
    }

    // Carregar status de interesse do usuário atual
    if (_interestCache.containsKey(post.id)) return;

    if (!mounted) return;
    if (activeProfile == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('interests')
          .where('postId', isEqualTo: post.id)
          .where('interestedProfileId', isEqualTo: activeProfile.profileId)
          .limit(1)
          .get();

      if (mounted) {
        setState(() => _interestCache[post.id] = snapshot.docs.isNotEmpty);
      }
    } catch (e) {
      debugPrint('Erro ao carregar interesse: $e');
    }
  }

  Future<void> _toggleInterest(PostEntity post) async {
    if (_isProcessingInterest) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    final activeProfile = ref.read(activeProfileProvider);
    if (currentUser == null || activeProfile == null) return;
    if (post.authorProfileId == activeProfile.profileId) return;

    // Verifica estado atual do interesse (do provider que é a fonte de verdade)
    final hasInterest = ref.read(interestNotifierProvider).contains(post.id);

    setState(() {
      _isProcessingInterest = true;
      if (!hasInterest) {
        // Adicionar: mostrar animação do coração
        _interestCache[post.id] = true;
        _interestCountCache[post.id] = (_interestCountCache[post.id] ?? 0) + 1;
        _showHeartAnimation = true;
      } else {
        // Remover: sem animação
        _interestCache[post.id] = false;
        _interestCountCache[post.id] = (_interestCountCache[post.id] ?? 1) - 1;
      }
    });

    HapticFeedback.mediumImpact();

    if (!hasInterest) {
      _heartAnimationController.forward(from: 0).then((_) {
        if (mounted) setState(() => _showHeartAnimation = false);
      });
    }

    try {
      if (!hasInterest) {
        await ref.read(interestNotifierProvider.notifier).addInterest(
              postId: post.id,
              postAuthorUid: post.authorUid,
              postAuthorProfileId: post.authorProfileId,
            );
      } else {
        await ref.read(interestNotifierProvider.notifier).removeInterest(
              postId: post.id,
            );
      }
    } catch (e) {
      // Rollback em caso de erro
      if (mounted) {
        setState(() {
          _interestCache[post.id] = hasInterest;
          _interestCountCache[post.id] = hasInterest
              ? (_interestCountCache[post.id] ?? 0) + 1
              : (_interestCountCache[post.id] ?? 1) - 1;
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessingInterest = false);
    }
  }

  void _onPageChanged(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
    _precacheAdjacentImages(index);
    _loadInterestStatus(index);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.posts.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_left_2, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Text('Nenhum post disponível',
              style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: _handleBackDragUpdate,
      onHorizontalDragEnd: _handleBackDragEnd,
      onHorizontalDragCancel: _resetBackDrag,
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // PageView vertical
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              physics: const ClampingScrollPhysics(),
              itemCount: widget.posts.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final post = widget.posts[index];
                final interestCount = _interestCountCache[post.id] ?? 0;
                final hasInterest = _interestCache[post.id] ?? false;

                return GestureDetector(
                  onDoubleTap:
                      post.type != 'sales' ? () => _toggleInterest(post) : null,
                  child: _PostFullCard(
                    post: post,
                    interestCount: interestCount,
                    hasInterest: hasInterest,
                    onTapProfile: () =>
                        context.pushProfile(post.authorProfileId),
                    onTapInterest: () => _toggleInterest(post),
                  ),
                );
              },
            ),

            // Animação de coração
            if (_showHeartAnimation)
              Center(
                child: AnimatedBuilder(
                  animation: _heartAnimationController,
                  builder: (_, __) => Opacity(
                    opacity: _heartOpacityAnimation.value,
                    child: Transform.scale(
                      scale: _heartScaleAnimation.value,
                      child: const Icon(
                        Iconsax.heart5,
                        color: Colors.white,
                        size: 120,
                        shadows: [
                          Shadow(blurRadius: 30, color: Colors.black54)
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // AppBar overlay
            _buildAppBar(),

            // Indicador de posição
            if (widget.posts.length > 1)
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(child: _buildPositionIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final post = widget.posts[_currentIndex];
    final mapLabel = widget.mapCenterLabel?.trim();
    final radiusLabel = _formatRadius(widget.visibleRadiusKm);

    late final String locationLabel;
    if (mapLabel != null && mapLabel.isNotEmpty) {
      if (radiusLabel != null) {
        locationLabel = 'em um raio de $radiusLabel';
      } else {
        locationLabel = mapLabel;
      }
    } else {
      locationLabel = _buildPostLocationLabel(post);
    }

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Botão voltar
              Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: IconButton(
                  icon: const Icon(Iconsax.arrow_left_2, color: Colors.white),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              // Localização de referência
              Expanded(
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Iconsax.location,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            locationLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Contador
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.posts.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildPostLocationLabel(PostEntity post) {
    final locationParts = <String>[];
    if (post.neighborhood?.isNotEmpty == true)
      locationParts.add(post.neighborhood!);
    if (post.city.isNotEmpty) locationParts.add(post.city);
    if (post.state?.isNotEmpty == true) locationParts.add(post.state!);
    return locationParts.isNotEmpty ? locationParts.join(', ') : 'Localização';
  }

  String? _formatRadius(double? km) {
    if (km == null || km <= 0) return null;
    final formatted = km >= 10 ? km.toStringAsFixed(0) : km.toStringAsFixed(1);
    return '~$formatted km';
  }

  Widget _buildPositionIndicator() {
    if (widget.posts.length <= 7) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(widget.posts.length, (i) {
          final isActive = i == _currentIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(vertical: 3),
            width: isActive ? 4 : 3,
            height: isActive ? 18 : 8,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Colors.white38,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      );
    }

    // Para muitos posts, barra de progresso
    return Container(
      width: 4,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: FractionallySizedBox(
          heightFactor: (_currentIndex + 1) / widget.posts.length,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

/// Card fullscreen de post para o feed vertical com seção expansível
class _PostFullCard extends ConsumerStatefulWidget {
  const _PostFullCard({
    required this.post,
    required this.interestCount,
    required this.hasInterest,
    required this.onTapProfile,
    required this.onTapInterest,
  });

  final PostEntity post;
  final int interestCount;
  final bool hasInterest;
  final VoidCallback onTapProfile;
  final VoidCallback onTapInterest;

  @override
  ConsumerState<_PostFullCard> createState() => _PostFullCardState();
}

class _PostFullCardState extends ConsumerState<_PostFullCard> {
  late final PageController _photoPageController;
  int _currentPhotoIndex = 0;
  bool _isExpanded = false;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  YoutubePlayerController? _youtubeController;

  // Estado para interessados
  List<Map<String, dynamic>> _interestedUsers = [];
  bool _isLoadingInterests = false;
  bool _isOpeningConversation = false; // Loading ao abrir chat
  String _authorUid = ''; // UID do autor para criar conversa

  List<String> get _photoUrls {
    if (widget.post.photoUrls.isNotEmpty) {
      return widget.post.photoUrls;
    }
    final singleUrl = widget.post.photoUrl ?? widget.post.firstPhotoUrl ?? '';
    return singleUrl.isNotEmpty ? [singleUrl] : [];
  }

  String? get _youtubeVideoId {
    final link = widget.post.youtubeLink;
    if (link == null || link.isEmpty) return null;
    return YoutubePlayer.convertUrlToId(link);
  }

  @override
  void initState() {
    super.initState();
    _photoPageController = PageController();
    _initYoutubeController();
    _loadInterestedUsers();
    _loadAuthorUid();
  }

  /// Carrega o UID do autor do post para criar conversa
  Future<void> _loadAuthorUid() async {
    try {
      final profileDoc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(widget.post.authorProfileId)
          .get();

      if (profileDoc.exists && mounted) {
        setState(() {
          _authorUid = (profileDoc.data()?['uid'] as String?) ?? '';
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar UID do autor: $e');
    }
  }

  void _initYoutubeController() {
    final videoId = _youtubeVideoId;
    if (videoId != null) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: false,
        ),
      );
    }
  }

  /// Carrega lista de usuários interessados neste post
  Future<void> _loadInterestedUsers() async {
    if (!mounted) return;
    setState(() => _isLoadingInterests = true);

    try {
      final interestsSnapshot = await FirebaseFirestore.instance
          .collection('interests')
          .where('postId', isEqualTo: widget.post.id)
          .orderBy('createdAt', descending: true)
          .limit(10) // Limitar para performance
          .get();

      final users = <Map<String, dynamic>>[];
      final seenProfileIds = <String>{};

      for (final interestDoc in interestsSnapshot.docs) {
        final data = interestDoc.data();
        final interestedProfileId = data['interestedProfileId'] as String?;

        if (interestedProfileId == null || interestedProfileId.isEmpty)
          continue;
        if (seenProfileIds.contains(interestedProfileId)) continue;
        seenProfileIds.add(interestedProfileId);

        try {
          final profileDoc = await FirebaseFirestore.instance
              .collection('profiles')
              .doc(interestedProfileId)
              .get();

          if (profileDoc.exists) {
            final profileData = profileDoc.data()!;
            users.add({
              'profileId': interestedProfileId,
              'name': profileData['name'] as String? ?? 'Usuário',
              'photoUrl': profileData['photoUrl'] as String? ?? '',
              'isBand': profileData['isBand'] as bool? ?? false,
            });
          }
        } catch (e) {
          debugPrint('Erro ao buscar perfil: $e');
        }
      }

      if (mounted) {
        setState(() {
          _interestedUsers = users;
          _isLoadingInterests = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar interessados: $e');
      if (mounted) {
        setState(() => _isLoadingInterests = false);
      }
    }
  }

  @override
  void dispose() {
    _photoPageController.dispose();
    _sheetController.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
    HapticFeedback.lightImpact();

    if (_isExpanded) {
      _sheetController.animateTo(
        0.7,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _sheetController.animateTo(
        0.35,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasMultiplePhotos = _photoUrls.length > 1;

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Carrossel de fotos ou imagem única
          if (_photoUrls.isNotEmpty)
            hasMultiplePhotos
                ? PageView.builder(
                    controller: _photoPageController,
                    scrollDirection: Axis.horizontal,
                    itemCount: _photoUrls.length,
                    onPageChanged: (index) {
                      setState(() => _currentPhotoIndex = index);
                    },
                    itemBuilder: (context, index) {
                      return CachedNetworkImage(
                        imageUrl: _photoUrls[index],
                        fit: BoxFit.contain,
                        memCacheWidth: 1200,
                        fadeInDuration: const Duration(milliseconds: 200),
                        placeholder: (_, __) => _buildPlaceholder(),
                        errorWidget: (_, __, ___) => _buildFallback(),
                      );
                    },
                  )
                : CachedNetworkImage(
                    imageUrl: _photoUrls.first,
                    fit: BoxFit.contain,
                    memCacheWidth: 1200,
                    fadeInDuration: const Duration(milliseconds: 200),
                    placeholder: (_, __) => _buildPlaceholder(),
                    errorWidget: (_, __, ___) => _buildFallback(),
                  )
          else
            _buildFallback(),

          // Indicador de fotos (dots)
          if (hasMultiplePhotos)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_photoUrls.length, (index) {
                  final isActive = index == _currentPhotoIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 8 : 6,
                    height: isActive ? 8 : 6,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.white54,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(blurRadius: 4, color: Colors.black45),
                      ],
                    ),
                  );
                }),
              ),
            ),

          // Bottom Sheet expansível com detalhes
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.35,
            minChildSize: 0.15,
            maxChildSize: 0.85,
            snap: true,
            snapSizes: const [0.15, 0.35, 0.7, 0.85],
            builder: (context, scrollController) {
              return NotificationListener<DraggableScrollableNotification>(
                onNotification: (notification) {
                  if (notification.extent > 0.5 && !_isExpanded) {
                    setState(() => _isExpanded = true);
                  } else if (notification.extent <= 0.35 && _isExpanded) {
                    setState(() => _isExpanded = false);
                  }
                  return true;
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.15, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.95),
                        Colors.black,
                      ],
                    ),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.zero,
                    children: [
                      // Handle de arraste
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white38,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Conteúdo principal
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Conteúdo à esquerda
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Avatar + Nome
                                  _buildHeader(),

                                  const SizedBox(height: 12),

                                  // Tipo do post
                                  _buildTypeChip(),

                                  const SizedBox(height: 12),

                                  // Mensagem/Descrição
                                  _buildDescription(),

                                  // Seção expandida com mais detalhes
                                  if (_isExpanded) ...[
                                    const SizedBox(height: 20),
                                    _buildExpandedDetails(),
                                  ],

                                  // Botão expandir/colapsar
                                  _buildExpandButton(),

                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Ícones de ação alinhados verticalmente
                            _buildActionIcons(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      onTap: widget.onTapProfile,
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.authorName ?? 'Perfil',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.post.city.isNotEmpty)
                  Text(
                    formatCleanLocation(
                      neighborhood: widget.post.neighborhood,
                      city: widget.post.city,
                      state: widget.post.state,
                      fallback: '',
                    ),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _getTypeColor().withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _getTypeLabel(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Helper para ícone com contador (estilo feed escuro)
  Widget _buildFeedIconWithCounter({
    required IconData icon,
    required int count,
    required String tooltip,
    required VoidCallback onPressed,
    VoidCallback? onCountTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: Colors.white, size: 18),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            tooltip: tooltip,
          ),
        ),
        if (count > 0)
          GestureDetector(
            onTap: onCountTap,
            behavior: onCountTap != null
                ? HitTestBehavior.opaque
                : HitTestBehavior.deferToChild,
            child: Padding(
              padding:
                  const EdgeInsets.only(top: 2, left: 6, right: 6, bottom: 2),
              child: Text(
                count > 999
                    ? '${(count / 1000).toStringAsFixed(1)}k'
                    : '$count',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Coluna de ícones de ação alinhados à direita
  Widget _buildActionIcons() {
    final isSales = widget.post.type == 'sales';
    final liveCommentCount =
        ref.watch(commentCountStreamProvider(widget.post.id)).value ??
            widget.post.commentCount;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Comentários
          _buildFeedIconWithCounter(
            icon: Iconsax.message,
            count: liveCommentCount,
            tooltip: 'Comentários',
            onPressed: () {
              CommentsBottomSheet.show(context, widget.post);
            },
            onCountTap: () {
              CommentsBottomSheet.show(context, widget.post);
            },
          ),
          const SizedBox(height: 16),
          // Encaminhar
          _buildFeedIconWithCounter(
            icon: Iconsax.send_1,
            count: widget.post.forwardCount,
            tooltip: 'Enviar para conversa',
            onPressed: _sharePostToChat,
          ),
          const SizedBox(height: 16),
          // Interesse / Opções do post
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: _isOwnPost()
                    ? IconButton(
                        icon: const Icon(
                          Iconsax.more,
                          color: Colors.white,
                          size: 18,
                        ),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                        onPressed: _showOwnPostOptions,
                      )
                    : Builder(
                        builder: (context) {
                          final hasInterest = ref
                              .watch(interestNotifierProvider)
                              .contains(widget.post.id);
                          return IconButton(
                            icon: Icon(
                              hasInterest
                                  ? (isSales ? Iconsax.tag5 : Iconsax.heart5)
                                  : (isSales ? Iconsax.tag : Iconsax.heart),
                              color: hasInterest ? Colors.pink : Colors.white,
                              size: 18,
                            ),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                            onPressed: _showInterestOptions,
                          );
                        },
                      ),
              ),
              if (widget.interestCount > 0)
                GestureDetector(
                  onTap: _showAllInterestedUsers,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(
                        top: 4, left: 8, right: 8, bottom: 4),
                    child: Text(
                      widget.interestCount > 999
                          ? '${(widget.interestCount / 1000).toStringAsFixed(1)}k'
                          : '${widget.interestCount}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    if (widget.post.content.isEmpty) return const SizedBox.shrink();

    return Text(
      widget.post.content,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        height: 1.4,
      ),
      maxLines: _isExpanded ? null : 3,
      overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
    );
  }

  Widget _buildExpandedDetails() {
    final post = widget.post;
    final locationLabel = _buildLocationLabel(post);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Interessados (no topo)
          if (_interestedUsers.isNotEmpty || _isLoadingInterests) ...[
            _buildInterestedUsers(),
            const SizedBox(height: 16),
          ],

          // Localização
          if (locationLabel.isNotEmpty) ...[
            _buildDetailRow(
              Iconsax.location,
              'Local',
              locationLabel,
            ),
            const SizedBox(height: 12),
          ],

          if (post.type == 'hiring') ...[
            if (post.eventType?.isNotEmpty == true)
              _buildDetailRow(
                Iconsax.tick_circle,
                'Tipo de evento',
                post.eventType!,
              ),
            if (post.eventType?.isNotEmpty == true) const SizedBox(height: 12),
            if (post.gigFormat?.isNotEmpty == true)
              _buildDetailRow(
                Iconsax.music_filter,
                'Formação desejada',
                post.gigFormat!,
              ),
            if (post.gigFormat?.isNotEmpty == true) const SizedBox(height: 12),
            _buildDetailRow(
              Iconsax.calendar,
              'Data do evento',
              _formatEventDate(post.eventDate),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Iconsax.clock,
              'Horário',
              _formatEventTime(
                post.eventStartTime,
                post.eventEndTime,
                post.eventDurationMinutes,
              ),
            ),
            if (post.guestCount != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                Iconsax.user,
                'Público estimado',
                '${post.guestCount} convidados',
              ),
            ],
            if (post.budgetRange?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                Iconsax.money,
                'Orçamento',
                post.budgetRange!,
              ),
            ],
            if (post.venueSetup.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                Iconsax.microphone_2,
                'Estrutura disponível',
                post.venueSetup.join(', '),
              ),
            ],
            if (post.instruments.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                Iconsax.search_favorite,
                'Formação/Instrumentos',
                post.instruments.join(', '),
              ),
            ],
            if (post.genres.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                Iconsax.music_playlist,
                'Gêneros',
                post.genres.join(', '),
              ),
            ],
          ] else ...[
            // Instrumentos ou Procurando
            if (post.type == 'musician' && post.instruments.isNotEmpty)
              _buildDetailRow(
                Iconsax.musicnote,
                'Instrumentos',
                post.instruments.join(', '),
              )
            else if (post.type == 'band' && post.seekingMusicians.isNotEmpty)
              _buildDetailRow(
                Iconsax.search_favorite,
                'Procurando',
                post.seekingMusicians.join(', '),
              ),

            // Gêneros
            if (post.genres.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                Iconsax.music_library_2,
                'Gêneros',
                post.genres.join(', '),
              ),
            ],

            // Nível
            if (post.level.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                Iconsax.star,
                'Nível',
                _getSkillLevelLabel(post.level),
              ),
            ],

            // Disponível para
            if (post.availableFor.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                Iconsax.calendar,
                'Disponível para',
                post.availableFor.join(', '),
              ),
            ],
          ],

          // Preço (para vendas) — inclui gratuitos
          if (post.type == 'sales' && post.price != null) ...[
            const SizedBox(height: 12),
            Builder(builder: (context) {
              final priceData = PriceCalculator.getPriceDisplayData(post);
              final currency =
                  NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

              return Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Baseline(
                    baseline:
                        18, // Ajuste para alinhar com a baseline do texto (aproximadamente 80% da fontSize 22)
                    baselineType: TextBaseline.alphabetic,
                    child: const Icon(Iconsax.money,
                        color: Colors.green, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        priceData.isFree
                            ? 'Grátis'
                            : currency.format(priceData.finalPrice),
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                      if (priceData.hasDiscount && !priceData.isFree) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (priceData.discountLabel != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  priceData.discountLabel!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            if (priceData.discountLabel != null)
                              const SizedBox(width: 8),
                            Text(
                              currency.format(priceData.originalPrice),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              );
            }),
          ],

          // Validade (para vendas)
          if (post.type == 'sales') ...[
            const SizedBox(height: 12),
            Builder(builder: (context) {
              final startDate = post.promoStartDate ?? post.createdAt;
              final endDate = post.promoEndDate ?? post.expiresAt;
              final dateFormat = DateFormat('dd/MM/yyyy');

              return _buildDetailRow(
                Iconsax.calendar,
                'Validade',
                '${dateFormat.format(startDate)} até ${dateFormat.format(endDate)}',
              );
            }),
          ],

          // WhatsApp (para vendas)
          if (post.type == 'sales' &&
              post.whatsappNumber != null &&
              post.whatsappNumber!.isNotEmpty) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _openWhatsApp(post.whatsappNumber!),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFF25D366).withValues(alpha: 0.5)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.message, color: Color(0xFF25D366), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Chamar no WhatsApp',
                      style: TextStyle(
                        color: Color(0xFF25D366),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (widget.post.spotifyLink != null &&
              widget.post.spotifyLink!.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSpotifySection(widget.post.spotifyLink!),
          ],

          if (widget.post.deezerLink != null &&
              widget.post.deezerLink!.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildDeezerSection(widget.post.deezerLink!),
          ],

          // YouTube Player
          if (_youtubeController != null) ...[
            const SizedBox(height: 20),
            _buildYoutubeSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildSpotifySection(String url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Iconsax.music, color: Colors.greenAccent, size: 20),
            SizedBox(width: 8),
            Text(
              'Ouça no Spotify',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Iconsax.external_drive, color: Colors.white),
            label: const Text(
              'Abrir Spotify',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _launchSpotify(url),
          ),
        ),
      ],
    );
  }

  Widget _buildYoutubeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Iconsax.video_play, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text(
              'Vídeo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: YoutubePlayer(
            controller: _youtubeController!,
            showVideoProgressIndicator: true,
            progressIndicatorColor: Colors.red,
            progressColors: const ProgressBarColors(
              playedColor: Colors.red,
              handleColor: Colors.redAccent,
            ),
            bottomActions: const [
              SizedBox(width: 14.0),
              CurrentPosition(),
              SizedBox(width: 8.0),
              ProgressBar(isExpanded: true),
              RemainingDuration(),
              PlaybackSpeedButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeezerSection(String url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Iconsax.music, color: Colors.lightBlueAccent, size: 20),
            SizedBox(width: 8),
            Text(
              'Ouça no Deezer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Iconsax.external_drive, color: Colors.white),
            label: const Text(
              'Abrir Deezer',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _launchDeezer(url),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white54, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandButton() {
    return GestureDetector(
      onTap: _toggleExpanded,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isExpanded ? 'Ver menos' : 'Ver mais detalhes',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _isExpanded ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1,
              color: Colors.white70,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final photoUrl = widget.post.authorPhotoUrl;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: Colors.grey[800],
        backgroundImage: CachedNetworkImageProvider(photoUrl),
      );
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: _getTypeColor().withValues(alpha: 0.3),
      child: Icon(
        widget.post.type == 'band' ? Iconsax.people : Iconsax.user,
        color: Colors.white70,
        size: 22,
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: AppRadioPulseLoader(size: 40, color: AppColors.primary),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: _getTypeColor().withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.post.type == 'band'
                ? Iconsax.people
                : (widget.post.type == 'sales'
                    ? Iconsax.tag
                    : (widget.post.type == 'hiring'
                        ? Iconsax.briefcase
                        : Iconsax.user)),
            size: 64,
            color: _getTypeColor().withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  String _getTypeLabel() {
    switch (widget.post.type) {
      case 'band':
        return 'Banda procura músico';
      case 'musician':
        return 'Músico procura banda';
      case 'sales':
        return widget.post.title ?? 'Anúncio';
      case 'hiring':
        return widget.post.eventType?.isNotEmpty == true
            ? 'Contratação • ${widget.post.eventType}'
            : 'Contratação / Oportunidade';
      default:
        return 'Post';
    }
  }

  Color _getTypeColor() {
    switch (widget.post.type) {
      case 'band':
        return AppColors.bandColor;
      case 'sales':
        return AppColors.salesColor;
      case 'hiring':
        return AppColors.hiringColor;
      default:
        return AppColors.musicianColor;
    }
  }

  String _getSkillLevelLabel(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return 'Iniciante';
      case 'intermediate':
        return 'Intermediário';
      case 'advanced':
        return 'Avançado';
      case 'professional':
        return 'Profissional';
      default:
        return level;
    }
  }

  String _buildLocationLabel(PostEntity post) {
    final parts = <String>[];
    if (post.neighborhood?.isNotEmpty == true) parts.add(post.neighborhood!);
    if (post.city.isNotEmpty) parts.add(post.city);
    if (post.state?.isNotEmpty == true) parts.add(post.state!);
    return parts.isNotEmpty ? parts.join(', ') : 'Localização';
  }

  String _formatEventDate(DateTime? date) {
    if (date == null) return 'Data a combinar';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatEventTime(String? start, String? end, int? durationMinutes) {
    if (start != null && start.isNotEmpty && end != null && end.isNotEmpty) {
      final durationLabel = durationMinutes != null && durationMinutes > 0
          ? ' (${_formatDurationLabel(durationMinutes)})'
          : '';
      return '$start - $end$durationLabel';
    }
    if (start != null && start.isNotEmpty) {
      return 'A partir das $start';
    }
    if (durationMinutes != null && durationMinutes > 0) {
      return _formatDurationLabel(durationMinutes);
    }
    return 'Horário a combinar';
  }

  String _formatDurationLabel(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0 && mins > 0)
      return '${hours}h${mins.toString().padLeft(2, '0')}min';
    if (hours > 0) return '${hours}h';
    return '${minutes}min';
  }

  /// Encaminha o post para uma conversa (estilo Instagram)
  void _sharePostToChat() {
    HapticFeedback.lightImpact();
    SharePostBottomSheet.show(context, widget.post);
  }

  /// Compartilha o post usando deep link (para bottom sheet)
  void _sharePostWithDeepLink() {
    HapticFeedback.lightImpact();
    final post = widget.post;
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

  Future<void> _openWhatsApp(String number) async {
    HapticFeedback.lightImpact();
    final cleanNumber = number.replaceAll(RegExp(r'[^\d]'), '');
    final url = Uri.parse('https://wa.me/55$cleanNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  /// Abre conversa direta com o autor do post
  Future<void> _openConversation() async {
    if (_authorUid.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faça login para enviar mensagem')),
      );
      return;
    }

    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um perfil primeiro')),
      );
      return;
    }

    // Impedir conversa consigo mesmo
    if (activeProfile.profileId == widget.post.authorProfileId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este é seu próprio post')),
      );
      return;
    }

    // 🔒 Bloqueios: impede abrir conversa com usuário bloqueado
    try {
      final excluded = await BlockedRelations.getExcludedProfileIds(
        firestore: FirebaseFirestore.instance,
        profileId: activeProfile.profileId,
        uid: currentUser.uid,
      );
      if (!mounted) return;
      if (excluded.contains(widget.post.authorProfileId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversa indisponível')),
        );
        return;
      }
    } catch (_) {
      // Se falhar, continua (ChatNewPage também tem guard)
    }

    if (mounted) {
      setState(() => _isOpeningConversation = true);
    }

    try {
      // Busca/cria a conversa
      final conversation = await ref
          .read(mensagensNewRepositoryProvider)
          .getOrCreateConversation(
        currentProfileId: activeProfile.profileId,
        currentUid: currentUser.uid,
        otherProfileId: widget.post.authorProfileId,
        otherUid: _authorUid,
        currentProfileData: {
          'name': activeProfile.name,
          'photoUrl': activeProfile.photoUrl,
        },
        otherProfileData: {
          'name': widget.post.authorName ?? 'Perfil',
          'photoUrl': widget.post.authorPhotoUrl ?? '',
        },
      );

      // Navegar para a tela de chat
      if (mounted) {
        setState(() => _isOpeningConversation = false);

        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => ChatNewPage(
              conversationId: conversation.id,
              otherUid: _authorUid,
              otherProfileId: widget.post.authorProfileId,
              otherName: widget.post.authorName ?? 'Perfil',
              otherPhotoUrl: widget.post.authorPhotoUrl ?? '',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro ao abrir conversa: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Erro ao abrir conversa. Tente novamente.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isOpeningConversation = false);
      }
    }
  }

  /// Verifica se o post é do próprio usuário
  bool _isOwnPost() {
    final activeProfile = ref.read(activeProfileProvider);
    return activeProfile?.profileId == widget.post.authorProfileId;
  }

  /// Navega para edição do post
  void _editPost() {
    final post = widget.post;
    final postData = {
      // Include postId to enable edit flow to update instead of creating new posts
      'id': post.id,
      'postId': post.id,
      'type': post.type,
      'content': post.content,
      'message': post.content, // Compatibilidade
      'instruments': post.instruments,
      'genres': post.genres,
      'seekingMusicians': post.seekingMusicians,
      'level': post.level,
      'availableFor': post.availableFor,
      'photoUrls': post.photoUrls,
      'photoUrl': post.photoUrl,
      'youtubeLink': post.youtubeLink,
      'spotifyLink': post.spotifyLink,
      'deezerLink': post.deezerLink,
      'city': post.city,
      'neighborhood': post.neighborhood,
      'state': post.state,
      'location': post.location,
      'eventDate': post.eventDate,
      'eventType': post.eventType,
      'gigFormat': post.gigFormat,
      'venueSetup': post.venueSetup,
      'budgetRange': post.budgetRange,
      'eventStartTime': post.eventStartTime,
      'eventEndTime': post.eventEndTime,
      'eventDurationMinutes': post.eventDurationMinutes,
      'guestCount': post.guestCount,
      // Sales fields
      'title': post.title,
      'salesType': post.salesType,
      'price': post.price,
      'discountMode': post.discountMode,
      'discountValue': post.discountValue,
      'promoStartDate': post.promoStartDate,
      'promoEndDate': post.promoEndDate,
      'whatsappNumber': post.whatsappNumber,
    };
    showEditPostModal(context, postData);
  }

  /// Mostra opções para posts próprios (editar, excluir, etc)
  void _showOwnPostOptions() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Iconsax.edit, color: AppColors.primary),
                title: const Text('Editar post'),
                onTap: () {
                  Navigator.pop(context);
                  _editPost();
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.trash, color: Colors.red),
                title: const Text('Excluir post',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeletePost();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Confirmação de exclusão de post
  void _confirmDeletePost() {
    // Capturar o navigator ANTES de abrir o dialog
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir post?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              // Fechar o dialog primeiro
              Navigator.pop(dialogContext);

              try {
                await FirebaseFirestore.instance
                    .collection('posts')
                    .doc(widget.post.id)
                    .delete();

                // Invalidar cache de posts para atualizar a lista imediatamente
                ref.read(postCacheNotifierProvider.notifier).invalidate();

                // Usar referências capturadas antes do dialog
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Post excluído com sucesso')),
                );

                // Sair do feed usando o navigator capturado
                if (navigator.canPop()) {
                  navigator.pop();
                }
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Erro ao excluir post')),
                );
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Mostra opções de interesse (curtir/descurtir, denunciar)
  void _showInterestOptions() {
    HapticFeedback.mediumImpact();
    final hasInterest =
        ref.read(interestNotifierProvider).contains(widget.post.id);

    showInterestOptionsDialog(
      context: context,
      post: widget.post,
      isInterestSent: hasInterest,
      isOwner: _isOwnPost(),
      onSendInterest: widget.onTapInterest,
      onRemoveInterest: widget.onTapInterest,
      onDeletePost: _confirmDeletePost,
      onViewProfile: () => context.pushProfile(widget.post.authorProfileId),
      onPostEdited: () {
        ref.read(postCacheNotifierProvider.notifier).invalidate();
      },
    );
  }

  /// Widget para exibir usuários interessados
  /// Layout estilo Instagram: avatares sobrepostos + texto clicável
  Widget _buildInterestedUsers() {
    // Loading state
    if (_isLoadingInterests) {
      return Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: AppRadioPulseLoader(size: 18, color: Colors.white38),
          ),
          const SizedBox(width: 10),
          Text(
            'Carregando interessados...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
        ],
      );
    }

    // Empty state
    if (_interestedUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    final isSales = widget.post.type == 'sales';

    return GestureDetector(
      onTap: _showAllInterestedUsers,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título da seção (mesmo estilo do _buildDetailRow)
          Row(
            children: [
              Icon(
                isSales ? Iconsax.tag : Iconsax.heart,
                color: Colors.white54,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                isSales ? 'Salvaram' : 'Interessados',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Avatares + texto
          Row(
            children: [
              // Stack de avatares sobrepostos (máximo 3)
              SizedBox(
                width: _interestedUsers.length == 1
                    ? 28
                    : (_interestedUsers.length == 2 ? 44 : 60),
                height: 28,
                child: Stack(
                  children: [
                    if (_interestedUsers.isNotEmpty)
                      Positioned(
                        left: 0,
                        child: _buildStackedAvatar(_interestedUsers[0], 0),
                      ),
                    if (_interestedUsers.length >= 2)
                      Positioned(
                        left: 16,
                        child: _buildStackedAvatar(_interestedUsers[1], 1),
                      ),
                    if (_interestedUsers.length >= 3)
                      Positioned(
                        left: 32,
                        child: _buildStackedAvatar(_interestedUsers[2], 2),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Texto descritivo
              Expanded(
                child: Text(
                  _getInterestedText(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Ícone de seta
              const Icon(
                Iconsax.arrow_right_3,
                size: 16,
                color: Colors.white38,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getInterestedText() {
    if (_interestedUsers.isEmpty) return '';

    final firstName = _interestedUsers[0]['name'] as String;
    if (_interestedUsers.length == 1) {
      return firstName;
    } else if (_interestedUsers.length == 2) {
      return '$firstName e ${_interestedUsers[1]['name']}';
    } else {
      return '$firstName e +${_interestedUsers.length - 1}';
    }
  }

  Future<void> _launchSpotify(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Erro ao abrir Spotify: $e');
    }
  }

  Future<void> _launchDeezer(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Erro ao abrir Deezer: $e');
    }
  }

  /// Avatar com borda para o stack
  Widget _buildStackedAvatar(Map<String, dynamic> user, int index) {
    final photoUrl = user['photoUrl'] as String;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: CircleAvatar(
        radius: 12,
        backgroundColor: Colors.grey[800],
        backgroundImage:
            photoUrl.isNotEmpty ? CachedNetworkImageProvider(photoUrl) : null,
        child: photoUrl.isEmpty
            ? const Icon(
                Iconsax.user,
                color: Colors.white54,
                size: 12,
              )
            : null,
      ),
    );
  }

  /// Modal bottom sheet com lista completa de interessados
  void _showAllInterestedUsers() {
    HapticFeedback.mediumImpact();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) {
          final isSales = widget.post.type == 'sales';

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(
                        isSales ? Iconsax.tag5 : Iconsax.heart5,
                        color: isSales ? AppColors.salesColor : Colors.pink,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isSales ? 'Salvaram' : 'Interessados',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_interestedUsers.length}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(height: 1, color: Colors.grey[200]),

                // Lista de interessados
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _interestedUsers.length,
                    itemBuilder: (context, index) {
                      final user = _interestedUsers[index];
                      final photoUrl = user['photoUrl'] as String;
                      final name = user['name'] as String;
                      final isBand = user['isBand'] as bool;
                      final profileId = user['profileId'] as String;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 4),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          backgroundImage: photoUrl.isNotEmpty
                              ? CachedNetworkImageProvider(photoUrl)
                              : null,
                          child: photoUrl.isEmpty
                              ? const Icon(
                                  Iconsax.user,
                                  color: AppColors.primary,
                                  size: 24,
                                )
                              : null,
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          isBand ? 'Banda' : 'Músico',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: Icon(
                          Iconsax.arrow_right_3,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          context.pushProfile(profileId);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
