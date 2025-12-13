# Guia de Boas Práticas - WeGig

> Última atualização: 06/12/2025

Este documento consolida as boas práticas aprendidas durante o desenvolvimento do WeGig, com foco em prevenir bugs comuns e manter a qualidade do código.

---

## 🔥 Firebase & Multi-Ambiente

### ✅ Isolamento de Ambientes

```dart
// ✅ CORRETO - Cada flavor com seu projeto
// main_dev.dart
await bootstrapCoreServices(
  firebaseOptions: DefaultFirebaseOptions.currentPlatform,
  flavorLabel: 'dev',
  expectedProjectId: 'wegig-dev',  // ⚠️ CRITICAL: Validação em runtime
);

// main_prod.dart
await bootstrapCoreServices(
  firebaseOptions: DefaultFirebaseOptions.currentPlatform,
  flavorLabel: 'prod',
  expectedProjectId: 'to-sem-banda-83e19',  // ⚠️ Projeto correto
);
```

### ❌ Erros Comuns

```dart
// ❌ ERRADO - Projeto inconsistente
expectedProjectId: 'wegig-dev',  // Em main_prod.dart!

// ❌ ERRADO - Hardcoded project ID
const projectId = 'to-sem-banda-83e19';  // Não funciona para todos os flavors
```

### 📋 Checklist de Configuração

1. **Android**

   - [ ] `google-services.json` em `android/app/src/dev/`
   - [ ] `google-services.json` em `android/app/src/staging/`
   - [ ] `google-services.json` em `android/app/src/prod/`
   - [ ] `project_id` correto em cada arquivo

2. **iOS**

   - [ ] `GoogleService-Info-dev.plist` em `ios/Firebase/`
   - [ ] `GoogleService-Info-staging.plist` em `ios/Firebase/`
   - [ ] `GoogleService-Info-prod.plist` em `ios/Firebase/`
   - [ ] Build Phase copia plist correto baseado em `$CONFIGURATION`

3. **Flutter**
   - [ ] `firebase_options_dev.dart` com `projectId: 'wegig-dev'`
   - [ ] `firebase_options_staging.dart` com `projectId: 'wegig-staging'`
   - [ ] `firebase_options_prod.dart` com `projectId: 'to-sem-banda-83e19'`
   - [ ] `main_*.dart` com `expectedProjectId` correspondente

---

## 🎭 Multi-Profile Pattern

### ✅ Leitura de Perfil Ativo

```dart
// ✅ CORRETO - Sempre ler do Riverpod
final profileState = ref.read(profileProvider);
final activeProfile = profileState.value?.activeProfile;

if (activeProfile == null) {
  // Handle: usuário não tem perfil ativo
  return;
}

// Usar profileId para queries
final posts = await getPosts(activeProfile.profileId);
```

### ❌ Erros Comuns

```dart
// ❌ ERRADO - Cache local desatualizado
final profileId = SharedPreferences.getString('activeProfileId');  // Pode estar errado após switch

// ❌ ERRADO - Usar no dispose()
@override
void dispose() {
  final profile = ref.read(profileProvider).value?.activeProfile;  // Pode crashar
  super.dispose();
}
```

### 🔄 Invalidação Após Switch

```dart
Future<void> switchProfile(String newProfileId) async {
  await profileRepository.setActiveProfile(newProfileId);

  // ✅ CRITICAL: Invalidar todos os providers dependentes
  ref.invalidate(profileProvider);
  ref.invalidate(postNotifierProvider);
  ref.invalidate(messagesProvider);
  ref.invalidate(notificationsProvider);
}
```

---

## 🗺️ GoRouter Navigation

### ✅ Redirect Logic Correto

```dart
// ✅ CORRETO - Só redireciona rotas iniciais
redirect: (context, state) {
  if (!isLoggedIn) return AppRoutes.auth;
  if (!hasAnyProfile) return AppRoutes.createProfile;

  // Verifica se está em rota inicial
  final isGoingToAuth = state.matchedLocation == AppRoutes.auth;
  final isGoingToSplash = state.matchedLocation == AppRoutes.splash;

  if (isGoingToAuth || isGoingToSplash) {
    return AppRoutes.home;
  }

  // ✅ Permite navegação para /profile/:id, /post/:id, etc
  return null;  // Não redireciona
}
```

### ❌ Erros Comuns

```dart
// ❌ ERRADO - Sempre redireciona para home
redirect: (context, state) {
  if (isLoggedIn && hasProfiles) {
    return AppRoutes.home;  // Bloqueia /profile/:id, /post/:id, etc!
  }
  return null;
}
```

### 🎯 Navegação Type-Safe

```dart
// ✅ CORRETO - Usar extensões tipadas
context.pushProfile(profileId);
context.pushPostDetail(postId);
context.goToConversation(conversationId);

// ❌ ERRADO - String routes
context.push('/profile/$profileId');  // Sem type safety
```

---

## 🔔 Notificações & Streams

### ✅ Query Optimization

```dart
// ✅ CORRETO - Query por UID + filtro client-side
Stream<List<NotificationEntity>> getNotifications(String profileId) {
  final activeProfile = _profileState.activeProfile;

  return _firestore
      .collection('notifications')
      .where('recipientUid', isEqualTo: activeProfile.uid)  // Security Rules
      .orderBy('createdAt', descending: true)
      .snapshots()
      .handleError((error) {
        debugPrint('Error: $error');
        return <NotificationEntity>[];  // Fallback gracioso
      })
      .debounceTime(const Duration(milliseconds: 50))  // Latência mínima
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => NotificationEntity.fromFirestore(doc))
            .where((n) => n.recipientProfileId == profileId)  // Filtro client-side
            .toList();
      });
}
```

### ❌ Erros Comuns

```dart
// ❌ ERRADO - Query direta por profileId (viola Security Rules)
.where('recipientProfileId', isEqualTo: profileId)  // Permission denied

// ❌ ERRADO - Sem tratamento de erros
.snapshots()  // Crash em caso de permission-denied

// ❌ ERRADO - Debounce alto
.debounceTime(const Duration(milliseconds: 300))  // Latência perceptível
```

### 🎛️ Debounce Otimizado

```dart
// ✅ Streams de UI crítica: 50ms
streamUnreadCount().debounceTime(const Duration(milliseconds: 50));

// ✅ Streams de background: 300ms
streamMessagesSyncStatus().debounceTime(const Duration(milliseconds: 300));

// ✅ Search/autocomplete: 500ms
searchUsers(query).debounceTime(const Duration(milliseconds: 500));
```

---

## 🧹 Memory Management

### ✅ Dispose Correto

```dart
class _MyWidgetState extends ConsumerState<MyWidget> {
  late final StreamSubscription _subscription;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);  // Named method
  }

  @override
  void dispose() {
    // ✅ CORRETO - Dispose de recursos
    _scrollController.dispose();  // Já remove listeners automaticamente
    _subscription.cancel();
    super.dispose();
  }

  void _onScroll() {
    // Named method permite remover listener se necessário
  }
}
```

### ❌ Erros Comuns

```dart
// ❌ ERRADO - Listener inline sem remoção
_controller.addListener(() {
  // Impossível remover este listener
});

// ❌ ERRADO - ref.read() no dispose
@override
void dispose() {
  final data = ref.read(myProvider);  // Pode crashar
  super.dispose();
}

// ❌ ERRADO - Forgot to dispose
@override
void dispose() {
  // _controller.dispose() esquecido!
  super.dispose();
}
```

### 📊 StreamBuilder Best Practices

```dart
// ✅ CORRETO - Tratamento completo de estados
StreamBuilder<List<T>>(
  stream: myStream,
  builder: (context, snapshot) {
    // Loading apenas no primeiro carregamento
    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
      return const CircularProgressIndicator();
    }

    // Erro tratado como empty state (melhor UX)
    if (snapshot.hasError) {
      debugPrint('Stream error: ${snapshot.error}');
      // Fallback gracioso
    }

    final data = snapshot.data ?? [];
    if (data.isEmpty) {
      return const EmptyState();
    }

    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) => ItemWidget(data[index]),
    );
  },
)
```

---

## 🎨 UI/UX Best Practices

### ✅ Empty States

```dart
// ✅ CORRETO - Mensagem simples sem botão
const EmptyState(
  icon: Iconsax.notification,
  title: 'Nenhuma notificação',
  subtitle: 'Você ainda não tem notificações.',
  // NO ACTION BUTTON - Apenas informativo
);

// ❌ ERRADO - Botão desnecessário
EmptyState(
  title: 'Nenhuma notificação',
  action: ElevatedButton(
    onPressed: () => refresh(),  // Refresh automático não precisa de botão
    child: const Text('Atualizar'),
  ),
);
```

### 🎭 Loading States

```dart
// ✅ CORRETO - Loading apenas no primeiro carregamento
if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
  return const CircularProgressIndicator();
}

// ❌ ERRADO - Loading em toda mudança
if (snapshot.connectionState == ConnectionState.waiting) {
  return const CircularProgressIndicator();  // Pisca a cada update!
}
```

---

## 🔍 Debugging

### ✅ Debug Logging

```dart
// ✅ CORRETO - Logs estruturados com emojis
debugPrint('📍 PostCard: Tap na foto do post $postId');
debugPrint('✅ NotificationService: ${notifications.length} carregadas');
debugPrint('⚠️ ProfileRepository: Perfil não encontrado');
debugPrint('❌ FirebaseError: ${error.code}');

// Usar prefixos claros:
// 📍 - Navegação/Geolocalização
// ✅ - Sucesso/Conclusão
// ⚠️ - Aviso/Fallback
// ❌ - Erro/Falha
// 📊 - Métricas/Performance
// 🔄 - Loading/Processing
```

### 🐛 Debug Tools

```dart
// ✅ DevTools para analisar:
// - Memory leaks (Track instances)
// - Performance (Timeline)
// - Network (Firestore queries)
// - Logs (Structured logging)

// ✅ Firebase Console:
// - Firestore usage
// - Auth users
// - Storage files
// - Functions logs
```

---

## 📋 Code Review Checklist

### Antes de Commit

- [ ] `flutter analyze` sem warnings
- [ ] `flutter test` todos passando
- [ ] Memory leaks verificados (dispose correto)
- [ ] Debug prints removidos ou com flag
- [ ] Empty states implementados
- [ ] Error handling completo
- [ ] Navigation testada (tap events)
- [ ] Multi-profile isolation verificado

### Antes de Merge

- [ ] CI/CD pipeline passando
- [ ] Documentation atualizada
- [ ] CHANGELOG.md atualizado
- [ ] Breaking changes documentadas
- [ ] Firebase indexes atualizados (se necessário)

---

## 🎯 Performance Targets

| Métrica            | Target  | Atual    |
| ------------------ | ------- | -------- |
| Notification load  | < 100ms | 50ms ✅  |
| Map markers render | < 500ms | 150ms ✅ |
| Profile switch     | < 200ms | 100ms ✅ |
| Message send       | < 300ms | 180ms ✅ |
| Image compression  | < 2s    | 1.2s ✅  |

---

## 📚 Referências

- [Flutter Best Practices](https://docs.flutter.dev/perf/best-practices)
- [Riverpod Architecture](https://riverpod.dev/docs/concepts/reading)
- [Firebase Security Rules](https://firebase.google.com/docs/rules)
- [GoRouter Migration Guide](https://docs.flutter.dev/development/ui/navigation)
