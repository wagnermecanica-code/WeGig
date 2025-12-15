/// WeGig - NotificationsNew Repository Interface
///
/// Interface abstrata do repositório de notificações seguindo Clean Architecture.
/// A camada de domínio define o contrato, a camada de dados implementa.
///
/// Features:
/// - Paginação cursor-based com startAfter
/// - Filtro por tipo de notificação
/// - Multi-perfil obrigatório (profileId + recipientUid)
/// - Streams para real-time updates
library;

import 'package:wegig_app/features/notifications_new/domain/entities/notification_new_entity.dart';

/// Interface abstrata do repositório de notificações
///
/// Todas as operações requerem [profileId] para isolamento multi-perfil.
/// Operações de leitura também requerem [recipientUid] para match com Security Rules.
abstract class NotificationsNewRepository {
  /// Busca notificações paginadas de um perfil
  ///
  /// [profileId] - ID do perfil ativo (obrigatório)
  /// [recipientUid] - UID do Firebase Auth (obrigatório para Security Rules)
  /// [type] - Filtro por tipo (null = todas)
  /// [limit] - Quantidade por página (default: 20)
  /// [startAfter] - Cursor para paginação (última notificação da página anterior)
  ///
  /// Retorna lista de [NotificationEntity] ordenada por createdAt DESC
  Future<List<NotificationEntity>> getNotifications({
    required String profileId,
    required String recipientUid,
    NotificationType? type,
    int limit = 20,
    NotificationEntity? startAfter,
  });

  /// Busca uma notificação específica por ID
  ///
  /// [notificationId] - ID da notificação
  /// [profileId] - ID do perfil para validação de permissão
  ///
  /// Retorna null se não encontrada ou sem permissão
  Future<NotificationEntity?> getNotificationById({
    required String notificationId,
    required String profileId,
  });

  /// Marca uma notificação como lida
  ///
  /// [notificationId] - ID da notificação
  /// [profileId] - ID do perfil para validação de permissão
  Future<void> markAsRead({
    required String notificationId,
    required String profileId,
  });

  /// Marca todas as notificações do perfil como lidas
  ///
  /// [profileId] - ID do perfil
  /// [recipientUid] - UID do Firebase Auth para Security Rules
  Future<void> markAllAsRead({
    required String profileId,
    required String recipientUid,
  });

  /// Deleta uma notificação
  ///
  /// [notificationId] - ID da notificação
  /// [profileId] - ID do perfil para validação de permissão
  Future<void> deleteNotification({
    required String notificationId,
    required String profileId,
  });

  /// Conta notificações não lidas
  ///
  /// [profileId] - ID do perfil
  /// [recipientUid] - UID do Firebase Auth para Security Rules
  Future<int> getUnreadCount({
    required String profileId,
    required String recipientUid,
  });

  /// Stream de notificações em tempo real
  ///
  /// [profileId] - ID do perfil
  /// [recipientUid] - UID do Firebase Auth para Security Rules
  /// [limit] - Limite de notificações (default: 50)
  Stream<List<NotificationEntity>> watchNotifications({
    required String profileId,
    required String recipientUid,
    int limit = 50,
  });

  /// Stream de contador de não lidas em tempo real
  ///
  /// Usado para badge no BottomNavigation
  ///
  /// [profileId] - ID do perfil
  /// [recipientUid] - UID do Firebase Auth para Security Rules
  Stream<int> watchUnreadCount({
    required String profileId,
    required String recipientUid,
  });
}
