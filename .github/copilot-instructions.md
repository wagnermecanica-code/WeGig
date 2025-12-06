# WeGig – AI Agent Cheatsheet

## Repo Layout & Architecture

- **Monorepo with Clean Architecture**: `packages/app` holds features built as `data → domain → presentation` slices, `packages/core_ui` exposes shared entities/theme/providers/widgets, and imports must flow `core_ui → app` only.
- **The product**: Multi-profile social network for musicians/bands (expiring posts, geospatial search, realtime chat, proximity push notifications). Multi-profile switching works like Instagram.
- **Typed navigation** lives in `packages/app/lib/app/router/app_router.dart` with generated extension methods (`context.goToProfile(profileId)`). Never use string routes or bypass auth guards described in `DEEP_LINKING_GUIDE.md`.
- **Cloud Functions + Firebase infra** at repo root (`.tools/functions/index.js`, `.config/firestore.rules`, `.config/firestore.indexes.json`). Design system tokens/widgets under `packages/core_ui/lib/theme` and `packages/core_ui/lib/widgets`.

## Daily Workflow & Tooling

- **Flutter version**: 3.27.1 managed via FVM at `.fvm/flutter_sdk`. From repo root run `melos bootstrap` once, then `melos get|analyze|test|build_runner` to fan out commands across packages.
- **Running the app**: All `flutter ...` commands (run, build, test) must execute inside `packages/app/`. Example: `cd packages/app && flutter run --flavor dev -t lib/main_dev.dart`.
- **Flavors**: Three environments (dev/staging/prod) with separate Firebase projects, bundle IDs, and entry points (`lib/main_<flavor>.dart`). Use helper scripts: `./.tools/scripts/build_release.sh <dev|staging|prod>` or `./.tools/scripts/run_app.sh <flavor>`.
- **Code generation**: After touching Freezed/JSON/adapters, run `melos run build_runner` from repo root. If files drift: `flutter clean && melos get && melos run build_runner`.
- **Tests**: `melos test` mirrors CI (`melos analyze && melos test`). Config per flavor is in `packages/app/lib/config/{dev,staging,prod}_config.dart`.

## Patterns & Pitfalls

### Multi-Profile State Management

- **Always** read `ref.read(profileProvider).value?.activeProfile` on demand; after switching profiles call `ref.invalidate(profileProvider)` plus post feeds and unread counters so Riverpod refreshes state. See `docs/sessions/SESSION_14_MULTI_PROFILE_REFACTORING.md` for why providers get invalidated.
- **Providers** are handwritten `AsyncNotifier/Notifier/StreamProvider` classes inside `packages/core_ui/lib/di` and feature folders (e.g., `packages/app/lib/features/profile/presentation/providers/profile_providers.dart`).
- **Memory leaks**: Register `ref.onDispose(() { _streamController.close(); })` for all controllers/streams to avoid leaks documented in `MEMORY_LEAK_AUDIT_CONSOLIDADO.md`. NEVER create inline listeners without named methods for removal.

### Firestore Query Conventions

- **CRITICAL**: Every query must filter `.where('expiresAt', isGreaterThan: Timestamp.now())` and `.orderBy('expiresAt')` BEFORE other orderings. Paginate with `startAfterDocument(lastDoc)`. Missing this breaks indexes in `.config/firestore.indexes.json`.
- Posts expire after 30 days; Cloud Functions auto-cleanup runs nightly.
- Notification radius stored in kilometers; maintain consistency between `.tools/functions/index.js` and validators in `packages/app/lib/features/notifications`.

### Navigation Architecture

- **Bottom navigation** centralized in `packages/core_ui/lib/navigation/bottom_nav_scaffold.dart` using `ValueNotifier` + `IndexedStack` to preserve state.
- Heavy streams (chat/notifications) must be lazily initialized (only when tab is active) to avoid perf regressions. See `NAVIGATION_TRANSITIONS_AUDIT.md` for rules.
- Auth guard in `app_router.dart` auto-redirects: not logged in → `/auth`, logged but no profile → `/profiles/new`, logged + profile → `/home`.

## UI, Data & Performance Conventions

### Image Handling

- **Remote images**: Always use `CachedNetworkImage`/`CachedNetworkImageProvider`; never `Image.network`. Width/height should be doubled for retina caching (see `packages/core_ui/lib/widgets/photo_upload_widget.dart`).
- **Image uploads**: Compress using `FlutterImageCompress.compressAndGetFile()` targeting ~85 quality (see `packages/app/lib/features/post/presentation/pages/post_page.dart` line 447). Do NOT use `compute()` isolates—compression happens synchronously but is fast enough.
- **Geo queries**: Keep `location` (GeoPoint) attached to each post; use Google Maps cluster helpers under `.tools/third_party/google_maps_cluster_manager` for efficient map rendering.

### Input Debouncing & Utilities

- Use `Debouncer`/`Throttler` classes from `packages/core_ui/lib/utils/debouncer.dart` instead of manual timers. Example: `final _debouncer = Debouncer(milliseconds: 300);` then `_debouncer.run(() { ... });` and `_debouncer.dispose();` in dispose.
- UI feedback: Use `AppLoadingOverlay.show(context)` and `AppSnackbar.show()` from design system. Colors defined in `packages/core_ui/lib/theme/app_colors.dart` (primary: Teal `#00A699`).

### Analytics & Logging

- Typed routes automatically log Firebase Analytics events; when adding a route extend helpers in `packages/app/lib/app/router/app_router.dart`.
- Use `debugPrint()` for logs; they're stripped in prod builds via obfuscation.

## Config, Env & External Services

### Environment Setup

- **Initialization order**: Call `await EnvService.init()` (`packages/core_ui/lib/services/env_service.dart`) BEFORE `Firebase.initializeApp()` in `main_<flavor>.dart`.
- **Required .env variables**: `APP_ENV`, `FIREBASE_PROJECT_ID`, `GOOGLE_MAPS_API_KEY`, optional `ENABLE_PUSH_NOTIFICATIONS`.
- **Flavor-specific config**: `packages/app/lib/config/{dev,staging,prod}_config.dart` chosen by entry point (`main_dev.dart`, etc.). Never mix prod keys into dev/staging.

### Push Notifications

- Client side in `packages/app/lib/features/notifications`, backend in Cloud Functions (`.tools/functions/index.js`).
- FCM tokens persisted per profile document under `users/{uid}/profiles/{profileId}`.
- **Proximity notifications**: Cloud Function `notifyNearbyPosts` triggers when new post created within user's configured radius (5-100km).

### Firebase Deployment

- **Sequence matters**: `firebase deploy --only firestore:indexes` → wait for completion → `firebase deploy --only .config/firestore.rules` → `firebase deploy --only functions`.
- Debug Cloud Functions: `firebase functions:log --only notifyNearbyPosts` for delivery issues.
- Security rules in `.config/firestore.rules` require posts to have proper `uid` ownership checks.

## Key Documentation Reference

- **Multi-profile refactoring**: `docs/sessions/SESSION_14_MULTI_PROFILE_REFACTORING.md` (state management, transactions, validations)
- **Typed navigation**: `SESSION_TASK_11_TYPED_ROUTES.md` (type-safe routing, analytics integration)
- **Memory leak audits**: `MEMORY_LEAK_AUDIT_CONSOLIDADO.md` (8 leaks fixed, disposal patterns)
- **Navigation rules**: `NAVIGATION_TRANSITIONS_AUDIT.md` (transitions, guards, IndexedStack usage)
- **Deep linking**: `DEEP_LINKING_GUIDE.md` (wegig:// scheme + universal links)
- **Monorepo structure**: `MONOREPO_STRUCTURE.md` (package organization, dependencies)
- **CI/CD setup**: `.github/workflows/` (automated builds, code signing)
