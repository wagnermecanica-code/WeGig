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
/// - Cache de Markers completos por post ID (evita reconstruções)
/// - Marcadores em formato pin (gota invertida)
/// - Cores dinâmicas (azul músicos, laranja bandas)
/// - Efeito glow no marcador ativo
class MarkerBuilder {
  MarkerBuilder({WeGigPinDescriptorBuilder? descriptorBuilder})
      : _descriptorBuilder = descriptorBuilder ?? WeGigPinDescriptorBuilder();

  final WeGigPinDescriptorBuilder _descriptorBuilder;
  // Cache de BitmapDescriptor por tipo e estado
  final Map<String, BitmapDescriptor> _iconCache = {};
  // ✅ Cache de Markers completos por post ID + estado ativo
  final Map<String, Marker> _markerCache = {};
  // ✅ Tracking do último estado ativo para invalidação seletiva
  String? _lastActivePostId;

  /// Inicializa cache de marcadores (warmup)
  Future<void> initialize() async {
    debugPrint('📍 MarkerBuilder: Iniciando warmup...');
    final stopwatch = Stopwatch()..start();
    await _descriptorBuilder.warmup();
    stopwatch.stop();
    debugPrint('✅ MarkerBuilder: Warmup completo em ${stopwatch.elapsedMilliseconds}ms');
  }

  /// Constrói marcadores para lista de posts (com cache inteligente)
  Future<Set<Marker>> buildMarkersForPosts(
    List<PostEntity> posts,
    String? activePostId,
    Future<void> Function(PostEntity) onMarkerTapped,
  ) async {
    final markers = <Marker>{};
    final currentPostIds = posts.map((p) => p.id).toSet();
    
    // ✅ Invalidação seletiva: só recria markers afetados pela mudança de estado ativo
    final needsActiveUpdate = _lastActivePostId != activePostId;
    final idsToInvalidate = <String>{};
    
    if (needsActiveUpdate) {
      // Invalida o marker que era ativo (se existir)
      if (_lastActivePostId != null) {
        idsToInvalidate.add(_lastActivePostId!);
      }
      // Invalida o novo marker ativo (se existir)
      if (activePostId != null) {
        idsToInvalidate.add(activePostId);
      }
      _lastActivePostId = activePostId;
    }
    
    // ✅ Limpa markers de posts que não estão mais visíveis
    _markerCache.removeWhere((key, _) => !currentPostIds.contains(key));

    for (final post in posts) {
      final isActive = post.id == activePostId;
      final cacheKey = post.id;
      
      // ✅ Reutiliza marker do cache se não precisa atualizar
      if (_markerCache.containsKey(cacheKey) && !idsToInvalidate.contains(cacheKey)) {
        markers.add(_markerCache[cacheKey]!);
        continue;
      }
      
      // Gera novo marker (somente quando necessário)
      final icon = await _getMarkerIcon(post.type, isActive);

      final marker = Marker(
        markerId: MarkerId(post.id),
        position: LatLng(post.location.latitude, post.location.longitude),
        icon: icon,
        anchor: const Offset(0.5, 1.0), // Ancora na ponta do pin
        zIndex: isActive ? 1000.0 : 1.0, // Ativo sempre no topo
        onTap: () {
          debugPrint('📍 Marcador tocado: ${post.id}');
          onMarkerTapped(post);
        },
      );
      
      // ✅ Armazena no cache
      _markerCache[cacheKey] = marker;
      markers.add(marker);
    }

    return markers;
  }

  /// Obtém ícone do marcador (com cache)
  Future<BitmapDescriptor> _getMarkerIcon(String type, bool isActive) async {
    final cacheKey = '${type}_$isActive';

    if (_iconCache.containsKey(cacheKey)) {
      return _iconCache[cacheKey]!;
    }

    debugPrint('🎨 MarkerBuilder: Gerando marcador $cacheKey...');
    final userType = userTypeFromPostType(type);
    final icon = await _descriptorBuilder.getDescriptor(
      userType,
      isHighlighted: isActive,
    );

    _iconCache[cacheKey] = icon;
    return icon;
  }

  /// Limpa cache (útil ao descartar widget)
  void dispose() {
    _iconCache.clear();
    _markerCache.clear();
    _lastActivePostId = null;
    debugPrint('🗑️ MarkerBuilder: Cache limpo');
  }
  
  /// ✅ Retorna estatísticas do cache para debugging
  Map<String, int> get cacheStats => {
    'icons': _iconCache.length,
    'markers': _markerCache.length,
  };
}
