# WeGig – AI Agent Cheatsheet

## Architecture Overview

**Product**: Multi-profile social network for musicians/bands with expiring posts (30 days), geospatial search, realtime chat, and proximity push notifications. Profile switching works like Instagram.

**Monorepo Structure** (Melos-managed):

```
packages/app/           → Main Flutter app (Clean Architecture: data → domain → presentation)
packages/core_ui/       → Shared entities, theme, widgets, services (import: core_ui → app ONLY)
.tools/functions/       → Cloud Functions (Node.js) for push notifications
.config/                → Firestore rules, indexes, Firebase configs
```

**Key Files**:

- `packages/app/lib/app/router/app_router.dart` — Typed routes with auth guards (GoRouter + Riverpod)
- `packages/app/lib/bootstrap/bootstrap_core.dart` — Firebase/Hive initialization with environment validation
- `packages/app/lib/features/*/presentation/providers/*.dart` — Riverpod AsyncNotifier pattern
- `packages/core_ui/lib/core_ui.dart` — Barrel export for all shared resources
- `packages/core_ui/lib/theme/app_colors.dart` — Design tokens (Primary `#37475A`, Accent `#E47911`, Badge `#FF2828`)

## Developer Workflow

**Setup** (from repo root):

```bash
melos bootstrap
```

**Run app** (MUST be from `packages/app/`):

```bash
cd packages/app
flutter run --flavor dev -t lib/main_dev.dart
```

**Code generation** (after Freezed/JSON model changes):

```bash
melos run build_runner  # from repo root
```

**Tests**:

```bash
cd packages/app && flutter test --coverage
```

**Flavors**: `dev` (wegig-dev), `staging` (wegig-staging), `prod` (to-sem-banda-83e19) — each has its own Firebase project, entry point (`main_<flavor>.dart`), and bundle ID.

## Critical Patterns

### Feature Architecture (Clean Architecture per Feature)

Each feature in `packages/app/lib/features/` follows:

```
feature/
├── data/
│   ├── datasources/    → Remote/local data sources (Firestore, Hive)
│   ├── models/         → Data transfer objects
│   └── repositories/   → Repository implementations
├── domain/
│   ├── entities/       → Business models (in core_ui for shared entities)
│   ├── repositories/   → Abstract repository interfaces
│   └── usecases/       → Single-responsibility use cases
└── presentation/
    ├── pages/          → Full-screen widgets
    ├── widgets/        → Reusable UI components
    └── providers/      → Riverpod state management
```

### Firestore Query Convention (MANDATORY)

Every posts query MUST include expiration filter with correct ordering:

```dart
.where('expiresAt', isGreaterThan: Timestamp.now())
.orderBy('expiresAt')  // FIRST - required for composite index
.orderBy('createdAt', descending: true)
```

Missing this breaks indexes defined in `.config/firestore.indexes.json`.

### Multi-Profile State Management

Use `profileSwitcherNotifierProvider` for profile switching (centralizes cache invalidation):

```dart
// Switch profile (invalidates all dependent caches automatically)
await ref.read(profileSwitcherNotifierProvider.notifier).switchToProfile(profileId);

// Read active profile
final profile = ref.read(profileProvider).value?.activeProfile;

// Manual invalidation (when not using switcher)
ref.invalidate(profileProvider);
ref.invalidate(postNotifierProvider);
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

| Issue                   | Fix                                                              |
| ----------------------- | ---------------------------------------------------------------- |
| Wrong directory error   | Flutter commands MUST run from `packages/app/`, not repo root    |
| Stale generated files   | `flutter clean && melos get && melos run build_runner`           |
| iOS DerivedData issues  | `rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*`          |
| Pod problems            | `cd packages/app/ios && rm -rf Pods Podfile.lock && pod install` |
| Firestore index missing | Deploy indexes first, wait for completion before rules           |
| Profile data not updating | Use `profileSwitcherNotifierProvider` or manually invalidate all dependent providers |
