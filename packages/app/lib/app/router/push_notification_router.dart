import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Centraliza a navegação disparada por push notifications (FCM).
///
/// Cloud Functions enviam os seguintes tipos (message.data['type']):
/// - nearbyPost: abre o post
/// - interest: abre o post
/// - comment: abre o post (comentário/resposta)
/// - postExpiring: abre o post (renovação)
/// - newMessage: abre a conversa
Future<void> handlePushNotificationTap({
  required GoRouter router,
  required RemoteMessage message,
}) async {
  final data = message.data;
  final type = (data['type'] as String?)?.trim();

  debugPrint('🔔 PushDeepLink: tapped type=$type data=$data');

  // Helper: garante que existe uma base (/home) para manter bottom nav
  // e depois empilha a tela destino.
  // 🍎 iOS: usar delay maior que microtask para garantir que GoRouter
  // processou a navegação para /home antes de empilhar a tela destino.
  // No Android, microtask é suficiente; no iOS, o ciclo de UI pode
  // precisar de um frame completo para estabilizar.
  void goHomeThenPush(String location) {
    router.go('/home');
    final delay = Platform.isIOS
        ? const Duration(milliseconds: 350)
        : Duration.zero;
    Future.delayed(delay, () {
      router.push(location);
    });
  }

  String _trimString(Object? value) {
    if (value is String) return value.trim();
    return '';
  }

  switch (type) {
    case 'nearbyPost':
    case 'interest':
    case 'comment':
    case 'comment_like':
    case 'postExpiring':
      final postId = (data['postId'] as String?)?.trim();
      if (postId == null || postId.isEmpty) {
        debugPrint('🔔 PushDeepLink: postId missing, fallback to home/notifications');
        router.go('/home?index=1');
        return;
      }
      goHomeThenPush('/post/$postId');
      return;

    case 'newMessage':
      final conversationId = (data['conversationId'] as String?)?.trim();
      if (conversationId == null || conversationId.isEmpty) {
        debugPrint('🔔 PushDeepLink: conversationId missing, fallback to home/messages');
        router.go('/home?index=3');
        return;
      }

      // Se o payload incluir metadados do outro participante, passe via query params.
      // Isso evita leituras extras e permite UI/guard mais imediatos.
      final otherProfileId = _trimString(data['otherProfileId'])
          .isNotEmpty
          ? _trimString(data['otherProfileId'])
          : _trimString(data['senderProfileId']);
      final otherUid = _trimString(data['otherUid']);
      final otherName = _trimString(data['otherName']);
      final otherPhotoUrl = _trimString(data['otherPhotoUrl']);

      final uri = Uri(
        path: '/chat-new/$conversationId',
        queryParameters: <String, String>{
          if (otherProfileId.isNotEmpty) 'otherProfileId': otherProfileId,
          if (otherUid.isNotEmpty) 'otherUid': otherUid,
          if (otherName.isNotEmpty) 'otherName': otherName,
          if (otherPhotoUrl.isNotEmpty) 'otherPhotoUrl': otherPhotoUrl,
        },
      );

      goHomeThenPush(uri.toString());
      return;

    default:
      // Fallback: abre home (com bottom nav) na aba de notificações.
      // Usar go('/notifications-new') diretamente fazia o BottomNavScaffold
      // ficar ausente, prendendo o usuário na tela sem navegação.
      debugPrint('🔔 PushDeepLink: unknown type="$type", fallback to home');
      router.go('/home?index=1');
      return;
  }
}
