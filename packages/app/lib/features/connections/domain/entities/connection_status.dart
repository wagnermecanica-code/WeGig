enum ConnectionRequestStatus {
  pending,
  accepted,
  declined,
  cancelled,
}

enum ConnectionRelationshipStatus {
  none,
  pendingSent,
  pendingReceived,
  connected,
}

ConnectionRequestStatus connectionRequestStatusFromString(String value) {
  return ConnectionRequestStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => ConnectionRequestStatus.pending,
  );
}
