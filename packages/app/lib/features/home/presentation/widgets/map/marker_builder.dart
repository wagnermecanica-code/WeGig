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

  static const List<(String, bool)> _baseWarmupRequests = [
    ('musician', false),
    ('band', false),
  ];

  final WeGigPinDescriptorBuilder _descriptorBuilder;
  // Cache de BitmapDescriptor por tipo e estado
  final Map<String, BitmapDescriptor> _iconCache = {};
  final Map<String, Future<BitmapDescriptor>> _iconInFlight = {};
  // ✅ Cache de Markers completos por post ID + estado ativo
  final Map<String, Marker> _markerCache = {};
  // ✅ Tracking do último estado ativo para invalidação seletiva
  String? _lastActivePostId;
  Future<void>? _warmupFuture;
  bool _isDisposed = false;

  /// Inicializa cache de marcadores (warmup)
  Future<void> initialize() async {
    if (_warmupFuture != null) {
      return _warmupFuture!;
    }

    debugPrint('📍 MarkerBuilder: Iniciando warmup progressivo...');
    final stopwatch = Stopwatch()..start();
    _warmupFuture = _primeRequests(_baseWarmupRequests).whenComplete(() {
      stopwatch.stop();
      debugPrint('✅ MarkerBuilder: Warmup base completo em ${stopwatch.elapsedMilliseconds}ms');
    });

    return _warmupFuture!;
  }

  Future<void> primeForPosts(
    Iterable<PostEntity> posts, {
    String? activePostId,
    int maxPosts = 6,
  }) async {
    if (_isDisposed) return;

    final requests = <(String, bool)>[];
    final seen = <String>{};

    for (final post in posts.take(maxPosts)) {
      final inactiveKey = '${post.type}_false';
      if (seen.add(inactiveKey)) {
        requests.add((post.type, false));
      }

      if (post.id == activePostId) {
        final activeKey = '${post.type}_true';
        if (seen.add(activeKey)) {
          requests.add((post.type, true));
        }
      }
    }

    if (requests.isEmpty) return;
    await _primeRequests(requests);
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

    final iconRequests = <String, Future<BitmapDescriptor>>{};

    for (final post in posts) {
      final cacheKey = post.id;
      if (_markerCache.containsKey(cacheKey) && !idsToInvalidate.contains(cacheKey)) {
        continue;
      }

      final isActive = post.id == activePostId;
      final iconKey = '${post.type}_$isActive';
      iconRequests.putIfAbsent(
        iconKey,
        () => _getMarkerIcon(post.type, isActive),
      );
    }

    if (iconRequests.isNotEmpty) {
      await Future.wait(iconRequests.values);
    }

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

    if (_iconInFlight.containsKey(cacheKey)) {
      return _iconInFlight[cacheKey]!;
    }

    debugPrint('🎨 MarkerBuilder: Gerando marcador $cacheKey...');
    final userType = userTypeFromPostType(type);
    final future = _descriptorBuilder
        .getDescriptor(
          userType,
          isHighlighted: isActive,
        )
        .then((icon) {
          _iconCache[cacheKey] = icon;
          return icon;
        }).whenComplete(() {
          _iconInFlight.remove(cacheKey);
        });

    _iconInFlight[cacheKey] = future;
    return future;
  }

  Future<void> _primeRequests(List<(String, bool)> requests) async {
    if (requests.isEmpty || _isDisposed) return;

    for (final request in requests) {
      if (_isDisposed) return;
      await _getMarkerIcon(request.$1, request.$2);
      await Future<void>.delayed(Duration.zero);
    }
  }

  /// Limpa caches sem descartar o builder.
  /// Usar ao entrar em background para liberar memória — caches são
  /// re-populados sob demanda quando o app volta ao foreground.
  void clearCaches() {
    if (_isDisposed) return;
    final iconsBefore = _iconCache.length;
    final markersBefore = _markerCache.length;
    _iconCache.clear();
    _iconInFlight.clear();
    _markerCache.clear();
    _lastActivePostId = null;
    debugPrint(
      '🧹 MarkerBuilder: caches limpos (icons=$iconsBefore, markers=$markersBefore)',
    );
  }

  /// Limpa cache (útil ao descartar widget)
  void dispose() {
    _isDisposed = true;
    _iconCache.clear();
    _iconInFlight.clear();
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
