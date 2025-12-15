import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço de cache offline para posts e perfis
/// Armazena dados localmente para acesso offline
class CacheService {
  static const String _postsKey = 'cached_posts';
  static const String _profilesKey = 'cached_profiles';
  static const String _lastUpdateKey = 'cache_last_update';
  static const Duration _cacheExpiration = Duration(hours: 24);

  /// Salva posts no cache
  static Future<void> cachePosts(List<Map<String, dynamic>> posts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(posts);
      await prefs.setString(_postsKey, jsonString);
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Erro ao salvar cache de posts: $e');
    }
  }

  /// Recupera posts do cache
  static Future<List<Map<String, dynamic>>?> getCachedPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Verifica se o cache expirou
      final lastUpdate = prefs.getInt(_lastUpdateKey);
      if (lastUpdate != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - lastUpdate;
        if (cacheAge > _cacheExpiration.inMilliseconds) {
          return null; // Cache expirado
        }
      }
      
      final jsonString = prefs.getString(_postsKey);
      if (jsonString == null) return null;
      
      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      debugPrint('Erro ao recuperar cache de posts: $e');
      return null;
    }
  }

  /// Salva perfis no cache
  static Future<void> cacheProfiles(List<Map<String, dynamic>> profiles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(profiles);
      await prefs.setString(_profilesKey, jsonString);
    } catch (e) {
      debugPrint('Erro ao salvar cache de perfis: $e');
    }
  }

  /// Recupera perfis do cache
  static Future<List<Map<String, dynamic>>?> getCachedProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_profilesKey);
      if (jsonString == null) return null;
      
      final List<dynamic> decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      debugPrint('Erro ao recuperar cache de perfis: $e');
      return null;
    }
  }

  /// Limpa todo o cache
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_postsKey);
      await prefs.remove(_profilesKey);
      await prefs.remove(_lastUpdateKey);
    } catch (e) {
      debugPrint('Erro ao limpar cache: $e');
    }
  }

  /// Verifica se há cache disponível
  static Future<bool> hasCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    // O método containsKey já retorna false se a chave não existir e não lança exceção.
    return prefs.containsKey(_postsKey);
  }
}
