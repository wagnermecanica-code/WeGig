import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/utils/app_snackbar.dart';
import 'package:core_ui/utils/deep_link_generator.dart';
import 'package:core_ui/utils/geo_utils.dart';
import 'package:core_ui/utils/location_utils.dart';
import 'package:core_ui/widgets/mention_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wegig_app/app/router/app_router.dart';
import 'package:wegig_app/features/notifications/domain/services/notification_service.dart';
import 'package:wegig_app/features/post/presentation/pages/post_page.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// Tela de detalhes completos de um post
///
/// Acessível via navegação de cards de posts, notificações e galerias.
/// Exibe informações completas do post incluindo:
/// - Foto e informações do autor
/// - Gêneros, instrumentos e localização
/// - Link de YouTube (se disponível)
/// - Sistema de interesse (curtir)
/// - Lista de perfis interessados
/// - Ações (editar/deletar para autor, demonstrar interesse para outros)
class PostDetailPage extends ConsumerStatefulWidget {
  /// Construtor da página de detalhes
  const PostDetailPage({
    required this.postId,
    super.key,
  });

  /// ID do post a ser exibido
  final String postId;

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  PostEntity? _post;
  String _authorName = '';
  String _authorPhotoUrl = '';
  bool _isLoading = true;
  bool _hasInterest = false;
  String? _interestId;
  YoutubePlayerController? _youtubeController;
  List<Map<String, dynamic>> _interestedUsers = [];
  bool _isLoadingInterests = false;

  void _handleBackNavigation() {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    context.goToHome();
  }

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    super.dispose();
  }

  /// Carrega os dados do post
  Future<void> _loadPost() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .get();

      if (!doc.exists) {
        if (mounted) {
          Navigator.pop(context);
          AppSnackBar.showError(context, 'Post não encontrado');
        }
        return;
      }

      final post = PostEntity.fromFirestore(doc);

      // Buscar informações do autor
      await _loadAuthorProfile(post.authorProfileId);

      // Inicializar player de YouTube se houver link
      if (post.youtubeLink != null && post.youtubeLink!.isNotEmpty) {
        final videoId = YoutubePlayer.convertUrlToId(post.youtubeLink!);
        if (videoId != null) {
          _youtubeController = YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(
              autoPlay: false,
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _post = post;
          _isLoading = false;
        });
      }

      // Verificar se já tem interesse (APÓS definir _post)
      await _checkInterest(post);

      // Carregar interessados (visível para todos) (APÓS definir _post)
      await _loadInterestedUsers();
    } catch (e) {
      debugPrint('Erro ao carregar post: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackBar.showError(context, 'Erro ao carregar post');
      }
    }
  }

  /// Carrega lista de usuários que demonstraram interesse neste post
  Future<void> _loadInterestedUsers() async {
    if (_post == null) {
      debugPrint('⚠️ _loadInterestedUsers: _post é null, retornando');
      return;
    }

    debugPrint('🔍 Carregando interessados para post: ${_post!.id}');

    setState(() => _isLoadingInterests = true);

    try {
      // Buscar todos os interesses deste post
      final interestsSnapshot = await FirebaseFirestore.instance
          .collection('interests')
          .where('postId', isEqualTo: _post!.id)
          .orderBy('createdAt', descending: true)
          .get();

      debugPrint(
          '📊 Encontrados ${interestsSnapshot.docs.length} documentos na collection interests');

      final users = <Map<String, dynamic>>[];

      // Para cada interesse, buscar dados do perfil
      for (final interestDoc in interestsSnapshot.docs) {
        final data = interestDoc.data();
        final interestedProfileId = data['interestedProfileId'] as String?;

        debugPrint('👤 Carregando perfil: $interestedProfileId');

        if (interestedProfileId != null) {
          try {
            // Buscar perfil do interessado
            final profileDoc = await FirebaseFirestore.instance
                .collection('profiles')
                .doc(interestedProfileId)
                .get();

            if (profileDoc.exists) {
              final profileData = profileDoc.data()!;
              users.add({
                'profileId': interestedProfileId,
                'userId': data['interestedUid'] as String,
                'name': profileData['name'] as String? ?? 'Usuário',
                'photoUrl': profileData['photoUrl'] as String? ?? '',
                'isBand': profileData['isBand'] as bool? ?? false,
                'createdAt': data['createdAt'] as Timestamp?,
              });
              debugPrint('✅ Perfil carregado: ${profileData['name']}');
            } else {
              debugPrint('⚠️ Perfil não encontrado: $interestedProfileId');
            }
          } catch (e) {
            debugPrint('❌ Erro ao buscar perfil do interessado: $e');
          }
        }
      }

      debugPrint(
          '✅ Total de usuários interessados carregados: ${users.length}');

      if (mounted) {
        setState(() {
          _interestedUsers = users;
          _isLoadingInterests = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar interessados: $e');

      // Se for erro de índice, mostrar mensagem mais amigável
      if (e.toString().contains('requires an index')) {
        debugPrint(
            '⚠️ Índice do Firestore ainda não está ativo. Aguarde 2-5 minutos após o deploy.');
      }

      if (mounted) {
        setState(() => _isLoadingInterests = false);
      }
    }
  }

  /// Verifica se o usuário já demonstrou interesse
  Future<void> _checkInterest(PostEntity post) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final profileState = ref.read(profileProvider);
      final activeProfile = profileState.value?.activeProfile;
      if (activeProfile == null) return;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('interests')
          .where('postId', isEqualTo: post.id)
          .where('interestedUid', isEqualTo: currentUser.uid)
          .where('interestedProfileId', isEqualTo: activeProfile.profileId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _hasInterest = true;
          _interestId = querySnapshot.docs.first.id;
        });
      }
    } catch (e) {
      debugPrint(r'Erro ao verificar interesse: $e');
    }
  }

  /// Verifica se o post pertence ao perfil ativo
  bool _isOwnPost() {
    if (_post == null) return false;
    final profileState = ref.read(profileProvider);
    final activeProfile = profileState.value?.activeProfile;
    if (activeProfile == null) return false;
    return _post!.authorProfileId == activeProfile.profileId;
  }

  /// Carrega informações do perfil do autor
  Future<void> _loadAuthorProfile(String profileId) async {
    try {
      final profileDoc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(profileId)
          .get();

      if (profileDoc.exists) {
        final profileData = profileDoc.data()!;
        setState(() {
          _authorName = (profileData['name'] as String?) ?? 'Perfil';
          _authorPhotoUrl = (profileData['photoUrl'] as String?) ?? '';
        });
      }
    } catch (e) {
      debugPrint(r'Erro ao carregar perfil do autor: $e');
    }
  }

  /// Demonstra interesse no post
  Future<void> _showInterest() async {
    if (_post == null) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final profileState = ref.read(profileProvider);
      final activeProfile = profileState.value?.activeProfile;
      if (activeProfile == null) return;

      // Criar documento de interesse
      final docRef =
          await FirebaseFirestore.instance.collection('interests').add({
        'postId': _post!.id,
        'postAuthorUid': _post!.authorUid,
        'postAuthorProfileId': _post!.authorProfileId,
        'interestedUid': currentUser.uid,
        'interestedProfileId': activeProfile.profileId,
        'interestedProfileName': activeProfile.name, // ✅ Cloud Function expects this
        'interestedProfilePhotoUrl': activeProfile.photoUrl, // ✅ Used in notification
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      setState(() {
        _hasInterest = true;
        _interestId = docRef.id;
      });

      final distance = _calculateDistance(activeProfile);

      await ref.read(notificationServiceProvider).createInterestReceivedNotification(
            postId: _post!.id,
            postOwnerProfileId: _post!.authorProfileId,
            postOwnerUid: _post!.authorUid,
            interestedProfileId: activeProfile.profileId,
            interestedUserName: activeProfile.name,
            interestedUserPhoto: activeProfile.photoUrl ?? '',
        interestedUserUsername: activeProfile.username,
            city: _post!.city,
            distanceKm: distance,
          );

      // Aguardar 500ms para garantir que o Firestore processou o serverTimestamp
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // Recarregar lista de interessados
      debugPrint('🔄 Recarregando interessados após demonstrar interesse...');
      await _loadInterestedUsers();
      debugPrint(
          '✅ Interessados recarregados - _interestedUsers.length: ${_interestedUsers.length}');

      if (mounted) {
        AppSnackBar.showSuccess(context, 'Interesse demonstrado! 💙');
      }
    } catch (e) {
      debugPrint('Erro ao demonstrar interesse: $e');
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao demonstrar interesse');
      }
    }
  }

  double? _calculateDistance(ProfileEntity activeProfile) {
    try {
      return calculateDistanceBetweenGeoPoints(
        _post!.location,
        activeProfile.location,
      );
    } catch (_) {
      return null;
    }
  }

  /// Remove interesse
  Future<void> _removeInterest() async {
    if (_interestId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('interests')
          .doc(_interestId)
          .delete();

      setState(() {
        _hasInterest = false;
        _interestId = null;
      });

      // Aguardar 500ms para garantir que o Firestore processou a exclusão
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // Recarregar lista de interessados
      debugPrint('🔄 Recarregando interessados após remover interesse...');
      await _loadInterestedUsers();
      debugPrint(
          '✅ Interessados recarregados - _interestedUsers.length: ${_interestedUsers.length}');

      if (mounted) {
        AppSnackBar.showInfo(context, 'Interesse removido');
      }
    } catch (e) {
      debugPrint('Erro ao remover interesse: $e');
    }
  }

  /// Compartilha o post
  void _sharePost() {
    if (_post == null) return;

    final text = DeepLinkGenerator.generatePostShareMessage(
      postId: _post!.id,
      authorName: _authorName,
      postType: _post!.type,
      city: _post!.city,
      neighborhood: _post!.neighborhood,
      state: _post!.state,
      content: _post!.content,
      instruments: _post!.type == 'musician'
          ? _post!.instruments
          : _post!.seekingMusicians,
      genres: _post!.genres,
    );

    SharePlus.instance.share(ShareParams(text: text));
  }

  /// Deleta o post
  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletar post'),
        content: const Text(
            'Tem certeza que deseja deletar este post? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Deletar interesses relacionados
      final interestsSnapshot = await FirebaseFirestore.instance
          .collection('interests')
          .where('postId', isEqualTo: _post!.id)
          .get();

      for (final doc in interestsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Deletar o post
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(_post!.id)
          .delete();

      if (mounted) {
        Navigator.pop(context);
        AppSnackBar.showSuccess(context, 'Post deletado com sucesso');
      }
    } catch (e) {
      debugPrint(r'Erro ao deletar post: $e');
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao deletar post');
      }
    }
  }

  /// Widget para exibir usuários interessados (visível para todos)
  /// Layout estilo Instagram: avatares sobrepostos + texto clicável
  Widget _buildInterestedUsers() {
    if (_post == null) {
      return const SizedBox.shrink();
    }

    // Loading state
    if (_isLoadingInterests) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Carregando interessados...',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Empty state - não mostra nada se não houver interessados
    if (_interestedUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _showAllInterestedUsers,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(
          children: [
            // Stack de avatares sobrepostos (máximo 3)
            SizedBox(
              width: _interestedUsers.length == 1
                  ? 32
                  : (_interestedUsers.length == 2 ? 52 : 72),
              height: 32,
              child: Stack(
                children: [
                  // Avatar 1 (sempre visível se houver pelo menos 1)
                  if (_interestedUsers.isNotEmpty)
                    Positioned(
                      left: 0,
                      child: _buildStackedAvatar(_interestedUsers[0], 0),
                    ),
                  // Avatar 2 (se houver 2 ou mais)
                  if (_interestedUsers.length >= 2)
                    Positioned(
                      left: 20,
                      child: _buildStackedAvatar(_interestedUsers[1], 1),
                    ),
                  // Avatar 3 (se houver 3 ou mais)
                  if (_interestedUsers.length >= 3)
                    Positioned(
                      left: 40,
                      child: _buildStackedAvatar(_interestedUsers[2], 2),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Texto descritivo
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Interessados: ',
                      style: TextStyle(fontWeight: FontWeight.normal),
                    ),
                    TextSpan(
                      text: _interestedUsers[0]['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (_interestedUsers.length == 2)
                      TextSpan(
                        text: ' e ${_interestedUsers[1]['name']}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      )
                    else if (_interestedUsers.length > 2)
                      TextSpan(
                        text:
                            ' e outras ${_interestedUsers.length - 1} pessoas',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),
            ),

            // Ícone de seta (indica que é clicável)
            Icon(
              Iconsax.arrow_right_3,
              size: 20,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói um avatar individual para o stack (com borda branca)
  Widget _buildStackedAvatar(Map<String, dynamic> user, int index) {
    final photoUrl = user['photoUrl'] as String;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: CircleAvatar(
        radius: 14,
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        backgroundImage:
            photoUrl.isNotEmpty ? CachedNetworkImageProvider(photoUrl) : null,
        child: photoUrl.isEmpty
            ? const Icon(
                Icons.person,
                color: AppColors.primary,
                size: 16,
              )
            : null,
      ),
    );
  }

  /// Modal bottom sheet com lista completa de interessados
  void _showAllInterestedUsers() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
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
                      const Icon(
                        Iconsax.heart5,
                        color: Colors.red,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Interessados',
                        style: TextStyle(
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
                                  Icons.person,
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
                          Navigator.pop(context); // Fecha modal
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

  /// Mostra opções do próprio post
  void _showOwnPostOptions() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Iconsax.edit, color: AppColors.primary),
              title: const Text('Editar post'),
              onTap: () async {
                Navigator.pop(context);

                final result = await Navigator.push<bool?>(
                  context,
                  MaterialPageRoute<bool?>(
                    builder: (_) => PostPage(
                      postType: _post!.type,
                      existingPostData: {
                        'postId': _post!.id,
                        'content': _post!.content,
                        'instruments': _post!.instruments,
                        'genres': _post!.genres,
                        'seekingMusicians': _post!.seekingMusicians,
                        'level': _post!.level,
                        'city': _post!.city,
                        'neighborhood': _post!.neighborhood,
                        'state': _post!.state,
                        'photoUrl': _post!.photoUrl,
                        'youtubeLink': _post!.youtubeLink,
                        'location': GeoPoint(_post!.location.latitude,
                            _post!.location.longitude),
                      },
                    ),
                  ),
                );
                // Se o post foi editado, recarregar
                if (result == true) {
                  _loadPost();
                }
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.trash, color: Colors.red),
              title: const Text('Deletar post'),
              onTap: () {
                Navigator.pop(context);
                _deletePost();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Mostra opções de interesse
  void _showInterestOptions() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Iconsax.heart, color: Colors.red),
              title: const Text('Remover interesse'),
              onTap: () {
                Navigator.pop(context);
                _removeInterest();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE47911)),
          ),
        ),
      );
    }

    if (_post == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('Post não encontrado')),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final photoHeight = screenWidth * 0.7; // Proporção ~10:7

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Conteúdo scrollável
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero com foto do post
                Hero(
                  tag: r'post-photo-${_post!.id}',
                  child: Container(
                    width: screenWidth,
                    height: photoHeight,
                    color: Colors.grey[200],
                    child:
                        (_post!.photoUrl != null && _post!.photoUrl!.isNotEmpty)
                            ? CachedNetworkImage(
                                imageUrl: _post!.photoUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFFE47911)),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[300],
                                  child: Icon(
                                    _post!.type == 'band'
                                        ? Iconsax.people
                                        : Iconsax.user,
                                    size: 80,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              )
                            : Center(
                                child: Icon(
                                  _post!.type == 'band'
                                      ? Iconsax.people
                                      : Iconsax.user,
                                  size: 80,
                                  color: Colors.grey[600],
                                ),
                              ),
                  ),
                ),

                // Overlap negativo com informações do autor
                Transform.translate(
                  offset: const Offset(0, -16),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header com autor e localização
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                          child: Row(
                            children: [
                              // Avatar do autor (clicável)
                              GestureDetector(
                                onTap: () {
                                  context.pushProfile(_post!.authorProfileId);
                                },
                                child: CircleAvatar(
                                  radius: 28,
                                  backgroundColor:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  backgroundImage: _authorPhotoUrl.isNotEmpty
                                      ? CachedNetworkImageProvider(
                                          _authorPhotoUrl)
                                      : null,
                                  child: _authorPhotoUrl.isEmpty
                                      ? const Icon(
                                          Icons.person,
                                          color: AppColors.primary,
                                          size: 32,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Nome e localização
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Nome do perfil (clicável e destacado)
                                    GestureDetector(
                                      onTap: () {
                                        context.pushProfile(_post!.authorProfileId);
                                      },
                                      child: Text(
                                        _authorName,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Divisor
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Divider(height: 1, color: Colors.grey[300]),
                        ),

                        // Seção de interessados (visível para todos)
                        _buildInterestedUsers(),

                        // Título dinâmico do tipo de post
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                          child: Text(
                            _post!.type == 'musician'
                                ? 'Músico em busca de banda'
                                : 'Banda em busca de músico',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),

                        // Card de informações
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Área de Interesse (Localização)
                                _buildInfoRow(
                                  Iconsax.location,
                                  'Área de Interesse',
                                  formatCleanLocation(
                                    neighborhood: _post!.neighborhood,
                                    city: _post!.city,
                                    state: _post!.state,
                                    fallback: 'Localização não disponível',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Instrumentos (músico) ou Procurando (banda)
                                if (_post!.type == 'musician' &&
                                    _post!.instruments.isNotEmpty)
                                  _buildInfoRow(
                                    Iconsax.musicnote,
                                    'Instrumentos',
                                    _post!.instruments.join(', '),
                                  )
                                else if (_post!.type == 'band' &&
                                    _post!.seekingMusicians.isNotEmpty)
                                  _buildInfoRow(
                                    Iconsax.search_favorite,
                                    'Procurando',
                                    _post!.seekingMusicians.join(', '),
                                  ),
                                if ((_post!.type == 'musician' &&
                                        _post!.instruments.isNotEmpty) ||
                                    (_post!.type == 'band' &&
                                        _post!.seekingMusicians.isNotEmpty))
                                  const SizedBox(height: 12),
                                // Gêneros musicais
                                if (_post!.genres.isNotEmpty)
                                  _buildInfoRow(
                                    Iconsax.music_library_2,
                                    'Gêneros',
                                    _post!.genres.join(', '),
                                  ),
                                if (_post!.genres.isNotEmpty)
                                  const SizedBox(height: 12),
                                // Nível de habilidade
                                _buildInfoRow(
                                  Iconsax.star,
                                  'Nível',
                                  _getSkillLevelLabel(_post!.level),
                                ),
                                // Disponível para
                                if (_post!.availableFor.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  _buildInfoRow(
                                    Iconsax.calendar,
                                    'Disponível para',
                                    _post!.availableFor.join(', '),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Card de mensagem
                        if (_post!.content.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Iconsax.message,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Mensagem',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  MentionText(
                                    text: _post!.content,
                                    selectable: true,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[800],
                                      height: 1.5,
                                    ),
                                    onMentionTap: (username) {
                                      context.pushProfileByUsername(username);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Card de vídeo do YouTube
                        if (_youtubeController != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: YoutubePlayer(
                                  controller: _youtubeController!,
                                  showVideoProgressIndicator: true,
                                  progressIndicatorColor: AppColors.primary,
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // AppBar transparente sobre a foto
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botão voltar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Iconsax.arrow_left_2,
                          color: Colors.white,
                          size: 18,
                        ),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                        onPressed: _handleBackNavigation,
                      ),
                    ),
                    // Botões de ação
                    Row(
                      children: [
                        // Compartilhar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Iconsax.share,
                              color: Colors.white,
                              size: 18,
                            ),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                            onPressed: _sharePost,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Interesse ou Menu de opções
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
                              : IconButton(
                                  icon: Icon(
                                    _hasInterest
                                        ? Iconsax.heart5
                                        : Iconsax.heart,
                                    color: _hasInterest
                                        ? Colors.red
                                        : Colors.white,
                                    size: 18,
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  constraints: const BoxConstraints(),
                                  onPressed: _hasInterest
                                      ? _showInterestOptions
                                      : _showInterest,
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  /// Widget para linha de informação
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Converte nível de habilidade em texto
  String _getSkillLevelLabel(String level) {
    switch (level) {
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

}
