/// WeGig - GetUnreadCountNew UseCase
///
/// Use case para obter contagem de não lidas seguindo Clean Architecture.
library;

import 'package:wegig_app/features/notifications_new/domain/repositories/notifications_new_repository.dart';

/// Use case para obter contador de notificações não lidas
///
/// Exemplo:
/// ```dart
/// final useCase = GetUnreadCountNewUseCase(repository);
/// final count = await useCase(
///   profileId: 'profile-123',
///   recipientUid: 'uid-456',
/// );
/// ```
class GetUnreadCountNewUseCase {
  /// Cria o use case com o repositório injetado
  const GetUnreadCountNewUseCase(this._repository);

  final NotificationsNewRepository _repository;

  /// Executa a contagem
  ///
  /// [profileId] - ID do perfil
  /// [recipientUid] - UID do Firebase Auth
  Future<int> call({
    required String profileId,
    required String recipientUid,
  }) {
    return _repository.getUnreadCount(
      profileId: profileId,
      recipientUid: recipientUid,
    );
  }

  /// Stream de contagem em tempo real
  ///
  /// [profileId] - ID do perfil
  /// [recipientUid] - UID do Firebase Auth
  Stream<int> watch({
    required String profileId,
    required String recipientUid,
  }) {
    return _repository.watchUnreadCount(
      profileId: profileId,
      recipientUid: recipientUid,
    );
  }
}
