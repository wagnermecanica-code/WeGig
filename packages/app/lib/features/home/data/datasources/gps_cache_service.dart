// WEGIG – GPS CACHE SERVICE
// Caches last known GPS position for faster app startup
// Fallback hierarchy: Cache → GPS → São Paulo default

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

class GpsCacheService {
  static const String _latKey = 'last_gps_lat';
  static const String _lngKey = 'last_gps_lng';
  static const String _timestampKey = 'last_gps_timestamp';
  
  // Cache expiration: 24 hours
  static const Duration _cacheExpiration = Duration(hours: 24);
  
  // Default position (São Paulo)
  static const LatLng _defaultPosition = LatLng(-23.5505, -46.6333);

  /// Obtém última posição conhecida (cache → GPS → default)
  static Future<LatLng> getLastKnownPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Tentar carregar do cache
      final cachedPosition = await _getCachedPosition(prefs);
      if (cachedPosition != null) {
        debugPrint('📍 GPS: Usando posição em cache');
        return cachedPosition;
      }

      // Cache expirou ou não existe - tentar obter GPS
      debugPrint('📍 GPS: Cache expirado, obtendo nova posição...');
      final gpsPosition = await _getCurrentPosition();
      
      if (gpsPosition != null) {
        // Salvar nova posição no cache
        await _savePosition(prefs, gpsPosition);
        return gpsPosition;
      }

      // GPS falhou - usar posição padrão
      debugPrint('📍 GPS: Falhou, usando posição padrão (São Paulo)');
      return _defaultPosition;
      
    } catch (e) {
      debugPrint('⚠️ GPS Cache Service error: $e');
      return _defaultPosition;
    }
  }

  /// Obtém posição do cache se válida
  static Future<LatLng?> _getCachedPosition(SharedPreferences prefs) async {
    try {
      final lat = prefs.getDouble(_latKey);
      final lng = prefs.getDouble(_lngKey);
      final timestamp = prefs.getInt(_timestampKey);

      if (lat == null || lng == null || timestamp == null) {
        return null;
      }

      // Verificar se cache não expirou
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      
      if (now.difference(cacheTime) > _cacheExpiration) {
        debugPrint('📍 GPS: Cache expirado (${now.difference(cacheTime).inHours}h)');
        return null;
      }

      return LatLng(lat, lng);
      
    } catch (e) {
      debugPrint('⚠️ Erro ao ler cache GPS: $e');
      return null;
    }
  }

  /// Obtém posição atual do GPS com timeout
  static Future<LatLng?> _getCurrentPosition() async {
    try {
      // Verificar permissões
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ GPS: Permissão negada');
        return null;
      }

      // Verificar se serviço está habilitado
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ GPS: Serviço de localização desabilitado');
        return null;
      }

      // Obter posição com timeout de 10s
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return LatLng(position.latitude, position.longitude);
      
    } catch (e) {
      debugPrint('⚠️ Erro ao obter posição GPS: $e');
      return null;
    }
  }

  /// Salva posição no cache
  static Future<void> _savePosition(
    SharedPreferences prefs,
    LatLng position,
  ) async {
    try {
      await prefs.setDouble(_latKey, position.latitude);
      await prefs.setDouble(_lngKey, position.longitude);
      await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);
      
      debugPrint('📍 GPS: Posição salva em cache (${position.latitude}, ${position.longitude})');
    } catch (e) {
      debugPrint('⚠️ Erro ao salvar cache GPS: $e');
    }
  }

  /// Limpa cache (útil para testes ou logout)
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_latKey);
      await prefs.remove(_lngKey);
      await prefs.remove(_timestampKey);
      
      debugPrint('📍 GPS: Cache limpo');
    } catch (e) {
      debugPrint('⚠️ Erro ao limpar cache GPS: $e');
    }
  }

  /// Atualiza posição no cache (chamar ao obter nova posição)
  static Future<void> updateCache(LatLng position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _savePosition(prefs, position);
    } catch (e) {
      debugPrint('⚠️ Erro ao atualizar cache GPS: $e');
    }
  }
}
