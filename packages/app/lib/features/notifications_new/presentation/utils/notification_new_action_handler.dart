/// WeGig - NotificationNew Action Handler
///
/// Handler centralizado para ações de notificações (deep links).
/// Implementa navegação baseada no tipo e actionType da notificação.
///
/// SINGLE SOURCE OF TRUTH para navegação de notificações.
library;

import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wegig_app/features/mensagens_new/presentation/pages/chat_new_page.dart';
import 'package:wegig_app/features/notifications_new/domain/entities/notification_new_entity.dart';
import 'package:wegig_app/features/notifications_new/presentation/providers/notifications_new_providers.dart';
import 'package:wegig_app/features/profile/presentation/pages/view_profile_page.dart';

/// Handler centralizado para ações de notificações
///
/// Responsável por:
/// - Marcar notificação como lida ao interagir
/// - Navegar para destino correto baseado em actionType
/// - Tratar fallbacks quando destino não existe
///
/// Exemplo:
/// ```dart
/// final handler = NotificationNewActionHandler(ref: ref, context: context);
/// await handler.handle(notification);
/// ```
class NotificationNewActionHandler {
  /// Cria o handler com referências necessárias
  NotificationNewActionHandler({
    required this.ref,
    required this.context,
  });

  /// Referência ao Riverpod para acessar providers
  final WidgetRef ref;

  /// BuildContext para navegação
  final BuildContext context;

  /// Executa ação da notificação
  ///
  /// 1. Marca como lida (se ainda não estiver)
  /// 2. Navega para destino baseado em actionType
  Future<void> handle(NotificationEntity notification) async {
    debugPrint(
        '🔔 NotificationNewHandler: Handling ${notification.type.name}');
    debugPrint('   ActionType: ${notification.actionType?.name ?? 'null'}');
    debugPrint('   TargetId: ${notification.targetId ?? 'null'}');

    // 1. Marcar como lida (otimista - não bloqueia navegação)
    if (!notification.read) {
      _markAsReadAsync(notification.notificationId);
    }

    // 2. Navegar baseado em actionType
    if (!context.mounted) return;

    final router = GoRouter.of(context);
    var handled = false;

    switch (notification.actionType) {
      case NotificationActionType.viewProfile:
        handled = await _handleViewProfile(notification);

      case NotificationActionType.openChat:
        handled = await _handleOpenChat(notification);

      case NotificationActionType.viewPost:
        handled = _handleViewPost(notification, router);

      case NotificationActionType.renewPost:
        handled = await _handleRenewPost(notification);

      case NotificationActionType.navigate:
        handled = _handleGenericNavigate(notification, router);

      case NotificationActionType.none:
      case null:
        debugPrint('⚠️ NotificationNewHandler: No action defined');
    }

    // 3. Fallback: tentar inferir destino do tipo
    if (!handled) {
      handled = await _handleFallbackByType(notification, router);
    }

    if (!handled) {
      debugPrint('⚠️ NotificationNewHandler: Could not handle notification');
    }
  }

  /// Marca como lida de forma assíncrona (fire-and-forget)
  void _markAsReadAsync(String notificationId) {
    try {
      final useCase = ref.read(markNotificationAsReadNewUseCaseProvider);
      useCase(
        notificationId: notificationId,
        profileId: '', // profileId não é usado no markAsRead atual
      );
      debugPrint('✅ NotificationNewHandler: Marked as read');
    } catch (e) {
      debugPrint('⚠️ NotificationNewHandler: markAsRead error - $e');
    }
  }

  /// Navega para perfil do remetente
  Future<bool> _handleViewProfile(NotificationEntity notification) async {
    final profileId = notification.senderProfileId ?? notification.targetId;

    if (profileId == null || profileId.isEmpty) {
      debugPrint('⚠️ NotificationNewHandler: No profileId for viewProfile');
      return false;
    }

    if (!context.mounted) return false;

    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ViewProfilePage(profileId: profileId),
      ),
    );

    debugPrint('✅ NotificationNewHandler: Navigated to profile $profileId');
    return true;
  }

  /// Abre chat com o remetente
  Future<bool> _handleOpenChat(NotificationEntity notification) async {
    // Tenta obter conversationId de actionData ou data
    final conversationId = notification.actionData?['conversationId'] as String? ??
        notification.data['conversationId'] as String?;

    if (conversationId == null || conversationId.isEmpty) {
      debugPrint('⚠️ NotificationNewHandler: No conversationId for openChat');
      return false;
    }

    if (!context.mounted) return false;

    // Obtém dados adicionais do remetente
    final otherUserId = notification.senderUid ?? '';
    final otherProfileId = notification.senderProfileId ?? '';
    final otherUserName = notification.senderName ?? '';
    final otherUserPhoto = notification.senderPhoto ?? '';

    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ChatNewPage(
          conversationId: conversationId,
          otherUid: otherUserId,
          otherProfileId: otherProfileId,
          otherName: otherUserName,
          otherPhotoUrl: otherUserPhoto,
        ),
      ),
    );

    debugPrint(
        '✅ NotificationNewHandler: Navigated to chat $conversationId');
    return true;
  }

  /// Abre detalhe do post
  bool _handleViewPost(NotificationEntity notification, GoRouter router) {
    final postId = notification.targetId ??
        notification.actionData?['postId'] as String? ??
        notification.data['postId'] as String?;

    if (postId == null || postId.isEmpty) {
      debugPrint('⚠️ NotificationNewHandler: No postId for viewPost');
      return false;
    }

    router.push('/post/$postId');
    debugPrint('✅ NotificationNewHandler: Navigated to post $postId');
    return true;
  }

  /// Abre tela de renovação de post
  Future<bool> _handleRenewPost(NotificationEntity notification) async {
    final postId = notification.targetId ??
        notification.data['postId'] as String?;

    if (postId == null || postId.isEmpty) {
      debugPrint('⚠️ NotificationNewHandler: No postId for renewPost');
      return false;
    }

    // TODO: Implementar navegação para tela de renovação quando existir
    // Por enquanto, navega para o post
    if (!context.mounted) return false;

    GoRouter.of(context).push('/post/$postId');
    debugPrint('✅ NotificationNewHandler: Navigated to post $postId (renewPost)');
    return true;
  }

  /// Navegação genérica por rota
  bool _handleGenericNavigate(
      NotificationEntity notification, GoRouter router) {
    final route = notification.actionRoute;

    if (route == null || route.isEmpty) {
      debugPrint('⚠️ NotificationNewHandler: No route for navigate');
      return false;
    }

    router.push(route);
    debugPrint('✅ NotificationNewHandler: Navigated to route $route');
    return true;
  }

  /// Fallback: tenta inferir destino do tipo de notificação
  Future<bool> _handleFallbackByType(
      NotificationEntity notification, GoRouter router) async {
    debugPrint(
        '🔔 NotificationNewHandler: Trying fallback for ${notification.type.name}');

    switch (notification.type) {
      // Interesses: navega para post ou perfil do interessado
      case NotificationType.interest:
      case NotificationType.interestResponse:
        final postId = notification.data['postId'] as String?;
        if (postId != null && postId.isNotEmpty) {
          router.push('/post/$postId');
          return true;
        }
        final profileId = notification.senderProfileId;
        if (profileId != null && profileId.isNotEmpty && context.mounted) {
          Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => ViewProfilePage(profileId: profileId),
            ),
          );
          return true;
        }

      // Mensagens: abre chat
      case NotificationType.newMessage:
        return _handleOpenChat(notification);

      // Posts: navega para post
      case NotificationType.nearbyPost:
      case NotificationType.postExpiring:
      case NotificationType.postUpdated:
      case NotificationType.savedPost:
        final postId = notification.data['postId'] as String?;
        if (postId != null && postId.isNotEmpty) {
          router.push('/post/$postId');
          return true;
        }

      // Perfil: navega para perfil
      case NotificationType.profileMatch:
      case NotificationType.profileView:
        return _handleViewProfile(notification);

      // Sistema: sem ação padrão
      case NotificationType.system:
        debugPrint('ℹ️ NotificationNewHandler: System notification - no action');
    }

    return false;
  }
}
