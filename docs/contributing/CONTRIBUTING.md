# Guia de Contribuição - WeGig

Obrigado por considerar contribuir para o **WeGig**! Este documento fornece diretrizes para manter a qualidade e consistência do código.

---

## 📋 Índice

- [Conventional Commits](#conventional-commits)
- [Fluxo de Desenvolvimento](#fluxo-de-desenvolvimento)
- [Padrões de Código](#padrões-de-código)
- [Testes](#testes)
- [Pull Requests](#pull-requests)

---

## 🔖 Conventional Commits

### Formato

Todas as mensagens de commit DEVEM seguir o padrão [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Tipos Permitidos

| Tipo         | Descrição                                | Exemplo                                         |
| ------------ | ---------------------------------------- | ----------------------------------------------- |
| **feat**     | Nova funcionalidade                      | `feat(auth): add Google sign-in`                |
| **fix**      | Correção de bug                          | `fix(posts): resolve location validation`       |
| **docs**     | Alterações em documentação               | `docs(readme): update setup instructions`       |
| **style**    | Formatação, espaços, vírgulas            | `style: format code with dart formatter`        |
| **refactor** | Refatoração sem mudança de comportamento | `refactor(profile): extract ProfileMapper`      |
| **test**     | Adição ou correção de testes             | `test(auth): add unit tests for AuthService`    |
| **chore**    | Tarefas de manutenção                    | `chore: update dependencies`                    |
| **perf**     | Melhorias de performance                 | `perf(home): optimize marker rendering`         |
| **ci**       | Mudanças em CI/CD                        | `ci: add GitHub Actions workflow`               |
| **build**    | Mudanças no build system                 | `build: update gradle version`                  |
| **revert**   | Reverter commit anterior                 | `revert: revert feat(auth): add Google sign-in` |

### Scopes Sugeridos

- `auth` - Autenticação
- `profile` - Perfis
- `posts` - Posts e feed
- `messages` - Chat e mensagens
- `notifications` - Notificações
- `home` - Tela inicial e busca
- `settings` - Configurações
- `router` - Navegação
- `core` - Código compartilhado

### Exemplos Válidos

✅ **Bons exemplos:**

```bash
feat(auth): implement email verification flow
fix(posts): prevent duplicate post creation
docs(contributing): add commit message guidelines
refactor(profile): migrate to Clean Architecture
test(messages): add integration tests for chat
perf(home): cache map markers for 95% faster rendering
chore(deps): upgrade firebase packages to latest
```

❌ **Exemplos inválidos:**

```bash
# Sem tipo
Update profile page

# Tipo inválido
feature: add new button

# Descrição muito curta
fix: bug

# Primeira letra maiúscula
feat: Add login

# Ponto final
feat: add button.
```

### Validação Automática

Ao fazer commit, o **husky** + **commitlint** validará automaticamente a mensagem:

```bash
git commit -m "feat(auth): add Google sign-in"
# ✅ Commit válido

git commit -m "Added Google sign-in"
# ❌ Erro: type-enum → Deve começar com tipo válido
```

Se houver erro, corrija a mensagem e tente novamente.

---

## 🔄 Fluxo de Desenvolvimento

### 1. Criar Branch

```bash
# Feature
git checkout -b feat/add-google-signin

# Bugfix
git checkout -b fix/location-validation

# Refactor
git checkout -b refactor/profile-clean-arch
```

### 2. Desenvolver

1. Faça alterações incrementais
2. Execute testes localmente: `flutter test`
3. Execute análise de código: `flutter analyze`
4. Formate código: `dart format .`

### 3. Commitar

```bash
# Commit com mensagem Conventional
git add .
git commit -m "feat(auth): implement Google sign-in"

# Commit com corpo (para mudanças complexas)
git commit -m "feat(auth): implement Google sign-in

- Add GoogleSignInService
- Update AuthRepository to support Google
- Add tests for Google authentication flow

Closes #123"
```

### 4. Push e Pull Request

```bash
git push origin feat/add-google-signin
```

Depois, abra PR no GitHub seguindo o template.

---

## 🎨 Padrões de Código

### Clean Architecture

Toda feature DEVE seguir a estrutura:

```
features/
└── feature_name/
    ├── domain/
    │   ├── entities/          # Business objects (Freezed)
    │   ├── repositories/      # Interfaces
    │   └── usecases/          # Business logic
    ├── data/
    │   ├── models/            # DTOs (Freezed + json_serializable)
    │   ├── datasources/       # Remote/Local data
    │   ├── repositories/      # Repository implementations
    │   └── mappers/           # Entity ↔ DTO
    └── presentation/
        ├── pages/             # Screens
        ├── widgets/           # UI components
        └── providers/         # Riverpod state management
```

### Code Generation

**SEMPRE** use code generation:

```dart
// ✅ Entities com Freezed
@freezed
class ProfileEntity with _$ProfileEntity {
  const factory ProfileEntity({
    required String profileId,
    required String name,
    // ...
  }) = _ProfileEntity;
}

// ✅ DTOs com Freezed + JSON
@freezed
class ProfileDTO with _$ProfileDTO {
  const factory ProfileDTO({
    required String id,
    required String name,
    // ...
  }) = _ProfileDTO;

  factory ProfileDTO.fromJson(Map<String, dynamic> json) =>
      _$ProfileDTOFromJson(json);
}

// ✅ Providers com riverpod_annotation
@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  @override
  Future<ProfileState> build() async {
    // ...
  }
}
```

Execute após mudanças:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Lint

O projeto usa **very_good_analysis**. Execute:

```bash
flutter analyze
```

**Zero warnings** antes de commitar!

### Imports

Organize imports nesta ordem:

```dart
// 1. Dart imports
import 'dart:async';
import 'dart:io';

// 2. Flutter imports
import 'package:flutter/material.dart';

// 3. Package imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 4. Project imports
import 'package:wegig_app/core/core.dart';
import 'package:wegig_app/features/auth/auth.dart';
```

---

## 🧪 Testes

### Cobertura Mínima

- **Use Cases:** 95%
- **Providers:** 80%
- **Repositories:** 80%

### Estrutura de Testes

```dart
// Use Case Test
void main() {
  group('CreatePostUseCase', () {
    late CreatePostUseCase useCase;
    late MockPostRepository mockRepository;

    setUp(() {
      mockRepository = MockPostRepository();
      useCase = CreatePostUseCase(mockRepository);
    });

    test('should create post with valid data', () async {
      // Arrange
      final post = PostEntity(...);
      when(() => mockRepository.createPost(post))
          .thenAnswer((_) async => post);

      // Act
      final result = await useCase(post);

      // Assert
      expect(result, equals(post));
      verify(() => mockRepository.createPost(post)).called(1);
    });
  });
}
```

### Executar Testes

```bash
# Todos os testes
flutter test

# Testes específicos
flutter test test/features/auth/

# Com coverage
flutter test --coverage
```

---

## 🔀 Pull Requests

### Checklist

Antes de criar PR, verifique:

- [ ] Código segue Clean Architecture
- [ ] Usa code generation (Freezed, Riverpod, JSON)
- [ ] Todos commits seguem Conventional Commits
- [ ] `flutter analyze` sem warnings
- [ ] `flutter test` passando (todos testes)
- [ ] Cobertura de testes adequada (95% use cases, 80% providers)
- [ ] Documentação atualizada (README, CHANGELOG)
- [ ] Self-review realizado

### Template de PR

```markdown
## Tipo de Mudança

- [ ] feat: Nova funcionalidade
- [ ] fix: Correção de bug
- [ ] docs: Atualização de documentação
- [ ] refactor: Refatoração
- [ ] test: Adição de testes
- [ ] chore: Manutenção

## Descrição

[Descreva o que foi feito e por quê]

## Como Testar

1. [Passo 1]
2. [Passo 2]
3. [Passo 3]

## Screenshots (se aplicável)

[Adicione screenshots ou vídeos]

## Checklist

- [ ] Conventional Commits seguido
- [ ] Testes adicionados/atualizados
- [ ] Zero lint warnings
- [ ] Documentação atualizada
- [ ] Self-review realizado
```

### Review Process

1. **Automated Checks:** CI/CD executará lint + testes
2. **Code Review:** Mínimo 1 aprovação necessária
3. **Merge:** Squash and merge (para manter histórico limpo)

---

## 🚀 Comandos Úteis

```bash
# Setup inicial
flutter pub get
cd ios && pod install

# Desenvolvimento
flutter run
flutter run --verbose

# Qualidade
flutter analyze
dart format .
flutter test
flutter test --coverage

# Build
flutter build apk --release
flutter build ios --release

# Code Generation
dart run build_runner build --delete-conflicting-outputs
dart run build_runner watch  # Auto-regenerate on changes

# Firebase
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
cd functions && firebase deploy --only functions
```

---

## ⚠️ Práticas Críticas (OBRIGATÓRIAS)

### 🔥 Firebase Multi-Ambiente

**NUNCA** hardcode project IDs. Sempre use a configuração correta por flavor:

```dart
// ✅ CORRETO
await bootstrapCoreServices(
  firebaseOptions: DefaultFirebaseOptions.currentPlatform,
  flavorLabel: 'dev',
  expectedProjectId: 'wegig-dev',  // Validação em runtime
);

// ❌ ERRADO
const projectId = 'to-sem-banda-83e19';  // Hardcoded!
```

**Checklist antes de commit:**

- [ ] `main_dev.dart` → `expectedProjectId: 'wegig-dev'`
- [ ] `main_staging.dart` → `expectedProjectId: 'wegig-staging'`
- [ ] `main_prod.dart` → `expectedProjectId: 'to-sem-banda-83e19'`
- [ ] `firebase_options_*.dart` com `projectId` correto

### 🎭 Multi-Profile

**SEMPRE** leia o perfil ativo do Riverpod, NUNCA use cache local:

```dart
// ✅ CORRETO
final profileState = ref.read(profileProvider);
final activeProfile = profileState.value?.activeProfile;

// ❌ ERRADO
final profileId = SharedPreferences.getString('activeProfileId');
```

**Após troca de perfil:**

```dart
// ✅ CRITICAL: Invalidar todos os providers
ref.invalidate(profileProvider);
ref.invalidate(postNotifierProvider);
ref.invalidate(messagesProvider);
ref.invalidate(notificationsProvider);
```

### 🗺️ GoRouter Navigation

**NUNCA** redirecione todas as rotas para home. Apenas rotas iniciais:

```dart
// ✅ CORRETO
if (isGoingToAuth || isGoingToSplash || isGoingToCreateProfile) {
  return AppRoutes.home;
}
return null;  // Permite /profile/:id, /post/:id, etc

// ❌ ERRADO
if (isLoggedIn && hasProfiles) {
  return AppRoutes.home;  // Bloqueia TUDO!
}
```

### 🔔 Notificações & Streams

**SEMPRE** adicione `handleError()` em streams Firestore:

```dart
// ✅ CORRETO
return query.snapshots()
    .handleError((error) {
      debugPrint('Error: $error');
      return <T>[];  // Fallback gracioso
    })
    .debounceTime(const Duration(milliseconds: 50));

// ❌ ERRADO
return query.snapshots();  // Crash em permission-denied
```

**Debounce guidelines:**

- UI crítica: 50ms
- Background sync: 300ms
- Search/autocomplete: 500ms

### 🧹 Memory Management

**SEMPRE** dispose de recursos:

```dart
// ✅ CORRETO
@override
void dispose() {
  _controller.dispose();  // Já remove listeners
  _subscription.cancel();
  super.dispose();
}

// ❌ ERRADO - Esqueceu dispose
@override
void dispose() {
  super.dispose();
}

// ❌ ERRADO - ref.read() no dispose
@override
void dispose() {
  ref.read(myProvider);  // Pode crashar!
  super.dispose();
}
```

### 📝 Code Review Checklist

Antes de abrir PR, verifique:

- [ ] `flutter analyze` sem warnings
- [ ] `flutter test` todos passando
- [ ] Memory leaks verificados
- [ ] Debug prints removidos/com flag
- [ ] Empty states implementados
- [ ] Error handling completo
- [ ] Navigation testada manualmente
- [ ] Multi-profile isolation verificado
- [ ] CHANGELOG.md atualizado

**Veja:** `BEST_PRACTICES.md` para detalhes completos

---

## 📚 Recursos

### Documentação Interna

- `README.md` - Overview do projeto
- `PLANO_ACAO_100_BOAS_PRATICAS.md` - Roadmap de melhorias
- `SESSION_14_MULTI_PROFILE_REFACTORING.md` - Clean Architecture patterns
- `DEEP_LINKING_GUIDE.md` - Deep linking setup

### Packages Key

- [freezed](https://pub.dev/packages/freezed) - Code generation
- [riverpod_annotation](https://pub.dev/packages/riverpod_annotation) - State management
- [go_router](https://pub.dev/packages/go_router) - Navigation
- [very_good_analysis](https://pub.dev/packages/very_good_analysis) - Lint rules

### External Resources

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Flutter Clean Architecture](https://resocoder.com/flutter-clean-architecture/)
- [Riverpod Best Practices](https://riverpod.dev/docs/concepts/about_code_generation)
- [Flutter Testing Guide](https://docs.flutter.dev/testing)

---

## 💬 Dúvidas?

Abra uma issue ou pergunte no canal de desenvolvimento!

**Obrigado por contribuir! 🎉**
