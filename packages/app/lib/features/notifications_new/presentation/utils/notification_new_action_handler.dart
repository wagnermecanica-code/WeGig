/// WeGig - NotificationNew Action Handler
///
/// Handler centralizado para ações de notificações (deep links).
/// Implementa navegação baseada no tipo e actionType da notificação.
///
/// SINGLE SOURCE OF TRUTH para navegação de notificações.
library;

import 'package:core_ui/core_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wegig_app/core/firebase/blocked_relations.dart';
import 'package:wegig_app/features/mensagens_new/presentation/pages/chat_new_page.dart';
import 'package:wegig_app/features/notifications_new/data/services/push_notification_service.dart';
import 'package:wegig_app/features/notifications_new/domain/entities/notification_new_entity.dart';
import 'package:wegig_app/features/notifications_new/presentation/providers/notifications_new_providers.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';
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
    debugPrint('🔔 NotificationNewHandler: Handling ${notification.type.name}');
    debugPrint('   ActionType: ${notification.actionType?.name ?? 'null'}');
    debugPrint('   TargetId: ${notification.targetId ?? 'null'}');

    final router = GoRouter.of(context);
    final eventType =
        ((notification.actionData?['eventType'] ??
                    notification.data['eventType'])
                as String?)
            ?.trim();

    // 1. Marcar como lida (otimista - não bloqueia navegação)
    if (!notification.read) {
      _markAsReadAsync(notification.notificationId);
    }

    // Notificações da Minha Rede: abre a aba Minha Rede e empilha o perfil
    // do remetente para que o usuário veja o botão contextual
    // (Aceitar / Conectado / Cancelar convite).
    if (eventType == 'connectionRequest' || eventType == 'connectionAccepted') {
      final senderProfileId = (notification.senderProfileId ??
              notification.actionData?['connectionProfileId'] as String? ??
              notification.data['connectionProfileId'] as String? ??
              notification.actionData?['senderProfileId'] as String? ??
              notification.data['senderProfileId'] as String? ??
              '')
          .trim();
      debugPrint(
        '🔔 NotificationNewHandler: $eventType senderProfileId=$senderProfileId',
      );

      router.go('/home?index=1');
      if (senderProfileId.isEmpty) {
        return;
      }

      final allowed = await _canOpenProfile(senderProfileId);
      if (!allowed) {
        if (context.mounted) {
          AppSnackBar.showInfo(context, 'Perfil indisponível.');
        }
        return;
      }

      // Aguarda GoRouter trocar para /home antes de empilhar o perfil.
      // Usa delay em ambos plataformas para evitar race com BottomNavScaffold.
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!context.mounted) return;
      router.push('/profile/$senderProfileId');
      return;
    }

    // 2. Navegar baseado em actionType
    if (!context.mounted) return;

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
      final activeProfile = ref.read(activeProfileProvider);
      if (activeProfile == null) return;

      final useCase = ref.read(markNotificationAsReadNewUseCaseProvider);
      useCase(
        notificationId: notificationId,
        profileId: activeProfile.profileId,
      );

      // Mantém badge do ícone do app consistente com Firestore
      // (iOS pode manter badge antigo vindo do APNS se não sincronizarmos).
      PushNotificationService().updateAppBadge(
        activeProfile.profileId,
        activeProfile.uid,
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

    final allowed = await _canOpenProfile(profileId);
    if (!allowed) {
      if (context.mounted) {
        AppSnackBar.showInfo(context, 'Perfil indisponível.');
      }
      return true;
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
    final conversationId =
        notification.actionData?['conversationId'] as String? ??
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
    final isGroup =
        (notification.actionData?['isGroup'] as bool?) ??
            (notification.data['isGroup'] as bool?) ??
            false;
    final groupName =
        notification.actionData?['groupName'] as String? ??
            notification.data['groupName'] as String? ??
            '';
    final groupPhotoUrl =
        notification.actionData?['groupPhotoUrl'] as String? ??
            notification.data['groupPhotoUrl'] as String?;

    if (!isGroup && otherProfileId.trim().isNotEmpty) {
      final allowed = await _canOpenProfile(otherProfileId);
      if (!allowed) {
        if (context.mounted) {
          AppSnackBar.showInfo(context, 'Perfil indisponível.');
        }
        return true;
      }
    }

    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ChatNewPage(
          conversationId: conversationId,
          otherUid: otherUserId,
          otherProfileId: otherProfileId,
          otherName: isGroup && groupName.trim().isNotEmpty
              ? groupName
              : otherUserName,
          otherPhotoUrl: otherUserPhoto,
          isGroup: isGroup,
          groupPhotoUrl: groupPhotoUrl,
        ),
      ),
    );

    debugPrint('✅ NotificationNewHandler: Navigated to chat $conversationId');
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
    final postId =
        notification.targetId ?? notification.data['postId'] as String?;

    if (postId == null || postId.isEmpty) {
      debugPrint('⚠️ NotificationNewHandler: No postId for renewPost');
      return false;
    }

    // TODO: Implementar navegação para tela de renovação quando existir
    // Por enquanto, navega para o post
    if (!context.mounted) return false;

    GoRouter.of(context).push('/post/$postId');
    debugPrint(
        '✅ NotificationNewHandler: Navigated to post $postId (renewPost)');
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

    if (route.startsWith('/home')) {
      router.go(route);
    } else {
      router.push(route);
    }
    debugPrint('✅ NotificationNewHandler: Navigated to route $route');
    return true;
  }

  /// Fallback: tenta inferir destino do tipo de notificação
  Future<bool> _handleFallbackByType(
      NotificationEntity notification, GoRouter router) async {
    debugPrint(
        '🔔 NotificationNewHandler: Trying fallback for ${notification.type.name}');

    final eventType =
        ((notification.actionData?['eventType'] ?? notification.data['eventType'])
                as String?)
            ?.trim();

    if (eventType == 'connectionRequest' ||
        eventType == 'connectionAccepted') {
      router.go('/home?index=1');
      return true;
    }

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
        if (profileId != null && profileId.isNotEmpty) {
          return _handleViewProfile(notification);
        }

      // Mensagens: abre chat
      case NotificationType.newMessage:
        return _handleOpenChat(notification);

      // Comentários e curtidas de comentários: navega para post
      case NotificationType.comment:
      case NotificationType.commentLike:

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
        debugPrint(
            'ℹ️ NotificationNewHandler: System notification - no action');
    }

    return false;
  }

  Future<bool> _canOpenProfile(String otherProfileId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final activeProfile = ref.read(activeProfileProvider);

    final uid = currentUser?.uid.trim() ?? '';
    final me = activeProfile?.profileId.trim() ?? '';
    final other = otherProfileId.trim();

    if (uid.isEmpty || me.isEmpty || other.isEmpty) return true;
    if (other == me) return true;

    try {
      final excluded = await BlockedRelations.getExcludedProfileIds(
        firestore: FirebaseFirestore.instance,
        profileId: me,
        uid: uid,
      );
      return !excluded.contains(other);
    } catch (e) {
      debugPrint(
          '⚠️ NotificationNewHandler: _canOpenProfile error (non-blocking): $e');
      return true;
    }
  }
}
