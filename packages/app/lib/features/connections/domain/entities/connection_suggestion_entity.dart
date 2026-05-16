import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';

class ConnectionSuggestionEntity {
  const ConnectionSuggestionEntity({
    required this.profile,
    required this.score,
    required this.reason,
    required this.commonConnectionsCount,
  });

  final ProfileEntity profile;
  final int score;
  final String reason;
  final int commonConnectionsCount;
}