import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

/// Estado de conectividade do dispositivo
enum ConnectivityStatus {
  /// Conectado via WiFi
  wifi,
  /// Conectado via dados móveis
  mobile,
  /// Conectado via Ethernet
  ethernet,
  /// Sem conexão
  offline,
  /// Estado desconhecido
  unknown,
}

/// Provider de conectividade para gerenciar estado de rede
/// 
/// Funcionalidades:
/// - Monitoramento em tempo real de conexão
/// - Diferenciação WiFi/Mobile/Offline
/// - Callbacks para mudanças de estado
/// - Integração com cache (modo offline)
/// 
/// Uso:
/// ```dart
/// final connectivity = ref.watch(connectivityNotifierProvider);
/// if (connectivity == ConnectivityStatus.offline) {
///   // Mostrar banner offline
/// }
/// ```
@Riverpod(keepAlive: true)
class ConnectivityNotifier extends _$ConnectivityNotifier {
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  
  @override
  ConnectivityStatus build() {
    // Iniciar monitoramento
    _startMonitoring();
    
    // Cleanup ao dispose
    ref.onDispose(() {
      _subscription?.cancel();
      debugPrint('📡 ConnectivityNotifier: Disposed');
    });
    
    // Verificar estado inicial
    _checkInitialConnectivity();
    
    return ConnectivityStatus.unknown;
  }
  
  /// Inicia monitoramento de mudanças de conectividade
  void _startMonitoring() {
    _subscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final newStatus = _mapConnectivityResult(results);
        
        if (state != newStatus) {
          final oldStatus = state;
          state = newStatus;
          
          _logConnectivityChange(oldStatus, newStatus);
        }
      },
      onError: (error) {
        debugPrint('📡 ConnectivityNotifier: Erro - $error');
        state = ConnectivityStatus.unknown;
      },
    );
    
    debugPrint('📡 ConnectivityNotifier: Monitoramento iniciado');
  }
  
  /// Verifica conectividade inicial
  Future<void> _checkInitialConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      state = _mapConnectivityResult(results);
      debugPrint('📡 ConnectivityNotifier: Estado inicial - $state');
    } catch (e) {
      debugPrint('📡 ConnectivityNotifier: Erro ao verificar inicial - $e');
      state = ConnectivityStatus.unknown;
    }
  }
  
  /// Mapeia resultado do plugin para nosso enum
  ConnectivityStatus _mapConnectivityResult(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return ConnectivityStatus.offline;
    }
    
    if (results.contains(ConnectivityResult.wifi)) {
      return ConnectivityStatus.wifi;
    }
    
    if (results.contains(ConnectivityResult.mobile)) {
      return ConnectivityStatus.mobile;
    }
    
    if (results.contains(ConnectivityResult.ethernet)) {
      return ConnectivityStatus.ethernet;
    }
    
    return ConnectivityStatus.unknown;
  }
  
  /// Log de mudanças de conectividade
  void _logConnectivityChange(
    ConnectivityStatus oldStatus,
    ConnectivityStatus newStatus,
  ) {
    final emoji = newStatus == ConnectivityStatus.offline ? '📴' : '📶';
    debugPrint('$emoji Conectividade: $oldStatus → $newStatus');
    
    if (newStatus == ConnectivityStatus.offline) {
      debugPrint('   ⚠️ App entrando em modo offline');
    } else if (oldStatus == ConnectivityStatus.offline) {
      debugPrint('   ✅ Conexão restaurada');
    }
  }
  
  /// Força re-verificação da conectividade
  Future<void> refresh() async {
    await _checkInitialConnectivity();
  }
  
  /// Verifica se está online (qualquer tipo de conexão)
  bool get isOnline => state != ConnectivityStatus.offline && 
                        state != ConnectivityStatus.unknown;
  
  /// Verifica se está offline
  bool get isOffline => state == ConnectivityStatus.offline;
  
  /// Verifica se está em WiFi (conexão de alta velocidade)
  bool get isWifi => state == ConnectivityStatus.wifi;
  
  /// Verifica se está em dados móveis (conexão potencialmente limitada)
  bool get isMobile => state == ConnectivityStatus.mobile;
}

/// Provider de conveniência para verificar se está online
@riverpod
bool isOnline(IsOnlineRef ref) {
  final status = ref.watch(connectivityNotifierProvider);
  return status != ConnectivityStatus.offline && 
         status != ConnectivityStatus.unknown;
}

/// Provider de conveniência para verificar se está offline
@riverpod
bool isOffline(IsOfflineRef ref) {
  final status = ref.watch(connectivityNotifierProvider);
  return status == ConnectivityStatus.offline;
}

/// Provider que retorna true se deve economizar dados (mobile ou offline)
@riverpod
bool shouldSaveData(ShouldSaveDataRef ref) {
  final status = ref.watch(connectivityNotifierProvider);
  return status == ConnectivityStatus.mobile || 
         status == ConnectivityStatus.offline;
}
