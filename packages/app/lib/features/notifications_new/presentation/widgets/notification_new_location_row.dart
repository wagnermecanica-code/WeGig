/// WeGig - NotificationNew Location Row
///
/// Widget para exibir localização do post relacionado à notificação.
/// Implementa cache inteligente para evitar múltiplas chamadas ao Firestore.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:wegig_app/features/notifications_new/domain/entities/notification_new_entity.dart';

/// Cache estático para dados de localização de posts
///
/// Evita múltiplas chamadas ao Firestore para o mesmo post.
/// Chave: postId, Valor: Map com city, neighborhood, etc.
final Map<String, Map<String, dynamic>?> _locationCache = {};

/// Widget para exibir localização do post
///
/// Busca dados do post no Firestore (com cache) e exibe:
/// - Cidade/Bairro
/// - Distância aproximada (se disponível)
class NotificationNewLocationRow extends StatefulWidget {
  /// Cria row de localização
  const NotificationNewLocationRow({
    required this.notification,
    super.key,
  });

  /// Notificação para extrair postId
  final NotificationEntity notification;

  @override
  State<NotificationNewLocationRow> createState() =>
      _NotificationNewLocationRowState();
}

class _NotificationNewLocationRowState
    extends State<NotificationNewLocationRow> {
  Map<String, dynamic>? _locationData;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  /// Carrega dados de localização do post
  Future<void> _loadLocation() async {
    // Primeiro, verifica se city já está no actionData (enviado pelo Cloud Function)
    final actionData = widget.notification.actionData;
    if (actionData != null && actionData['city'] != null) {
      final cityFromAction = actionData['city'] as String?;
      if (cityFromAction != null && cityFromAction.isNotEmpty) {
        if (mounted) {
          setState(() {
            _locationData = {
              'city': cityFromAction,
              'neighborhood': '',
              'state': '',
            };
            _isLoading = false;
          });
        }
        return;
      }
    }

    // Extrai postId da notificação
    final postId = widget.notification.targetId ??
        widget.notification.data['postId'] as String? ??
        widget.notification.actionData?['postId'] as String?;

    if (postId == null || postId.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
      return;
    }

    // Verifica cache primeiro
    if (_locationCache.containsKey(postId)) {
      if (mounted) {
        setState(() {
          _locationData = _locationCache[postId];
          _isLoading = false;
        });
      }
      return;
    }

    // Busca no Firestore
    try {
      final doc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .get();

      if (!doc.exists) {
        _locationCache[postId] = null;
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
        return;
      }

      final data = doc.data();
      final locationData = {
        'city': data?['city'] as String? ?? '',
        'neighborhood': data?['neighborhood'] as String? ?? '',
        'state': data?['state'] as String? ?? '',
      };

      // Armazena no cache
      _locationCache[postId] = locationData;

      if (mounted) {
        setState(() {
          _locationData = locationData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ NotificationNewLocationRow: Error loading location - $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Não exibe nada enquanto carrega ou se erro
    if (_isLoading || _hasError || _locationData == null) {
      return const SizedBox.shrink();
    }

    final city = _locationData!['city'] as String? ?? '';
    final neighborhood = _locationData!['neighborhood'] as String? ?? '';

    // Não exibe se não tem localização
    if (city.isEmpty && neighborhood.isEmpty) {
      return const SizedBox.shrink();
    }

    // Formata texto de localização
    String locationText;
    if (neighborhood.isNotEmpty && city.isNotEmpty) {
      locationText = '$neighborhood, $city';
    } else if (city.isNotEmpty) {
      locationText = city;
    } else {
      locationText = neighborhood;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(
            Iconsax.location,
            size: 14,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              locationText,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Limpa o cache de localização
///
/// Pode ser chamado ao trocar de perfil ou fazer logout.
void clearNotificationLocationCache() {
  _locationCache.clear();
}
