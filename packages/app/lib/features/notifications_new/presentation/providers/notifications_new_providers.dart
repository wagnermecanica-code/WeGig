/// WeGig - NotificationsNew Providers
///
/// Providers Riverpod para injeção de dependências da feature de notificações.
/// Seguem Clean Architecture: DataSource → Repository → UseCases → Controllers
///
/// Uso:
/// ```dart
/// final notifications = ref.watch(notificationsNewControllerProvider(profileId));
/// ```
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wegig_app/features/notifications_new/data/datasources/notifications_new_remote_datasource.dart';
import 'package:wegig_app/features/notifications_new/data/repositories/notifications_new_repository_impl.dart';
import 'package:wegig_app/features/notifications_new/domain/entities/notification_new_entity.dart';
import 'package:wegig_app/features/notifications_new/domain/repositories/notifications_new_repository.dart';
import 'package:wegig_app/features/notifications_new/domain/usecases/delete_notification_new.dart';
import 'package:wegig_app/features/notifications_new/domain/usecases/get_unread_count_new.dart';
import 'package:wegig_app/features/notifications_new/domain/usecases/load_notifications_new.dart';
import 'package:wegig_app/features/notifications_new/domain/usecases/mark_all_notifications_as_read_new.dart';
import 'package:wegig_app/features/notifications_new/domain/usecases/mark_notification_as_read_new.dart';

part 'notifications_new_providers.g.dart';

// ============================================================================
// DATA LAYER PROVIDERS
// ============================================================================

/// Provider para o DataSource de notificações
///
/// Singleton gerenciado pelo Riverpod, descartado automaticamente quando
/// não há mais listeners.
@riverpod
INotificationsNewRemoteDataSource notificationsNewRemoteDataSource(Ref ref) {
  return NotificationsNewRemoteDataSource();
}

/// Provider para o Repository de notificações
///
/// Injeta o DataSource automaticamente via ref.watch.
@riverpod
NotificationsNewRepository notificationsNewRepository(Ref ref) {
  final dataSource = ref.watch(notificationsNewRemoteDataSourceProvider);
  return NotificationsNewRepositoryImpl(remoteDataSource: dataSource);
}

// ============================================================================
// USE CASE PROVIDERS
// ============================================================================

/// Provider para LoadNotificationsNewUseCase
@riverpod
LoadNotificationsNewUseCase loadNotificationsNewUseCase(Ref ref) {
  final repository = ref.watch(notificationsNewRepositoryProvider);
  return LoadNotificationsNewUseCase(repository);
}

/// Provider para MarkNotificationAsReadNewUseCase
@riverpod
MarkNotificationAsReadNewUseCase markNotificationAsReadNewUseCase(Ref ref) {
  final repository = ref.watch(notificationsNewRepositoryProvider);
  return MarkNotificationAsReadNewUseCase(repository);
}

/// Provider para MarkAllNotificationsAsReadNewUseCase
@riverpod
MarkAllNotificationsAsReadNewUseCase markAllNotificationsAsReadNewUseCase(
    Ref ref) {
  final repository = ref.watch(notificationsNewRepositoryProvider);
  return MarkAllNotificationsAsReadNewUseCase(repository);
}

/// Provider para DeleteNotificationNewUseCase
@riverpod
DeleteNotificationNewUseCase deleteNotificationNewUseCase(Ref ref) {
  final repository = ref.watch(notificationsNewRepositoryProvider);
  return DeleteNotificationNewUseCase(repository);
}

/// Provider para GetUnreadCountNewUseCase
@riverpod
GetUnreadCountNewUseCase getUnreadCountNewUseCase(Ref ref) {
  final repository = ref.watch(notificationsNewRepositoryProvider);
  return GetUnreadCountNewUseCase(repository);
}

// ============================================================================
// STREAM PROVIDERS FOR REAL-TIME UPDATES
// ============================================================================

/// Stream de notificações em tempo real para um perfil
///
/// Requer profileId E recipientUid para match com Security Rules.
/// Invalida automaticamente quando perfil muda.
@riverpod
Stream<List<NotificationEntity>> notificationsNewStream(
  Ref ref,
  String profileId,
  String recipientUid,
) {
  final repository = ref.watch(notificationsNewRepositoryProvider);
  return repository.watchNotifications(
    profileId: profileId,
    recipientUid: recipientUid,
  );
}

/// Stream de contador de não lidas em tempo real
///
/// Usado para badge no BottomNavigation.
/// Emite apenas quando valor muda (distinct).
@riverpod
Stream<int> unreadNotificationCountNewStream(
  Ref ref,
  String profileId,
  String recipientUid,
) {
  final repository = ref.watch(notificationsNewRepositoryProvider);
  return repository.watchUnreadCount(
    profileId: profileId,
    recipientUid: recipientUid,
  );
}
