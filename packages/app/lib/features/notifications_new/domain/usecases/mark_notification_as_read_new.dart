/// WeGig - MarkNotificationAsReadNew UseCase
///
/// Use case para marcar notificação como lida seguindo Clean Architecture.
library;

import 'package:wegig_app/features/notifications_new/domain/repositories/notifications_new_repository.dart';

/// Use case para marcar uma notificação como lida
///
/// Exemplo:
/// ```dart
/// final useCase = MarkNotificationAsReadNewUseCase(repository);
/// await useCase(
///   notificationId: 'notif-123',
///   profileId: 'profile-456',
/// );
/// ```
class MarkNotificationAsReadNewUseCase {
  /// Cria o use case com o repositório injetado
  const MarkNotificationAsReadNewUseCase(this._repository);

  final NotificationsNewRepository _repository;

  /// Executa a marcação como lida
  ///
  /// [notificationId] - ID da notificação
  /// [profileId] - ID do perfil para validação
  Future<void> call({
    required String notificationId,
    required String profileId,
  }) {
    return _repository.markAsRead(
      notificationId: notificationId,
      profileId: profileId,
    );
  }
}
