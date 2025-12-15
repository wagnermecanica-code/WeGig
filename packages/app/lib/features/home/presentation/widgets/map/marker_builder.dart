import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:core_ui/models/user_type.dart';
import 'package:wegig_app/features/home/presentation/widgets/map/wegig_pin_descriptor_builder.dart';

/// Builder de marcadores customizados de alta qualidade
/// 
/// Funcionalidades:
/// - Converte Widget → BitmapDescriptor via widget_to_marker (alta qualidade)
/// - Cache automático de pins (evita regeneração)
/// - Marcadores em formato pin (gota invertida)
/// - Cores dinâmicas (azul músicos, laranja bandas)
/// - Efeito glow no marcador ativo
class MarkerBuilder {
  MarkerBuilder({WeGigPinDescriptorBuilder? descriptorBuilder})
      : _descriptorBuilder = descriptorBuilder ?? WeGigPinDescriptorBuilder();

  final WeGigPinDescriptorBuilder _descriptorBuilder;
  // Cache de BitmapDescriptor por tipo e estado
  final Map<String, BitmapDescriptor> _markerCache = {};

  /// Inicializa cache de marcadores (warmup)
  Future<void> initialize() async {
    debugPrint('📍 MarkerBuilder: Iniciando warmup...');
    final stopwatch = Stopwatch()..start();
    await _descriptorBuilder.warmup();
    stopwatch.stop();
    debugPrint('✅ MarkerBuilder: Warmup completo em ${stopwatch.elapsedMilliseconds}ms');
  }

  /// Constrói marcadores para lista de posts
  Future<Set<Marker>> buildMarkersForPosts(
    List<PostEntity> posts,
    String? activePostId,
    Future<void> Function(PostEntity) onMarkerTapped,
  ) async {
    final markers = <Marker>{};

    for (final post in posts) {
      final isActive = post.id == activePostId;
      final icon = await _getMarkerIcon(post.type, isActive);

      markers.add(
        Marker(
          markerId: MarkerId(post.id),
          position: LatLng(post.location.latitude, post.location.longitude),
          icon: icon,
          anchor: const Offset(0.5, 1.0), // Ancora na ponta do pin
          zIndexInt: isActive ? 1000 : 1, // Ativo sempre no topo
          onTap: () {
            debugPrint('📍 Marcador tocado: ${post.id}');
            onMarkerTapped(post);
          },
        ),
      );
    }

    return markers;
  }

  /// Obtém ícone do marcador (com cache)
  Future<BitmapDescriptor> _getMarkerIcon(String type, bool isActive) async {
    final cacheKey = '${type}_$isActive';

    if (_markerCache.containsKey(cacheKey)) {
      return _markerCache[cacheKey]!;
    }

    debugPrint('🎨 MarkerBuilder: Gerando marcador $cacheKey...');
    final userType = userTypeFromPostType(type);
    final icon = await _descriptorBuilder.getDescriptor(
      userType,
      isHighlighted: isActive,
    );

    _markerCache[cacheKey] = icon;
    return icon;
  }

  /// Limpa cache (útil ao descartar widget)
  void dispose() {
    _markerCache.clear();
    debugPrint('🗑️ MarkerBuilder: Cache limpo');
  }
}
