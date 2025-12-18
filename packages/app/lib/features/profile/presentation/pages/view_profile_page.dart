import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/core_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wegig_app/app/router/app_router.dart';
import 'package:wegig_app/features/mensagens_new/presentation/pages/chat_new_page.dart';
import 'package:wegig_app/features/mensagens_new/presentation/providers/mensagens_new_providers.dart';
import 'package:wegig_app/features/post/presentation/providers/interest_providers.dart';
import 'package:wegig_app/features/post/presentation/pages/post_page.dart';
import 'package:wegig_app/features/post/presentation/widgets/interest_options_dialog.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';
import 'package:wegig_app/features/profile/presentation/widgets/profile_switcher_bottom_sheet.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// Página principal de visualização/edição de perfis, tanto para o próprio
/// usuário quanto para outros músicos/bandas.
class ViewProfilePage extends ConsumerStatefulWidget {
  /// Cria uma nova tela de perfil opcionalmente fixando usuário/perfil.
  const ViewProfilePage({super.key, this.userId, this.profileId});

  /// UID do dono do perfil que deve ser exibido (opcional para perfis próprios).
  final String? userId;

  /// Identificador do perfil específico a ser carregado; quando ausente usa-se o
  /// perfil ativo do usuário.
  final String? profileId;

  @override
  ConsumerState<ViewProfilePage> createState() => _ViewProfilePageState();
}

class _ViewProfilePageState extends ConsumerState<ViewProfilePage>
    with TickerProviderStateMixin {
  ProfileEntity? _profile;
  List<String> _gallery = [];
  bool _loadingProfile = false;
  int _postsKey = 0; // Key para forçar rebuild do FutureBuilder de posts

  // IDs reais do perfil carregado (para compartilhamento)
  String? _loadedUserId;
  String? _loadedProfileId;

  YoutubePlayerController? _youtubeController;
  TabController? _tabController;

  // Estado de loading para o botão de mensagem (evita cliques múltiplos)
  bool _isOpeningConversation = false;
  
  // Cache de conversationId para acelerar abertura do chat
  String? _prefetchedConversationId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 4, vsync: this); // 4 tabs: Gallery, YouTube, Posts, Interests
    _loadProfileFromFirestore();
    
    // Prefetch conversation ID em background (não bloqueia UI)
    _prefetchConversationIfNeeded();
  }
  
  // Função para formatar telefone brasileiro
  String _formatBrazilianPhone(String phone) {
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    
    if (digitsOnly.length == 10) {
      // Formato: (XX) XXXX-XXXX
      return '(${digitsOnly.substring(0, 2)}) ${digitsOnly.substring(2, 6)}-${digitsOnly.substring(6)}';
    } else if (digitsOnly.length == 11) {
      // Formato: (XX) XXXXX-XXXX
      return '(${digitsOnly.substring(0, 2)}) ${digitsOnly.substring(2, 7)}-${digitsOnly.substring(7)}';
    }
    
    // Retorna o telefone original se não conseguir formatar
    return phone;
  }

  /// Retorna o título apropriado para o tipo de post
  String _getPostTitle(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'band':
        return 'Banda procura músico';
      case 'musician':
        return 'Músico procura banda';
      case 'sales':
        // Para posts de vendas, usa o título do anúncio ou fallback
        final title = data['title'] as String?;
        return title?.isNotEmpty == true ? title! : 'Anúncio';
      default:
        return 'Post';
    }
  }

  /// Carrega conversationId em background para acelerar botão de mensagem
  Future<void> _prefetchConversationIfNeeded() async {
    // Só faz prefetch para perfis de outros usuários
    if (widget.profileId == null && widget.userId == null) return;
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      final activeProfile = ref.read(activeProfileProvider);
      if (activeProfile == null) return;
      
      // Aguarda perfil carregar
      await Future.delayed(const Duration(milliseconds: 500));
      if (_profile == null) return;
      
      // Evita prefetch para si mesmo
      if (activeProfile.profileId == _profile!.profileId) return;
      
      // Query otimizada: busca APENAS conversationId (não cria)
      final query = await FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: currentUser.uid)
          .limit(10) // Limita para economizar bandwidth
          .get();
      
      // Filtra client-side (mais rápido que query complexa)
      for (final doc in query.docs) {
        final data = doc.data();
        final participantProfiles = (data['participantProfiles'] as List?)?.cast<String>() ?? [];
        
        if (participantProfiles.contains(activeProfile.profileId) &&
            participantProfiles.contains(_profile!.profileId)) {
          _prefetchedConversationId = doc.id;
          debugPrint('⚡ ViewProfile: Conversation prefetched: $_prefetchedConversationId');
          break;
        }
      }
    } catch (e) {
      debugPrint('⚠️ ViewProfile: Prefetch error (non-critical): $e');
    }
  }

  Future<void> _loadProfileFromFirestore() async {
    debugPrint('🔄 ViewProfilePage: _loadProfileFromFirestore() iniciado');
    if (!mounted) return;
    setState(() => _loadingProfile = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('⚠️ ViewProfilePage: Usuário não autenticado');
      if (mounted) setState(() => _loadingProfile = false);
      return;
    }

    try {
      ProfileEntity? profile;
      String? profileId;

      // Se profileId foi fornecido, usar ele diretamente (prioridade máxima)
      if (widget.profileId != null) {
        profileId = widget.profileId;
        debugPrint(
            '📌 ViewProfilePage: Carregando perfil específico: $profileId');
      } else if (widget.userId == null || widget.userId == user.uid) {
        // Meu perfil ativo - utiliza cache atual e só força refresh se necessário
        debugPrint(
            '👤 ViewProfilePage: Buscando perfil ativo do Riverpod sem forçar refresh');
        var profileState = ref.read(profileProvider);
        profile = profileState.value?.activeProfile;
        if (profile == null) {
          debugPrint(
              '⚠️ ViewProfilePage: activeProfile null, forçando refresh único');
          await ref.read(profileProvider.notifier).refresh();
          profileState = ref.read(profileProvider);
          profile = profileState.value?.activeProfile;
        }
        profileId = profile?.profileId;

        debugPrint(
            '✅ ViewProfilePage: Carregando MEU perfil ativo: $profileId');
      } else {
        // Visualizando perfil de outro usuário (buscar activeProfileId dele)
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get();
        final activeProfileId = userDoc.data()?['activeProfileId'] as String?;
        profileId = activeProfileId ?? widget.userId;
        debugPrint(
            'ViewProfilePage: Carregando perfil de outro usuário: $profileId');
      }

      if (profileId == null) {
        debugPrint('ViewProfilePage: profileId null, abortando');
        if (mounted) setState(() => _loadingProfile = false);
        return;
      }

      // Buscar perfil na coleção global profiles
      final doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(profileId)
          .get();

      if (!doc.exists) {
        debugPrint(
            'ViewProfilePage: Perfil $profileId não existe no Firestore');
        if (mounted) setState(() => _loadingProfile = false);
        return;
      }

      profile = ProfileEntity.fromFirestore(doc);
      debugPrint(
          'ViewProfilePage: Perfil carregado: ${profile.name} (${profile.isBand ? 'Banda' : 'Músico'})');

      // Buscar galeria do perfil (armazenada no documento do perfil)
      final gallery =
          (doc.data()?['gallery'] as List<dynamic>?)?.cast<String>() ??
              <String>[];
      _gallery = gallery.take(12).toList(); // Limitar a 12 fotos para performance

      // Preparar YouTube controller se link válido
      final videoId = _extractYoutubeVideoId(profile.youtubeLink);
      if (videoId != null && videoId.isNotEmpty) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
          ),
        );
      } else {
        _youtubeController = null;
      }

      if (!mounted) {
        debugPrint('⚠️ ViewProfilePage: Widget desmontado, abortando setState');
        return;
      }

      // Atualizar TabController baseado no tipo de perfil
      final newTabLength = profile.isSpace ? 3 : 4;
      if (_tabController?.length != newTabLength) {
        _tabController?.dispose();
        _tabController = TabController(length: newTabLength, vsync: this);
      }

      setState(() {
        _profile = profile;
        _loadingProfile = false;
        // Armazenar IDs reais do perfil carregado
        _loadedProfileId = profile!.profileId;
        _loadedUserId = profile.uid;
        // Força rebuild das tabs incrementando o key
        _postsKey++;
      });

      debugPrint(
          '✅ ViewProfilePage: Perfil carregado com sucesso - ${profile.name} (${profile.profileId})');
      debugPrint('   📊 Profile Type: ${profile.profileType.label} (isSpace=${profile.isSpace})');
      if (profile.isSpace) {
        debugPrint('   🏢 Space Type: ${profile.spaceType}');
        debugPrint('   📞 Phone: ${profile.phone}');
        debugPrint('   🕐 Operating Hours: ${profile.operatingHours}');
        debugPrint('   🌐 Website: ${profile.website}');
        debugPrint('   ✨ Amenities: ${profile.amenities}');
      }
    } catch (e) {
      debugPrint('❌ ViewProfilePage: Erro ao carregar perfil: $e');
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  @override
  void didUpdateWidget(ViewProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Detecta mudança nos parâmetros do widget
    if (oldWidget.userId != widget.userId ||
        oldWidget.profileId != widget.profileId) {
      debugPrint(
          '🔄 ViewProfilePage: didUpdateWidget detectou mudança nos parâmetros');
      if (mounted) {
        _loadProfileFromFirestore();
      }
    }
  }

  @override
  void dispose() {
    if (!mounted) return;
    _youtubeController?.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  /// Verifica se o perfil visualizado é o perfil ativo do usuário
  bool _isMyProfile() {
    final profileState = ref.read(profileProvider);
    final activeProfile = profileState.value?.activeProfile;
    if (activeProfile == null || _profile == null) return false;
    return _profile!.profileId == activeProfile.profileId;
  }

  /// Constrói botão de ação (Mensagem / Ligar / WhatsApp) estilo Instagram
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isPrimary,
    bool isLoading = false,
  }) {
    final isDisabled = onPressed == null || isLoading;
    
    return Expanded(
      child: SizedBox(
        height: 36,
        child: ElevatedButton.icon(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isPrimary
                ? (isDisabled ? AppColors.primary.withOpacity(0.7) : AppColors.primary)
                : (isDisabled ? Colors.grey[300] : Colors.grey[200]),
            foregroundColor: isPrimary ? Colors.white : Colors.black,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          icon: isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isPrimary ? Colors.white : Colors.black54,
                    ),
                  ),
                )
              : Icon(
                  icon,
                  size: 18,
                  color: isDisabled
                      ? (isPrimary ? Colors.white70 : Colors.black38)
                      : (isPrimary ? Colors.white : Colors.black),
                ),
          label: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDisabled
                  ? (isPrimary ? Colors.white70 : Colors.black38)
                  : (isPrimary ? Colors.white : Colors.black),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  /// Abre ou cria uma conversa com o perfil visualizado
  Future<void> _openOrCreateConversation() async {
    // Debouncing: evita cliques múltiplos
    if (_isOpeningConversation) {
      debugPrint('⚠️ ViewProfile: Operação já em andamento, ignorando clique');
      return;
    }
    
    if (_profile == null) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      AppSnackBar.showError(context, 'Você precisa estar autenticado');
      return;
    }

    // Obter perfil ativo do usuário atual
    final profileState = ref.read(profileProvider);
    final activeProfile = profileState.value?.activeProfile;
    if (activeProfile == null) {
      AppSnackBar.showError(context, 'Perfil ativo não encontrado');
      return;
    }

    // Ativar estado de loading
    if (mounted) {
      setState(() => _isOpeningConversation = true);
    }

    try {
      // Verificar se está tentando conversar com seu próprio perfil (mesmo profileId)
      if (activeProfile.profileId == _profile!.profileId) {
        throw Exception('Não é possível iniciar conversa consigo mesmo');
      }

      // Usar conversationId prefetched se disponível (economiza 1 query!)
      String conversationId;
      if (_prefetchedConversationId != null) {
        conversationId = _prefetchedConversationId!;
        debugPrint('⚡ ViewProfile: Usando conversation prefetched');
      } else {
        // Fallback: busca/cria conversa normalmente
        final conversation = await ref.read(mensagensNewRepositoryProvider).getOrCreateConversation(
          currentProfileId: activeProfile.profileId,
          currentUid: currentUser.uid,
          otherProfileId: _profile!.profileId,
          otherUid: _profile!.uid,
          currentProfileData: {
            'name': activeProfile.name,
            'photoUrl': activeProfile.photoUrl,
          },
          otherProfileData: {
            'name': _profile!.name,
            'photoUrl': _profile!.photoUrl,
          },
        );
        conversationId = conversation.id;
      }

      // Navegar para a tela de chat
      if (mounted) {
        // Desativar loading antes de navegar
        setState(() => _isOpeningConversation = false);
        
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => ChatNewPage(
              conversationId: conversationId,
              otherUid: widget.userId ?? _profile!.uid,
              otherProfileId: _profile!.profileId,
              otherName: _profile!.name,
              otherPhotoUrl: _profile!.photoUrl ?? '',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro ao abrir conversa: $e');
      if (mounted) {
        // Mensagem de erro mais amigável
        final errorMessage = e.toString().contains('consigo mesmo')
            ? 'Não é possível enviar mensagem para si mesmo'
            : 'Não foi possível abrir a conversa. Tente novamente.';
        AppSnackBar.showError(context, errorMessage);
      }
    } finally {
      // Garantir que loading é desativado em caso de erro
      if (mounted) {
        setState(() => _isOpeningConversation = false);
      }
    }
  }

  /// Exibe opções do perfil para visitantes (Compartilhar e Reportar)
  void _showProfileOptions() {
    if (_profile == null) return;

    showProfileOptionsDialog(
      context: context,
      profileId: _loadedProfileId ?? _profile!.profileId,
      userId: _loadedUserId ?? _profile!.uid,
      profileName: _profile!.name,
      isBand: _profile!.isBand,
      city: _profile!.city,
      neighborhood: _profile!.neighborhood,
      state: _profile!.state,
      instruments: _profile!.instruments ?? <String>[],
      genres: _profile!.genres ?? <String>[],
    );
  }

  void _openSettings() {
    // ✅ ALTERAÇÃO: Usa GoRouter para navegar para settings
    // Isso ativará a transição _slideLeftPage definida no router
    context.push('/settings');
  }

  String? _extractYoutubeVideoId(String? originalUrl) {
    if (originalUrl == null || originalUrl.isEmpty) return null;

    // Limpar espaços e garantir que é uma URL válida
    var url = originalUrl.trim();

    // Padrões mais abrangentes para YouTube
    final patterns = [
      RegExp(r'(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com\/embed\/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com\/v\/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com\/shorts\/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com\/live\/([a-zA-Z0-9_-]{11})'),
      RegExp(r'\?v=([a-zA-Z0-9_-]{11})'), // Qualquer URL com ?v=
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        final videoId = match.group(1);
        debugPrint('✅ YouTube videoId extraído: $videoId');
        return videoId;
      }
    }

    debugPrint('⚠️ Não foi possível extrair videoId da URL: $url');
    return null;
  }

  Future<void> _launchUrl(String url) async {
    try {
      // Adicionar protocolo se não tiver
      var finalUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://') && !url.startsWith('tel:') && !url.startsWith('whatsapp://')) {
        finalUrl = 'https://$url';
      }
      
      final uri = Uri.tryParse(finalUrl);
      if (uri != null) {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          if (mounted) {
            AppSnackBar.showError(context, 'Não foi possível abrir o link');
          }
        }
      } else {
        if (mounted) {
          AppSnackBar.showError(context, 'URL inválida');
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao abrir o link');
      }
    }
  }

  Widget _buildGalleryImage(String pathOrUrl) {
    // AspectRatio 1:1 para garantir células quadradas e evitar achatamento
    if (pathOrUrl.startsWith('http')) {
      return AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
          ),
          child: CachedNetworkImage(
            imageUrl: pathOrUrl,
            fit: BoxFit.cover, // Preenche o espaço mantendo proporção
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[300],
              child: const Icon(Iconsax.gallery_slash, size: 42, color: Colors.grey),
            ),
            memCacheWidth: 400,
            memCacheHeight: 400,
            maxWidthDiskCache: 800,
            maxHeightDiskCache: 800,
          ),
        ),
      );
    }

    final candidate = pathOrUrl.startsWith('file://')
        ? pathOrUrl.replaceFirst('file://', '')
        : pathOrUrl;

    final f = File(candidate);
    if (f.existsSync()) {
      return AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
          ),
          child: Image.file(
            f,
            fit: BoxFit.cover, // Preenche o espaço mantendo proporção
            cacheWidth: 400,
            cacheHeight: 400,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[300],
              child: const Icon(Iconsax.gallery_slash, size: 42),
            ),
          ),
        ),
      );
    }

    return Container(
      color: Colors.grey[300],
      child: const Icon(Icons.broken_image, size: 40),
    );
  }

  void _openPhotoViewer(int startIndex) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (context) {
        return _PhotoViewerPage(
          gallery: _gallery,
          startIndex: startIndex,
          isMyProfile: _isMyProfile(),
          onSetProfilePic: (url) async {
            try {
              final profileState = ref.read(profileProvider);
              final activeProfile = profileState.value?.activeProfile;
              if (activeProfile == null) return;

              await FirebaseFirestore.instance
                  .collection('profiles')
                  .doc(activeProfile.profileId)
                  .update({'photoUrl': url});

              // Recarregar perfil
              await _loadProfileFromFirestore();
              await ref.read(profileProvider.notifier).refresh();

              if (mounted) {
                Navigator.of(context).pop();
                AppSnackBar.showSuccess(context, 'Foto de perfil atualizada!');
              }
            } catch (e) {
              debugPrint('Erro ao definir foto de perfil: $e');
              if (mounted) {
                AppSnackBar.showError(context, 'Erro: $e');
              }
            }
          },
          onDownload: (url) async {
            try {
              final ref = FirebaseStorage.instance.refFromURL(url);
              final data = await ref.getData();
              if (data == null) throw Exception('Erro ao baixar imagem');

              final directory = await getApplicationDocumentsDirectory();
              final fileName =
                  'download_${DateTime.now().millisecondsSinceEpoch}.jpg';
              final file = File('${directory.path}/$fileName');
              await file.writeAsBytes(data);

              if (mounted) {
                Navigator.of(context).pop(); // Fecha o visualizador
                AppSnackBar.showSuccess(context, 'Foto baixada com sucesso!');
              }
            } catch (e) {
              debugPrint('Erro ao fazer download: $e');
              if (mounted) {
                AppSnackBar.showError(
                  context,
                  'Erro ao fazer download: $e',
                );
              }
            }
          },
          onEdit: (url) async {
            // Edição de foto da galeria - abrir image picker/cropper
            try {
              debugPrint('ViewProfile: Iniciando edição de foto da galeria...');
              final picked = await ImagePicker().pickImage(
                source: ImageSource.gallery,
                maxWidth: 2000,
                maxHeight: 2000,
                imageQuality: 95,
              );

              if (picked == null) {
                debugPrint('ViewProfile: Seleção cancelada');
                return;
              }

              debugPrint(
                  'ViewProfile: Nova imagem selecionada: ${picked.path}');

              final cropped = await ImageCropper().cropImage(
                sourcePath: picked.path,
                uiSettings: [
                  AndroidUiSettings(
                    toolbarTitle: 'Editar foto',
                    toolbarColor: AppColors.primary,
                    toolbarWidgetColor: Colors.white,
                    aspectRatioPresets: [
                      CropAspectRatioPreset.square,
                      CropAspectRatioPreset.ratio3x2,
                      CropAspectRatioPreset.ratio4x3,
                      CropAspectRatioPreset.ratio16x9,
                    ],
                  ),
                  IOSUiSettings(
                    title: 'Editar foto',
                    aspectRatioPresets: [
                      CropAspectRatioPreset.square,
                      CropAspectRatioPreset.ratio3x2,
                      CropAspectRatioPreset.ratio4x3,
                      CropAspectRatioPreset.ratio16x9,
                    ],
                  ),
                ],
              );

              String? editedPath = picked.path;
              if (cropped != null) {
                try {
                  editedPath = (cropped as dynamic).path as String?;
                  debugPrint('ViewProfile: Imagem cortada: $editedPath');
                } catch (e) {
                  debugPrint(
                      'ViewProfile: Erro ao extrair path do cropped: $e');
                }
              }

              if (editedPath == null) return;

              // Compressão direta (não em isolate)
              debugPrint('ViewProfile: Iniciando compressão...');
              final tempDir = Directory.systemTemp;
              final targetPath = p.join(
                tempDir.path,
                'gallery_edit_${DateTime.now().millisecondsSinceEpoch}_comp.jpg',
              );

              final compressed = await FlutterImageCompress.compressAndGetFile(
                editedPath,
                targetPath,
                quality: 85,
              );

              if (compressed == null) {
                debugPrint('ViewProfile: Compressão falhou');
                return;
              }

              final compressedPath = compressed.path;
              debugPrint('ViewProfile: Imagem comprimida: $compressedPath');

              final squareFile = await _createLetterboxedSquare(compressedPath);
              debugPrint('ViewProfile: Imagem com letterbox pronta: ${squareFile.path}');

              // Fazer upload da foto editada
              final profileState = ref.read(profileProvider);
              final activeProfile = profileState.value?.activeProfile;
              if (activeProfile == null) return;

              debugPrint(
                  'ViewProfile: Iniciando upload para Firebase Storage...');
              final storageRef = FirebaseStorage.instance
                  .ref()
                  .child('profiles')
                  .child(activeProfile.profileId)
                  .child('gallery')
                  .child('photo_${DateTime.now().millisecondsSinceEpoch}.jpg');

              await storageRef.putFile(squareFile);
              final newUrl = await storageRef.getDownloadURL();
              debugPrint('ViewProfile: Upload concluído: $newUrl');

              // Substituir a URL antiga pela nova na galeria
              final oldIndex = _gallery.indexOf(url);
              final newGallery = List<String>.from(_gallery);
              if (oldIndex != -1) {
                newGallery[oldIndex] = newUrl;
              }

              // Deletar foto antiga do Storage
              try {
                debugPrint('ViewProfile: Deletando foto antiga do Storage...');
                final oldStorageRef = FirebaseStorage.instance.refFromURL(url);
                await oldStorageRef.delete();
                debugPrint('ViewProfile: Foto antiga deletada');
              } catch (e) {
                debugPrint('ViewProfile: Erro ao deletar foto antiga: $e');
              }

              // Atualizar Firestore
              await FirebaseFirestore.instance
                  .collection('profiles')
                  .doc(activeProfile.profileId)
                  .update({'gallery': newGallery});

              setState(() {
                _gallery = newGallery;
              });

              if (mounted) {
                Navigator.of(context).pop();
                AppSnackBar.showSuccess(
                  context,
                  'Foto atualizada com sucesso!',
                );
              }
            } catch (e) {
              debugPrint('ViewProfile: ERRO ao editar foto: $e');
              if (mounted) {
                AppSnackBar.showError(
                  context,
                  'Erro ao editar foto: $e',
                );
              }
            }
          },
          onDelete: (url) async {
            try {
              final profileState = ref.read(profileProvider);
              final activeProfile = profileState.value?.activeProfile;
              if (activeProfile == null) return;

              // Remover da lista da galeria
              final newGallery =
                  _gallery.where((photo) => photo != url).toList();

              // Deletar do Storage
              try {
                final storageRef = FirebaseStorage.instance.refFromURL(url);
                await storageRef.delete();
              } catch (e) {
                debugPrint('Erro ao deletar do Storage: $e');
              }

              // Atualizar Firestore
              await FirebaseFirestore.instance
                  .collection('profiles')
                  .doc(activeProfile.profileId)
                  .update({'gallery': newGallery});

              setState(() {
                _gallery = newGallery;
              });

              if (mounted) {
                Navigator.of(context).pop();
                AppSnackBar.showSuccess(
                  context,
                  'Foto deletada com sucesso!',
                );
              }
            } catch (e) {
              debugPrint('Erro ao deletar foto: $e');
              if (mounted) {
                AppSnackBar.showError(
                  context,
                  'Erro ao deletar: $e',
                );
              }
            }
          },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwnProfile = _isMyProfile();
    final theme = Theme.of(context);

    // ✅ FIX: Listener para detectar mudanças no perfil ativo
    // Após trocar de perfil, recarrega ViewProfilePage ao invés de ir para Home
    // SEMPRE escuta, mas só age se for visualização do próprio perfil
    ref.listen<AsyncValue<ProfileState?>>(
      profileProvider,
      (previous, next) {
        // Verifica se estamos visualizando nosso próprio perfil
        final isViewingMyProfile = (widget.userId == null ||
                widget.userId == FirebaseAuth.instance.currentUser?.uid) &&
            widget.profileId == null;

        if (!isViewingMyProfile) return; // Ignora se for perfil de outra pessoa

        final previousProfileId = previous?.value?.activeProfile?.profileId;
        final currentProfileId = next.value?.activeProfile?.profileId;

        // Detecta mudança de perfil
        if (previousProfileId != null &&
            currentProfileId != null &&
            previousProfileId != currentProfileId) {
          debugPrint(
              '🔄 ViewProfilePage: Perfil ativo mudou de $previousProfileId para $currentProfileId');
          // ✅ Recarrega o perfil imediatamente na mesma página (não navega para Home)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _loadProfileFromFirestore();
            }
          });
        }
      },
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Iconsax.arrow_left_2, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        actions: isOwnProfile
            ? [
                IconButton(
                  icon: const Icon(Iconsax.arrow_swap_horizontal, color: Colors.black),
                  tooltip: 'Trocar perfil',
                  onPressed: () {
                    ProfileSwitcherBottomSheet.show(
                      context,
                      activeProfileId: ref
                          .read(profileProvider)
                          .value
                          ?.activeProfile
                          ?.profileId,
                      onProfileSelected: (newProfileId) async {
                        debugPrint(
                            '🔄 ViewProfile: Callback recebido - perfil trocado para $newProfileId');
                        // Aguarda um frame para garantir que o Riverpod atualizou
                        await Future<void>.delayed(
                          const Duration(milliseconds: 100),
                        );
                        // Força reload imediato após troca
                        if (mounted) {
                          debugPrint(
                              '🔄 ViewProfile: Iniciando reload do perfil...');
                          await _loadProfileFromFirestore();
                          debugPrint('✅ ViewProfile: Reload concluído!');
                        }
                      },
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Iconsax.setting_2, color: Colors.black),
                  tooltip: 'Configurações',
                  onPressed: _openSettings,
                ),
              ]
            : [
                // Botão de opções para visitantes (Compartilhar e Reportar)
                IconButton(
                  icon: const Icon(Iconsax.more, color: Colors.black),
                  tooltip: 'Opções',
                  onPressed: () => _showProfileOptions(),
                ),
              ],
      ),
      body: _loadingProfile
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE47911)),
              ),
            )
          : _profile == null
              ? const Center(child: Text('Perfil não encontrado'))
              : RefreshIndicator(
                  onRefresh: _loadProfileFromFirestore,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // Header: Avatar + Stats
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          child: Row(
                            children: [
                              // Avatar
                              Hero(
                                tag: 'profile-avatar-${_profile!.profileId}',
                                child: CircleAvatar(
                                  radius: 42,
                                  backgroundColor: Colors.grey[300],
                                  foregroundImage: _profile!.photoUrl != null &&
                                          _profile!.photoUrl!.startsWith('http')
                                      ? CachedNetworkImageProvider(
                                          _profile!.photoUrl!)
                                      : null,
                                  child: _profile!.photoUrl == null
                                      ? const Icon(Iconsax.user,
                                          size: 42, color: Colors.grey)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Nome e Bio ao lado da foto - ALINHADO À ESQUERDA
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start, // Alinhamento à esquerda
                                  children: [
                                    Text(
                                      _profile!.name,
                                      style: theme.textTheme.headlineSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 22,
                                                height: 1.2,
                                                color: Colors.black87,
                                              ) ??
                                          const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 22,
                                          ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if ((_profile!.username ?? '').isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          '@${_profile!.username}',
                                          style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    fontSize: 16,
                                                    color: Colors.grey[700],
                                                  ) ??
                                              TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey[700],
                                              ),
                                        ),
                                      ),
                                    if (_profile!.bio != null &&
                                        _profile!.bio!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          _profile!.bio!,
                                          style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    fontSize: 15,
                                                    height: 1.4,
                                                    color: Colors.grey[800],
                                                  ) ??
                                              const TextStyle(fontSize: 15),
                                          maxLines: 4,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Location and Social Links Section - ALINHADO À ESQUERDA
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, // Alinhamento à esquerda
                            children: [
                              // Space Type subtitle (only for Space profiles)
                              if (_profile!.isSpace && _profile!.spaceType != null) ...[
                                Text(
                                  SpaceType.fromString(_profile!.spaceType!).label,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                        fontSize: 15,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ) ??
                                      TextStyle(
                                        fontSize: 15,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 8),
                              ],

                              // Location info
                              Text(
                                formatCleanLocation(
                                  neighborhood: _profile!.neighborhood,
                                  city: _profile!.city,
                                  state: _profile!.state,
                                ),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 14.5,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ) ??
                                    TextStyle(
                                      fontSize: 14.5,
                                      color: Colors.grey[700],
                                    ),
                              ),

                              const SizedBox(height: 12),

                              // ===== CAMPOS ESPECÍFICOS DE ESPAÇO =====
                              if (_profile!.isSpace) ...[
                                // Horário de funcionamento
                                if (_profile!.operatingHours != null && _profile!.operatingHours!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Iconsax.clock, size: 18, color: AppColors.primary),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _profile!.operatingHours!,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Comodidades
                                if (_profile!.amenities != null && _profile!.amenities!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Iconsax.tick_circle, size: 18, color: Colors.grey[600]),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _profile!.amenities!.join(' • '),
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Site/Linktree (shortlink)
                                if (_profile!.website != null && _profile!.website!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: InkWell(
                                      onTap: () => _launchUrl(_profile!.website!),
                                      child: Row(
                                        children: [
                                          const Icon(Iconsax.link, size: 18, color: AppColors.primary),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              _profile!.website!
                                                  .replaceFirst(RegExp(r'^https?://'), '')
                                                  .replaceFirst(RegExp(r'^www\.'), '')
                                                  .split('/').first,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: AppColors.primary,
                                                decoration: TextDecoration.underline,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],

                              // Social Links Block (YouTube, TikTok, Instagram)
                              if (_hasSocialLinks()) _buildSocialLinksBlock(),

                              // Botões de ação alinhados: Mensagem, Ligar, WhatsApp
                              if (!isOwnProfile || (_profile!.isSpace && _profile!.phone != null && _profile!.phone!.isNotEmpty)) ...[
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    // Botão Mensagem (sempre visível para não-donos)
                                    if (!isOwnProfile)
                                      _buildActionButton(
                                        label: 'Mensagem',
                                        icon: Iconsax.message,
                                        onPressed: _openOrCreateConversation,
                                        isPrimary: true,
                                        isLoading: _isOpeningConversation,
                                      ),
                                    // Botões de telefone (apenas para spaces com telefone)
                                    if (_profile!.isSpace && _profile!.phone != null && _profile!.phone!.isNotEmpty) ...[
                                      if (!isOwnProfile) const SizedBox(width: 8),
                                      // Botão de ligar
                                      _buildActionButton(
                                        label: 'Ligar',
                                        icon: Iconsax.call,
                                        onPressed: () => _launchUrl('tel:${_profile!.phone}'),
                                        isPrimary: isOwnProfile,
                                      ),
                                      const SizedBox(width: 8),
                                      // Botão WhatsApp
                                      _buildActionButton(
                                        label: 'WhatsApp',
                                        icon: Icons.chat,
                                        onPressed: () {
                                          final phone = _profile!.phone!.replaceAll(RegExp(r'[^\d]'), '');
                                          final phoneWithCountry = phone.startsWith('55') ? phone : '55$phone';
                                          _launchUrl('https://wa.me/$phoneWithCountry');
                                        },
                                        isPrimary: false,
                                      ),
                                    ],
                                  ],
                                ),
                              ],

                              // Seção "Sobre o Músico/Banda"
                              if (_shouldShowProfileInfo())
                                _buildProfileInfoSection(),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Tabs
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                  color: Colors.grey[300]!, width: 0.5),
                            ),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            labelColor: Colors.black,
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: Colors.black,
                            indicatorWeight: 1,
                            tabs: _profile!.isSpace
                                ? const [
                                    Tab(icon: Icon(Iconsax.element_3, size: 26)), // Galeria
                                    Tab(icon: Icon(Iconsax.video_play, size: 26)), // YouTube
                                    Tab(icon: Icon(Iconsax.document_text, size: 26)), // Ofertas
                                  ]
                                : const [
                                    Tab(icon: Icon(Iconsax.element_3, size: 26)), // Galeria
                                    Tab(icon: Icon(Iconsax.video_play, size: 26)), // YouTube
                                    Tab(icon: Icon(Iconsax.document_text, size: 26)), // Posts
                                    Tab(icon: Icon(Iconsax.heart, size: 26)), // Interesses
                                  ],
                          ),
                        ),

                        // Tab Content (altura fixa para funcionar dentro do SingleChildScrollView)
                        SizedBox(
                          height: 600, // Altura fixa para o TabBarView
                          child: TabBarView(
                            controller: _tabController,
                            children: _profile!.isSpace
                                ? [
                                    _buildGalleryTab(),
                                    _buildYoutubeTab(),
                                    _buildPostsTab(), // Ofertas (reaproveita a mesma função)
                                  ]
                                : [
                                    _buildGalleryTab(),
                                    _buildYoutubeTab(),
                                    _buildPostsTab(),
                                    _buildInterestsTab(),
                                  ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  bool _hasSocialLinks() {
    return (_profile?.instagramLink != null &&
            _profile!.instagramLink!.isNotEmpty) ||
        (_profile?.tiktokLink != null && _profile!.tiktokLink!.isNotEmpty) ||
        (_profile?.youtubeLink != null && _profile!.youtubeLink!.isNotEmpty);
  }

  Widget _buildSocialLinksBlock() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_profile?.instagramLink != null &&
              _profile!.instagramLink!.isNotEmpty)
            _buildSocialIcon(
              icon: Iconsax.camera,
              label: 'Instagram',
              onTap: () => _launchUrl(_profile!.instagramLink!),
            ),
          if (_profile?.tiktokLink != null && _profile!.tiktokLink!.isNotEmpty)
            _buildSocialIcon(
              icon: Iconsax.musicnote,
              label: 'TikTok',
              onTap: () => _launchUrl(_profile!.tiktokLink!),
            ),
          if (_profile?.youtubeLink != null &&
              _profile!.youtubeLink!.isNotEmpty)
            _buildSocialIcon(
              icon: Iconsax.play_circle,
              label: 'YouTube',
              onTap: () => _launchUrl(_profile!.youtubeLink!),
            ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.black87),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowProfileInfo() {
    if (_profile == null) return false;

    // Mostrar se tiver nível (músico), instrumentos, gêneros ou membros da banda
    return (_profile!.level != null && _profile!.level!.isNotEmpty) ||
        (_profile!.instruments?.isNotEmpty ?? false) ||
        (_profile!.genres?.isNotEmpty ?? false) ||
        (_profile!.isBand && (_profile!.bandMembers?.isNotEmpty ?? false));
  }

  Widget _buildProfileInfoSection() {
    final theme = Theme.of(context);
    final sectionTitleStyle = theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: Colors.black87,
        ) ??
        const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: Colors.black87,
        );
    final labelStyle = theme.textTheme.bodyMedium?.copyWith(
          fontSize: 14.5,
          color: Colors.grey[700],
          fontWeight: FontWeight.w600,
        ) ??
        TextStyle(
          fontSize: 14.5,
          color: Colors.grey[700],
          fontWeight: FontWeight.w600,
        );
    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
          fontSize: 14.5,
          color: Colors.black87,
        ) ??
        const TextStyle(
          fontSize: 14.5,
          color: Colors.black87,
        );
    final chipPrimaryStyle = theme.textTheme.bodySmall?.copyWith(
          fontSize: 13,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ) ??
        const TextStyle(
          fontSize: 13,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        );
    final chipSecondaryStyle = theme.textTheme.bodySmall?.copyWith(
          fontSize: 13,
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ) ??
        const TextStyle(
          fontSize: 13,
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        );

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Alinhamento à esquerda
        children: [
          Text(
            _profile!.isSpace
                ? 'Sobre o Espaço'
                : (_profile!.isBand ? 'Sobre a Banda' : 'Sobre o Músico'),
            style: sectionTitleStyle,
          ),
          const SizedBox(height: 12),

          // Idade (músicos) ou Tempo de formação (bandas) - não para espaços
          if (!_profile!.isSpace && _profile!.ageOrFormationText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    _profile!.isBand ? Iconsax.calendar : Iconsax.cake,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _profile!.ageOrFormationText!,
                    style: valueStyle,
                  ),
                ],
              ),
            ),

          // Nível (apenas para músicos, não para espaços)
          if (!_profile!.isSpace &&
              !_profile!.isBand &&
              _profile!.level != null &&
              _profile!.level!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(Iconsax.chart, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Nível: ',
                    style: labelStyle,
                  ),
                  Text(
                    _profile!.level!,
                    style: valueStyle,
                  ),
                ],
              ),
            ),

          // Instrumentos (rótulo adaptável) - não para espaços
          if (!_profile!.isSpace && (_profile!.instruments?.isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Alinhamento à esquerda
                children: [
                  Row(
                    children: [
                      Icon(Iconsax.musicnote, size: 20, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        _profile!.isBand ? 'Instrumentação:' : 'Instrumentos:',
                        style: labelStyle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    alignment: WrapAlignment.start, // Alinhamento à esquerda
                    spacing: 6,
                    runSpacing: 6,
                    children: _profile!.instruments?.map((String instrument) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              instrument,
                              style: chipPrimaryStyle,
                            ),
                          );
                        }).toList() ??
                        <Widget>[],
                  ),
                ],
              ),
            ),

          // Gêneros - não para espaços
          if (!_profile!.isSpace && (_profile!.genres?.isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Alinhamento à esquerda
                children: [
                  Row(
                    children: [
                      Icon(Iconsax.music_library_2,
                          size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Gêneros:',
                        style: labelStyle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    alignment: WrapAlignment.start, // Alinhamento à esquerda
                    spacing: 6,
                    runSpacing: 6,
                    children: _profile!.genres?.map((String genre) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              genre,
                              style: chipSecondaryStyle,
                            ),
                          );
                        }).toList() ??
                        <Widget>[],
                  ),
                ],
              ),
            ),

          // ===== ESPAÇO: Campos Específicos =====
          if (_profile!.isSpace) ...[
            // Tipo de Espaço
            if (_profile!.spaceType != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(Iconsax.building, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Tipo: ',
                      style: labelStyle,
                    ),
                    Expanded(
                      child: Text(
                        SpaceType.fromString(_profile!.spaceType!).label,
                        style: valueStyle,
                      ),
                    ),
                  ],
                ),
              ),

            // Telefone (clicável)
            if (_profile!.phone != null && _profile!.phone!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _launchUrl('tel:${_profile!.phone}'),
                  child: Row(
                    children: [
                      Icon(Iconsax.call, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatBrazilianPhone(_profile!.phone!.trim()),
                          style: valueStyle.copyWith(
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Horário de Funcionamento
            if (_profile!.operatingHours != null &&
                _profile!.operatingHours!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Iconsax.clock, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Horário:', style: labelStyle),
                          const SizedBox(height: 4),
                          Text(
                            _profile!.operatingHours!.trim(),
                            style: valueStyle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Comodidades/Amenidades
            if (_profile!.amenities?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Iconsax.ticket_star,
                            size: 20, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Comodidades:',
                          style: labelStyle,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      alignment: WrapAlignment.start,
                      spacing: 6,
                      runSpacing: 6,
                      children: _profile!.amenities!.map((String amenity) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.purple.shade200,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            amenity,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.purple.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

            // Website (shortlink - última posição)
            if (_profile!.website != null && _profile!.website!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _launchUrl(_profile!.website!),
                  child: Row(
                    children: [
                      const Icon(Iconsax.link, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _profile!.website!.trim()
                              .replaceFirst(RegExp(r'^https?://'), '')
                              .replaceFirst(RegExp(r'^www\.'), '')
                              .split('/').first,
                          style: valueStyle.copyWith(
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildGalleryTab() {
    final isOwnProfile = _isMyProfile();

    // Se galeria vazia e não é o próprio perfil
    if (_gallery.isEmpty && !isOwnProfile) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhuma foto na galeria',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Se galeria vazia e é o próprio perfil, mostrar apenas botão de adicionar
    if (_gallery.isEmpty && isOwnProfile) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Adicione fotos à sua galeria',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickAndUploadGalleryPhoto,
              icon: const Icon(Iconsax.camera),
              label: const Text('Adicionar Foto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Galeria com fotos - adicionar apenas 1 botão + no final se for próprio perfil
    var totalItems = _gallery.length;
    if (isOwnProfile && _gallery.length < 12) {
      totalItems = _gallery.length + 1; // Apenas 1 botão + no final
    }

    return GridView.builder(
      padding: const EdgeInsets.all(1),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        // NãO usar childAspectRatio aqui - deixar AspectRatio dos children controlarem
      ),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        // Se é uma foto existente
        if (index < _gallery.length) {
          return GestureDetector(
            onTap: () => _openPhotoViewer(index),
            child: _buildGalleryImage(_gallery[index]),
          );
        }

        // Último item: botão + para adicionar foto (apenas para próprio perfil)
        if (isOwnProfile) {
          return _buildEmptyGallerySlot();
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyGallerySlot() {
    return GestureDetector(
      onTap: _pickAndUploadGalleryPhoto,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Icon(
            Iconsax.camera,
            size: 32,
            color: Colors.grey[400],
          ),
        ),
      ),
    );
  }

  Future<File> _createLetterboxedSquare(String sourcePath) async {
    final originalBytes = await File(sourcePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(originalBytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    final image = frame.image;

    final squareSize = math.max(image.width, image.height);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final backgroundPaint = Paint()..color = Colors.black;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, squareSize.toDouble(), squareSize.toDouble()),
      backgroundPaint,
    );

    final offset = Offset(
      (squareSize - image.width) / 2,
      (squareSize - image.height) / 2,
    );
    canvas.drawImage(image, offset, Paint());

    final picture = recorder.endRecording();
    final squareImage = await picture.toImage(squareSize, squareSize);
    final byteData =
        await squareImage.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      image.dispose();
      squareImage.dispose();
      throw Exception('Não foi possível gerar imagem quadrada');
    }

    final tempDir = Directory.systemTemp;
    final squarePath = p.join(
      tempDir.path,
      'gallery_square_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final Uint8List pngBytes = byteData.buffer.asUint8List();
    final jpgBytes = await FlutterImageCompress.compressWithList(
      pngBytes,
      quality: 90,
      format: CompressFormat.jpeg,
    );
    final squareFile = await File(squarePath).writeAsBytes(jpgBytes);

    image.dispose();
    squareImage.dispose();

    return squareFile;
  }

  Future<void> _pickAndUploadGalleryPhoto() async {
    try {
      debugPrint('ViewProfile: Iniciando seleção de foto para galeria...');
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 95,
      );

      if (pickedFile == null) {
        debugPrint('ViewProfile: Seleção cancelada');
        return;
      }

      debugPrint('ViewProfile: Imagem selecionada: ${pickedFile.path}');

      // Crop da imagem com opção square
      final cropped = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        compressQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
        compressFormat: ImageCompressFormat.jpg,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Editar Foto',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: AppColors.primary,
            initAspectRatio: CropAspectRatioPreset.square,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
              CropAspectRatioPreset.original,
            ],
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Editar Foto',
            minimumAspectRatio: 0.5,
            aspectRatioLockDimensionSwapEnabled: true,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
              CropAspectRatioPreset.original,
            ],
          ),
        ],
      );

      String? croppedPath = pickedFile.path;
      if (cropped != null) {
        try {
          croppedPath = (cropped as dynamic).path as String?;
          debugPrint('ViewProfile: Imagem cortada: $croppedPath');
        } catch (e) {
          debugPrint('ViewProfile: Erro ao extrair path do cropped: $e');
        }
      }

      if (croppedPath == null || !mounted) return;

      // Compressão direta (não em isolate)
      debugPrint('ViewProfile: Iniciando compressão...');
      final tempDir = Directory.systemTemp;
      final targetPath = p.join(
        tempDir.path,
        'gallery_${DateTime.now().millisecondsSinceEpoch}_comp.jpg',
      );

      final compressed = await FlutterImageCompress.compressAndGetFile(
        croppedPath,
        targetPath,
        quality: 85,
      );

      if (compressed == null) {
        debugPrint('ViewProfile: Compressão falhou');
        return;
      }

      final compressedPath = compressed.path;
      debugPrint('ViewProfile: Imagem comprimida: $compressedPath');

      final squareFile = await _createLetterboxedSquare(compressedPath);
      debugPrint('ViewProfile: Imagem com letterbox pronta: ${squareFile.path}');

      // Upload para o Firebase Storage
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final profileState = ref.read(profileProvider);
      final activeProfile = profileState.value?.activeProfile;
      if (activeProfile == null) return;

      debugPrint('ViewProfile: Iniciando upload para Firebase Storage...');
      final fileName = 'gallery_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profiles/${activeProfile.profileId}/gallery/$fileName');

      await storageRef.putFile(squareFile);
      final downloadUrl = await storageRef.getDownloadURL();
      debugPrint('ViewProfile: Upload concluído: $downloadUrl');

      // Atualizar lista de galeria no Firestore
      final newGallery = [..._gallery, downloadUrl];
      await FirebaseFirestore.instance
          .collection('profiles')
          .doc(activeProfile.profileId)
          .update({'gallery': newGallery});

      setState(() {
        _gallery = newGallery;
      });

      if (mounted) {
        AppSnackBar.showSuccess(
          context,
          'Foto adicionada com sucesso!',
        );
      }
    } catch (e) {
      debugPrint('ViewProfile: ERRO ao adicionar foto: $e');
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Erro ao adicionar foto: $e',
        );
      }
    }
  }

  Widget _buildYoutubeTab() {
    if (_youtubeController == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.video_play,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nenhum vídeo do YouTube',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            if (_profile?.youtubeLink != null &&
                _profile!.youtubeLink!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Link: ${_profile!.youtubeLink}',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _youtubeController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.primary,
        progressColors: const ProgressBarColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
        ),
        onReady: () {
          debugPrint('✅ YouTube player ready');
        },
        onEnded: (data) {
          debugPrint('YouTube video ended');
        },
      ),
      builder: (context, player) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: player,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostsTab() {
    if (_profile == null) {
      return const Center(child: Text('Perfil não encontrado'));
    }

    final profileState = ref.read(profileProvider);
    final activeProfile = profileState.value?.activeProfile;
    final isOwner =
        activeProfile != null && activeProfile.profileId == _profile!.profileId;

    // ✅ Buscar status de interesses do usuário ativo
    final interestsAsync = ref.watch(interestNotifierProvider);

    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      key: ValueKey(_postsKey), // Força rebuild quando _postsKey muda
      future: _fetchPosts(isOwner),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE47911)),
            ),
          );
        }

        if (snap.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Erro ao carregar posts',
                    style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.document_text, size: 68, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Nenhum post encontrado',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap:
              true, // ✅ Permite ListView dentro de SingleChildScrollView
          physics:
              const NeverScrollableScrollPhysics(), // ✅ Desabilita scroll próprio
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data();
            final postId = docs[i].id;
            // ✅ Verificar se o usuário ativo demonstrou interesse neste post
            final isInterestSent = interestsAsync.contains(postId);
            return _buildPostCard(postId, d, isOwner, isInterestSent: isInterestSent);
          },
        );
      },
    );
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _fetchPosts(bool isOwner) async {
    Query<Map<String, dynamic>> postsQuery =
        FirebaseFirestore.instance.collection('posts');

    if (isOwner) {
      // Owner vê todos os posts (incluindo expirados)
      postsQuery = postsQuery
          .where('authorProfileId', isEqualTo: _profile!.profileId)
          .orderBy('createdAt', descending: true);
    } else {
      // Visitantes vêem apenas posts não expirados, ordenados por createdAt
      // ✅ Usa índice composto: authorProfileId + expiresAt + __name__
      final now = DateTime.now();
      postsQuery = postsQuery
          .where('authorProfileId', isEqualTo: _profile!.profileId)
          .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('expiresAt') // Requerido para o índice
          .orderBy('createdAt', descending: true); // Ordem desejada
    }

    return postsQuery.get();
  }

  Widget _buildInterestsTab() {
    if (_profile == null) {
      return const Center(child: Text('Perfil não encontrado'));
    }

    final profileState = ref.read(profileProvider);
    final activeProfile = profileState.value?.activeProfile;
    final isOwner =
        activeProfile != null && activeProfile.profileId == _profile!.profileId;

    // ✅ NOVO: Buscar status de interesses do usuário ativo
    final interestsAsync = ref.watch(interestNotifierProvider);

    // Apenas mostra se for o próprio perfil
    if (!isOwner) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.lock, size: 68, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Conteúdo privado',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: _fetchInterests(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE47911)),
            ),
          );
        }

        if (snap.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Erro ao carregar interesses',
                    style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Nenhum interesse enviado',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap:
              true, // ✅ Permite ListView dentro de SingleChildScrollView
          physics:
              const NeverScrollableScrollPhysics(), // ✅ Desabilita scroll próprio
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final interest = docs[i].data();
            final postId = interest['postId'] as String?;
            if (postId == null) return const SizedBox.shrink();

            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(postId)
                  .get(),
              builder: (context, postSnap) {
                if (!postSnap.hasData || !postSnap.data!.exists) {
                  debugPrint(
                      'ViewProfile: Post $postId não encontrado ou deletado');
                  return const SizedBox.shrink();
                }
                final postData = postSnap.data!.data()!;
                debugPrint(
                    'ViewProfile: Mostrando post $postId - type: ${postData['type']}');

                // ✅ NOVO: Verificar se o usuário ativo demonstrou interesse neste post
                final isInterestSent = interestsAsync.contains(postId);

                return _buildPostCard(postId, postData, false,
                    isInterestCard: true, isInterestSent: isInterestSent);
              },
            );
          },
        );
      },
    );
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _fetchInterests() async {
    try {
      final profileState = ref.read(profileProvider);
      final activeProfile = profileState.value?.activeProfile;
      if (activeProfile == null) {
        debugPrint(
            'ViewProfile: Perfil ativo não encontrado para buscar interesses');
        throw Exception('Perfil ativo não encontrado');
      }

      debugPrint(
          'ViewProfile: Buscando interesses para profileId: ${activeProfile.profileId}');

      final query = await FirebaseFirestore.instance
          .collection('interests')
          .where('interestedProfileId', isEqualTo: activeProfile.profileId)
          .where('profileUid', isEqualTo: activeProfile.uid)
          .limit(50)
          .get();

      debugPrint('ViewProfile: Encontrados ${query.docs.length} interesses');

      // Ordenar manualmente por createdAt
      final docs = query.docs.toList();
      docs.sort((a, b) {
        final aTime =
            (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
        final bTime =
            (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });

      return query;
    } catch (e) {
      debugPrint('ViewProfile: Erro ao buscar interesses: $e');
      rethrow;
    }
  }

  Future<void> _sendInterestOptimistically(
      String postId, String authorProfileId, String postType) async {
    if (!mounted) return;

    try {
      final activeProfile = ref.read(profileProvider).value?.activeProfile;
      if (activeProfile == null) return;

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // ✅ Buscar dados do autor do post para preencher postAuthorUid
      final postDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .get();

      if (!postDoc.exists) {
        throw Exception('Post não encontrado');
      }

      final postAuthorUid = postDoc.data()?['authorUid'] as String?;
      if (postAuthorUid == null) {
        throw Exception('Post sem authorUid');
      }

      // ✅ Usar provider global para optimistic update e persistência
      await ref.read(interestNotifierProvider.notifier).addInterest(
        postId: postId,
        postAuthorUid: postAuthorUid,
        postAuthorProfileId: authorProfileId,
      );

      if (mounted) {
        AppSnackBar.showSuccess(
          context,
          'Interesse enviado!',
        );
      }
    } catch (e) {
      debugPrint('Erro no envio otimista de interesse: $e');
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Erro ao enviar interesse: $e',
        );
      }
    }
  }

  Future<void> _removeInterestOptimistically(
      String postId, String authorProfileId) async {
    if (!mounted) return;

    try {
      final activeProfile = ref.read(profileProvider).value?.activeProfile;
      if (activeProfile == null) return;

      // ✅ Usar provider global para optimistic update e remoção
      await ref.read(interestNotifierProvider.notifier).removeInterest(
        postId: postId,
      );

      if (mounted) {
        AppSnackBar.showInfo(
          context,
          'Interesse removido',
        );
      }
    } catch (e) {
      debugPrint('Erro ao remover interesse: $e');
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Erro ao remover interesse: $e',
        );
      }
    }
  }

  void _showInterestOptionsDialog(String postId, Map<String, dynamic> data,
      bool isInterestSent, bool isOwner) {
    final type = (data['type'] as String?) ?? '';
    final authorProfileId = (data['authorProfileId'] as String?) ?? '';
    final authorUid = (data['authorUid'] as String?) ?? '';
    
    // Converter GeoPoint para formato válido
    final locationData = data['location'];
    final GeoPoint location;
    if (locationData is GeoPoint) {
      location = locationData;
    } else if (locationData is Map) {
      location = GeoPoint(
        (locationData['latitude'] as num?)?.toDouble() ?? 0.0,
        (locationData['longitude'] as num?)?.toDouble() ?? 0.0,
      );
    } else {
      location = const GeoPoint(0, 0);
    }
    
    // Criar PostEntity manualmente para evitar problemas de serialização
    final post = PostEntity(
      id: postId,
      authorProfileId: authorProfileId,
      authorUid: authorUid,
      content: (data['content'] ?? data['message']) as String? ?? '',
      location: location,
      city: (data['city'] as String?) ?? '',
      neighborhood: data['neighborhood'] as String?,
      state: data['state'] as String?,
      photoUrl: data['photoUrl'] as String?,
      photoUrls: (data['photoUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      youtubeLink: data['youtubeLink'] as String?,
      type: type,
      level: (data['level'] as String?) ?? '',
      instruments: (data['instruments'] as List<dynamic>?)?.cast<String>() ?? [],
      genres: (data['genres'] as List<dynamic>?)?.cast<String>() ?? [],
      seekingMusicians: (data['seekingMusicians'] as List<dynamic>?)?.cast<String>() ?? [],
      availableFor: (data['availableFor'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 30)),
      authorName: data['authorName'] as String?,
      authorPhotoUrl: data['authorPhotoUrl'] as String?,
      activeProfileName: data['activeProfileName'] as String?,
      activeProfilePhotoUrl: data['activeProfilePhotoUrl'] as String?,
      // Sales fields
      title: data['title'] as String?,
      salesType: data['salesType'] as String?,
      price: (data['price'] as num?)?.toDouble(),
      discountMode: data['discountMode'] as String?,
      discountValue: (data['discountValue'] as num?)?.toDouble(),
      promoStartDate: (data['promoStartDate'] as Timestamp?)?.toDate(),
      promoEndDate: (data['promoEndDate'] as Timestamp?)?.toDate(),
      whatsappNumber: data['whatsappNumber'] as String?,
    );

    showInterestOptionsDialog(
      context: context,
      post: post,
      isInterestSent: isInterestSent,
      isOwner: isOwner,
      onSendInterest: () => _sendInterestOptimistically(postId, authorProfileId, type),
      onRemoveInterest: () => _removeInterestOptimistically(postId, authorProfileId),
      onDeletePost: () => _confirmDeletePost(post),
      onViewProfile: () => context.pushProfile(authorProfileId),
      onPostEdited: () {
        if (mounted) {
          setState(() {
            _postsKey++; // Força rebuild do FutureBuilder
          });
        }
      },
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
        AppSnackBar.showSuccess(context, 'Post deletado com sucesso');
        setState(() {
          _postsKey++; // Força rebuild do FutureBuilder
        });
      }
    } catch (e) {
      debugPrint('Erro ao deletar post: $e');
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao deletar post: $e');
      }
    }
  }

  Widget _buildPostCard(String postId, Map<String, dynamic> data, bool isOwner,
      {bool isInterestCard = false, bool isInterestSent = false}) {
    // ✅ Priorizar photoUrls (carrossel) com fallback para photoUrl legado
    final photoUrls = (data['photoUrls'] as List<dynamic>?)?.cast<String>() ?? [];
    final photo = photoUrls.isNotEmpty 
        ? photoUrls.first 
        : (data['photoUrl'] as String? ?? '');
    
    final type = (data['type'] as String?) ?? '';
    final city = (data['city'] as String?) ?? '';
    final state = (data['state'] as String?) ?? '';
    // Se é um card de interesse, já foi enviado. Senão, verifica no Set ou parâmetro
    final primaryColor = type == 'band' ? AppColors.accent : AppColors.primary;

    // Time counter (apenas para posts do owner)
    String? timeAgo;
    String? daysLeft;
    if (isOwner) {
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();

      if (createdAt != null) {
        final diff = DateTime.now().difference(createdAt);
        if (diff.inDays > 0) {
          timeAgo = '${diff.inDays}d';
        } else if (diff.inHours > 0) {
          timeAgo = '${diff.inHours}h';
        } else if (diff.inMinutes > 0) {
          timeAgo = '${diff.inMinutes}m';
        } else {
          timeAgo = 'agora';
        }
      }

      if (expiresAt != null) {
        final daysUntilExpiry = expiresAt.difference(DateTime.now()).inDays;
        if (daysUntilExpiry >= 0) {
          daysLeft = '$daysUntilExpiry dias';
        } else {
          daysLeft = 'Expirado';
        }
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
        side: BorderSide(color: Colors.grey[200]!, width: 0.5),
      ),
      child: InkWell(
        onTap: () {
          context.pushPostDetail(postId);
        },
        child: Stack(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              leading: photo.isNotEmpty
                  ? Hero(
                      tag: 'post-photo-$postId',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: (() {
                          try {
                            if (photo.startsWith('http')) {
                              return CachedNetworkImage(
                                imageUrl: photo,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 56,
                                  height: 56,
                                  color: Colors.grey[200],
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Iconsax.musicnote,
                                      color: Colors.grey, size: 24),
                                ),
                                memCacheWidth: 112,
                                memCacheHeight: 112,
                                maxWidthDiskCache: 112,
                                maxHeightDiskCache: 112,
                              );
                            }
                          } catch (e) {
                            debugPrint('thumbnail image error: $e');
                          }
                          return Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Iconsax.musicnote,
                                color: Colors.grey, size: 24),
                          );
                        })(),
                      ),
                    )
                  : Hero(
                      tag: 'post-photo-$postId',
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Iconsax.musicnote, color: Colors.grey, size: 24),
                      ),
                    ),
              title: isOwner && timeAgo != null
                  ? Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getPostTitle(type, data),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          ' • $timeAgo',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      _getPostTitle(type, data),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    () {
                      final locationText = formatCleanLocation(
                        neighborhood: data['neighborhood'] as String?,
                        city: city,
                        state: state.isEmpty ? null : state,
                        fallback: '',
                      );

                      return locationText.isNotEmpty
                          ? Text(
                              locationText,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[700]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.left,
                            )
                          : const SizedBox.shrink();
                    }(),
                    if (isOwner && daysLeft != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Expira em: $daysLeft',
                          style: TextStyle(
                            fontSize: 11,
                            color: daysLeft == 'Expirado'
                                ? Colors.red
                                : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Botão de interesse (alinhado com topo da foto) ou menu (canto inferior direito)
            if (isOwner)
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _showInterestOptionsDialog(
                      postId, data, isInterestSent, isOwner),
                  child: Icon(
                    Iconsax.more,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ),
              )
            else
              Positioned(
                top: 16, // Alinhado com contentPadding top do ListTile
                right: 8,
                child: GestureDetector(
                  onTap: () => _showInterestOptionsDialog(
                      postId, data, isInterestSent, isOwner),
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
                          ? (type == 'sales' ? Iconsax.tag5 : Iconsax.heart5)
                          : (type == 'sales' ? Iconsax.tag : Iconsax.heart),
                      size: 16,
                      color: isInterestSent ? Colors.pink : primaryColor,
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

/// Photo Viewer Page with management menu
class _PhotoViewerPage extends StatefulWidget {
  const _PhotoViewerPage({
    required this.gallery,
    required this.startIndex,
    required this.isMyProfile,
    required this.onSetProfilePic,
    required this.onDownload,
    required this.onEdit,
    required this.onDelete,
  });
  final List<String> gallery;
  final int startIndex;
  final bool isMyProfile;
  final Future<void> Function(String url) onSetProfilePic;
  final Future<void> Function(String url) onDownload;
  final Future<void> Function(String url) onEdit;
  final Future<void> Function(String url) onDelete;

  @override
  State<_PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<_PhotoViewerPage> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildImage(String pathOrUrl) {
    try {
      if (pathOrUrl.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: pathOrUrl,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          placeholder: (context, url) => const ColoredBox(
            color: Colors.black,
            child:
                Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
          errorWidget: (context, url, error) =>
              const Icon(Iconsax.gallery_slash, size: 100, color: Colors.white),
          memCacheWidth: 1200,
          memCacheHeight: 1200,
        );
      }

      final candidate = pathOrUrl.startsWith('file://')
          ? pathOrUrl.replaceFirst('file://', '')
          : pathOrUrl;

      final f = File(candidate);
      if (f.existsSync()) {
        return Image.file(
          f,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          cacheWidth: 1200,
        );
      }

      return const Icon(Iconsax.gallery_slash, size: 100, color: Colors.white);
    } catch (e) {
      return const Icon(Iconsax.gallery_slash, size: 100, color: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Iconsax.close_circle, color: Colors.white, size: 26),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: widget.isMyProfile
            ? [
                PopupMenuButton<String>(
                  icon: const Icon(Iconsax.more, color: Colors.white, size: 26),
                  color: Colors.white,
                  onSelected: (value) async {
                    final url = widget.gallery[_currentIndex];
                    Navigator.of(context)
                        .pop(); // Fechar viewer antes de executar ação

                    if (value == 'set_profile') {
                      await widget.onSetProfilePic(url);
                    } else if (value == 'download') {
                      await widget.onDownload(url);
                    } else if (value == 'edit') {
                      await widget.onEdit(url);
                    } else if (value == 'delete') {
                      await widget.onDelete(url);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'set_profile',
                      child: Row(
                        children: [
                          Icon(Iconsax.profile_circle, size: 22),
                          SizedBox(width: 12),
                          Text('Tornar foto de perfil'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'download',
                      child: Row(
                        children: [
                          Icon(Iconsax.document_download, size: 22),
                          SizedBox(width: 12),
                          Text('Fazer download'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Iconsax.edit, size: 22),
                          SizedBox(width: 12),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Iconsax.trash, size: 22, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Deletar', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ]
            : null,
      ),
      body: Center(
        child: PageView.builder(
          itemCount: widget.gallery.length,
          controller: _pageController,
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
          },
          itemBuilder: (context, index) {
            return _buildImage(widget.gallery[index]);
          },
        ),
      ),
    );
  }
}
