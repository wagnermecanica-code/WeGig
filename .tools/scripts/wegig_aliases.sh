#!/usr/bin/env zsh
# Convenience aliases/functions for WeGig development and deployment
# Usage: source "/path/to/to_sem_banda/.tools/scripts/wegig_aliases.sh" in your ~/.zshrc

# Deploy the app to a connected device (release, dev flavor)
wegig_deploy() {
  REPO_ROOT="/Users/wagneroliveira/to_sem_banda"
  APP_DIR="$REPO_ROOT/packages/app"

  echo "==> Building release (dev flavor) in $APP_DIR"
  pushd "$APP_DIR" >/dev/null || return 1
  flutter build ios --flavor dev -t lib/main_dev.dart --release || { echo "Build failed"; popd >/dev/null; return 1; }

  APP_PATH="$APP_DIR/build/ios/iphoneos/WeGig.app"
  if [ -d "$APP_PATH" ]; then
    if command -v ios-deploy >/dev/null 2>&1; then
      echo "==> Installing $APP_PATH to attached device"
      ios-deploy --bundle "$APP_PATH" || { echo "ios-deploy failed"; popd >/dev/null; return 1; }
    else
      echo "==> Build produced $APP_PATH — install it from Xcode or with ios-deploy"
    fi
  else
    echo "==> App not found at $APP_PATH"
    popd >/dev/null
    return 1
  fi

  popd >/dev/null
  echo "==> Deploy finished"
}

# Deploy and then tail logs from the device (prefer idevicesyslog if available)
wegig_deploy_watch() {
  wegig_deploy || return 1

  echo "==> Starting log tail. Press Ctrl+C to stop."

  # Prefer idevicesyslog for raw device logs, fallback to `flutter logs`
  if command -v idevicesyslog >/dev/null 2>&1; then
    idevicesyslog | grep -i --line-buffered "WeGig\|flutter\|permission\|ERROR\|Exception"
  else
    echo "idevicesyslog not found — falling back to 'flutter logs' (requires Flutter device connection)"
    flutter logs || true
  fi
}

# Tail Firebase Functions logs (example). Replace <FUNCTION_NAME> as needed.
wegig_fn_logs() {
  PROJECT="wegig-dev"
  if [ -z "$1" ]; then
    echo "Usage: wegig_fn_logs <FUNCTION_NAME>"
    return 1
  fi
  FUNCTION_NAME="$1"
  echo "==> Tailing logs for function: $FUNCTION_NAME (project: $PROJECT)"
  firebase functions:log --project "$PROJECT" --only "$FUNCTION_NAME"
}

# Shorter aliases for interactive shells
alias wegig-deploy='wegig_deploy'
alias wegig-deploy-watch='wegig_deploy_watch'
alias wegig-fn-logs='wegig_fn_logs'

# Helpful note when sourced
echo "Loaded WeGig aliases: wegig-deploy, wegig-deploy-watch, wegig-fn-logs"
