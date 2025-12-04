/// Core UI Package - Barrel Export
///
/// Central export file for all shared UI components, theme, services, and domain entities.
/// Used by wegig_app package to access shared resources.
library core_ui;

// Theme
export 'theme/app_colors.dart';
export 'theme/app_theme.dart';
export 'theme/app_typography.dart';

// Navigation
export 'navigation/bottom_nav_scaffold.dart';

// Services
export 'services/env_service.dart';

// Widgets
export 'widgets/app_loading_overlay.dart';
export 'widgets/app_dialogs.dart';
export 'widgets/app_bottom_sheet.dart';
export 'widgets/mention_text.dart';

// Domain Entities
export 'features/profile/domain/entities/profile_entity.dart';
export 'features/post/domain/entities/post_entity.dart';
export 'features/messages/domain/entities/message_entity.dart';
export 'features/messages/domain/entities/conversation_entity.dart';
export 'features/notifications/domain/entities/notification_entity.dart';
export 'features/settings/domain/entities/user_settings_entity.dart';

// Models
export 'models/search_params.dart';
export 'models/user_type.dart';

// Utils
export 'utils/app_snackbar.dart';
export 'utils/location_utils.dart';

// Core Types
export 'core/ui_state.dart' hide Success; // Hide Success to avoid conflict with result.dart
export 'core/result.dart';
