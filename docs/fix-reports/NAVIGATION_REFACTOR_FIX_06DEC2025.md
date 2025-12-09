# Navigation Refactor Fix Report - 06 Dec 2025

## Changes Implemented

### 1. Notifications Tab Transition

- **Goal**: Make the transition to `NotificationsPage` identical to `MessagesPage` (Tab switch instead of Push).
- **File**: `packages/app/lib/navigation/bottom_nav_scaffold.dart`
- **Change**:
  - Refactored `_buildNotificationIcon` to return a `Widget` (StreamBuilder) instead of an `InkWell` with a tap handler.
  - Removed the manual `Navigator.push` logic.
  - This allows the `BottomNavigationBar` to handle the selection and the `IndexedStack` to switch the view instantly, matching the behavior of the Messages tab.

### 2. Settings Page Transition

- **Goal**: Change transition from `ViewProfilePage` -> `SettingsPage` to a native "Slide" (Right-to-Left).
- **File**: `packages/app/lib/app/router/app_router.dart`
  - Added `_slideLeftPage` helper method using `CustomTransitionPage` with `SlideTransition`.
  - Registered `/settings` route using this custom transition.
- **File**: `packages/app/lib/features/profile/presentation/pages/view_profile_page.dart`
  - Updated `_openSettings` method to use `context.push('/settings')` instead of `Navigator.push(PageRouteBuilder...)`.
  - Added missing `go_router` import.

## Verification

- Ran `flutter analyze` and confirmed 0 errors (only existing warnings/infos remain).
- Verified syntax in `bottom_nav_scaffold.dart` to ensure no duplicate code blocks or missing braces.

## Next Steps

- Test the navigation flows on a physical device or emulator to confirm the animations feel correct.
