import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

/// Widget para visualização de fotos em tela cheia com zoom, swipe e download
/// Estilo similar ao Instagram
class FullScreenPhotoViewer extends StatefulWidget {
  const FullScreenPhotoViewer({
    required this.photos,
    this.initialIndex = 0,
    this.heroTagPrefix,
    this.showDownloadButton = true,
    this.showShareButton = true,
    super.key,
  });

  /// Lista de URLs das fotos
  final List<String> photos;

  /// Índice inicial da foto a ser exibida
  final int initialIndex;

  /// Prefixo para Hero tag (opcional, para animação de transição)
  final String? heroTagPrefix;

  /// Se deve mostrar botão de download
  final bool showDownloadButton;

  /// Se deve mostrar botão de compartilhar
  final bool showShareButton;

  /// Abre o visualizador de fotos em tela cheia
  static void open(
    BuildContext context, {
    required List<String> photos,
    int initialIndex = 0,
    String? heroTagPrefix,
    bool showDownloadButton = true,
    bool showShareButton = true,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FullScreenPhotoViewer(
            photos: photos,
            initialIndex: initialIndex,
            heroTagPrefix: heroTagPrefix,
            showDownloadButton: showDownloadButton,
            showShareButton: showShareButton,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<FullScreenPhotoViewer> createState() => _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends State<FullScreenPhotoViewer> {
  late PageController _pageController;
  late int _currentIndex;
  final TransformationController _transformationController =
      TransformationController();
  bool _isDownloading = false;

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

  Future<void> _downloadImage() async {
    if (_isDownloading) return;

    setState(() => _isDownloading = true);

    try {
      final imageUrl = widget.photos[_currentIndex];

      // Solicitar permissão no Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          final photosStatus = await Permission.photos.request();
          if (!photosStatus.isGranted) {
            if (mounted) {
              _showSnackBar('Permissão negada para salvar imagem', isError: true);
            }
            return;
          }
        }
      }

      // Baixar imagem
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Erro ao baixar imagem');
      }

      // Salvar na galeria
      final result = await ImageGallerySaverPlus.saveImage(
        Uint8List.fromList(response.bodyBytes),
        quality: 100,
        name: 'WeGig_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        if (result['isSuccess'] == true) {
          _showSnackBar('Imagem salva na galeria!');
        } else {
          _showSnackBar('Erro ao salvar imagem', isError: true);
        }
      }
    } catch (e) {
      debugPrint('Erro ao baixar imagem: $e');
      if (mounted) {
        _showSnackBar('Erro ao salvar imagem', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Future<void> _shareImage() async {
    try {
      final imageUrl = widget.photos[_currentIndex];

      // Baixar imagem para arquivo temporário
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Erro ao baixar imagem');
      }

      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/share_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(response.bodyBytes);

      // Compartilhar
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Compartilhado via WeGig'),
      );
    } catch (e) {
      debugPrint('Erro ao compartilhar imagem: $e');
      if (mounted) {
        _showSnackBar('Erro ao compartilhar imagem', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
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
                final photoUrl = widget.photos[index];
                
                // Verificar URL válida
                if (photoUrl.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.image, size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'Imagem não disponível',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  );
                }
                
                Widget imageWidget = InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: photoUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFFE47911)),
                      ),
                    ),
                    errorWidget: (context, url, error) {
                      debugPrint('❌ FullScreenPhotoViewer error: $error for URL: $url');
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Iconsax.image, size: 80, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'Erro ao carregar imagem',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              CachedNetworkImage.evictFromCache(url);
                              setState(() {}); // Trigger rebuild
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE47911),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Tentar novamente',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );

                // Adicionar Hero se heroTagPrefix foi fornecido
                if (widget.heroTagPrefix != null) {
                  final heroTag = widget.photos.length == 1
                      ? widget.heroTagPrefix!
                      : '${widget.heroTagPrefix}-$index';
                  imageWidget = Hero(
                    tag: heroTag,
                    child: imageWidget,
                  );
                }

                return Center(child: imageWidget);
              },
            ),

            // Botão fechar (topo esquerdo)
            Positioned(
              top: 16,
              left: 16,
              child: _buildIconButton(
                icon: Icons.close,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),

            // Contador de fotos (se mais de uma)
            if (widget.photos.length > 1)
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              ),

            // Botões de ação (topo direito)
            Positioned(
              top: 16,
              right: 16,
              child: Row(
                children: [
                  if (widget.showShareButton) ...[
                    _buildIconButton(
                      icon: Iconsax.share,
                      onTap: _shareImage,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (widget.showDownloadButton)
                    _buildIconButton(
                      icon: _isDownloading ? null : Iconsax.arrow_down_2,
                      isLoading: _isDownloading,
                      onTap: _downloadImage,
                    ),
                ],
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

  Widget _buildIconButton({
    IconData? icon,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
      ),
    );
  }
}
