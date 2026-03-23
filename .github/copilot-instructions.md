# WeGig – Copilot Instructions

## Repo shape (Melos monorepo)

| Path                             | Purpose                                                                                     |
| -------------------------------- | ------------------------------------------------------------------------------------------- |
| `packages/app/`                  | Flutter app (SDK ≥3.6.0, Flutter 3.27.1 via FVM)                                            |
| `packages/core_ui/`              | Shared widgets, theme, domain entities, `Result<T,E>`/`UIState<T>` (barrel: `core_ui.dart`) |
| `.config/functions/`             | Firebase Cloud Functions (Node 20, region `southamerica-east1`)                             |
| `.config/firestore.rules`        | Security rules                                                                              |
| `.config/firestore.indexes.json` | Composite indexes — update when adding Firestore queries                                    |
| `admin-dashboard/`               | Vite + React + Tailwind admin for moderating reports                                        |
| `.tools/scripts/`                | Build, deploy, and migration helpers                                                        |

## Critical workflows

```bash
# Bootstrap (from repo root — NEVER run flutter pub get directly)
melos bootstrap

# Run app (from packages/app)
flutter run --flavor dev -t lib/main_dev.dart

# Codegen after Freezed/Riverpod changes
melos run build_runner

# Clean rebuild
flutter clean && melos bootstrap && melos run build_runner

# Tests (from packages/app)
flutter test --coverage

# Deploy Firebase (order matters)
firebase deploy --only firestore:indexes
firebase deploy --only firestore:rules
firebase deploy --only functions
```

`.env` at repo root (copy `.env.example`). Key vars: `FIREBASE_PROJECT_ID`, `GOOGLE_MAPS_API_KEY_*`, `APP_ENV`, feature flags. Loaded by `EnvService.init()` at bootstrap. Flavors: `dev` (wegig-dev), `staging`, `prod` (to-sem-banda-83e19). Entry points: `lib/main_<flavor>.dart`. Lint: `very_good_analysis` with `prefer_single_quotes`, `require_trailing_commas`.

## Architecture: Clean Architecture per feature

Path: `packages/app/lib/features/<feature>/{data,domain,presentation}`

Features: `auth`, `post`, `profile`, `mensagens_new` (chat v2), `notifications_new`, `comment`, `report`, `settings`, `home`.

### Provider DI chain (follow this pattern exactly)

In `presentation/providers/<feature>_providers.dart`, wire the full chain:

```dart
@riverpod
IPostRemoteDataSource postRemoteDataSource(Ref ref) => PostRemoteDataSource();

@riverpod
PostRepository postRepositoryNew(Ref ref) {
  return PostRepositoryImpl(remoteDataSource: ref.read(postRemoteDataSourceProvider));
}

@riverpod
CreatePost createPostUseCase(Ref ref) => CreatePost(ref.read(postRepositoryNewProvider));

// Notifier consumes use cases via ref.read inside methods
@riverpod
class PostNotifier extends _$PostNotifier { ... }
```

- Datasource: abstract interface (`IFooDataSource`) + impl in **same file**; constructor accepts optional `FirebaseFirestore` for test injection.
- Repository: thin wrapper, currently rethrows exceptions.
- Use case: single-responsibility `call()` method with domain validation.
- Notifier: `@riverpod class` with Freezed state union (`posts`, `isLoading`, `error`).

### Riverpod conventions

- `@riverpod` codegen for all new providers. `@Riverpod(keepAlive: true)` only for long-lived state in `packages/app/lib/core/providers/` (badge counts, cache config, connectivity, GPS cache).
- Always `ref.onDispose` to cancel `StreamSubscription`s — see `badge_count_provider.dart`.
- `UIState<T>` barrel **hides `Success`** to avoid conflict with `Result<T,E>`. Use `Result.success()` for domain results.
- Run `melos run build_runner` after any Freezed/Riverpod annotation change.

### Navigation

GoRouter with type-safe `BuildContext` extensions — **never use string routes**:

```dart
context.goToHome();            context.goToAuth();
context.pushPostDetail(id);    context.pushProfile(id);
context.pushConversation(conversationId, otherUserId: ..., otherProfileId: ...);
```

Auth guard flow: auth-in-progress → splash → auth page → create-profile → home. All navigation logs to Firebase Analytics.

### Firestore patterns

Posts always filter expired then order (must match indexes in `.config/firestore.indexes.json`):

```dart
.where('expiresAt', isGreaterThan: Timestamp.now())
.orderBy('expiresAt', descending: true)
```

Key collections: `posts`, `profiles`, `interests`, `blocks`, `conversations`, `conversations/{id}/messages`, `users`, `fcmTokens`, `notifications`, `reports`, `adminNotifications`.

### Block filtering

`BlockedRelations.getExcludedProfileIds()` (static, no DI) — returns "I blocked" + "blocked me" combined. Server reverse index via `syncBlockedByProfileIndex` Cloud Function. Client-side enforcement required. Methods never throw — return empty list on error.

### Profile switching

`profileSwitcherNotifierProvider.notifier.switchToProfile(id)` — invalidates post/interest caches, updates Analytics. FCM tokens **kept across all profiles**.

### Post caching

`PostCacheNotifier` — manual TTL-based. `PostNotifier` checks `isCacheValid` before Firestore, falls back to stale cache on timeout/error. Granular: `removePost(id)`, `updatePost(entity)`.

### UGC filtering

`ObjectionableContentFilter.validate(fieldLabel, input)` — client-side before writes. Leetspeak normalization, diacritic stripping, ~30 PT-BR terms. Returns error string or `null`. Server-side backstop in Cloud Functions.

### Bootstrap sequence

`bootstrapCoreServices()`: WidgetsBinding → Hive → EnvService → Firebase (duplicate-app guard) → `FirebaseCacheConfig.validateEnvironment()` (throws in debug if project ID mismatches) → Firestore cache (50/75/100MB by flavor) → push notifications → Crashlytics (staging/prod) → portrait lock.

## UI rules

- **Never** `Image.network` — always `CachedNetworkImage` with placeholder + errorWidget.
- Image compression: `FlutterImageCompress.compressAndGetFile(path, target, quality: 85, minWidth: 800, minHeight: 800)`.
- Profile-type colors: `AppColors.getProfileTypeColor(type)`.
- Domain constants: `MusicConstants.instrumentOptions`, `genreOptions`, etc. in `core_ui/lib/utils/music_constants.dart`.

## Cloud Functions

All in `southamerica-east1`. `syncBlockedByProfileIndex` (onWrite blocks), `notifyNearbyPosts` (onCreate posts), `sendInterestNotification` (onCreate interests), `sendMessageNotification` (onCreate messages), `cleanupExpiredNotifications` (daily 3AM BRT), `onProfileDelete` (cascading cleanup).

## Testing

Tests at `packages/app/test/features/`, mirroring feature structure. **Manual mocks** (Mockito incompatible with Dart 3.6.0): implement repository interface with `setupSuccessResponse()`/`setupFailureResponse()` helpers, track calls via boolean flags. AAA pattern with `group()`. Focus on domain logic isolated from Firebase.

## Key files

| What                | Where                                                                                     |
| ------------------- | ----------------------------------------------------------------------------------------- |
| Bootstrap           | `packages/app/lib/bootstrap/bootstrap_core.dart`                                          |
| Router + auth guard | `packages/app/lib/app/router/app_router.dart`                                             |
| Block filtering     | `packages/app/lib/core/firebase/blocked_relations.dart`                                   |
| Cache config        | `packages/app/lib/core/firebase/firebase_cache_config.dart`                               |
| Profile switcher    | `packages/app/lib/features/profile/presentation/providers/profile_switcher_provider.dart` |
| Env service         | `packages/core_ui/lib/services/env_service.dart`                                          |
| core_ui barrel      | `packages/core_ui/lib/core_ui.dart`                                                       |
| Security rules      | `.config/firestore.rules`                                                                 |
| Cloud Functions     | `.config/functions/index.js`                                                              |
| Content filter      | `packages/core_ui/lib/utils/objectionable_content_filter.dart`                            |
| Post provider DI    | `packages/app/lib/features/post/presentation/providers/post_providers.dart`               |
