import 'package:flutter/material.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';

/// Widget customizado para marcadores do mapa usando custom_map_markers
/// 
/// Oferece marcadores mais ricos e personalizáveis que BitmapDescriptor:
/// - Foto do perfil do autor
/// - Badge com quantidade de instrumentos/membros
/// - Indicador visual de tipo (músico/banda)
/// - Animação de pulso para marcador ativo
/// - Degradê de cor baseado no tipo
class CustomMarkerWidget extends StatelessWidget {
  final String type; // 'musician' ou 'band'
  final String? authorPhotoUrl;
  final int itemCount; // instrumentos (musician) ou membros (band)
  final bool isActive;
  final String? authorName;

  const CustomMarkerWidget({
    super.key,
    required this.type,
    this.authorPhotoUrl,
    this.itemCount = 0,
    this.isActive = false,
    this.authorName,
  });

  @override
  Widget build(BuildContext context) {
    final isBand = type == 'band';
    final primaryColor = isBand ? AppColors.accent : AppColors.primary;
    
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Efeito de pulso para marcador ativo (mais visível que o atual)
        if (isActive) ...[
          Positioned(
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        ],
        
        // Container principal do marcador
        Container(
          width: isActive ? 60 : 50,
          height: isActive ? 60 : 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor,
                primaryColor.withValues(alpha: 0.8),
              ],
            ),
            border: Border.all(
              color: Colors.white,
              width: isActive ? 4 : 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: authorPhotoUrl != null && authorPhotoUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: authorPhotoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _buildDefaultIcon(isBand, isActive),
                    errorWidget: (_, __, ___) => _buildDefaultIcon(isBand, isActive),
                  )
                : _buildDefaultIcon(isBand, isActive),
          ),
        ),
        
        // Badge com contador (superior direito)
        if (itemCount > 0)
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '$itemCount',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ),
        
        // Indicador de tipo (inferior centro) - apenas quando ativo
        if (isActive && authorName != null)
          Positioned(
            bottom: -25,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isBand ? Iconsax.people : Iconsax.musicnote,
                    size: 12,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    authorName!.length > 15
                        ? '${authorName!.substring(0, 15)}...'
                        : authorName!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDefaultIcon(bool isBand, bool isActive) {
    return Container(
      color: isBand 
          ? AppColors.accent.withValues(alpha: 0.2)
          : AppColors.primary.withValues(alpha: 0.2),
      child: Center(
        child: Icon(
          isBand ? Icons.group : Icons.music_note,
          size: isActive ? 28 : 24,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Widget de marcador simplificado (para quando não há foto)
class SimpleMarkerWidget extends StatelessWidget {
  final String type;
  final bool isActive;
  final Color? customColor;

  const SimpleMarkerWidget({
    super.key,
    required this.type,
    this.isActive = false,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final isBand = type == 'band';
    final color = customColor ?? 
        (isBand ? AppColors.accent : AppColors.primary);
    
    return Container(
      width: isActive ? 50 : 40,
      height: isActive ? 50 : 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: Colors.white,
          width: isActive ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
          if (isActive)
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 15,
              spreadRadius: 5,
            ),
        ],
      ),
      child: Icon(
        isBand ? Icons.group : Icons.music_note,
        size: isActive ? 24 : 20,
        color: Colors.white,
      ),
    );
  }
}
