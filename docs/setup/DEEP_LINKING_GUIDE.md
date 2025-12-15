# Deep Linking Implementation Guide

**Status:** ✅ **CONFIGURED** (Platform setup complete)

---

## 📱 What is Deep Linking?

Deep linking allows users to open specific content in your app directly from:

- Links shared on social media
- Email campaigns
- QR codes
- Web browsers
- Push notifications

---

## 🎯 Supported Deep Links

### App Scheme (`wegig://`)

**Profile:**

```
wegig://app/profile/PROFILE_ID
```

**Post:**

```
wegig://app/post/POST_ID
```

**Conversation:**

```
wegig://app/conversation/CONVERSATION_ID?otherUserId=USER_ID&otherProfileId=PROFILE_ID
```

### Universal Links (`https://wegig.app/`)

**Profile:**

```
https://wegig.app/profile/PROFILE_ID
```

**Post:**

```
https://wegig.app/post/POST_ID
```

**Conversation:**

```
https://wegig.app/conversation/CONVERSATION_ID
```

---

## ✅ Platform Configuration

### Android (`AndroidManifest.xml`)

✅ **Already configured** with:

```xml
<!-- Deep Links: wegig://app/* -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="wegig" android:host="app" />
</intent-filter>

<!-- Universal Links: https://wegig.app/* -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="wegig.app" />
</intent-filter>
```

### iOS (`Info.plist`)

✅ **Already configured** with:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>wegig</string>
        </array>
    </dict>
</array>
<key>FlutterDeepLinkingEnabled</key>
<true/>
```

---

## 🌐 Universal Links Setup

### 1. Android Asset Links (`assetlinks.json`)

**File:** `docs/.well-known/assetlinks.json`

**Location:** Must be served at `https://wegig.app/.well-known/assetlinks.json`

**Current content:**

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.example.wegig",
      "sha256_cert_fingerprints": ["YOUR_SHA256_CERT_FINGERPRINT_HERE"]
    }
  }
]
```

**⚠️ TODO:**

1. Replace `YOUR_SHA256_CERT_FINGERPRINT_HERE` with your app's SHA-256 fingerprint
2. Get fingerprint: `keytool -list -v -keystore your-release.keystore`
3. Upload to `https://wegig.app/.well-known/assetlinks.json`

### 2. Apple App Site Association

**File:** `docs/.well-known/apple-app-site-association`

**Location:** Must be served at `https://wegig.app/.well-known/apple-app-site-association`

**Current content:**

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "YOUR_TEAM_ID.com.example.wegig",
        "paths": ["/profile/*", "/post/*", "/conversation/*", "/"]
      }
    ]
  }
}
```

**⚠️ TODO:**

1. Replace `YOUR_TEAM_ID` with your Apple Developer Team ID
2. Replace `com.example.wegig` with your actual bundle identifier
3. Upload to `https://wegig.app/.well-known/apple-app-site-association`
4. Ensure file is served with `Content-Type: application/json`
5. Add domain to Xcode: **Signing & Capabilities** → **Associated Domains** → `applinks:wegig.app`

---

## 🔧 Router Integration

### GoRouter Configuration

✅ **Already integrated** in `lib/app/router/app_router.dart`:

```dart
GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/profile/:profileId',
      builder: (context, state) {
        final profileId = state.pathParameters['profileId']!;
        return ViewProfilePage(profileId: profileId);
      },
    ),
    GoRoute(
      path: '/post/:postId',
      builder: (context, state) {
        final postId = state.pathParameters['postId']!;
        return PostDetailPage(postId: postId);
      },
    ),
    GoRoute(
      path: '/conversation/:conversationId',
      builder: (context, state) {
        final conversationId = state.pathParameters['conversationId']!;
        final otherUserId = state.uri.queryParameters['otherUserId'];
        final otherProfileId = state.uri.queryParameters['otherProfileId'];
        return ChatDetailPage(
          conversationId: conversationId,
          otherUserId: otherUserId ?? '',
          otherProfileId: otherProfileId ?? '',
        );
      },
    ),
  ],
);
```

**GoRouter automatically handles deep links!** No additional code needed.

---

## 🧪 Testing Deep Links

### Android (adb)

```bash
# Test app scheme
adb shell am start -W -a android.intent.action.VIEW \
  -d "wegig://app/profile/PROFILE_ID" com.example.wegig

# Test Universal Link
adb shell am start -W -a android.intent.action.VIEW \
  -d "https://wegig.app/profile/PROFILE_ID" com.example.wegig
```

### iOS (xcrun)

```bash
# Test app scheme
xcrun simctl openurl booted "wegig://app/profile/PROFILE_ID"

# Test Universal Link
xcrun simctl openurl booted "https://wegig.app/profile/PROFILE_ID"
```

### Manual Testing

1. **Send link via Messages/WhatsApp:**

   - Tap link → Should open app

2. **QR Code:**

   - Generate QR for `wegig://app/profile/123`
   - Scan with camera → Should open app

3. **Browser:**
   - Open `https://wegig.app/profile/123` in Safari/Chrome
   - Should show banner "Open in WeGig app"

---

## 📊 Analytics Tracking

✅ **Already integrated** - All deep link navigations are automatically tracked:

```dart
void _logNavigation(String screenName, Map<String, String> parameters) {
  FirebaseAnalytics.instance.logEvent(
    name: 'navigate_$screenName',
    parameters: parameters,
  );
  FirebaseAnalytics.instance.logScreenView(
    screenName: screenName,
    screenClass: screenName,
  );
}
```

**Events logged:**

- `navigate_profile` with `profileId`
- `navigate_post_detail` with `postId`
- `navigate_conversation` with `conversationId`

---

## 🎨 Share Links Generation

Use existing `DeepLinkGenerator` from `core_ui`:

```dart
import 'package:core_ui/utils/deep_link_generator.dart';

// Generate profile link
final profileLink = DeepLinkGenerator.profileLink(profileId);
// Returns: "https://wegig.app/profile/$profileId"

// Generate post link
final postLink = DeepLinkGenerator.postLink(postId);
// Returns: "https://wegig.app/post/$postId"

// Share via Share Plus
Share.share(
  'Confira meu perfil: $profileLink',
  subject: 'Perfil no WeGig',
);
```

---

## 🚀 Deployment Checklist

### Android

- [x] Deep link scheme configured in AndroidManifest.xml
- [x] Universal Links intent-filter added
- [ ] Generate SHA-256 fingerprint from release keystore
- [ ] Update `assetlinks.json` with correct fingerprint
- [ ] Upload `assetlinks.json` to https://wegig.app/.well-known/assetlinks.json
- [ ] Verify file is accessible (HTTP 200)
- [ ] Test with `adb` commands

### iOS

- [x] CFBundleURLSchemes added to Info.plist
- [x] FlutterDeepLinkingEnabled set to true
- [ ] Get Apple Developer Team ID
- [ ] Update `apple-app-site-association` with Team ID
- [ ] Upload to https://wegig.app/.well-known/apple-app-site-association
- [ ] Ensure served with correct Content-Type
- [ ] Add Associated Domain in Xcode
- [ ] Test with `xcrun` commands

### Firebase

- [ ] Add `wegig.app` to Firebase Dynamic Links (optional)
- [ ] Configure short link domain (optional)
- [ ] Add Analytics events dashboard

---

## 📈 Next Steps

### 1. Complete Universal Links Setup

**Priority:** HIGH

**Actions:**

1. Obtain Android SHA-256 fingerprint
2. Obtain Apple Team ID
3. Update JSON files
4. Upload to web server
5. Add Associated Domain in Xcode

**Time:** 30 minutes

### 2. Add Firebase Dynamic Links (Optional)

**Priority:** MEDIUM

**Benefits:**

- Click tracking
- Custom short URLs
- Social media preview cards
- Platform-specific routing

**Time:** 1 hour

### 3. Add Deep Link Attribution (Optional)

**Priority:** LOW

**Track:**

- Which links get most clicks
- Conversion from link to sign-up
- Most shared content

**Time:** 2 hours

---

## 🐛 Troubleshooting

### Android: Link opens in browser instead of app

**Cause:** App not verified or `assetlinks.json` not accessible

**Solution:**

```bash
# Verify assetlinks.json is accessible
curl https://wegig.app/.well-known/assetlinks.json

# Check app verification status
adb shell pm get-app-links com.example.wegig
```

### iOS: Link doesn't open app

**Cause:** Associated Domain not configured

**Solution:**

1. Open Xcode project
2. Go to **Signing & Capabilities**
3. Add **Associated Domains** capability
4. Add domain: `applinks:wegig.app`

### GoRouter not handling deep link

**Cause:** Route path doesn't match deep link path

**Solution:**
Ensure GoRouter routes match deep link paths exactly:

```dart
// Deep link: wegig://app/profile/123
// Route must be: /profile/:profileId
GoRoute(path: '/profile/:profileId', ...)
```

---

## 📚 Resources

- [Flutter Deep Linking Guide](https://docs.flutter.dev/ui/navigation/deep-linking)
- [Android App Links](https://developer.android.com/training/app-links)
- [iOS Universal Links](https://developer.apple.com/ios/universal-links/)
- [GoRouter Deep Linking](https://pub.dev/documentation/go_router/latest/topics/Deep%20linking-topic.html)
- [Firebase Dynamic Links](https://firebase.google.com/docs/dynamic-links)

---

## ✅ Summary

**Platform Configuration:** ✅ COMPLETE

- Android: Deep links + Universal Links configured
- iOS: URL Schemes + Universal Links ready

**Router Integration:** ✅ COMPLETE

- All routes support deep linking
- Analytics tracking enabled

**Pending Actions:**

- [ ] Get SHA-256 fingerprint (Android)
- [ ] Get Apple Team ID (iOS)
- [ ] Upload `.well-known` files to web server
- [ ] Add Associated Domain in Xcode
- [ ] Test on physical devices

**Estimated Time to Production:** 30-60 minutes (just configuration, no coding needed!)
