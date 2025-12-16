# WeGig – AI Agent Cheatsheet

## Architecture Overview

**Product**: Multi-profile social network for musicians, bands, and musical spaces with expiring posts (30 days), geospatial search, realtime chat, and proximity push notifications. Profile switching works like Instagram.

**MVP Status** (Revision 0.3 - December 2025):

- Platforms: iOS 15.0+ / Android API 24+
- Tests: 270+ passing | Compilation errors: 0
- Cloud Functions: 5 active | Firestore indexes: 13 composite

**Profile Types** (`ProfileType` enum):

- `musician` — Individual musician profile
- `band` — Band/group profile
- `space` — Musical venues with 9 subtypes (`SpaceType`): recording_studio, instrument_store, bar_venue, music_school, event_producer, equipment_rental, luthier, label, other

**Post Categories** (`type` field / `UserType` enum):

- `musician` — Musician looking for band/collaborators (Primary `#37475A`)
- `band` — Band looking for musicians (Accent `#E47911`)
- `sales` — Space service announcements with title, price, discounts, promo dates, WhatsApp (SalesBlue `#007EB9`)

**Monorepo Structure** (Melos-managed):

```
packages/app/           → Main Flutter app (Feature-First Clean Architecture)
packages/core_ui/       → Shared entities, theme, widgets, services (import: core_ui → app ONLY)
.config/functions/      → Cloud Functions (Node.js 20) - region: southamerica-east1
.config/                → Firestore rules, indexes, Firebase configs
docs/                   → Technical documentation (MVP_Rev0.0.md, architecture/)
```

**Cloud Functions** (5 active):

- `notifyNearbyPosts` — Trigger: posts.onCreate → Push to profiles in radius
- `sendInterestNotification` — Trigger: interests.onCreate
- `sendMessageNotification` — Trigger: messages.onCreate
- `cleanupExpiredNotifications` — Scheduled daily
- `onProfileDelete` — Cleanup posts/storage on profile deletion

**Key Files**:

- [packages/app/lib/app/router/app_router.dart](packages/app/lib/app/router/app_router.dart) — Typed routes with auth guards (`AppRoutes` class + GoRouter)
- [packages/app/lib/bootstrap/bootstrap_core.dart](packages/app/lib/bootstrap/bootstrap_core.dart) — Firebase/Hive initialization with environment validation
- [packages/app/lib/features/_/presentation/providers/_.dart](packages/app/lib/features) — Riverpod `@riverpod` + Freezed state pattern
- [packages/core_ui/lib/core_ui.dart](packages/core_ui/lib/core_ui.dart) — Barrel export for all shared resources
- [packages/core_ui/lib/theme/app_colors.dart](packages/core_ui/lib/theme/app_colors.dart) — Design tokens with `getProfileTypeColor()`

## Developer Workflow

**Setup** (from repo root):

```bash
melos bootstrap
```

**Run app** (MUST be from `packages/app/`):

```bash
cd packages/app && flutter run --flavor dev -t lib/main_dev.dart
```

**Code generation** (after Freezed/JSON model changes):

```bash
melos run build_runner  # from repo root
```

**Tests** (from `packages/app/`):

```bash
flutter test --coverage
```

**Clean rebuild** (when generated files are stale):

```bash
flutter clean && melos bootstrap && melos run build_runner
```

**Flavors**: `dev` (wegig-dev), `staging` (wegig-staging), `prod` (to-sem-banda-83e19) — each has its own Firebase project, entry point (`main_<flavor>.dart`), and bundle ID.

## Critical Patterns

### Feature Architecture (Clean Architecture per Feature)

Each feature in `packages/app/lib/features/` follows Feature-First Clean Architecture:

```
feature/
├── data/
│   ├── datasources/    → Remote/local data sources (Firestore, Hive)
│   ├── models/         → Data transfer objects (DTOs)
│   └── repositories/   → Repository implementations
├── domain/
│   ├── entities/       → Business models (shared in core_ui)
│   ├── repositories/   → Abstract repository interfaces
│   └── usecases/       → Single-responsibility use cases
└── presentation/
    ├── pages/          → Full-screen widgets
    ├── widgets/        → Reusable UI components
    └── providers/      → Riverpod state management
```

**Dependency Rule**: Presentation → Domain → Data (inner layers never depend on outer).

### Firestore Query Convention (MANDATORY)

Every posts query MUST include expiration filter:

```dart
.where('expiresAt', isGreaterThan: Timestamp.now())
.orderBy('expiresAt')  // For composite indexes
```

Missing this breaks indexes defined in `.config/firestore.indexes.json`.

### Multi-Profile State Management

Use `profileSwitcherNotifierProvider` for profile switching (centralizes cache invalidation):

```dart
// Switch profile (invalidates all dependent caches automatically)
await ref.read(profileSwitcherNotifierProvider.notifier).switchToProfile(profileId);

// Read active profile
final profile = ref.read(profileProvider).value?.activeProfile;
```

**Ownership Model**: Firestore uses `uid` (Firebase Auth UID), app uses `profileId` for isolation.

### Riverpod Provider Pattern

Use `AutoDisposeAsyncNotifier` with Freezed state classes:

```dart
@freezed
class FeatureState with _$FeatureState {
  const factory FeatureState({
    @Default([]) List<Item> items,
    @Default(false) bool isLoading,
    String? error,
  }) = _FeatureState;
}

@riverpod
class FeatureNotifier extends _$FeatureNotifier {
  @override
  FutureOr<FeatureState> build() async {
    ref.onDispose(() {
      _streamController.close();  // CRITICAL: prevent memory leaks
    });
    return _loadInitialData();
  }
}
```

### Memory Leak Prevention (Required in all stream providers)

```dart
ref.onDispose(() {
  _streamController.close();
  _subscription.cancel();
});
```

### Image Handling

- **Remote**: Always `CachedNetworkImage`, never `Image.network`
- **Uploads**: Compress with `FlutterImageCompress.compressAndGetFile()` at quality ~85

### Debouncing (search, filters)

```dart
import 'package:core_ui/utils/debouncer.dart';

final _debouncer = Debouncer(milliseconds: 300);
_debouncer.run(() => _performSearch(query));
```

## Routing & Navigation

- **Auth guard flow**: not logged → `/auth` → no profile → `/profiles/new` → `/home`
- **Typed routes**: Use `AppRoutes.profile(id)` not string literals
- **Bottom nav**: `IndexedStack` + `ValueNotifier<int>` preserves tab state (see `bottom_nav_scaffold.dart`)

## Features Summary

| Feature                | Key Capabilities                                                                                                               |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| **auth/**              | Email/password, Google, Apple login; session persistence; password recovery                                                    |
| **profile/**           | Create/edit/delete profiles (limit 5); upload photo with compression; location required                                        |
| **post/**              | Create with 9 images max; sales posts with price/discount/promo/WhatsApp; 30-day expiration; interests system                  |
| **home/**              | Map with clustering; filters by type/genre/instrument/radius; sales filters (price range, discounts, promos); @username search |
| **mensagens_new/**     | Real-time chat; unread counter per profile; lazy stream loading                                                                |
| **notifications_new/** | In-app + FCM push; proximity alerts; interest notifications; auto-cleanup                                                      |
| **settings/**          | Notification radius (5-100km); profile management; legal links                                                                 |

## Firestore Security Rules

Posts use `authorUid` (Firebase Auth UID) for ownership. Key rules in `.config/firestore.rules`:

```javascript
allow create: if isSignedIn() && request.resource.data.authorUid == request.auth.uid;
allow update, delete: if isSignedIn() && resource.data.authorUid == request.auth.uid;
```

## Firebase Deployment

**Deploy sequence matters** (from `.config/`):

```bash
firebase deploy --only firestore:indexes --project <env>  # wait 5-10min for index build
firebase deploy --only firestore:rules --project <env>
firebase deploy --only functions --project <env>
```

**Project IDs**: `wegig-dev`, `wegig-staging`, `to-sem-banda-83e19` (prod)

## Troubleshooting

| Issue                     | Fix                                                                                  |
| ------------------------- | ------------------------------------------------------------------------------------ |
| Wrong directory error     | Flutter commands MUST run from `packages/app/`, not repo root                        |
| Stale generated files     | `flutter clean && melos bootstrap && melos run build_runner`                         |
| iOS DerivedData issues    | `rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*`                              |
| Pod problems              | `cd packages/app/ios && rm -rf Pods Podfile.lock && pod install`                     |
| Firestore index missing   | Deploy indexes first, wait for completion before rules                               |
| Profile data not updating | Use `profileSwitcherNotifierProvider` or manually invalidate all dependent providers |

## Additional Critical Knowledge

### Bootstrap & Environment Validation

- Firebase project validation in `bootstrap_core.dart` prevents data cross-contamination
- Hive for local caching, initialized before Firebase
- Push notifications enabled by default, with background handler

### Data Models & Serialization

- Entities in `core_ui` for shared domain models
- Freezed for immutable state classes with JSON serialization
- DTOs in data layer for API communication

### Geospatial Features

- Google Maps SDK 9.4.0 with clustering (`google_maps_cluster_manager`)
- Reverse geocoding for city detection
- Haversine distance calculations for proximity filters
- Marker cache: 6 types (musician/band/sales × normal/active) — 95% faster
- Proximity notifications via Cloud Function with configurable radius (5-100km)

### Real-time Features

- Firestore streams with `distinctUntilChanged` to prevent unnecessary rebuilds
- Lazy loading for chat and notifications
- Optimistic UI updates for interests (show immediately, sync in background)

### Build & CI/CD

- Automated builds via GitHub Actions for iOS/Android
- Flavor-specific bundle IDs and Firebase configs
- Proguard obfuscation only in production builds

### Dependencies & Versions

- Flutter 3.27.1+, Dart 3.10+
- Firebase: Firestore, Auth, Storage, Functions, Crashlytics, Analytics
- Riverpod 2.x with `@riverpod` annotations
- Google Maps SDK 9.4.0 + custom `google_maps_cluster_manager` fork
- Node.js 20 for Cloud Functions (region: southamerica-east1)

### Sales Post Schema (type: `sales`)

```dart
// Additional fields for sales posts:
title: String,           // Required for sales
salesType: String,       // Service type (e.g., "Gravação")
price: double,           // Base price
discountMode: String,    // "percentage" | "fixed"
discountValue: double,   // Discount amount
promoStartDate: Timestamp,
promoEndDate: Timestamp,
whatsappNumber: String,  // Direct contact
```
