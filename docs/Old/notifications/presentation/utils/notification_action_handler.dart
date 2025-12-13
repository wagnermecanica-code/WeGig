// WEGIG – NOTIFICATION ACTION HANDLER (2025)
// Arquitetura: Clean Architecture - Presentation Layer Utility
// Handler centralizado para ações de notificações (SINGLE SOURCE OF TRUTH)
// Usado por: NotificationsModal e NotificationItem

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wegig_app/features/mensagens_new/presentation/pages/chat_new_page.dart';
import 'package:wegig_app/features/notifications/domain/services/notification_service.dart';
import 'package:wegig_app/features/profile/presentation/pages/view_profile_page.dart';

/// Handler centralizado para ações de notificações
/// 
/// ✅ SINGLE SOURCE OF TRUTH: Usado por NotificationsModal e NotificationItem
/// ✅ Segue padrão WeGig de Clean Architecture
class NotificationActionHandler {
  NotificationActionHandler({
    required this.ref,
    required this.context,
  });

  final WidgetRef ref;
  final BuildContext context;

  /// Executa ação de notificação com marca como lida automática
  Future<void> handle(NotificationEntity notification) async {
    debugPrint('🔔 NotificationHandler: Executando ação ${notification.actionType?.name ?? 'undefined'} para notificação ${notification.notificationId}');
    debugPrint('   - Tipo: ${notification.type.name}');
    debugPrint('   - Destino: ${notification.targetId ?? 'null'}');
    debugPrint('   - ActionData: ${notification.actionData?.keys.join(', ') ?? 'vazio'}');

    // 1. Marcar como lida (otimista)
    if (!notification.read) {
      try {
        await ref
            .read(notificationServiceProvider)
            .markAsRead(notification.notificationId);
        debugPrint('✅ NotificationHandler: Notificação marcada como lida');
      } catch (e) {
        debugPrint('⚠️ NotificationHandler: Erro ao marcar como lida: $e');
        // Não bloqueia navegação
      }
    }

    // 2. Executar ação baseada em actionType
    if (!context.mounted) return;

    final router = GoRouter.of(context);
    bool handledNavigation = false;

    switch (notification.actionType) {
      case NotificationActionType.viewProfile:
        handledNavigation = await _handleViewProfile(notification);
        break;

      case NotificationActionType.openChat:
        handledNavigation = await _handleOpenChat(notification);
        break;

      case NotificationActionType.viewPost:
        handledNavigation = await _handleViewPost(notification, router);
        break;

      case NotificationActionType.renewPost:
        handledNavigation = await _handleRenewPost(notification);
        break;

      case NotificationActionType.navigate:
        // Genérico - ler actionData['route']
        final route = notification.actionRoute;
        if (route != null && context.mounted) {
          router.push(route);
          handledNavigation = true;
          debugPrint('✅ NotificationHandler: Navegado para rota genérica $route');
        }
        break;

      case NotificationActionType.none:
      case null:
        // Sem ação definida - ignorar
        debugPrint('⚠️ NotificationHandler: Sem actionType definido');
        break;
    }

    // 3. Fallback: Se não navegou via actionType, tentar targetId
    if (!handledNavigation && context.mounted) {
      await _handleFallbackNavigation(notification, router);
    }
  }

  /// Abre perfil de usuário
  Future<bool> _handleViewProfile(NotificationEntity notification) async {
    final userId = notification.actionUserId;
    final profileId = notification.actionProfileId;

    debugPrint('🔔 NotificationHandler: Abrindo perfil - userId=$userId, profileId=$profileId');

    if (userId != null && context.mounted) {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ViewProfilePage(
            userId: userId,
            profileId: profileId ?? userId,
          ),
        ),
      );
      debugPrint('✅ NotificationHandler: Navegado para perfil $profileId');
      return true;
    }
    
    debugPrint('⚠️ NotificationHandler: Falha ao abrir perfil - userId null');
    return false;
  }

  /// Abre chat
  Future<bool> _handleOpenChat(NotificationEntity notification) async {
    final conversationId = notification.actionConversationId;
    final otherUserId = notification.actionOtherUserId;
    final otherProfileId = notification.actionOtherProfileId;
    final otherUserName = notification.senderName ?? 'Usuário';
    final otherUserPhoto = notification.senderPhoto ?? '';

    debugPrint('🔔 NotificationHandler: Abrindo chat - conversationId=$conversationId');

    if (conversationId != null &&
        otherUserId != null &&
        otherProfileId != null &&
        context.mounted) {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ChatNewPage(
            conversationId: conversationId,
            otherUid: otherUserId,
            otherProfileId: otherProfileId,
            otherName: otherUserName,
            otherPhotoUrl: otherUserPhoto,
          ),
        ),
      );
      debugPrint('✅ NotificationHandler: Navegado para chat $conversationId');
      return true;
    }
    
    debugPrint('⚠️ NotificationHandler: Falha ao abrir chat - conversationId null');
    return false;
  }

  /// Abre detalhes do post
  Future<bool> _handleViewPost(
    NotificationEntity notification,
    GoRouter router,
  ) async {
    final postId = notification.actionPostId;

    debugPrint('🔔 NotificationHandler: Abrindo post - postId=$postId');

    if (postId != null && context.mounted) {
      router.push('/post/$postId');
      debugPrint('✅ NotificationHandler: Navegado para post $postId');
      return true;
    }
    
    debugPrint('⚠️ NotificationHandler: Falha ao abrir post - postId null');
    return false;
  }

  /// Renova post (adiciona +30 dias)
  Future<bool> _handleRenewPost(NotificationEntity notification) async {
    final postId = notification.actionPostId;

    debugPrint('🔔 NotificationHandler: Renovando post - postId=$postId');

    if (postId == null) {
      debugPrint('⚠️ NotificationHandler: Falha ao renovar - postId null');
      return false;
    }

    try {
      final now = DateTime.now();
      final newExpiresAt = now.add(const Duration(days: 30));

      await FirebaseFirestore.instance.collection('posts').doc(postId).update({
        'expiresAt': Timestamp.fromDate(newExpiresAt),
        'renewedAt': Timestamp.now(),
        'renewCount': FieldValue.increment(1),
      });

      if (context.mounted) {
        AppSnackBar.showSuccess(
          context,
          'Post renovado por mais 30 dias! 🎉',
        );
      }

      debugPrint('✅ NotificationHandler: Post renovado com sucesso');
      return true;
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context, 'Erro ao renovar: $e');
      }
      debugPrint('❌ NotificationHandler: Erro ao renovar post: $e');
      return false;
    }
  }

  /// Navegação fallback baseada em tipo de notificação
  Future<void> _handleFallbackNavigation(
    NotificationEntity notification,
    GoRouter router,
  ) async {
    debugPrint('🔔 NotificationHandler: Tentando fallback para tipo ${notification.type.name}');

    switch (notification.type) {
      case NotificationType.interest:
      case NotificationType.nearbyPost:
      case NotificationType.postExpiring:
        final postId = notification.targetId;
        if (postId != null) {
          router.push('/post/$postId');
          debugPrint('✅ NotificationHandler: Fallback navegou para post $postId');
        }
        break;

      case NotificationType.newMessage:
        // Tentar abrir chat via dados da notificação
        final success = await _handleOpenChat(notification);
        if (success) {
          debugPrint('✅ NotificationHandler: Fallback abriu chat');
        }
        break;

      case NotificationType.profileView:
      case NotificationType.profileMatch:
        // Tentar abrir perfil via senderUid
        final success = await _handleViewProfile(notification);
        if (success) {
          debugPrint('✅ NotificationHandler: Fallback abriu perfil');
        }
        break;

      default:
        debugPrint(
          '⚠️ NotificationHandler: Sem ação definida para tipo ${notification.type}',
        );
    }
  }
}
