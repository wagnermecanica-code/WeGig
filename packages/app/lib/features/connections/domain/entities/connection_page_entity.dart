import 'connection_entity.dart';

class ConnectionPageEntity {
  const ConnectionPageEntity({
    required this.connections,
    required this.hasMore,
    this.nextCursor,
  });

  final List<ConnectionEntity> connections;
  final bool hasMore;
  final String? nextCursor;
}
