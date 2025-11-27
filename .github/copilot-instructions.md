`````instructions
````instructions
# Tô Sem Banda – AI Coding Agent Guide

## Project Overview
Flutter app for connecting musicians and bands, using an **Instagram-style multi-profile model**. Each profile is a separate user identity. Location-based search, posts, and chat are core features.

**Tech Stack:** Flutter 3.9.2+, Firebase (Auth, Firestore, Storage, Messaging, Analytics), Google Maps, Geolocator

---

## Architecture & Patterns
- **Multi-profile:**
  - `users/{uid}`: minimal, holds `activeProfileId`.
  - `profiles/{profileId}`: full profile data, acts as user identity.
  - **Always use** the Riverpod `profileProvider` for active profile state and UI updates.
- **Posts:**
  - Every post **must** have `location` (GeoPoint) and `expiresAt`.
  - All post queries **must** filter `expiresAt > now` and paginate with `startAfterDocument`.
  - Never show posts of the active profile in HomePage lists (explicit filter required).
- **Firestore:**
  - Queries depend on `expiresAt`, `city`, `authorProfileId`.
  - **After query/index changes:**
    - `firebase deploy --only firestore:indexes`
    - `firebase deploy --only firestore:rules`
- **Ownership checks:** Always compare against the **active profile** (not UID). See `lib/pages/home_page.dart`, `lib/services/profile_service.dart`.
- **Image handling:**
  - Compress images in an isolate using a top-level function + `compute()` (see `lib/pages/post_page.dart`, `_compressImageIsolate`).
  - Use `CachedNetworkImage` with `memCacheWidth/Height = displaySize * 2` (never use `Image.network`).
- **Pagination:**
  - Use `_lastDoc` + `startAfterDocument` and `_hasMore` flags (see `lib/pages/home_page.dart`, `lib/pages/messages_page.dart`, `lib/pages/chat_detail_page.dart`).
- **Map markers:** Use `lib/services/marker_cache_service.dart` to warm up markers and avoid recreation costs.
- **Debounce/throttle:** Use `lib/utils/debouncer.dart` for location/search inputs (never use raw timers).
- **API keys:** Never hardcode. Load with `EnvService` and `.env` (see `lib/services/env_service.dart`, `.env.example`).

---

## Developer Workflows
- **Setup:**
  - `flutter pub get`
  - `flutter run` (requires iOS/Android google-services and `.env`)
  - `cd functions && npm install`
- **Deploy:**
  - `firebase deploy --only firestore:indexes`
  - `firebase deploy --only firestore:rules`
  - `cd functions && firebase deploy --only functions`
- **Cloud Functions:**
  - Source: `functions/index.js` (see also `functions/package.json` for scripts)
  - Lint: `npm run lint` in `functions/`
  - Logs: `firebase functions:log`
- **iOS:**
  - If `Podfile` changes: `cd ios && pod install`

---

## Debugging & Troubleshooting
- **Query/index errors:** `firestore.indexes.json`, `firestore.rules`
- **Missing GeoPoint/location:** `scripts/check_posts.sh`
- **Profile switching issues:** `lib/services/profile_service.dart`
- **Image upload freezing:** Ensure compression runs in `compute()` isolate
- **Cloud Functions:** See `NEARBY_POST_NOTIFICATIONS.md`, `DEPLOY_CLOUD_FUNCTIONS.md`

---

## Key Reference Files

- `lib/pages/home_page.dart`, `lib/pages/messages_page.dart`, `lib/pages/chat_detail_page.dart` – pagination, filtering
- `lib/services/env_service.dart`, `.env.example` – environment/config
- `lib/services/marker_cache_service.dart` – map marker optimization
- `lib/utils/debouncer.dart` – input debouncing
- `functions/index.js` – Cloud Functions
- `firestore.rules`, `firestore.indexes.json` – security and indexes
- `scripts/check_posts.sh` – data validation
- `NEARBY_POST_NOTIFICATIONS.md`, `DEPLOY_CLOUD_FUNCTIONS.md` – notification system

---

If anything here is unclear or incomplete, or you need code snippets/examples for a specific pattern, please specify which section to expand.
`````
