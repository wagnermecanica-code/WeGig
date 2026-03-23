/// WeGig - NotificationsNew Controller
///
/// Controller AsyncNotifier para gerenciar estado da lista de notificações.
/// Implementa paginação infinita, refresh e operações CRUD.
///
/// Features:
/// - Paginação cursor-based com hasMore flag
/// - Loading states granulares (initial, loadingMore)
/// - Atualização otimista (UI atualiza antes do backend)
/// - Multi-perfil com profileId obrigatório
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wegig_app/features/notifications_new/domain/entities/notification_new_entity.dart';
import 'package:wegig_app/features/notifications_new/data/services/push_notification_service.dart';
import 'package:wegig_app/features/notifications_new/presentation/providers/notifications_new_providers.dart';
import 'package:wegig_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';

part 'notifications_new_controller.freezed.dart';
part 'notifications_new_controller.g.dart';

/// Estado do controller de notificações
///
/// Usa Freezed para imutabilidade e copyWith automático.
@freezed
class NotificationsNewState with _$NotificationsNewState {
  /// Construtor factory com valores default
  const factory NotificationsNewState({
    /// Lista de notificações carregadas
    @Default([]) List<NotificationEntity> notifications,

    /// Flag indicando se há mais páginas para carregar
    @Default(true) bool hasMore,

    /// Flag indicando se está carregando mais itens (paginação)
    @Default(false) bool isLoadingMore,

    /// Mensagem de erro (se houver)
    String? errorMessage,
  }) = _NotificationsNewState;
}

/// Controller para lista de notificações com paginação
///
/// Parâmetros do build():
/// - [profileId] - ID do perfil ativo (obrigatório)
/// - [type] - Filtro por tipo (null = todas, interest = apenas interesses)
///
/// Exemplo:
/// ```dart
/// // Todas as notificações
/// final allNotifs = ref.watch(notificationsNewControllerProvider(profileId));
///
/// // Apenas interesses
/// final interests = ref.watch(
///   notificationsNewControllerProvider(profileId, type: NotificationType.interest),
/// );
/// ```
@riverpod
class NotificationsNewController extends _$NotificationsNewController {
  /// Tamanho da página para paginação
  static const int _pageSize = 20;

  @override
  FutureOr<NotificationsNewState> build(
    String profileId, {
    NotificationType? type,
  }) async {
    // Obter UID do usuário autenticado para Security Rules
    // (Evita mismatch durante troca de perfil/conta)
    final recipientUid = ref.read(currentUserProvider)?.uid;

    debugPrint(
        '🔔 NotificationsNewController: build() - profileId=$profileId, uid=$recipientUid, type=${type?.name ?? 'all'}');

    if (recipientUid == null) {
      debugPrint(
          '⚠️ NotificationsNewController: recipientUid is null (not authenticated?)');
      return const NotificationsNewState(hasMore: false);
    }

    try {
      // Carregamento inicial via use case
      final useCase = ref.watch(loadNotificationsNewUseCaseProvider);
      final notifications = await useCase(
        profileId: profileId,
        recipientUid: recipientUid,
        type: type,
        limit: _pageSize,
      );

      debugPrint(
          '✅ NotificationsNewController: Loaded ${notifications.length} notifications');

      return NotificationsNewState(
        notifications: notifications,
        hasMore: notifications.length >= _pageSize,
        isLoadingMore: false,
      );
    } catch (e, stack) {
      debugPrint('❌ NotificationsNewController: Error loading - $e');
      debugPrintStack(stackTrace: stack);
      return NotificationsNewState(
        hasMore: false,
        errorMessage: 'Erro ao carregar notificações: $e',
      );
    }
  }

  /// Carrega mais notificações (paginação infinita)
  ///
  /// Chamado automaticamente pelo scroll listener quando usuário
  /// chega a 80% do fim da lista.
  Future<void> loadMore() async {
    final currentState = state.valueOrNull;

    // Guards: não carrega se já carregando, sem mais páginas, ou lista vazia
    if (currentState == null ||
        !currentState.hasMore ||
        currentState.isLoadingMore ||
        currentState.notifications.isEmpty) {
      return;
    }

    // Se o perfil ativo mudou desde que este controller foi criado, não continue.
    final activeProfileId = ref.read(activeProfileProvider)?.profileId;
    if (activeProfileId != profileId) return;

    // Obter UID do usuário autenticado (Security Rules)
    final recipientUid = ref.read(currentUserProvider)?.uid;
    if (recipientUid == null) return;

    debugPrint('🔔 NotificationsNewController: loadMore');

    // Atualiza estado para loading more
    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

    try {
      final useCase = ref.read(loadNotificationsNewUseCaseProvider);
      final lastNotification = currentState.notifications.last;

      final newNotifications = await useCase(
        profileId: profileId,
        recipientUid: recipientUid,
        type: type,
        limit: _pageSize,
        startAfter: lastNotification,
      );

      debugPrint(
          '✅ NotificationsNewController: loadMore got ${newNotifications.length} items');

      // Atualiza estado com novos itens
      state = AsyncValue.data(currentState.copyWith(
        notifications: [...currentState.notifications, ...newNotifications],
        hasMore: newNotifications.length >= _pageSize,
        isLoadingMore: false,
      ));
    } catch (e) {
      debugPrint('❌ NotificationsNewController: loadMore error - $e');
      // Reverte loading state em caso de erro
      state = AsyncValue.data(currentState.copyWith(isLoadingMore: false));
    }
  }

  /// Recarrega a lista (pull-to-refresh)
  ///
  /// Invalida o provider e aguarda reconstrução completa.
  Future<void> refresh() async {
    debugPrint('🔔 NotificationsNewController: refresh');
    state = const AsyncValue.loading();
    ref.invalidateSelf();
    await future;
  }

  /// Marca uma notificação como lida (atualização otimista)
  ///
  /// Atualiza a UI imediatamente e depois persiste no backend.
  /// Em caso de erro, a UI já está atualizada (fire-and-forget).
  Future<void> markAsRead(String notificationId) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    debugPrint('🔔 NotificationsNewController: markAsRead $notificationId');

    // Atualização otimista - atualiza UI antes do backend
    final updatedList = currentState.notifications.map((n) {
      if (n.notificationId == notificationId) {
        return n.copyWith(read: true, readAt: DateTime.now());
      }
      return n;
    }).toList();

    state = AsyncValue.data(currentState.copyWith(notifications: updatedList));

    // Persistir no backend (fire-and-forget)
    try {
      final useCase = ref.read(markNotificationAsReadNewUseCaseProvider);
      await useCase(
        notificationId: notificationId,
        profileId: profileId,
      );

      // Atualizar badge do ícone do app baseado no Firestore (fonte da verdade)
      final recipientUid = ref.read(currentUserProvider)?.uid;
      if (recipientUid != null) {
        await PushNotificationService().updateAppBadge(profileId, recipientUid);
      }
    } catch (e) {
      debugPrint(
          '⚠️ NotificationsNewController: markAsRead backend error - $e');
      // Não reverte UI - atualização otimista permanece
    }
  }

  /// Deleta uma notificação (atualização otimista)
  ///
  /// Remove da lista local imediatamente e depois persiste no backend.
  Future<void> deleteNotification(String notificationId) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    debugPrint(
        '🔔 NotificationsNewController: deleteNotification $notificationId');

    // Atualização otimista - remove da lista antes do backend
    final updatedList = currentState.notifications
        .where((n) => n.notificationId != notificationId)
        .toList();

    state = AsyncValue.data(currentState.copyWith(notifications: updatedList));

    // Persistir no backend
    try {
      final useCase = ref.read(deleteNotificationNewUseCaseProvider);
      await useCase(
        notificationId: notificationId,
        profileId: profileId,
      );
    } catch (e) {
      debugPrint(
          '⚠️ NotificationsNewController: deleteNotification backend error - $e');
      // Não reverte UI - item já foi removido visualmente
    }
  }

  /// Marca todas as notificações como lidas
  ///
  /// Atualiza toda a lista local e depois persiste no backend.
  Future<void> markAllAsRead() async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    // Se o perfil ativo mudou desde que este controller foi criado, não continue.
    final activeProfileId = ref.read(activeProfileProvider)?.profileId;
    if (activeProfileId != profileId) return;

    // Obter UID do usuário autenticado (Security Rules)
    final recipientUid = ref.read(currentUserProvider)?.uid;
    if (recipientUid == null) return;

    debugPrint('🔔 NotificationsNewController: markAllAsRead');

    // Atualização otimista - marca todas como lidas localmente
    final now = DateTime.now();
    final updatedList = currentState.notifications.map((n) {
      if (!n.read) {
        return n.copyWith(read: true, readAt: now);
      }
      return n;
    }).toList();

    state = AsyncValue.data(currentState.copyWith(notifications: updatedList));

    // Persistir no backend
    try {
      final useCase = ref.read(markAllNotificationsAsReadNewUseCaseProvider);
      await useCase(
        profileId: profileId,
        recipientUid: recipientUid,
      );

      // Atualizar badge do ícone do app (remove se 0)
      await PushNotificationService().updateAppBadge(profileId, recipientUid);
    } catch (e) {
      debugPrint(
          '⚠️ NotificationsNewController: markAllAsRead backend error - $e');
    }
  }
}
