import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wegig_app/core/providers/cache_config_provider.dart';

part 'gps_cache_provider.g.dart';

/// Estado da localização GPS
@immutable
class GpsState {
  const GpsState({
    required this.position,
    this.source = GpsSource.unknown,
    this.lastUpdate,
    this.accuracy,
    this.isLoading = false,
    this.error,
  });
  
  /// Posição atual
  final LatLng position;
  
  /// Fonte da posição (cache, gps, default)
  final GpsSource source;
  
  /// Última atualização
  final DateTime? lastUpdate;
  
  /// Precisão em metros (se disponível)
  final double? accuracy;
  
  /// Indica se está carregando
  final bool isLoading;
  
  /// Erro (se houver)
  final String? error;
  
  /// Posição padrão (São Paulo)
  static const LatLng defaultPosition = LatLng(-23.5505, -46.6333);
  
  /// Estado inicial com posição padrão
  factory GpsState.initial() => const GpsState(
    position: GpsState.defaultPosition,
    source: GpsSource.defaultFallback,
    isLoading: true,
  );
  
  /// Idade do cache em minutos
  int get ageInMinutes {
    if (lastUpdate == null) return -1;
    return DateTime.now().difference(lastUpdate!).inMinutes;
  }
  
  /// Verifica se é posição real (não default)
  bool get isRealPosition => source == GpsSource.gps || source == GpsSource.cache;
  
  GpsState copyWith({
    LatLng? position,
    GpsSource? source,
    DateTime? lastUpdate,
    double? accuracy,
    bool? isLoading,
    String? error,
  }) {
    return GpsState(
      position: position ?? this.position,
      source: source ?? this.source,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      accuracy: accuracy ?? this.accuracy,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
  
  @override
  String toString() => 'GpsState(${position.latitude.toStringAsFixed(4)}, '
      '${position.longitude.toStringAsFixed(4)}, source: $source)';
}

/// Fonte da posição GPS
enum GpsSource {
  /// Posição obtida do GPS
  gps,
  /// Posição obtida do cache
  cache,
  /// Posição padrão (fallback)
  defaultFallback,
  /// Fonte desconhecida
  unknown,
}

/// Provider de localização GPS com cache inteligente
/// 
/// Funcionalidades:
/// - Cache persistente com TTL de 24h
/// - Fallback para posição padrão (São Paulo)
/// - Refresh automático quando cache expira
/// - Integração com CacheConfigNotifier
/// 
/// Uso:
/// ```dart
/// final gps = ref.watch(gpsCacheNotifierProvider);
/// final position = gps.position;
/// ```
@Riverpod(keepAlive: true)
class GpsCacheNotifier extends _$GpsCacheNotifier {
  static const String _latKey = 'gps_cache_lat';
  static const String _lngKey = 'gps_cache_lng';
  static const String _timestampKey = 'gps_cache_timestamp';
  static const String _accuracyKey = 'gps_cache_accuracy';
  
  /// TTL do cache GPS: 24 horas
  static const Duration _cacheTTL = Duration(hours: 24);
  
  @override
  GpsState build() {
    // Iniciar carregamento
    _loadPosition();
    
    return GpsState.initial();
  }
  
  /// Carrega posição (cache → GPS → default)
  Future<void> _loadPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Tentar cache primeiro
      final cached = await _loadFromCache(prefs);
      if (cached != null) {
        state = cached;
        debugPrint('📍 GPS: Carregado do cache (${cached.ageInMinutes}min)');
        return;
      }
      
      // 2. Cache expirado/inexistente - tentar GPS
      debugPrint('📍 GPS: Cache expirado, obtendo posição...');
      final gpsPosition = await _getCurrentGpsPosition();
      
      if (gpsPosition != null) {
        await _saveToCache(prefs, gpsPosition);
        state = gpsPosition;
        debugPrint('📍 GPS: Posição obtida e cacheada');
        return;
      }
      
      // 3. GPS falhou - usar default
      state = GpsState(
        position: GpsState.defaultPosition,
        source: GpsSource.defaultFallback,
        lastUpdate: DateTime.now(),
        isLoading: false,
        error: 'GPS indisponível, usando posição padrão',
      );
      debugPrint('📍 GPS: Usando posição padrão (São Paulo)');
      
    } catch (e) {
      state = GpsState(
        position: GpsState.defaultPosition,
        source: GpsSource.defaultFallback,
        lastUpdate: DateTime.now(),
        isLoading: false,
        error: e.toString(),
      );
      debugPrint('⚠️ GPS: Erro - $e');
    }
  }
  
  /// Carrega posição do cache se válida
  Future<GpsState?> _loadFromCache(SharedPreferences prefs) async {
    try {
      final lat = prefs.getDouble(_latKey);
      final lng = prefs.getDouble(_lngKey);
      final timestamp = prefs.getInt(_timestampKey);
      final accuracy = prefs.getDouble(_accuracyKey);
      
      if (lat == null || lng == null || timestamp == null) {
        return null;
      }
      
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final age = DateTime.now().difference(cacheTime);
      
      // Verificar TTL
      if (age > _cacheTTL) {
        debugPrint('📍 GPS: Cache expirado (${age.inHours}h > 24h)');
        return null;
      }
      
      return GpsState(
        position: LatLng(lat, lng),
        source: GpsSource.cache,
        lastUpdate: cacheTime,
        accuracy: accuracy,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('⚠️ GPS: Erro ao ler cache - $e');
      return null;
    }
  }
  
  /// Obtém posição atual do GPS
  Future<GpsState?> _getCurrentGpsPosition() async {
    try {
      // Verificar permissões
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ GPS: Permissão negada');
        return null;
      }
      
      // Verificar se serviço está habilitado
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ GPS: Serviço desabilitado');
        return null;
      }
      
      // Obter posição com timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('GPS timeout'),
      );
      
      return GpsState(
        position: LatLng(position.latitude, position.longitude),
        source: GpsSource.gps,
        lastUpdate: DateTime.now(),
        accuracy: position.accuracy,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('⚠️ GPS: Erro ao obter posição - $e');
      return null;
    }
  }
  
  /// Salva posição no cache
  Future<void> _saveToCache(SharedPreferences prefs, GpsState gpsState) async {
    try {
      await prefs.setDouble(_latKey, gpsState.position.latitude);
      await prefs.setDouble(_lngKey, gpsState.position.longitude);
      await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);
      
      if (gpsState.accuracy != null) {
        await prefs.setDouble(_accuracyKey, gpsState.accuracy!);
      }
      
      debugPrint('💾 GPS: Posição salva no cache');
    } catch (e) {
      debugPrint('⚠️ GPS: Erro ao salvar cache - $e');
    }
  }
  
  /// Força atualização da posição GPS
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final gpsPosition = await _getCurrentGpsPosition();
      
      if (gpsPosition != null) {
        final prefs = await SharedPreferences.getInstance();
        await _saveToCache(prefs, gpsPosition);
        state = gpsPosition;
        debugPrint('📍 GPS: Posição atualizada');
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Não foi possível obter posição GPS',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  /// Atualiza posição manualmente (ex: seleção no mapa)
  Future<void> setPosition(LatLng position) async {
    final prefs = await SharedPreferences.getInstance();
    
    final newState = GpsState(
      position: position,
      source: GpsSource.gps,
      lastUpdate: DateTime.now(),
      isLoading: false,
    );
    
    await _saveToCache(prefs, newState);
    state = newState;
    
    debugPrint('📍 GPS: Posição definida manualmente');
  }
  
  /// Limpa cache GPS
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_latKey);
      await prefs.remove(_lngKey);
      await prefs.remove(_timestampKey);
      await prefs.remove(_accuracyKey);
      
      state = GpsState.initial();
      debugPrint('🗑️ GPS: Cache limpo');
    } catch (e) {
      debugPrint('⚠️ GPS: Erro ao limpar cache - $e');
    }
  }
}

/// Provider de conveniência para posição atual
@riverpod
LatLng currentPosition(CurrentPositionRef ref) {
  return ref.watch(gpsCacheNotifierProvider).position;
}

/// Provider de conveniência para verificar se tem posição real
@riverpod
bool hasRealPosition(HasRealPositionRef ref) {
  return ref.watch(gpsCacheNotifierProvider).isRealPosition;
}
