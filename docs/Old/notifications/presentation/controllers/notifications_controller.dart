import 'package:core_ui/features/notifications/domain/entities/notification_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wegig_app/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';

part 'notifications_controller.g.dart';

/// Estado do controller de notificações
class NotificationsState {
  final List<NotificationEntity> notifications;
  final bool hasMore;
  final bool isLoadingMore;

  const NotificationsState({
    this.notifications = const [],
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  NotificationsState copyWith({
    List<NotificationEntity>? notifications,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Controller para gerenciar lista de notificações e paginação
@riverpod
class NotificationsController extends _$NotificationsController {
  @override
  FutureOr<NotificationsState> build(
    String profileId, {
    NotificationType? type,
  }) async {
    // Obter UID do perfil ativo para Security Rules
    final activeProfile = ref.read(activeProfileProvider);
    final recipientUid = activeProfile?.uid;

    if (recipientUid == null) {
      return const NotificationsState(hasMore: false);
    }

    // Carregamento inicial
    final repository = ref.watch(notificationsRepositoryNewProvider);
    final notifications = await repository.getNotifications(
      profileId: profileId,
      recipientUid: recipientUid,
      type: type,
      limit: 20,
    );

    return NotificationsState(
      notifications: notifications,
      hasMore: notifications.length >= 20,
      isLoadingMore: false,
    );
  }

  /// Carrega mais notificações (paginação)
  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null ||
        !currentState.hasMore ||
        currentState.isLoadingMore) {
      return;
    }

    // Obter UID
    final activeProfile = ref.read(activeProfileProvider);
    final recipientUid = activeProfile?.uid;
    if (recipientUid == null) return;

    // Atualiza estado para loading more
    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

    try {
      final repository = ref.read(notificationsRepositoryNewProvider);
      final lastNotification = currentState.notifications.last;

      final newNotifications = await repository.getNotifications(
        profileId: profileId,
        recipientUid: recipientUid,
        type: type,
        limit: 20,
        startAfter: lastNotification,
      );

      // Atualiza estado com novos itens
      state = AsyncValue.data(currentState.copyWith(
        notifications: [...currentState.notifications, ...newNotifications],
        hasMore: newNotifications.length >= 20,
        isLoadingMore: false,
      ));
    } catch (e, stack) {
      debugPrint('❌ NotificationsController: Erro ao carregar mais: $e');
      // Reverte loading more em caso de erro, mantendo lista atual
      state = AsyncValue.data(currentState.copyWith(isLoadingMore: false));
    }
  }

  /// Recarrega a lista (pull-to-refresh)
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    ref.invalidateSelf();
    await future;
  }

  /// Marca uma notificação como lida localmente e no backend
  Future<void> markAsRead(String notificationId) async {
    final currentState = state.value;
    if (currentState == null) return;

    // Atualização otimista
    final updatedList = currentState.notifications.map((n) {
      if (n.notificationId == notificationId) {
        return n.copyWith(read: true);
      }
      return n;
    }).toList();

    state = AsyncValue.data(currentState.copyWith(notifications: updatedList));

    try {
      final repository = ref.read(notificationsRepositoryNewProvider);
      await repository.markAsRead(notificationId: notificationId, profileId: profileId);
    } catch (e) {
      debugPrint('❌ NotificationsController: Erro ao marcar como lida: $e');
    }
  }
}
