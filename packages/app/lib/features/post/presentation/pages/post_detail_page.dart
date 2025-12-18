import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wegig_app/core/cache/image_cache_manager.dart';
import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/utils/app_snackbar.dart';
import 'package:core_ui/utils/deep_link_generator.dart';
import 'package:core_ui/utils/location_utils.dart';
import 'package:core_ui/utils/price_calculator.dart';
import 'package:core_ui/widgets/mention_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wegig_app/app/router/app_router.dart';
import 'package:wegig_app/features/mensagens_new/presentation/pages/chat_new_page.dart';
import 'package:wegig_app/features/mensagens_new/presentation/providers/mensagens_new_providers.dart';
import 'package:wegig_app/features/post/presentation/pages/post_page.dart';
import 'package:wegig_app/features/post/presentation/widgets/interest_options_dialog.dart';
import 'package:wegig_app/features/post/presentation/providers/interest_providers.dart';
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
  String _authorUid = ''; // UID do autor para criar conversa
  bool _isLoading = true;
  YoutubePlayerController? _youtubeController;
  List<Map<String, dynamic>> _interestedUsers = [];
  bool _isLoadingInterests = false;
  int _currentPhotoIndex = 0;
  bool _isOpeningConversation = false; // Loading ao abrir chat

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
      final seenProfileIds = <String>{}; // ✅ Conjunto para rastrear profileIds já vistos

      // Para cada interesse, buscar dados do perfil
      for (final interestDoc in interestsSnapshot.docs) {
        final data = interestDoc.data();
        final interestedProfileId = data['interestedProfileId'] as String?;

        // ✅ VALIDAÇÃO: Filtrar profileIds vazios
        if (interestedProfileId == null || interestedProfileId.isEmpty) {
          debugPrint('⚠️ Interesse sem interestedProfileId válido, pulando...');
          continue;
        }

        // ✅ DEDUPLICAÇÃO: Pular se já processamos este perfil
        if (seenProfileIds.contains(interestedProfileId)) {
          debugPrint('⚠️ Perfil $interestedProfileId já adicionado, pulando duplicata...');
          continue;
        }
        seenProfileIds.add(interestedProfileId);

        debugPrint('👤 Carregando perfil: $interestedProfileId');

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
              'userId': data['interestedUid'] as String? ?? '',
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
          _authorUid = (profileData['uid'] as String?) ?? '';
        });
      }
    } catch (e) {
      debugPrint(r'Erro ao carregar perfil do autor: $e');
    }
  }

  /// Demonstra interesse no post (usando provider global)
  Future<void> _showInterest() async {
    if (_post == null) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final profileState = ref.read(profileProvider);
    final activeProfile = profileState.value?.activeProfile;
    if (activeProfile == null) return;

    // Usar provider global para optimistic update
    final interestNotifier = ref.read(interestNotifierProvider.notifier);
    
    try {
      await interestNotifier.addInterest(
        postId: _post!.id,
        postAuthorUid: _post!.authorUid,
        postAuthorProfileId: _post!.authorProfileId,
      );

      if (mounted) {
        // Recarregar lista silenciosamente
        _loadInterestedUsers();
        
        AppSnackBar.showSuccess(
          context, 
          _post!.type == 'sales' ? 'Anúncio salvo!' : 'Interesse demonstrado!',
        );
      }
    } catch (e) {
      debugPrint('❌ Erro ao demonstrar interesse: $e');
      
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao salvar interesse. Verifique sua conexão.');
      }
    }
  }

  /// Remove interesse do post (usando provider global)
  Future<void> _removeInterest() async {
    if (_post == null) return;

    // Usar provider global para optimistic update
    final interestNotifier = ref.read(interestNotifierProvider.notifier);
    
    try {
      await interestNotifier.removeInterest(
        postId: _post!.id,
      );

      if (mounted) {
        AppSnackBar.showInfo(context, 'Interesse removido');
        // Recarregar lista
        _loadInterestedUsers();
      }
    } catch (e) {
      debugPrint('❌ Erro ao remover interesse: $e');
      
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao remover interesse.');
      }
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

  /// Abre conversa direta com o autor do post
  Future<void> _openConversation() async {
    if (_post == null || _authorUid.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      AppSnackBar.showError(context, 'Faça login para enviar mensagem');
      return;
    }

    final profileState = ref.read(profileProvider);
    final activeProfile = profileState.value?.activeProfile;
    if (activeProfile == null) {
      AppSnackBar.showError(context, 'Selecione um perfil primeiro');
      return;
    }

    // Impedir conversa consigo mesmo
    if (activeProfile.profileId == _post!.authorProfileId) {
      AppSnackBar.showInfo(context, 'Este é seu próprio post');
      return;
    }

    if (mounted) {
      setState(() => _isOpeningConversation = true);
    }

    try {
      // Busca/cria a conversa
      final conversation = await ref.read(mensagensNewRepositoryProvider).getOrCreateConversation(
        currentProfileId: activeProfile.profileId,
        currentUid: currentUser.uid,
        otherProfileId: _post!.authorProfileId,
        otherUid: _authorUid,
        currentProfileData: {
          'name': activeProfile.name,
          'photoUrl': activeProfile.photoUrl,
        },
        otherProfileData: {
          'name': _authorName,
          'photoUrl': _authorPhotoUrl,
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
              otherProfileId: _post!.authorProfileId,
              otherName: _authorName,
              otherPhotoUrl: _authorPhotoUrl,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro ao abrir conversa: $e');
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao abrir conversa. Tente novamente.');
      }
    } finally {
      if (mounted) {
        setState(() => _isOpeningConversation = false);
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
                    TextSpan(
                      text: _post!.type == 'sales' ? 'Salvaram: ' : 'Interessados: ',
                      style: const TextStyle(fontWeight: FontWeight.normal),
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
                        // Common fields
                        'city': _post!.city,
                        'neighborhood': _post!.neighborhood,
                        'state': _post!.state,
                        'photoUrls': _post!.photoUrls,
                        'photoUrl': _post!.photoUrl, // fallback
                        'youtubeLink': _post!.youtubeLink,
                        'location': GeoPoint(_post!.location.latitude,
                            _post!.location.longitude),
                        'createdAt': _post!.createdAt,
                        'expiresAt': _post!.expiresAt,
                        // Musician/Band fields
                        'instruments': _post!.instruments,
                        'genres': _post!.genres,
                        'seekingMusicians': _post!.seekingMusicians,
                        'level': _post!.level,
                        'availableFor': _post!.availableFor,
                        // Sales fields
                        'title': _post!.title,
                        'salesType': _post!.salesType,
                        'price': _post!.price,
                        'discountMode': _post!.discountMode,
                        'discountValue': _post!.discountValue,
                        'promoStartDate': _post!.promoStartDate,
                        'promoEndDate': _post!.promoEndDate,
                        'whatsappNumber': _post!.whatsappNumber,
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

  /// Mostra modal completo de opções de interesse
  void _showInterestOptions() {
    if (_post == null) return;
    
    final activeProfile = ref.read(profileProvider).value?.activeProfile;
    final isOwner = _post!.authorProfileId == activeProfile?.profileId;
    final isInterestSent = ref.read(interestNotifierProvider).contains(_post!.id);
    
    showInterestOptionsDialog(
      context: context,
      post: _post!,
      isInterestSent: isInterestSent,
      isOwner: isOwner,
      onSendInterest: _showInterest,
      onRemoveInterest: _removeInterest,
      onDeletePost: _confirmDeletePost,
      onViewProfile: () => context.pushProfile(_post!.authorProfileId),
      onPostEdited: () {
        // Recarregar dados do post após edição
        _loadPost();
      },
    );
  }
  
  /// Confirma deleção do post
  void _confirmDeletePost() {
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
              await _deletePost();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );
  }
  
  /// Deleta o post
  Future<void> _deletePost() async {
    if (_post == null) return;
    
    try {
      AppSnackBar.showInfo(context, 'Deletando post...');
      
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(_post!.id)
          .delete();
      
      if (mounted) {
        AppSnackBar.showSuccess(context, 'Post deletado com sucesso!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao deletar post');
      }
    }
  }

  /// Constrói o carrossel de fotos do post
  Widget _buildPhotoCarousel(double screenWidth, double photoHeight) {
    // Pega as fotos disponíveis (photoUrls ou fallback para photoUrl)
    final List<String> photos = _post!.photoUrls.isNotEmpty
        ? _post!.photoUrls
        : (_post!.photoUrl != null && _post!.photoUrl!.isNotEmpty)
            ? [_post!.photoUrl!]
            : [];

    // Se não há fotos, mostra placeholder
    if (photos.isEmpty) {
      return Container(
        width: screenWidth,
        height: photoHeight,
        color: Colors.grey[200],
        child: Center(
          child: Icon(
            _post!.type == 'band' ? Iconsax.people : Iconsax.user,
            size: 80,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    // Se só tem uma foto, não precisa de carrossel
    if (photos.length == 1) {
      return GestureDetector(
        onTap: () => _openPhotoViewer(photos, 0),
        child: Hero(
          tag: 'post-photo-${_post!.id}',
          child: Container(
            width: screenWidth,
            height: photoHeight,
            color: Colors.grey[200],
            child: CachedNetworkImage(
              cacheManager: WeGigImageCacheManager.instance,
              imageUrl: photos.first,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE47911)),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: Icon(
                  _post!.type == 'band' ? Iconsax.people : Iconsax.user,
                  size: 80,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Múltiplas fotos - carrossel com indicadores
    return SizedBox(
      width: screenWidth,
      height: photoHeight,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            itemCount: photos.length,
            onPageChanged: (index) => setState(() => _currentPhotoIndex = index),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _openPhotoViewer(photos, index),
                child: Hero(
                  tag: 'post-photo-${_post!.id}-$index',
                  child: CachedNetworkImage(
                    cacheManager: WeGigImageCacheManager.instance,
                    imageUrl: photos[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE47911)),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: Icon(
                        _post!.type == 'band' ? Iconsax.people : Iconsax.user,
                        size: 80,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Indicadores de página (dots)
          Positioned(
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  photos.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPhotoIndex == index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Contador de fotos
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentPhotoIndex + 1}/${photos.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
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
      onPopInvokedWithResult: (bool didPop, dynamic result) {
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
              children: [
                // Carrossel de fotos do post
                _buildPhotoCarousel(screenWidth, photoHeight),

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
                              // Botão de mensagem direta (aviãozinho de papel)
                              // Só aparece se não for o próprio post
                              if (!_isOwnPost())
                                _isOpeningConversation
                                    ? const SizedBox(
                                        width: 44,
                                        height: 44,
                                        child: Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                                            ),
                                          ),
                                        ),
                                      )
                                    : IconButton(
                                        onPressed: _openConversation,
                                        icon: const Icon(
                                          Iconsax.send_2, // Aviãozinho de papel
                                          color: AppColors.textSecondary,
                                          size: 24,
                                        ),
                                        tooltip: 'Enviar mensagem',
                                        style: IconButton.styleFrom(
                                          backgroundColor: AppColors.textSecondary.withValues(alpha: 0.1),
                                          shape: const CircleBorder(),
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

                        // ✅ Renderização condicional por tipo de post
                        if (_post!.type == 'sales')
                          _buildSalesContent()
                        else
                          _buildMusicianBandContent(),

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
                              : Builder(
                                  builder: (context) {
                                    final hasInterest = ref.watch(interestNotifierProvider).contains(_post!.id);
                                    return IconButton(
                                      icon: Icon(
                                        hasInterest
                                            ? (_post!.type == 'sales' ? Iconsax.tag5 : Iconsax.heart5)
                                            : (_post!.type == 'sales' ? Iconsax.tag : Iconsax.heart),
                                        color: hasInterest
                                            ? Colors.pink
                                            : Colors.white,
                                        size: 20,
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      constraints: const BoxConstraints(),
                                      onPressed: _showInterestOptions,
                                    );
                                  },
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
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.left,
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

  // ═══════════════════════════════════════════════════════════════════════════
  // ✅ CONTEÚDO PARA MÚSICO/BANDA (código original extraído)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Conteúdo para posts de músico ou banda
  Widget _buildMusicianBandContent() {
    return Column(
      children: [
        // Título dinâmico do tipo de post
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Align(
            alignment: Alignment.centerLeft,
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
                if (_post!.type == 'musician' && _post!.instruments.isNotEmpty)
                  _buildInfoRow(
                    Iconsax.musicnote,
                    'Instrumentos',
                    _post!.instruments.join(', '),
                  )
                else if (_post!.type == 'band' && _post!.seekingMusicians.isNotEmpty)
                  _buildInfoRow(
                    Iconsax.search_favorite,
                    'Procurando',
                    _post!.seekingMusicians.join(', '),
                  ),
                if ((_post!.type == 'musician' && _post!.instruments.isNotEmpty) ||
                    (_post!.type == 'band' && _post!.seekingMusicians.isNotEmpty))
                  const SizedBox(height: 12),
                // Gêneros musicais
                if (_post!.genres.isNotEmpty)
                  _buildInfoRow(
                    Iconsax.music_library_2,
                    'Gêneros',
                    _post!.genres.join(', '),
                  ),
                if (_post!.genres.isNotEmpty) const SizedBox(height: 12),
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
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ✅ CONTEÚDO PARA SALES (ANÚNCIOS DE ESPAÇOS)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Conteúdo principal para posts de sales (anúncios)
  Widget _buildSalesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Espaçamento adicional no topo
        const SizedBox(height: 16),

        // 1. Categoria (texto simples)
        _buildSalesCategoryText(),
        const SizedBox(height: 16),
        
        // 2. Badge de status da promoção
        _buildPromotionStatusBadge(),
        const SizedBox(height: 16),

        // 3. Título do anúncio
        _buildSalesTitle(),
        const SizedBox(height: 16),

        // 4. Bloco de preços Amazon-style
        _buildPriceBlock(),
        const SizedBox(height: 16),

        // 5. Descrição (reaproveita message card)
        _buildSalesDescriptionCard(),
        const SizedBox(height: 16),

        // 6. Localização + distância
        _buildSalesLocation(),
        const SizedBox(height: 16),

        // 7. Validade da promoção
        _buildPromoValidity(),
        const SizedBox(height: 24),

        // 8. Botões de ação rápida
        _buildSalesActionButtons(),
        const SizedBox(height: 24),
      ],
    );
  }

  /// Badge de status da promoção (ATIVA / EXPIRA EM X DIAS / EXPIRADA)
  Widget _buildPromotionStatusBadge() {
    final now = DateTime.now();
    final expiresAt = _post!.expiresAt;
    final daysRemaining = expiresAt.difference(now).inDays;

    final isUrgent = daysRemaining <= 3 && daysRemaining >= 0;
    final isExpired = daysRemaining < 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isExpired
              ? Colors.red.shade50
              : isUrgent
                  ? Colors.orange.shade50
                  : Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isExpired
                ? Colors.red.shade300
                : isUrgent
                    ? Colors.orange.shade300
                    : Colors.green.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Iconsax.clock,
              size: 16,
              color: isExpired
                  ? Colors.red
                  : isUrgent
                      ? Colors.orange
                      : Colors.green,
            ),
            const SizedBox(width: 6),
            Text(
              isExpired
                  ? 'PROMOÇÃO EXPIRADA'
                  : isUrgent
                      ? 'EXPIRA EM ${daysRemaining + 1} ${daysRemaining == 0 ? 'DIA' : 'DIAS'}'
                      : 'PROMOÇÃO ATIVA',
              style: TextStyle(
                color: isExpired
                    ? Colors.red
                    : isUrgent
                        ? Colors.orange
                        : Colors.green,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Título do anúncio
  Widget _buildSalesTitle() {
    // Usar campo 'title' da entidade ou primeira linha do content
    final title = _post!.title ?? 
        (_post!.content.isNotEmpty 
            ? _post!.content.split('\n').first 
            : 'Anúncio');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
      ),
    );
  }

  /// Bloco de preços Amazon-style com desconto
  Widget _buildPriceBlock() {
    final price = _post!.price;

    // Se não tem preço, não mostra o bloco
    if (price == null || price <= 0) {
      return const SizedBox.shrink();
    }

    // ✅ USAR PriceCalculator PARA CALCULOS CONSISTENTES
    final priceData = PriceCalculator.getPriceDisplayData(_post!);

    // ✅ FORMATADOR BRASILEIRO PARA PREÇOS
    final currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (priceData.hasDiscount) ...[
              Row(
                children: [
                  Text(
                    currencyFormatter.format(priceData.originalPrice),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (priceData.discountLabel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        priceData.discountLabel!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  priceData.hasDiscount ? 'Por' : 'Preço',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  currencyFormatter.format(priceData.finalPrice),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Card de descrição para sales
  Widget _buildSalesDescriptionCard() {
    if (_post!.content.isEmpty) return const SizedBox.shrink();

    // Se tem título, pegar conteúdo sem a primeira linha (que é o título)
    String description = _post!.content;
    if (_post!.title == null && _post!.content.contains('\n')) {
      final lines = _post!.content.split('\n');
      if (lines.length > 1) {
        description = lines.sublist(1).join('\n').trim();
      }
    }

    if (description.isEmpty) return const SizedBox.shrink();

    return Padding(
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
                  Iconsax.document_text,
                  size: 18,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8),
                Text(
                  'Descrição',
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
              text: description,
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
    );
  }

  /// Localização para sales
  Widget _buildSalesLocation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _buildInfoRow(
              Iconsax.location,
              'Localização',
              formatCleanLocation(
                neighborhood: _post!.neighborhood,
                city: _post!.city,
                state: _post!.state,
                fallback: 'Localização não disponível',
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Validade da promoção
  Widget _buildPromoValidity() {
    final startDate = _post!.promoStartDate ?? _post!.createdAt;
    final endDate = _post!.promoEndDate ?? _post!.expiresAt;

    final dateFormat = DateFormat('dd/MM/yyyy');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: _buildInfoRow(
          Iconsax.calendar,
          'Válida de',
          '${dateFormat.format(startDate)} até ${dateFormat.format(endDate)}',
        ),
      ),
    );
  }

  /// Botões de ação rápida para sales
  Widget _buildSalesActionButtons() {
    final whatsapp = _post!.whatsappNumber;
    final hasWhatsApp = whatsapp != null && whatsapp.isNotEmpty;

    if (!hasWhatsApp) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _launchWhatsApp(whatsapp),
          icon: const Icon(Iconsax.message, size: 20),
          label: const Text('WhatsApp'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  /// Categoria do anúncio (texto simples)
  Widget _buildSalesCategoryText() {
    final salesType = _post!.salesType;

    if (salesType == null || salesType.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(
            Iconsax.tag,
            size: 18,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            'Categoria: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            salesType,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// Abre o visualizador de fotos em tela cheia
  void _openPhotoViewer(List<String> photos, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullScreenPhotoViewer(
            photos: photos,
            initialIndex: initialIndex,
            postId: _post!.id,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  /// Abre WhatsApp com mensagem pré-definida
  Future<void> _launchWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final title = _post!.title ?? 'sem título';
    final message = Uri.encodeComponent(
      'Olá! Vi seu anúncio "$title" no WeGig e tenho interesse.',
    );
    final url = 'https://wa.me/55$cleanPhone?text=$message';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          AppSnackBar.showError(context, 'Não foi possível abrir o WhatsApp');
        }
      }
    } catch (e) {
      debugPrint('Erro ao abrir WhatsApp: $e');
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao abrir WhatsApp');
      }
    }
  }

}

/// Widget para visualização de fotos em tela cheia com zoom e swipe
class _FullScreenPhotoViewer extends StatefulWidget {
  const _FullScreenPhotoViewer({
    required this.photos,
    required this.initialIndex,
    required this.postId,
  });

  final List<String> photos;
  final int initialIndex;
  final String postId;

  @override
  State<_FullScreenPhotoViewer> createState() => _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends State<_FullScreenPhotoViewer> {
  late PageController _pageController;
  late int _currentIndex;
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Área de toque para fechar (fundo)
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(color: Colors.transparent),
            ),
            
            // PageView com fotos
            PageView.builder(
              controller: _pageController,
              itemCount: widget.photos.length,
              onPageChanged: (index) {
                _resetZoom();
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                final heroTag = widget.photos.length == 1
                    ? 'post-photo-${widget.postId}'
                    : 'post-photo-${widget.postId}-$index';
                    
                return Center(
                  child: Hero(
                    tag: heroTag,
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 1.0,
                      maxScale: 4.0,
                      child: CachedNetworkImage(
                        cacheManager: WeGigImageCacheManager.instance,
                        imageUrl: widget.photos[index],
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE47911)),
                          ),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Iconsax.image,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            
            // Botão fechar
            Positioned(
              top: 16,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            
            // Contador de fotos (se mais de uma)
            if (widget.photos.length > 1)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/${widget.photos.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            
            // Indicadores de página (dots)
            if (widget.photos.length > 1)
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.photos.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentIndex == index
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                      ),
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
