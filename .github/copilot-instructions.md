# WeGig – AI Agent Cheatsheet

## Architecture Overview

**Product**: Multi-profile social network for musicians, bands, and musical spaces with expiring posts (30 days), geospatial search, realtime chat, and proximity push notifications. Profile switching works like Instagram.

**Tech Stack**: Flutter 3.27+ (Dart 3.6+) | Firebase (Firestore, Auth, Storage, FCM) | Riverpod 2.x + Freezed | GoRouter

**Monorepo Structure** (Melos-managed):

```
packages/app/           → Main Flutter app (Feature-First Clean Architecture)
packages/core_ui/       → Shared entities, theme, widgets (import: core_ui → app ONLY)
.config/functions/      → Cloud Functions (Node.js 20) - region: southamerica-east1
.config/                → Firestore rules, indexes, Firebase configs
.tools/third_party/     → Forked dependencies (google_maps_cluster_manager)
```

**Profile Types** (`ProfileType` enum in `core_ui`):

- `musician` — Primary color `#37475A`
- `band` — Accent color `#E47911`
- `space` — SalesBlue `#007EB9` (9 subtypes via `SpaceType`)

**Cloud Functions** (5 active in `.config/functions/index.js`):

- `notifyNearbyPosts` — Trigger: posts.onCreate → Push to profiles in radius
- `sendInterestNotification` / `sendMessageNotification` — Trigger on subcollection writes
- `cleanupExpiredNotifications` — Scheduled daily
- `onProfileDelete` — Cascade delete posts/storage

**Key Entry Points**:

- [packages/app/lib/app/router/app_router.dart](packages/app/lib/app/router/app_router.dart) — `AppRoutes` typed routes + GoRouter auth guards
- [packages/app/lib/bootstrap/bootstrap_core.dart](packages/app/lib/bootstrap/bootstrap_core.dart) — Firebase init with environment validation
- [packages/core_ui/lib/core_ui.dart](packages/core_ui/lib/core_ui.dart) — Barrel export for all shared resources

## Developer Workflow

**IMPORTANT**: Flutter commands MUST run from `packages/app/`, not repo root.

```bash
# Setup (repo root)
melos bootstrap

# Run app (packages/app/)
cd packages/app && flutter run --flavor dev -t lib/main_dev.dart

# Code generation after Freezed/model changes (repo root)
melos run build_runner

# Tests (packages/app/)
flutter test --coverage

# Clean rebuild when generated files are stale
flutter clean && melos bootstrap && melos run build_runner
```

**Flavors**: `dev` (wegig-dev), `staging` (wegig-staging), `prod` (to-sem-banda-83e19) — each has Firebase project + entry point `main_<flavor>.dart`

## Critical Patterns

### Feature Architecture (Clean Architecture per Feature)

```
packages/app/lib/features/<feature>/
├── data/
│   ├── datasources/    → Firestore/Hive data sources
│   ├── models/         → DTOs with JSON serialization
│   └── repositories/   → Repository implementations
├── domain/
│   ├── entities/       → Business models (shared in core_ui)
│   ├── repositories/   → Abstract interfaces
│   └── usecases/       → Single-responsibility use cases
└── presentation/
    ├── pages/          → Full-screen widgets
    ├── widgets/        → Reusable UI components
    └── providers/      → Riverpod @riverpod + Freezed state
```

### Firestore Query Convention (MANDATORY)

**ALL posts queries MUST include expiration filter** — missing this breaks composite indexes:

```dart
.where('expiresAt', isGreaterThan: Timestamp.now())
.orderBy('expiresAt')  // Required for composite index
```

### Multi-Profile State Management

Use `profileSwitcherNotifierProvider` for profile switching (centralizes cache invalidation):

```dart
// Switch profile (invalidates posts, notifications, messages caches)
await ref.read(profileSwitcherNotifierProvider.notifier).switchToProfile(profileId);

// Read active profile
final profile = ref.read(profileProvider).value?.activeProfile;
```

**Ownership Model**: Firestore uses `authorUid` (Firebase Auth UID) for security rules; app uses `profileId` for data isolation.

### Riverpod Pattern

```dart
@riverpod
class FeatureNotifier extends _$FeatureNotifier {
  @override
  FutureOr<FeatureState> build() async {
    ref.onDispose(() {
      _subscription?.cancel();  // CRITICAL: prevent memory leaks
    });
    return _loadInitialData();
  }
}
```

### Code Conventions

- **Images**: Always `CachedNetworkImage`, never `Image.network`
- **Uploads**: Compress with `FlutterImageCompress.compressAndGetFile()` at ~85 quality
- **Debouncing**: Use `Debouncer` from `core_ui/utils/debouncer.dart`
- **Routes**: Use `AppRoutes.profile(id)` not string literals
- **Colors**: Use `AppColors.getProfileTypeColor(type)` for profile-based theming

## Routing & Navigation

- **Auth guard flow**: not logged → `/auth` → no profile → `/profiles/new` → `/home`
- **Typed routes**: Use `AppRoutes.profile(id)` not string literals
- **Bottom nav**: `IndexedStack` + `ValueNotifier<int>` preserves tab state

## Firebase Deployment

**Deploy sequence matters** (from `.config/`):

```bash
firebase deploy --only firestore:indexes --project <env>  # wait 5-10min for build
firebase deploy --only firestore:rules --project <env>
firebase deploy --only functions --project <env>
```

**Project IDs**: `wegig-dev`, `wegig-staging`, `to-sem-banda-83e19` (prod)

## Troubleshooting

| Issue                     | Fix                                                                      |
| ------------------------- | ------------------------------------------------------------------------ |
| Wrong directory error     | Flutter commands MUST run from `packages/app/`, not repo root            |
| Stale generated files     | `flutter clean && melos bootstrap && melos run build_runner`             |
| iOS DerivedData issues    | `rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*`                  |
| Pod problems              | `cd packages/app/ios && rm -rf Pods Podfile.lock && pod install`         |
| Firestore index missing   | Deploy indexes first, wait for completion before rules                   |
| Profile data not updating | Use `profileSwitcherNotifierProvider` to invalidate all dependent caches |

## Features Quick Reference

| Feature                | Key Points                                                             |
| ---------------------- | ---------------------------------------------------------------------- |
| **auth/**              | Email/password, Google, Apple; session persistence                     |
| **profile/**           | Multi-profile (limit 5); location required; photo compression          |
| **post/**              | 9 images max; 30-day expiration; sales posts with price/discount/promo |
| **home/**              | Map clustering; filters by type/genre/radius; @username search         |
| **mensagens_new/**     | Real-time chat; unread counters; lazy loading                          |
| **notifications_new/** | FCM push; proximity alerts; auto-cleanup                               |

## Geospatial & Real-time

- Google Maps with custom `google_maps_cluster_manager` fork (in `.tools/third_party/`)
- Marker cache: 6 types (musician/band/sales × normal/active) for performance
- Firestore streams with `distinctUntilChanged` to prevent rebuilds
- Proximity notifications via Cloud Function (configurable 5-100km radius)
