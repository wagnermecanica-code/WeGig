/// WeGig - LoadNotificationsNew UseCase
///
/// Use case para carregar notificações com paginação seguindo Clean Architecture.
/// Encapsula a lógica de negócio e depende apenas da interface do repositório.
library;

import 'package:wegig_app/features/notifications_new/domain/entities/notification_new_entity.dart';
import 'package:wegig_app/features/notifications_new/domain/repositories/notifications_new_repository.dart';

/// Use case para carregar notificações paginadas
///
/// Exemplo:
/// ```dart
/// final useCase = LoadNotificationsNewUseCase(repository);
/// final notifications = await useCase(
///   profileId: 'profile-123',
///   recipientUid: 'uid-456',
///   type: NotificationType.interest,
///   limit: 20,
/// );
/// ```
class LoadNotificationsNewUseCase {
  /// Cria o use case com o repositório injetado
  const LoadNotificationsNewUseCase(this._repository);

  final NotificationsNewRepository _repository;

  /// Executa a busca de notificações
  ///
  /// [profileId] - ID do perfil ativo
  /// [recipientUid] - UID do Firebase Auth
  /// [type] - Filtro por tipo (null = todas)
  /// [limit] - Quantidade por página
  /// [startAfter] - Cursor para paginação
  Future<List<NotificationEntity>> call({
    required String profileId,
    required String recipientUid,
    NotificationType? type,
    int limit = 20,
    NotificationEntity? startAfter,
  }) {
    return _repository.getNotifications(
      profileId: profileId,
      recipientUid: recipientUid,
      type: type,
      limit: limit,
      startAfter: startAfter,
    );
  }
}
