import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/utils/app_snackbar.dart';
import 'package:core_ui/widgets/app_loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax/iconsax.dart';

/// Widget para upload e exibição de fotos
/// 
/// Encapsula lógica de:
/// - Seleção de imagem (galeria/câmera)
/// - Compressão automática (85% quality, 800x800 min)
/// - Preview local e remote (CachedNetworkImage)
/// - Remoção de foto
/// 
/// ⚡ PERFORMANCE: Compressão automática reduz tamanho em ~80%
/// - Original: 2-5MB → Comprimido: 200-500KB
/// - Evita timeout em uploads lentos
/// 
/// 🎨 UX: Preview instantâneo com estados loading/error
class PhotoUploadWidget extends StatefulWidget {
  /// Cria um widget para upload de fotos
  const PhotoUploadWidget({
    required this.onPhotoSelected,
    this.currentPhotoPath,
    this.enabled = true,
    this.height = 180,
    this.showChangeHint = true,
    this.emptyText = 'Toque para adicionar foto',
    this.emptyIcon = Iconsax.camera,
    super.key,
  });

  /// Callback quando uma foto é selecionada e comprimida
  /// 
  /// Recebe o path local do arquivo comprimido.
  /// Path pode ser:
  /// - Local file path (após seleção nova)
  /// - HTTP URL (foto existente no servidor)
  final ValueChanged<String?> onPhotoSelected;

  /// Path atual da foto (local ou URL)
  /// 
  /// - Se começa com "http": carrega com CachedNetworkImage
  /// - Se não: carrega com Image.file
  final String? currentPhotoPath;

  /// Se o widget está habilitado para edição
  final bool enabled;

  /// Altura do container de foto
  final double height;

  /// Se deve mostrar hint "Alterar foto" quando há foto
  final bool showChangeHint;

  /// Texto a ser exibido quando não há foto
  final String emptyText;

  /// Ícone a ser exibido quando não há foto
  final IconData emptyIcon;

  @override
  State<PhotoUploadWidget> createState() => _PhotoUploadWidgetState();
}

class _PhotoUploadWidgetState extends State<PhotoUploadWidget> {
  bool _isProcessing = false;

  /// Mostra bottom sheet para escolher fonte da imagem
  Future<void> _showImageSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Iconsax.gallery, color: AppColors.primary),
              title: const Text('Galeria'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.camera, color: AppColors.primary),
              title: const Text('Câmera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (widget.currentPhotoPath != null)
              ListTile(
                leading: const Icon(Iconsax.trash, color: Colors.red),
                title: const Text('Remover foto', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  widget.onPhotoSelected(null);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Seleciona e comprime imagem
  /// 
  /// Compressão automática:
  /// - Quality: 85% (balanço qualidade/tamanho)
  /// - Min dimensions: 800x800 (evita imagens muito pequenas)
  /// - Target: ~200-500KB (vs 2-5MB original)
  Future<void> _pickImage(ImageSource source) async {
    if (!widget.enabled || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source);
      
      if (picked == null) {
        setState(() => _isProcessing = false);
        return;
      }

      debugPrint('📷 PhotoUploadWidget: Imagem selecionada: ${picked.path}');

      // Comprimir imagem antes de retornar
      final tempDir = Directory.systemTemp;
      final targetPath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';

      debugPrint('📷 PhotoUploadWidget: Comprimindo imagem...');
      final compressed = await FlutterImageCompress.compressAndGetFile(
        picked.path,
        targetPath,
        quality: 85,
        minWidth: 800,
        minHeight: 800,
      );

      if (compressed == null) {
        debugPrint('⚠️ PhotoUploadWidget: Falha na compressão, usando imagem original');
        widget.onPhotoSelected(picked.path);
      } else {
        final compressedSize = await compressed.length();
        debugPrint(
          '✅ PhotoUploadWidget: Imagem comprimida: ${(compressedSize / 1024).toStringAsFixed(2)} KB',
        );
        widget.onPhotoSelected(compressed.path);
      }
    } catch (e) {
      debugPrint('❌ PhotoUploadWidget: Erro ao processar imagem: $e');
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Erro ao processar imagem. Tente novamente.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.currentPhotoPath != null;
    final isRemoteUrl = hasPhoto && widget.currentPhotoPath!.startsWith('http');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: widget.enabled && !_isProcessing ? _showImageSourceSheet : null,
              child: Container(
                height: widget.height,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.surface,
                ),
                child: _isProcessing
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppRadioPulseLoader(
                              size: 44,
                              color: AppColors.primary,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Processando imagem...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : hasPhoto
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: isRemoteUrl
                                ? CachedNetworkImage(
                                    imageUrl: widget.currentPhotoPath!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                      child: AppRadioPulseLoader(
                                        size: 36,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Iconsax.danger,
                                          size: 48,
                                          color: Colors.red,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Erro ao carregar foto',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  )
                                : Image.file(
                                    File(widget.currentPhotoPath!),
                                    fit: BoxFit.cover,
                                  ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                widget.emptyIcon,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                widget.emptyText,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
              ),
            ),
            
            // Botão remover foto
            if (hasPhoto && widget.enabled && !_isProcessing)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => widget.onPhotoSelected(null),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Iconsax.close_circle,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
          ],
        ),
        
        // Hint "Alterar foto"
        if (hasPhoto && widget.showChangeHint && !_isProcessing)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Center(
              child: Text(
                'Alterar foto',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}
