# 📦 WeGig Monorepo Structure

**Last Updated:** 2025-12-01  
**Status:** ✅ Active

## Overview

WeGig uses a **monorepo structure** with multiple Flutter packages organized for clean separation of concerns and code reusability.

```
to_sem_banda/                     # Root monorepo
├── packages/
│   ├── app/                      # Main Flutter application (wegig_app)
│   │   ├── lib/
│   │   │   ├── main_dev.dart    # Dev flavor entry point
│   │   │   ├── main_staging.dart
│   │   │   └── main_prod.dart
│   │   ├── pubspec.yaml          # App dependencies (Firebase, Maps, etc.)
│   │   └── ios/                  # iOS native code
│   │       └── Podfile           # CocoaPods configuration
│   │
│   └── core_ui/                  # Shared UI components (core_ui)
│       ├── lib/
│       │   ├── theme/            # Design system (colors, typography)
│       │   ├── widgets/          # Reusable widgets
│       │   ├── di/               # Dependency injection (Riverpod)
│       │   └── services/         # Shared services (env, analytics)
│       └── pubspec.yaml          # UI-only dependencies
│
├── scripts/                      # Build automation scripts
│   ├── build_ios.sh              # iOS build helper
│   ├── build_android.sh          # Android build helper
│   ├── run_app.sh                # Run app helper
│   └── clean_all.sh              # Clean all artifacts
│
├── functions/                    # Firebase Cloud Functions
│   └── index.js                  # Backend logic (notifications, etc.)
│
├── docs/                         # Documentation
├── third_party/                  # External dependencies (e.g., cluster manager)
└── pubspec.yaml                  # Root workspace config (minimal)
```

---

## 🚀 Quick Start

### Prerequisites

- **Flutter:** 3.38.1 (managed via FVM at `.fvm/flutter_sdk`)
- **Xcode:** 26.0.1+ (iOS development)
- **CocoaPods:** 1.16.2+
- **Node.js:** 18+ (for Firebase Functions)

### Initial Setup

```bash
# 1. Install dependencies for all packages
melos bootstrap

# 2. Generate code (Freezed, JSON serializers)
melos run build_runner

# 3. Install iOS dependencies
cd packages/app/ios
pod install
cd ../../..
```

---

## 🏃 Running the App

### Using Helper Scripts (Recommended)

```bash
# Run dev flavor
./scripts/run_app.sh dev

# Run staging flavor on specific device
./scripts/run_app.sh staging <device-id>

# Run prod flavor
./scripts/run_app.sh prod
```

### Manual Run

```bash
# Always run from packages/app/ directory
cd packages/app

# Dev flavor
flutter run -t lib/main_dev.dart

# Staging flavor
flutter run -t lib/main_staging.dart

# Prod flavor
flutter run -t lib/main_prod.dart
```

---

## 🔨 Building the App

### iOS Builds

```bash
# Debug build (dev flavor)
./scripts/build_ios.sh dev debug

# Release build (prod flavor)
./scripts/build_ios.sh prod release

# Manual build
cd packages/app
flutter build ios --debug --no-codesign -t lib/main_dev.dart
```

### Android Builds

```bash
# Debug build (dev flavor)
./scripts/build_android.sh dev debug

# Release build (prod flavor)
./scripts/build_android.sh prod release

# Manual build
cd packages/app
flutter build apk --release --flavor prod -t lib/main_prod.dart
```

---

## 🧹 Cleaning Build Artifacts

```bash
# Clean entire monorepo (recommended)
./scripts/clean_all.sh

# Manual clean
cd packages/app
flutter clean
rm -rf ios/Pods ios/Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*
```

---

## 📦 Package Dependencies

### Root (`wegig_monorepo`)

- **Purpose:** Workspace-level configuration
- **Dependencies:** None (references `wegig_app` and `core_ui` via path)
- **Usage:** Do NOT run Flutter commands from here

### App Package (`wegig_app`)

- **Location:** `packages/app/`
- **Dependencies:**
  - Firebase services (Auth, Firestore, Storage, Messaging, Analytics, Crashlytics)
  - Google services (Sign In, Maps)
  - Media handling (image picker, cropper, compression)
  - State management (Riverpod)
  - Navigation (go_router)
  - Depends on `core_ui` package
- **Usage:** Run all Flutter commands from this directory

### Core UI Package (`core_ui`)

- **Location:** `packages/core_ui/`
- **Dependencies:** Flutter SDK only
- **Usage:** Provides shared UI components, theme, and utilities

---

## ⚙️ Configuration

### Environment Variables

Create `.env` file in **root directory**:

```bash
APP_ENV=dev
FIREBASE_PROJECT_ID=your-project-id
GOOGLE_MAPS_API_KEY=your-maps-key
ENABLE_PUSH_NOTIFICATIONS=true
```

### Flavors

WeGig supports three flavors:

| Flavor    | Entry Point         | Firebase Project | Use Case      |
| --------- | ------------------- | ---------------- | ------------- |
| `dev`     | `main_dev.dart`     | Development      | Local testing |
| `staging` | `main_staging.dart` | Staging          | QA testing    |
| `prod`    | `main_prod.dart`    | Production       | Live app      |

Configuration files: `packages/app/lib/config/{dev,staging,prod}_config.dart`

---

## 🔄 Common Workflows

### Adding a New Feature

```bash
# 1. Create feature structure in packages/app/lib/features/my_feature/
#    - data/
#    - domain/
#    - presentation/

# 2. If adding shared UI components, create in packages/core_ui/lib/widgets/

# 3. Add dependencies to appropriate pubspec.yaml
cd packages/app  # OR packages/core_ui
flutter pub add <package_name>

# 4. Run build_runner if using Freezed/JSON
cd packages/app
dart run build_runner build --delete-conflicting-outputs
```

### Updating Dependencies

```bash
# Update all packages at once
melos get

# Update specific package
cd packages/app
flutter pub get
```

### Running Tests

```bash
# Run all tests
melos test

# Run tests for specific package
cd packages/app
flutter test
```

---

## 🐛 Troubleshooting

### "Couldn't resolve the package 'wegig_app'"

**Cause:** Running Flutter commands from root directory  
**Fix:** Always `cd packages/app` before running Flutter commands

### Xcode Build Hanging at Linker Stage

**Cause:** Large dependency tree overwhelming Xcode linker  
**Fix:**

1. `killall -9 xcodebuild ld clang`
2. `./scripts/clean_all.sh`
3. `cd packages/app && flutter build ios ...`

### "database is locked" Error

**Cause:** Concurrent builds or stale lock files  
**Fix:**

1. `killall -9 xcodebuild`
2. `rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*/Build/Intermediates.noindex/XCBuildData/build.db*`

### Package Resolution Errors After Restructure

**Fix:**

```bash
./scripts/clean_all.sh
cd packages/app
flutter pub get
cd ios && pod install
```

---

## 📚 Related Documentation

- [Deep Linking Guide](../DEEP_LINKING_GUIDE.md)
- [Multi-Profile Refactoring](../SESSION_14_MULTI_PROFILE_REFACTORING.md)
- [Navigation Transitions Audit](../NAVIGATION_TRANSITIONS_AUDIT.md)
- [Typed Routes](../SESSION_TASK_11_TYPED_ROUTES.md)
- [Design System](../docs/design/DESIGN_SYSTEM_REPORT.md)
- [Xcode Build Analysis](../XCODE_BUILD_ANALYSIS_2025-12-01.md)

---

## 🛠️ Melos Commands

WeGig uses [Melos](https://melos.invertase.dev/) for monorepo management:

```bash
# Bootstrap all packages
melos bootstrap

# Get dependencies for all packages
melos get

# Run code generation for all packages
melos run build_runner

# Analyze all packages
melos analyze

# Test all packages
melos test

# Clean all packages
melos clean
```

See `melos.yaml` for all available commands.

---

## 🎯 Best Practices

1. **Always run Flutter commands from `packages/app/`** - Never from root
2. **Use helper scripts** - They handle directory navigation automatically
3. **Clean before major changes** - Run `./scripts/clean_all.sh` to reset state
4. **Keep packages focused:**
   - `app/`: Business logic, features, Firebase integration
   - `core_ui/`: Reusable UI components, theme, utilities
5. **Test after dependency updates** - Run `melos test` to catch breaking changes
6. **Follow Clean Architecture** - Keep features isolated in `data → domain → presentation` layers

---

## 📝 Notes

- **Firebase Rules/Indexes:** Located at repo root (`firestore.rules`, `firestore.indexes.json`)
- **Cloud Functions:** Separate Node.js project at `functions/`
- **Navigation:** Centralized typed routes in `packages/app/lib/app/router/`
- **State Management:** Handwritten Riverpod providers (no code generation for providers)

---

**For detailed setup instructions, see [START_HERE_FIREBASE.md](../START_HERE_FIREBASE.md)**
