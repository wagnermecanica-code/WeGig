import 'package:core_ui/features/post/domain/entities/post_entity.dart';

import 'network_activity_cursor_entity.dart';

class NetworkActivityPageEntity {
  const NetworkActivityPageEntity({
    required this.posts,
    required this.hasMore,
    this.nextCursor,
  });

  final List<PostEntity> posts;
  final bool hasMore;
  final NetworkActivityCursorEntity? nextCursor;
}
