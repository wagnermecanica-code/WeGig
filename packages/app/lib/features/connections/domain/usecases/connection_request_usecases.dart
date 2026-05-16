import '../entities/entities.dart';
import '../repositories/connections_repository.dart';

class SendConnectionRequestUseCase {
  const SendConnectionRequestUseCase(this._repository);

  final ConnectionsRepository _repository;

  Future<ConnectionRequestEntity> call({
    required String requesterProfileId,
    required String requesterUid,
    required String requesterName,
    String? requesterPhotoUrl,
    required String recipientProfileId,
    required String recipientUid,
    required String recipientName,
    String? recipientPhotoUrl,
  }) {
    return _repository.sendConnectionRequest(
      requesterProfileId: requesterProfileId,
      requesterUid: requesterUid,
      requesterName: requesterName,
      requesterPhotoUrl: requesterPhotoUrl,
      recipientProfileId: recipientProfileId,
      recipientUid: recipientUid,
      recipientName: recipientName,
      recipientPhotoUrl: recipientPhotoUrl,
    );
  }
}

class AcceptConnectionRequestUseCase {
  const AcceptConnectionRequestUseCase(this._repository);

  final ConnectionsRepository _repository;

  Future<void> call({
    required String requestId,
    required String responderProfileId,
  }) {
    return _repository.acceptConnectionRequest(
      requestId: requestId,
      responderProfileId: responderProfileId,
    );
  }
}

class DeclineConnectionRequestUseCase {
  const DeclineConnectionRequestUseCase(this._repository);

  final ConnectionsRepository _repository;

  Future<void> call({
    required String requestId,
    required String responderProfileId,
  }) {
    return _repository.declineConnectionRequest(
      requestId: requestId,
      responderProfileId: responderProfileId,
    );
  }
}

class CancelConnectionRequestUseCase {
  const CancelConnectionRequestUseCase(this._repository);

  final ConnectionsRepository _repository;

  Future<void> call({
    required String requestId,
    required String requesterProfileId,
  }) {
    return _repository.cancelConnectionRequest(
      requestId: requestId,
      requesterProfileId: requesterProfileId,
    );
  }
}

class RemoveConnectionUseCase {
  const RemoveConnectionUseCase(this._repository);

  final ConnectionsRepository _repository;

  Future<void> call({
    required String connectionId,
    required String currentProfileId,
  }) {
    return _repository.removeConnection(
      connectionId: connectionId,
      currentProfileId: currentProfileId,
    );
  }
}
