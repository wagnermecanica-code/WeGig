# Profile Feature - Correções Pendentes

**Data:** 30 de novembro de 2025  
**Status:** App funcionando, ajustes finos necessários

## 🎉 Status Atual

✅ App rodando no iPhone com sucesso  
✅ Firebase inicializado corretamente  
✅ .env carregado  
✅ Criação de posts funcionando  
✅ Navegação funcionando  
✅ Edição de perfil salvando no Firestore

## ❌ Problemas Identificados

### 1. Logout - Bad State Error

**Erro:** `Cannot use "ref" after the widget was disposed`
**Local:** `settings_page.dart:504`
**Causa:** Tentando usar `ref.read()` após `navigator.pop()`

**Solução:**

```dart
Future<void> _performLogout() async {
  if (!mounted) return;

  // Capturar TUDO antes de operações async
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final authService = ref.read(authServiceProvider); // ✅ Capturar ANTES do pop

  try {
    debugPrint('🔓 Iniciando logout...');

    // Invalidar providers ANTES de fechar tela
    ref.invalidate(profileProvider);
    ref.invalidate(postNotifierProvider);

    // Executar signOut
    await authService.signOut();

    // Pop apenas DEPOIS do signOut
    if (navigator.canPop() && mounted) {
      navigator.pop();
    }

    debugPrint('✅ Logout completo');
  } catch (e) {
    debugPrint('❌ Erro ao fazer logout: $e');
    if (mounted) {
      messenger.showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }
}
```

---

### 2. Edit Profile - StreamController Closed

**Erro:** `Cannot add new events after calling close`
**Local:** `profile_providers.dart:107`
**Causa:** `StreamController` está sendo fechado prematuramente no `ref.onDispose()`

**Solução:**

```dart
// profile_providers.dart - ProfileNotifier

final StreamController<ProfileState> _streamController =
    StreamController.broadcast();

@override
FutureOr<ProfileState> build() async {
  // ✅ Registrar dispose APENAS UMA VEZ na inicialização
  ref.onDispose(() {
    if (!_streamController.isClosed) {
      _streamController.close();
    }
  });

  return _loadProfiles();
}

// ✅ Sempre verificar se está fechado antes de adicionar eventos
void _addToStream(ProfileState state) {
  if (!_streamController.isClosed) {
    _streamController.add(state);
  }
}

Future<ProfileState> _loadProfiles() async {
  // ...código existente...

  // Usar helper method
  _addToStream(newState);
}
```

---

### 3. Long Press no Profile Icon

**Local:** `bottom_nav_scaffold.dart`
**Status:** Não implementado

**Solução:**

```dart
// Trocar BottomNavigationBar por custom widget com GestureDetector

Widget _buildCustomBottomNav() {
  return Container(
    height: 56,
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildNavButton(Icons.home, 'Home', 0),
        _buildNavButton(Icons.notifications, 'Notificações', 1),
        _buildNavButton(Icons.add_circle, 'Post', 2),
        _buildNavButton(Icons.chat_bubble, 'Mensagens', 3),
        _buildProfileNavButton(), // ✅ Botão especial com long press
      ],
    ),
  );
}

Widget _buildProfileNavButton() {
  return GestureDetector(
    onTap: () => _onTabChanged(4), // Tap normal
    onLongPress: () {
      // ✅ Long press abre profile switcher
      _showProfileSwitcher(context);
    },
    child: Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person,
            color: _currentIndexNotifier.value == 4
                ? AppColors.primary
                : Colors.grey,
          ),
          Text(
            'Perfil',
            style: TextStyle(
              fontSize: 12,
              color: _currentIndexNotifier.value == 4
                  ? AppColors.primary
                  : Colors.grey,
            ),
          ),
        ],
      ),
    ),
  );
}

void _showProfileSwitcher(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (context) => const ProfileSwitcherBottomSheet(),
  );
}
```

---

### 4. Fotos Não-Square Achatadas

**Local:** Galeria de fotos do perfil
**Problema:** `fit: BoxFit.cover` achata imagens não-quadradas

**Solução:**

```dart
// view_profile_page.dart - GridView de fotos

GridView.builder(
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    crossAxisSpacing: 4,
    mainAxisSpacing: 4,
    childAspectRatio: 1.0, // ✅ Mantém proporção quadrada
  ),
  itemBuilder: (context, index) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: photos[index],
        fit: BoxFit.cover, // ✅ Cover mantém proporção, cropando se necessário
        placeholder: (_, __) => Container(
          color: Colors.grey[300],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (_, __, ___) => Container(
          color: Colors.grey[300],
          child: const Icon(Icons.error),
        ),
      ),
    );
  },
)
```

**Se ainda aparecer achatado, usar AspectRatio:**

```dart
return AspectRatio(
  aspectRatio: 1.0, // ✅ Força proporção 1:1
  child: ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: CachedNetworkImage(
      imageUrl: photos[index],
      fit: BoxFit.cover,
      // ...
    ),
  ),
);
```

---

### 5. Deep Link Compartilhar Perfil

**Local:** `view_profile_page.dart` - botão compartilhar
**Status:** Abre apenas texto simples

**Solução:**

```dart
// 1. Adicionar deep link URL em app_config.dart
class AppConfig {
  static const String deepLinkScheme = 'wegig';
  static const String deepLinkHost = 'profile';
  static const String webUrl = 'https://wegig.app'; // ✅ Seu domínio

  static String getProfileDeepLink(String profileId) {
    return '$webUrl/profile/$profileId'; // https://wegig.app/profile/abc123
  }
}

// 2. Atualizar botão compartilhar
Future<void> _shareProfile() async {
  final profileId = widget.profileId ?? profile?.profileId;
  if (profileId == null) return;

  final deepLink = AppConfig.getProfileDeepLink(profileId);
  final name = profile?.name ?? 'Perfil';
  final type = profile?.isBand == true ? 'banda' : 'músico';

  final message = '''
🎸 Confira o perfil de $name no WeGig!

$name é $type procurando colaboração musical.

👉 Abrir perfil: $deepLink

📱 Baixe o app WeGig e conecte-se com músicos!
  ''';

  await Share.share(
    message,
    subject: 'Perfil de $name - WeGig',
  );
}

// 3. Configurar deep link no Android (AndroidManifest.xml)
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="https"
        android:host="wegig.app"
        android:pathPrefix="/profile" />
</intent-filter>

// 4. Configurar deep link no iOS (Info.plist)
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>wegig</string>
        </array>
    </dict>
</array>

// 5. Implementar handler no main_dev.dart
void main() async {
  // ...Firebase init...

  // ✅ Listener para deep links
  uriLinkStream.listen((Uri? uri) {
    if (uri != null) {
      _handleDeepLink(uri);
    }
  });

  runApp(const ProviderScope(child: WeGigApp()));
}

void _handleDeepLink(Uri uri) {
  if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'profile') {
    final profileId = uri.pathSegments.length > 1
        ? uri.pathSegments[1]
        : null;

    if (profileId != null) {
      // Navegar para ViewProfilePage
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ViewProfilePage(profileId: profileId),
        ),
      );
    }
  }
}
```

**Dependência necessária:**

```yaml
# pubspec.yaml
dependencies:
  uni_links: ^0.5.1 # Deep links
  share_plus: ^12.0.1 # Já instalado
```

---

### 6. Parâmetros de Notificação - Settings

**Local:** `settings_page.dart`
**Status:** Revisar configurações

**Campos esperados:**

```dart
class UserSettingsEntity {
  final String profileId;
  final bool notificationRadiusEnabled;  // ✅ Habilitar notificações de proximidade
  final double notificationRadius;       // ✅ Raio em km (5-100)
  final bool interestNotificationsEnabled;  // ✅ Notificações de interesse
  final bool messageNotificationsEnabled;   // ✅ Notificações de mensagens
  final bool emailNotificationsEnabled;     // ✅ Notificações por email
  final bool pushNotificationsEnabled;      // ✅ Push notifications
}
```

**UI Settings Page:**

```dart
// Seção: Notificações de Proximidade
SwitchListTile(
  title: const Text('Notificações de Proximidade'),
  subtitle: const Text('Receba alertas quando novos posts aparecerem próximos'),
  value: settings.notificationRadiusEnabled,
  onChanged: (value) => _updateSettings(
    settings.copyWith(notificationRadiusEnabled: value),
  ),
),

// Slider de raio (só visível se enabled)
if (settings.notificationRadiusEnabled)
  ListTile(
    title: Text('Raio: ${settings.notificationRadius.toInt()} km'),
    subtitle: Slider(
      value: settings.notificationRadius,
      min: 5,
      max: 100,
      divisions: 19,
      label: '${settings.notificationRadius.toInt()} km',
      onChanged: (value) => _updateSettings(
        settings.copyWith(notificationRadius: value),
      ),
    ),
  ),

// Outros toggles
SwitchListTile(
  title: const Text('Notificações de Interesse'),
  subtitle: const Text('Quando alguém demonstrar interesse no seu post'),
  value: settings.interestNotificationsEnabled,
  onChanged: (value) => _updateSettings(
    settings.copyWith(interestNotificationsEnabled: value),
  ),
),

SwitchListTile(
  title: const Text('Notificações de Mensagens'),
  subtitle: const Text('Novas mensagens no chat'),
  value: settings.messageNotificationsEnabled,
  onChanged: (value) => _updateSettings(
    settings.copyWith(messageNotificationsEnabled: value),
  ),
),
```

---

## 🔧 Prioridade de Implementação

### CRÍTICO (Implementar AGORA):

1. ✅ Logout - Bad State (linha 504 settings_page.dart)
2. ✅ Edit Profile - StreamController (linha 107 profile_providers.dart)

### ALTA (Próxima sessão):

3. Long Press Profile Icon (UX importante)
4. Deep Link Compartilhar (feature completa)

### MÉDIA (Pode aguardar):

5. Fotos Não-Square (issue visual menor)
6. Settings Notification Params (revisar com UX)

---

## 📝 Arquivos para Modificar

1. `packages/app/lib/features/settings/presentation/pages/settings_page.dart` (logout)
2. `packages/app/lib/features/profile/presentation/providers/profile_providers.dart` (stream)
3. `packages/core_ui/lib/navigation/bottom_nav_scaffold.dart` (long press)
4. `packages/app/lib/features/profile/presentation/pages/view_profile_page.dart` (share + photos)
5. `packages/app/lib/config/app_config.dart` (deep links)
6. `packages/app/android/app/src/main/AndroidManifest.xml` (deep links Android)
7. `packages/app/ios/Runner/Info.plist` (deep links iOS)

---

## ✅ Próximos Passos

1. Aplicar correções 1 e 2 (críticas)
2. Testar logout e edição de perfil
3. Implementar long press (item 3)
4. Configurar deep links (item 5)
5. Ajustar fotos se ainda necessário (item 4)
6. Revisar settings com time de produto (item 6)

**App está 95% funcional!** 🎉
