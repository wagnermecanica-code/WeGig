/// WeGig - DeleteNotificationNew UseCase
///
/// Use case para deletar notificação seguindo Clean Architecture.
library;

import 'package:wegig_app/features/notifications_new/domain/repositories/notifications_new_repository.dart';

/// Use case para deletar uma notificação
///
/// Exemplo:
/// ```dart
/// final useCase = DeleteNotificationNewUseCase(repository);
/// await useCase(
///   notificationId: 'notif-123',
///   profileId: 'profile-456',
/// );
/// ```
class DeleteNotificationNewUseCase {
  /// Cria o use case com o repositório injetado
  const DeleteNotificationNewUseCase(this._repository);

  final NotificationsNewRepository _repository;

  /// Executa a deleção
  ///
  /// [notificationId] - ID da notificação
  /// [profileId] - ID do perfil para validação
  Future<void> call({
    required String notificationId,
    required String profileId,
  }) {
    return _repository.deleteNotification(
      notificationId: notificationId,
      profileId: profileId,
    );
  }
}
