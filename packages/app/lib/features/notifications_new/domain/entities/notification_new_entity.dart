/// WeGig - NotificationNew Entity
///
/// Entidade de domínio para notificações seguindo Clean Architecture.
/// Re-exporta a entidade existente do core_ui para manter compatibilidade
/// com o backend Firestore enquanto oferece isolamento total da feature antiga.
///
/// Uso:
/// ```dart
/// import 'package:wegig_app/features/notifications_new/domain/entities/notification_new_entity.dart';
/// ```
library;

// Re-exporta a entidade do core_ui para manter compatibilidade com Firestore
export 'package:core_ui/features/notifications/domain/entities/notification_entity.dart';
