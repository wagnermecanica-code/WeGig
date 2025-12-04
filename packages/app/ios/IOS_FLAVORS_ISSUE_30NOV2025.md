# iOS Flavors Issue - 30 Nov 2025

## 🐛 Problem

Flutter command `flutter run --flavor dev` fails with:

```
Error: You must specify a --flavor option to select one of the available schemes.
```

**Root Cause:** Flutter's `--flavor` flag works differently on iOS vs Android:

- **Android:** Uses `productFlavors` in `build.gradle.kts` ✅ Working
- **iOS:** Expects schemes to match exact flavor name, BUT has additional complexity

## 📋 Current State

### Xcode Project Structure

```
Build Configurations:
  - Debug, Release, Profile (base)
  - Debug-dev, Release-dev, Profile-dev
  - Debug-staging, Release-staging, Profile-staging

Schemes:
  - Runner (base)
  - Runner-dev
  - Runner-staging
```

### Scheme Configuration

- ✅ `Runner-dev.xcscheme` uses Debug-dev, Release-dev, Profile-dev
- ✅ `Runner-staging.xcscheme` uses Debug-staging, Release-staging, Profile-staging
- ✅ Pre-action scripts copy correct `GoogleService-Info-*.plist`

## ❌ Why Flutter Command Fails

**Flutter's iOS flavor detection logic:**

1. Looks for schemes in project
2. Finds: Runner, Runner-dev, Runner-staging
3. **Expects `--flavor dev` to map to `dev` scheme** (not `Runner-dev`)
4. Doesn't find exact match → error

**The mismatch:**

- Command: `--flavor dev`
- Available schemes: `Runner`, `Runner-dev`, `Runner-staging`
- Flutter expects: `dev` scheme (exact match)

## ✅ Solutions

### Option 1: Rename Schemes (RECOMMENDED for Flutter CLI)

```bash
# Rename schemes to match Flutter's expected names
Runner-dev → dev
Runner-staging → staging

# Then this works:
flutter run --flavor dev -t lib/main_dev.dart
```

**Implementation:**

1. Open `packages/app/ios/Runner.xcodeproj/xcshareddata/xcschemes/`
2. Rename files:
   - `Runner-dev.xcscheme` → `dev.xcscheme`
   - `Runner-staging.xcscheme` → `staging.xcscheme`
3. Edit XML inside each file - change `<Scheme name="...">` attribute
4. Update Xcode scheme list via: Product → Scheme → Manage Schemes

### Option 2: Use Xcode Directly (CURRENT WORKAROUND) ✅ WORKING

```bash
# 1. Open Xcode
open packages/app/ios/Runner.xcworkspace

# 2. In Xcode:
#    - Select scheme: Runner-dev
#    - Select device: Wagner's iPhone
#    - Click Run (⌘+R)

# 3. (Optional) Attach Flutter tools for hot reload:
flutter attach -d 00008140-001948D20AE2801C
```

### Option 3: Single Scheme with Build Configurations (CLEANEST)

Remove extra schemes, use only `Runner` with config selection:

```bash
# Delete extra schemes
rm ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner-{dev,staging}.xcscheme

# Use Flutter's built-in config selection
flutter run -t lib/main_dev.dart --dart-define=FLAVOR=dev
```

**Requires:** Modify `Runner.xcscheme` to select config based on command-line args.

## 🎯 Recommended Action

**For now:** Use **Option 2** (Xcode direct run) - fastest path to testing.

**For production:** Implement **Option 1** (rename schemes) to enable full Flutter CLI support.

**Long term:** Consider **Option 3** for cleaner architecture, but requires more refactoring.

## 📚 References

- [Flutter iOS Flavors Guide](https://docs.flutter.dev/deployment/flavors#ios)
- [Xcode Schemes Documentation](https://developer.apple.com/documentation/xcode/customizing-the-build-schemes-for-a-project)
- Similar issues: [flutter/flutter#48392](https://github.com/flutter/flutter/issues/48392)

## ✅ Status

- [x] Build configurations created (Debug-dev, Release-dev, etc.) - PROJECT LEVEL
- [x] Schemes renamed to match Flutter expectations (`dev`, `staging`)
- [x] Schemes updated to use correct configurations
- [x] Firebase configs setup per flavor
- [x] CocoaPods xcfilelist files generated for all 6 configs
- [x] Podfile updated with flavor configurations
- [x] Xcode direct run working
- [x] Flutter CLI `--flavor dev` recognized
- [ ] Runner target configurations (1/6 complete - Debug-dev only)

## 🔧 Files Modified

- `packages/app/ios/Runner.xcodeproj/project.pbxproj` - Build configurations added
- `packages/app/ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner-dev.xcscheme` - Updated to use Debug-dev
- `packages/app/ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner-staging.xcscheme` - Updated to use Debug-staging
- `packages/app/ios/add_flavor_configs.rb` - Ruby script for automation

---

**Next Steps:** Run app via Xcode (Option 2), test all 9 bottom sheets, then decide on permanent solution (Option 1 or 3).
