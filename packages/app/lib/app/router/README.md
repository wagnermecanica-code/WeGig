# Type-Safe Navigation Guide

## Overview

O sistema de navegação usa **type-safe route classes** e **extension methods** para garantir navegação segura em compile-time.

## Benefits

✅ **Compile-time safety** - Erros de digitação são detectados antes de executar  
✅ **Autocomplete** - IDE sugere rotas disponíveis  
✅ **Refactoring-friendly** - Mudar nome de rota atualiza todos os usos  
✅ **Type-safe parameters** - IDs obrigatórios como parâmetros tipados

## Usage

### Import

```dart
import 'package:wegig_app/app/router/app_router.dart';
```

### Basic Navigation

```dart
// ❌ OLD WAY (string-based, error-prone)
context.go('/home');
context.go('/profile/$profileId'); // Typo risk!

// ✅ NEW WAY (type-safe)
context.goToHome();
context.goToProfile(profileId); // Compile-time safety!
```

### All Available Routes

```dart
// Navigate to auth page
context.goToAuth();

// Navigate to home
context.goToHome();

// Navigate to create profile
context.goToCreateProfile();

// Navigate to profile (requires ID)
context.goToProfile(String profileId);

// Navigate to post detail (requires ID)
context.goToPostDetail(String postId);

// Navigate to conversation/chat (requires ID + optional params)
context.goToConversation(
  String conversationId, {
  String? otherUserId,
  String? otherProfileId,
  String? otherUserName,
  String? otherUserPhoto,
});

// Navigate to edit profile (requires ID)
context.goToEditProfile(String profileId);

// Push (adds to stack instead of replacing)
context.pushProfile(String profileId);
context.pushPostDetail(String postId);
context.pushConversation(String conversationId, {...});
context.pushEditProfile(String profileId);
```

### Route Paths (if needed for direct use)

```dart
// Access route paths directly
AppRoutes.home                  // '/home'
AppRoutes.auth                  // '/auth'
AppRoutes.createProfile         // '/profiles/new'
AppRoutes.profile(id)           // '/profile/:id'
AppRoutes.postDetail(id)        // '/post/:id'
AppRoutes.conversation(id)      // '/conversation/:id'
AppRoutes.editProfile(id)       // '/profile/:id/edit'
```

## Migration from Old Code

```dart
// BEFORE
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => ViewProfilePage(profileId: profileId),
  ),
);

// AFTER
context.pushProfile(profileId);
```

```dart
// BEFORE
context.go('/post/$postId');

// AFTER
context.goToPostDetail(postId);
```

## Auth Guard

O router tem redirect automático:

- **Não autenticado** → Vai para `/auth`
- **Autenticado sem perfil** → Vai para `/profiles/new`
- **Autenticado com perfil** → Acesso livre a todas as rotas

## Error Handling

Rota não encontrada mostra página 404 com botão "Voltar ao Início" (type-safe).

## Testing

```dart
// Em testes, use os métodos tipados
testWidgets('should navigate to profile', (tester) async {
  await tester.pumpWidget(MyApp());

  // Type-safe navigation
  tester.state<NavigatorState>(find.byType(Navigator))
    .context.goToProfile('profile123');

  await tester.pumpAndSettle();
  expect(find.byType(ViewProfilePage), findsOneWidget);
});
```

## Implementation Details

### Route Classes

```dart
class AppRoutes {
  static const String auth = '/auth';
  static const String home = '/home';
  static String profile(String profileId) => '/profile/$profileId';
  // ...
}
```

### Extension Methods

```dart
extension TypedNavigationExtension on BuildContext {
  void goToProfile(String profileId) => go(AppRoutes.profile(profileId));
  // ...
}
```

## 📊 Firebase Analytics

✅ **Automatic tracking enabled!**

All navigation methods automatically log events to Firebase Analytics:

```dart
context.pushProfile(profileId);
// Logs: 'navigate_profile' with parameter profileId
// Logs: screen_view with screenName='profile'

context.goToPostDetail(postId);
// Logs: 'navigate_post_detail' with parameter postId
// Logs: screen_view with screenName='post_detail'
```

**Events tracked:**

- `navigate_auth`
- `navigate_home`
- `navigate_profile` (with `profileId`)
- `navigate_post_detail` (with `postId`)
- `navigate_conversation` (with `conversationId`)
- `navigate_edit_profile` (with `profileId`)

**View analytics in Firebase Console:**

```
Firebase Console → Analytics → Events → navigate_*
```

## 🔗 Deep Linking

✅ **Fully configured!**

### Supported URLs

**App Scheme (always works):**

```
wegig://app/profile/PROFILE_ID
wegig://app/post/POST_ID
wegig://app/conversation/CONVERSATION_ID
```

**Universal Links (requires web setup):**

```
https://wegig.app/profile/PROFILE_ID
https://wegig.app/post/POST_ID
https://wegig.app/conversation/CONVERSATION_ID
```

### Testing Deep Links

**Android:**

```bash
adb shell am start -W -a android.intent.action.VIEW \
  -d "wegig://app/profile/123" com.example.wegig
```

**iOS Simulator:**

```bash
xcrun simctl openurl booted "wegig://app/profile/123"
```

**Production Setup:**
See `DEEP_LINKING_GUIDE.md` for complete configuration.

## Future Improvements

- [x] Add query parameters support (✅ Conversation route)
- [x] Add deep linking configuration (✅ Android + iOS)
- [x] Add analytics tracking per route (✅ All routes)
- [ ] Add route guards for premium features
- [ ] Add Firebase Dynamic Links for sharing
