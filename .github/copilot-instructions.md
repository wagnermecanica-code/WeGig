# WeGig – AI Agent Cheatsheet

## Repo Layout & Architecture

- Monorepo with Clean Architecture: `packages/app` holds features built as `data → domain → presentation` slices, `packages/core_ui` exposes shared entities/theme/providers/widgets, and imports must flow `core_ui → app` only.
- The product is a multi-profile social network (expiring posts, map search, chat, push). Keep `docs/SESSION_14_MULTI_PROFILE_REFACTORING.md` handy for why providers get invalidated and `NAVIGATION_TRANSITIONS_AUDIT.md` for navigation rules.
- Typed navigation lives in `packages/app/lib/app/router` with generated extension methods (`context.goToProfile(...)`). Do not reintroduce string routes or bypass auth guards described in `DEEP_LINKING_GUIDE.md`.
- Cloud Functions + Firebase infra stay at repo root (`functions/index.js`, `firestore.rules`, `firestore.indexes.json`). Design system tokens/widgets are under `packages/core_ui/lib/theme` and `packages/core_ui/lib/widgets`.

## Daily Workflow & Tooling

- Use the FVM-managed Flutter (`.fvm/flutter_sdk`, version 3.27.1). From repo root run `melos bootstrap` once, then `melos get|analyze|test|build_runner` to fan out commands across packages.
- Any `flutter ...` (run, build, test) must execute inside `packages/app/`; e.g. `cd packages/app && flutter run --flavor dev -t lib/main_dev.dart`.
- After touching Freezed/JSON/adapters, run `melos run build_runner` (or `dart run build_runner build --delete-conflicting-outputs` package-local). If files drift, `flutter clean && melos get && melos run build_runner` resets artifacts.
- Tests: `melos test` mirrors CI (`melos analyze && melos test`). For flavor-specific runs use the entrypoints `lib/main_<flavor>.dart` plus `AppConfig` in `packages/app/lib/config/`.
- Release packaging is scripted: `./scripts/build_release.sh <dev|staging|prod> [android|ios]`. Use `scripts/check_posts.sh` when Firestore queries/indexes misbehave.

## Patterns & Pitfalls

- Multi-profile: always read `ref.read(profileProvider).value?.activeProfile` on demand; after switching profiles call `ref.invalidate` on `profileProvider`, post feeds, and unread counters so Riverpod refreshes state.
- Providers are handwritten `AsyncNotifier/Notifier/StreamProvider` classes inside `packages/core_ui/lib/di` and feature folders—register `ref.onDispose` for controllers/streams to avoid leaks documented in `MEMORY_LEAK_AUDIT_*`.
- Firestore rules require every query to filter `.where('expiresAt', isGreaterThan: Timestamp.now())` and `.orderBy('expiresAt')` before other orderings; paginate with `startAfterDocument`. Missing this breaks indexes defined in `firestore.indexes.json`.
- Notification radius is stored in kilometers; keep conversions consistent between `functions/index.js`, validators under `packages/app/lib/features/notifications`, and any UI sliders.
- Navigation is centralized in `core_ui/lib/navigation/bottom_nav_scaffold.dart` using a shared `ValueNotifier` + `IndexedStack`; keep heavy streams (chat/notifications) lazily initialized or you’ll regress perf goals from `SESSION_10_CODE_QUALITY_OPTIMIZATION.md`.

## UI, Data & Performance Conventions

- Remote images must always use `CachedNetworkImage`/`CachedNetworkImageProvider`; never resurrect `Image.network`. Width/height should be doubled for retina caching, see existing components under `packages/core_ui/lib/widgets/`.
- Image uploads compress inside an isolate via `compute(_compressImageIsolate, path)` (see `packages/app/lib/features/post/presentation/post_page.dart`) targeting ~85 quality; keep that pattern for any new media entry points.
- Inputs rely on `Debouncer`/`Throttler` utilities (`packages/core_ui/lib/utils/`) instead of manual timers. UI feedback uses `AppLoadingOverlay` and `AppColors` from the design system.
- Geo queries must keep `location` attached to each post (`packages/app/lib/features/post/data`); use Google Maps cluster helpers under `third_party/google_maps_cluster_manager` for map rendering rather than ad-hoc clustering.
- Typed routes automatically log Firebase Analytics events; when adding a route extend the helpers in `packages/app/lib/app/router/app_router.dart` so analytics stays wired.

## Config, Env & External Services

- Call `EnvService.init()` (`packages/core_ui/lib/services/env_service.dart`) before `Firebase.initializeApp()`. `.env` must supply `APP_ENV`, `FIREBASE_PROJECT_ID`, `GOOGLE_MAPS_API_KEY`, optional feature flags like `ENABLE_PUSH_NOTIFICATIONS`.
- Flavor-specific config resides in `packages/app/lib/config/{dev,staging,prod}_config.dart`; the correct file is chosen via the flavor entrypoint (`main_dev.dart`, etc.). Never mix prod keys into other flavors.
- Push notifications flow through `packages/app/lib/features/notifications` (client) plus Cloud Functions (`functions/index.js`), persisting FCM tokens per profile document.
- When debugging backend issues: `firebase deploy --only firestore:indexes` → wait → `firebase deploy --only firestore:rules` → `firebase deploy --only functions`; inspect `firebase functions:log --only notifyNearbyPosts` for delivery issues.
- Key docs: `SESSION_14_MULTI_PROFILE_REFACTORING.md` (state), `NEARBY_POST_NOTIFICATIONS.md` (Functions), `docs/design/DESIGN_SYSTEM_REPORT.md` (visual system), `SESSION_TASK_11_TYPED_ROUTES.md` (router deep dive).
