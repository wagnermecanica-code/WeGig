# WeGig – AI Agent Cheatsheet

## Architecture Overview

**Product**: Multi-profile social network for musicians/bands with expiring posts (30 days), geospatial search, realtime chat, and proximity push notifications. Profile switching works like Instagram.

**Monorepo Structure**:

- `packages/app/` — Main app with features as `data → domain → presentation` slices
- `packages/core_ui/` — Shared entities, theme, providers, widgets (import flows `core_ui → app` only)
- `.tools/functions/` — Cloud Functions (Node.js) for proximity notifications
- `.config/` — Firestore rules, indexes, Firebase configs

**Key Architectural Files**:

- Router: `packages/app/lib/app/router/app_router.dart` (typed routes with auth guards)
- Navigation: `packages/app/lib/navigation/bottom_nav_scaffold.dart` (IndexedStack + ValueNotifier)
- Bootstrap: `packages/app/lib/bootstrap/bootstrap_core.dart` (initialization sequence)
- Design tokens: `packages/core_ui/lib/theme/app_colors.dart`

## Developer Workflow

**Setup** (run once):

```bash
melos bootstrap  # from repo root
```

**Daily Commands** (MUST run from `packages/app/`):

```bash
cd packages/app
flutter run --flavor dev -t lib/main_dev.dart
flutter test --coverage
```

**Code Generation** (after modifying Freezed/JSON models):

```bash
melos run build_runner  # from repo root
```

**Stale Files Fix**:

```bash
flutter clean && melos get && melos run build_runner
```

**Flavors**: `dev` (wegig-dev), `staging` (wegig-staging), `prod` (to-sem-banda-83e19) — each has separate Firebase project, entry point (`main_<flavor>.dart`), and config (`lib/config/<flavor>_config.dart`).

## Critical Patterns

### Firestore Query Convention (MUST follow)

Every posts query MUST include expiration filter FIRST:

```dart
.where('expiresAt', isGreaterThan: Timestamp.now())
.orderBy('expiresAt')  // BEFORE other orderings
.orderBy('createdAt', descending: true)
.startAfterDocument(lastDoc)  // pagination
```

Missing this breaks composite indexes in `.config/firestore.indexes.json`.

### Multi-Profile State Management

```dart
// Read active profile on demand
final profile = ref.read(profileProvider).value?.activeProfile;

// After profile switch, invalidate dependent providers
ref.invalidate(profileProvider);
ref.invalidate(postsProvider);
ref.invalidate(unreadCountProvider);
```

### Memory Leak Prevention

Always register disposal for streams/controllers:

```dart
ref.onDispose(() {
  _streamController.close();
  _subscription.cancel();
});
```

NEVER create inline listeners — use named methods for removal.

### Image Handling

- **Remote images**: Always `CachedNetworkImage`, never `Image.network`
- **Uploads**: Compress with `FlutterImageCompress.compressAndGetFile()` at ~85 quality
- **Retina**: Double width/height for cache sizing

### Input Debouncing

```dart
final _debouncer = Debouncer(milliseconds: 300);  // from core_ui
_debouncer.run(() => _performSearch(query));
// Dispose in StatefulWidget.dispose()
```

## Navigation & Routing

- **Auth guard** in `app_router.dart`: not logged → `/auth`, no profile → `/profiles/new`, has profile → `/home`
- **Bottom nav** uses `IndexedStack` + `ValueNotifier` to preserve tab state
- **Lazy loading**: Heavy streams (chat/notifications) only initialize when tab is active
- **Typed routes**: Use `AppRoutes.profile(id)` not string literals

## Firebase Deployment

**Sequence matters** (from `.config/` directory):

```bash
firebase deploy --only firestore:indexes --project <env>  # wait 5-10min
firebase deploy --only firestore:rules --project <env>
firebase deploy --only functions --project <env>
```

**Project IDs**: `wegig-dev`, `wegig-staging`, `to-sem-banda-83e19` (prod)

**Security rules**: Posts use `authorUid` (auth UID) for ownership, not `uid`.

## Troubleshooting

| Issue                        | Fix                                                                        |
| ---------------------------- | -------------------------------------------------------------------------- |
| Wrong directory error        | Run flutter commands from `packages/app/`, not root                        |
| Stale generated files        | `flutter clean && melos get && melos run build_runner`                     |
| iOS DerivedData issues       | `rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*`                    |
| Pod problems                 | `cd packages/app/ios && rm -rf Pods Podfile.lock .symlinks && pod install` |
| Permission denied (Firebase) | Check `--project <env>` flag matches flavor config                         |
| Index missing errors         | Deploy indexes first, wait for completion                                  |

## Key Files Reference

- **Providers pattern**: `packages/app/lib/features/profile/presentation/providers/profile_providers.dart`
- **Firestore indexes**: `.config/firestore.indexes.json`
- **Cloud Functions**: `.tools/functions/index.js`
- **Debouncer/Throttler**: `packages/core_ui/lib/utils/debouncer.dart`
- **UI utilities**: `AppLoadingOverlay`, `AppSnackbar` from `core_ui`
- **Colors**: Primary `#37475A`, Accent `#E47911`
