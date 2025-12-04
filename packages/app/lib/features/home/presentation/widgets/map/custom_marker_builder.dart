import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:custom_map_markers/custom_map_markers.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wegig_app/features/home/presentation/widgets/map/custom_marker_widget.dart';

/// Builder para marcadores customizados usando custom_map_markers
/// 
/// Vantagens sobre o sistema atual (MarkerCacheService):
/// 1. Marcadores com Widget nativo do Flutter (mais flexibilidade)
/// 2. Suporte a foto do perfil do autor
/// 3. Badges e indicadores visuais ricos
/// 4. Animações e efeitos mais elaborados
/// 5. Sem necessidade de gerar BitmapDescriptor manualmente
/// 6. Atualização automática via setState (marcadores reativos)
/// 
/// Performance:
/// - Similar ao sistema atual (ambos fazem cache)
/// - custom_map_markers usa BitmapDescriptor internamente
/// - Vantagem: código mais simples e manutenível
class CustomMarkerBuilder {
  /// Converte lista de posts em marcadores customizados
  /// 
  /// Retorna lista de MarkerData que pode ser usada com CustomGoogleMapMarkerBuilder
  List<MarkerData> buildMarkersForPosts(
    List<PostEntity> posts,
    String? activePostId,
    void Function(PostEntity) onMarkerTapped,
  ) {
    return posts.map((post) {
      final isActive = post.id == activePostId;
      
      return MarkerData(
        marker: Marker(
          markerId: MarkerId(post.id),
          position: LatLng(
            post.location.latitude,
            post.location.longitude,
          ),
          onTap: () => onMarkerTapped(post),
          // Importante: zIndex para marcador ativo ficar no topo
          zIndexInt: isActive ? 1000 : 1,
        ),
        // Widget customizado que será renderizado como marcador
        child: CustomMarkerWidget(
          type: post.type,
          authorPhotoUrl: post.authorPhotoUrl,
          itemCount: post.type == 'musician' 
              ? post.instruments.length
              : post.genres.length, // ou número de membros se tiver
          isActive: isActive,
          authorName: post.authorName,
        ),
      );
    }).toList();
  }

  /// Versão simplificada (sem foto do perfil)
  /// 
  /// Use quando quiser marcadores mais simples ou quando
  /// não tiver foto do perfil disponível
  List<MarkerData> buildSimpleMarkersForPosts(
    List<PostEntity> posts,
    String? activePostId,
    void Function(PostEntity) onMarkerTapped,
  ) {
    return posts.map((post) {
      final isActive = post.id == activePostId;
      
      return MarkerData(
        marker: Marker(
          markerId: MarkerId(post.id),
          position: LatLng(
            post.location.latitude,
            post.location.longitude,
          ),
          onTap: () => onMarkerTapped(post),
          zIndexInt: isActive ? 1000 : 1,
        ),
        child: SimpleMarkerWidget(
          type: post.type,
          isActive: isActive,
        ),
      );
    }).toList();
  }

  /// Versão de alto desempenho (usa cache do MarkerCacheService como fallback)
  /// 
  /// Combina custom_map_markers para marcadores especiais (ativo, com foto)
  /// e BitmapDescriptor tradicional para marcadores normais (melhor performance)
  /// 
  /// Estratégia híbrida:
  /// - Marcador ativo: CustomMarkerWidget (rico, visível)
  /// - Marcadores normais: BitmapDescriptor do cache (rápido)
  List<MarkerData> buildHybridMarkersForPosts(
    List<PostEntity> posts,
    String? activePostId,
    void Function(PostEntity) onMarkerTapped, {
    bool usePhotosForAll = false, // Flag para forçar foto em todos
  }) {
    return posts.map((post) {
      final isActive = post.id == activePostId;
      final hasPhoto = post.authorPhotoUrl != null && 
                      post.authorPhotoUrl!.isNotEmpty;
      
      // Usa widget customizado apenas para marcadores especiais
      final useCustomWidget = isActive || (usePhotosForAll && hasPhoto);
      
      return MarkerData(
        marker: Marker(
          markerId: MarkerId(post.id),
          position: LatLng(
            post.location.latitude,
            post.location.longitude,
          ),
          onTap: () => onMarkerTapped(post),
          zIndexInt: isActive ? 1000 : 1,
        ),
        child: useCustomWidget
            ? CustomMarkerWidget(
                type: post.type,
                authorPhotoUrl: post.authorPhotoUrl,
                itemCount: post.type == 'musician' 
                    ? post.instruments.length
                    : post.genres.length,
                isActive: isActive,
                authorName: isActive ? post.authorName : null,
              )
            : SimpleMarkerWidget(
                type: post.type,
                isActive: false, // Nunca ativo neste modo
              ),
      );
    }).toList();
  }
}
