# CI/CD Pipeline Testing - Blocked by Git History

## Status

❌ **Unable to push test branch** - Large build artifacts in git history

## Problem

The repository contains build artifacts that exceed GitHub's 100MB file size limit:

```
packages/app/build/app/intermediates/merged_native_libs/stagingDebug/.../libflutter.so (341.85 MB)
packages/app/build/app/intermediates/merged_native_libs/stagingDebug/.../libflutter.so (337.17 MB)
packages/app/build/app/intermediates/merged_native_libs/stagingDebug/.../libflutter.so (300.94 MB)
packages/app/build/app/intermediates/merged_native_libs/stagingDebug/.../libVkLayer_khronos_validation.so (222.24 MB)
packages/app/build/app/outputs/apk/staging/debug/app-staging-debug.apk (160.76 MB)
... and 5 more files
```

These files are in the git history (not just working directory), so `flutter clean` doesn't remove them from commits.

## CI/CD Workflow Created

The workflow file `.github/workflows/ci.yml` was successfully created with:

✅ **Analyze & Test Job** (Ubuntu)

- Flutter setup with caching
- Dependency installation (core_ui + app)
- Code generation with build_runner
- Format verification
- Static analysis
- Unit tests with coverage
- Codecov upload

✅ **iOS Build Job** (macOS)

- Flutter + CocoaPods setup
- Pod install with caching
- iOS debug build (no codesign, dev flavor)
- Build settings verification

✅ **Android Build Job** (Ubuntu)

- Java 17 + Flutter setup
- Gradle caching
- APK build (debug, dev flavor)
- Artifact upload (7-day retention)

## Solution Options

### Option 1: Clean Git History (Recommended for Production)

Remove build artifacts from all commits:

```bash
# Install BFG Repo-Cleaner
brew install bfg

# Backup your repo first!
git clone --mirror https://github.com/wagnermecanica-code/ToSemBandaRepo.git backup.git

# Remove build folder from history
bfg --delete-folders build --no-blob-protection

# Force push cleaned history
git reflog expire --expire=now --all && git gc --prune=now --aggressive
git push --force
```

⚠️ **Warning**: This rewrites history. All team members must re-clone after this.

### Option 2: Update .gitignore and Start Fresh (Easier)

1. Ensure `.gitignore` has:

   ```
   **/build/
   **/.dart_tool/
   **/*.lock  # Except pubspec.lock
   ```

2. Create PR from a clean local branch:

   ```bash
   # Start from a commit before build artifacts were added
   git checkout -b ci-workflows <clean-commit-hash>

   # Add only the workflow
   git add .github/workflows/ci.yml
   git commit -m "ci: Add automated CI/CD pipeline"
   git push origin ci-workflows
   ```

### Option 3: Use GitHub Web UI (Simplest for Testing)

1. Go to GitHub repository
2. Navigate to `.github/workflows/`
3. Click "Add file" → "Create new file"
4. Name it `ci.yml`
5. Copy content from `/Users/wagneroliveira/to_sem_banda/.github/workflows/ci.yml`
6. Commit directly to a new branch
7. Create pull request

This bypasses the local git history issue completely.

## Testing the CI Pipeline

Once the workflow is in a branch/PR:

### Automatic Triggers

- **Push to branch**: Triggers full CI (analyze → iOS/Android builds)
- **Pull Request**: Triggers on PR open/sync
- **Manual**: Use "Actions" tab → "Run workflow"

### Expected Behavior

1. **Analyze & Test** (~3-5 min)

   - Passes if code is formatted
   - Passes if no lint errors
   - Passes if all tests pass
   - Uploads coverage to Codecov

2. **iOS Build** (~8-12 min on macOS runner)

   - Installs 70 CocoaPods
   - Builds Runner.app (debug)
   - Verifies bundle ID and signing settings

3. **Android Build** (~5-8 min on Ubuntu runner)
   - Downloads Gradle dependencies
   - Builds app-dev-debug.apk
   - Uploads APK artifact (downloadable for 7 days)

### First Run Notes

- **First run will be slower** due to cache misses
- **Subsequent runs** will use cached dependencies (3-5x faster)
- **iOS builds require macOS runners** (billed at 10x rate on GitHub)
- **Consider adding caching** for Flutter SDK itself if builds are slow

## Monitoring the Pipeline

### GitHub Actions UI

```
Repository → Actions tab
├── All workflows (left sidebar)
├── Workflow runs (center)
│   ├── analyze-and-test ✓
│   ├── build-ios ✓
│   └── build-android ✓
└── Artifacts (if any)
```

### Status Badges

Add to README.md:

```markdown
![CI Status](https://github.com/wagnermecanica-code/ToSemBandaRepo/actions/workflows/ci.yml/badge.svg)
```

### Notifications

- ✅ Success: Green check on commit
- ❌ Failure: Red X with logs link
- ⚠️ Pending: Yellow dot while running

## Next Steps

1. **Choose a solution** (Option 3 recommended for immediate testing)
2. **Create workflow via GitHub UI** or clean git history
3. **Monitor first CI run** in Actions tab
4. **Fix any failures** (likely CocoaPods or dependency issues)
5. **Merge to develop** once all jobs pass
6. **Configure Codecov** token if coverage uploads fail

## Related Documentation

- `docs/CI_CD_PIPELINE.md` - Complete workflow reference
- `docs/CI_CD_QUICK_START.md` - Step-by-step setup guide
- `docs/CI_CD_COMMANDS.md` - All CI/CD commands
- `docs/CI_CD_VALIDATION_CHECKLIST.md` - Pre-push checklist
- `XCODE_BUILD_ANALYSIS_COMPLETE_04DEC2025.md` - Build troubleshooting

---

**Created**: 2025-12-04  
**Status**: ⏸️ Blocked (awaiting git history cleanup)  
**Impact**: Medium (CI works locally, just can't push to test remotely)
