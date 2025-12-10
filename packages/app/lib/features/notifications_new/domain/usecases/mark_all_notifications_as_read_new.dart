/// WeGig - MarkAllNotificationsAsReadNew UseCase
///
/// Use case para marcar todas as notificações como lidas seguindo Clean Architecture.
library;

import 'package:wegig_app/features/notifications_new/domain/repositories/notifications_new_repository.dart';

/// Use case para marcar todas as notificações de um perfil como lidas
///
/// Exemplo:
/// ```dart
/// final useCase = MarkAllNotificationsAsReadNewUseCase(repository);
/// await useCase(
///   profileId: 'profile-123',
///   recipientUid: 'uid-456',
/// );
/// ```
class MarkAllNotificationsAsReadNewUseCase {
  /// Cria o use case com o repositório injetado
  const MarkAllNotificationsAsReadNewUseCase(this._repository);

  final NotificationsNewRepository _repository;

  /// Executa a marcação de todas como lidas
  ///
  /// [profileId] - ID do perfil
  /// [recipientUid] - UID do Firebase Auth
  Future<void> call({
    required String profileId,
    required String recipientUid,
  }) {
    return _repository.markAllAsRead(
      profileId: profileId,
      recipientUid: recipientUid,
    );
  }
}
