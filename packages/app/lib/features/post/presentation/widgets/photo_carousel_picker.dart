import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// Widget para upload de carrossel de fotos (até 4 imagens)
/// 
/// Funcionalidades:
/// - Seleção múltipla de fotos (galeria/câmera)
/// - Compressão automática (85% quality, 800x800 min)
/// - Preview em grid 2x2
/// - Remoção individual
/// - Suporte a fotos existentes (URLs) + novas (File)
class PhotoCarouselPicker extends StatefulWidget {
  const PhotoCarouselPicker({
    required this.onPhotosChanged,
    this.photoPaths = const [],
    this.maxPhotos = 4,
    this.enabled = true,
    super.key,
  });

  /// Callback quando fotos são adicionadas/removidas
  /// Recebe lista combinada de paths (URLs http:// ou paths locais de arquivo)
  final void Function(List<String> photoPaths) onPhotosChanged;
  
  /// Fotos atuais (URLs existentes do Firebase ou paths locais)
  final List<String> photoPaths;
  
  /// Máximo de fotos permitidas
  final int maxPhotos;
  
  /// Se o widget está habilitado
  final bool enabled;

  @override
  State<PhotoCarouselPicker> createState() => _PhotoCarouselPickerState();
}

class _PhotoCarouselPickerState extends State<PhotoCarouselPicker> {
  /// Lista combinada de fotos (URLs remotas + paths locais)
  List<String> _photoPaths = [];
  
  /// Foto sendo processada (compressão)
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _photoPaths = List.from(widget.photoPaths);
  }

  @override
  void didUpdateWidget(PhotoCarouselPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sincroniza estado se photoPaths mudou externamente
    if (widget.photoPaths != oldWidget.photoPaths) {
      setState(() {
        _photoPaths = List.from(widget.photoPaths);
      });
    }
  }

  int get _totalPhotos => _photoPaths.length;

  /// Notifica mudanças ao componente pai
  void _notifyChanges() {
    widget.onPhotosChanged(_photoPaths);
  }

  /// Mostra opções de adicionar foto
  Future<void> _showAddPhotoOptions() async {
    if (_totalPhotos >= widget.maxPhotos || !widget.enabled || _isProcessing) return;

    final remaining = widget.maxPhotos - _totalPhotos;
    
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Iconsax.gallery, color: AppColors.primary),
                title: Text('Galeria (até $remaining ${remaining == 1 ? "foto" : "fotos"})'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery(maxImages: remaining);
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.camera, color: AppColors.primary),
                title: const Text('Câmera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Seleciona imagens da galeria
  Future<void> _pickFromGallery({int maxImages = 4}) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final picker = ImagePicker();
      final picked = await picker.pickMultiImage(limit: maxImages);
      
      for (final image in picked) {
        if (_totalPhotos >= widget.maxPhotos) break;
        await _processAndAddPhoto(File(image.path));
      }
    } catch (e) {
      debugPrint('❌ Erro ao selecionar imagens: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Captura foto da câmera
  Future<void> _pickFromCamera() async {
    if (_isProcessing || _totalPhotos >= widget.maxPhotos) return;

    setState(() => _isProcessing = true);

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.camera);
      
      if (picked != null) {
        await _processAndAddPhoto(File(picked.path));
      }
    } catch (e) {
      debugPrint('❌ Erro ao capturar foto: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Processa e adiciona uma foto (crop + compressão)
  Future<void> _processAndAddPhoto(File photo) async {
    try {
      // Crop da imagem
      final cropped = await ImageCropper().cropImage(
        sourcePath: photo.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Ajustar foto',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Ajustar foto',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (cropped == null) return;

      // Compressão
      final tempDir = Directory.systemTemp;
      final targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';

      final compressed = await FlutterImageCompress.compressAndGetFile(
        cropped.path,
        targetPath,
        quality: 85,
        minWidth: 800,
        minHeight: 800,
      );

      final finalPath = compressed?.path ?? cropped.path;
      
      setState(() {
        _photoPaths.add(finalPath);
      });
      
      _notifyChanges();
      
      debugPrint('✅ Foto adicionada: ${(await File(finalPath).length()) ~/ 1024} KB');
    } catch (e) {
      debugPrint('❌ Erro ao processar foto: $e');
    }
  }

  /// Remove uma foto da lista
  void _removePhoto(int index) {
    setState(() {
      _photoPaths.removeAt(index);
    });
    _notifyChanges();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com contador
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Fotos do post',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _totalPhotos > 0 ? AppColors.primary.withOpacity(0.1) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_totalPhotos/${widget.maxPhotos}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _totalPhotos > 0 ? AppColors.primary : Colors.grey[600],
                        ),
                      ),
                    ),
                    if (_isProcessing) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ],
                ),
                if (_totalPhotos < widget.maxPhotos)
                  TextButton.icon(
                    onPressed: widget.enabled ? _showAddPhotoOptions : null,
                    icon: const Icon(Iconsax.add),
                    label: const Text('Adicionar'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Grid de fotos ou placeholder
            if (_totalPhotos == 0)
              _buildEmptyPlaceholder()
            else
              _buildPhotoGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPlaceholder() {
    return InkWell(
      onTap: widget.enabled ? _showAddPhotoOptions : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Iconsax.image,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'Toque para adicionar fotos',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              Text(
                'Até ${widget.maxPhotos} fotos',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: _totalPhotos,
      itemBuilder: (context, index) {
        final photoPath = _photoPaths[index];
        final isRemote = photoPath.startsWith('http');
        
        return _buildPhotoItem(photoPath, index, isRemote);
      },
    );
  }

  Widget _buildPhotoItem(String photoPath, int index, bool isRemote) {
    return Stack(
      children: [
        // Imagem
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: isRemote
              ? CachedNetworkImage(
                  imageUrl: photoPath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.error),
                  ),
                )
              : Image.file(
                  File(photoPath),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.error),
                  ),
                ),
        ),
        
        // Badge de ordem
        Positioned(
          bottom: 4,
          left: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        
        // Botão remover
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: () => _removePhoto(index),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
