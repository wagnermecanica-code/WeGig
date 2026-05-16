class NetworkActivityCursorEntity {
  const NetworkActivityCursorEntity({
    required this.createdAt,
    required this.boundaryPostIds,
  });

  final DateTime createdAt;
  final List<String> boundaryPostIds;
}
