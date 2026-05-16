# WeGig

App Flutter para conectar músicos e bandas usando arquitetura multi-perfil estilo Instagram.

[![Flutter](https://img.shields.io/badge/Flutter-3.27.1+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth%20%7C%20Storage-FFCA28?logo=firebase)](https://firebase.google.com)
[![Riverpod](https://img.shields.io/badge/Riverpod-3.x-00A699)](https://riverpod.dev)
[![CI](https://github.com/wagnermecanica-code/ToSemBandaRepo/workflows/CI%20-%20Build%20%26%20Test/badge.svg)](https://github.com/wagnermecanica-code/ToSemBandaRepo/actions)
[![codecov](https://codecov.io/gh/wagnermecanica-code/ToSemBandaRepo/branch/main/graph/badge.svg)](https://codecov.io/gh/wagnermecanica-code/ToSemBandaRepo)
[![Tests](https://img.shields.io/badge/Tests-270%20passing-success?logo=flutter)](https://github.com/wagnermecanica-code/ToSemBandaRepo/actions)
[![Documentation](https://img.shields.io/badge/Docs-DartDoc-blue?logo=dart)](./docs/api/index.html)

## 🎯 Visão Geral

**WeGig** é uma plataforma social para músicos, bandas e espaços musicais se conectarem através de busca geoespacial, posts efêmeros (30 dias), conexões por perfil, mensagens em tempo real e notificações contextuais. Cada conta pode administrar múltiplos perfis, alternando entre identidades de músico, banda e espaço no mesmo fluxo.

**Stack Principal:**

- **Frontend:** Flutter 3.27.1, Dart 3.10
- **Backend:** Firebase (Firestore, Auth, Storage, Cloud Functions)
- **State Management:** Riverpod 3.x (AsyncNotifier pattern)
- **Mapas:** Google Maps, Geolocator
- **Cloud Functions:** Node.js (notificações de proximidade)
- **CI/CD:** GitHub Actions (iOS + Android automated builds)

---

## ✨ Funcionalidades Principais

### 🔐 Autenticação Multi-Perfil

- Login via email/senha ou Google Sign-In
- Cada usuário Firebase pode ter múltiplos perfis (`musician`, `band`, `space`)
- Troca de perfil instantânea estilo Instagram
- Isolamento completo de dados entre perfis

### 🗺️ Busca Geoespacial

- Mapa interativo com markers customizados
- Filtro de posts por proximidade (raio ajustável)
- Geração automática de cidade via reverse geocoding
- Pagination de posts com `startAfterDocument`
- Cache de markers (95% mais rápido)

### 📝 Posts Efêmeros

- Validade de 30 dias (expiração automática)
- Filtros por tipo (`musician`, `band`, `sales`, `hiring`), gêneros, instrumentos
- Galeria de imagens (até 9 fotos)
- Carrossel com navegação horizontal
- Compressão de imagens em isolate (evita freeze de UI)

### 🤝 Minha Rede & Conexões

- `Minha Rede` como hub social principal no bottom nav
- Convites, aceite, recusa, cancelamento e remoção de conexão por perfil
- Sugestões de conexão com razões textuais e conexões em comum
- Atividade da rede com navegação para perfil e detalhe do post
- Reaproveitamento de conversa direta existente ao abrir chat por conexão
- Badge social integrado à navegação principal e ao seletor de perfis

### 💬 Chat em Tempo Real

- Mensagens instantâneas entre perfis
- Contador de não lidas por perfil
- Marcação automática como lida ao abrir conversa
- Lazy loading de streams (só carrega quando tab é acessada)

### 🔔 Notificações

- **Proximidade:** Cloud Function detecta novos posts no raio configurado (5-100km)
- **Interesses:** Notifica quando alguém demonstra interesse no seu post
- **Sociais:** Convites enviados, conexões aceitas e movimentações de `Minha Rede`
- Badge de não lidas em tempo real
- Streams otimizados com `distinctUntilChanged`

### ⚙️ Preferências & Privacidade

- Controle do raio de notificação por perfil
- Toggle para aparecer em sugestões de conexão
- Toggle para receber convites de conexão
- Gestão de perfis bloqueados com enforcement bidirecional nas superfícies sociais

### 🎨 Design System

- Material 3 + tema customizado
- Cor primária: Teal `#00A699`
- Tipografia principal: Cereal
- Dark mode opcional (via `.env`)
- Loader visual padronizado com `AppRadioPulseLoader`

---

## 🏗️ Arquitetura

### 🎭 Flavors (Dev / Staging / Production)

O projeto usa **flutter_flavorizr** para gerenciar 3 ambientes isolados:

| Flavor      | App Name      | Bundle ID (iOS)           | Package (Android)              | Firebase Project   | Logs   | Crashlytics |
| ----------- | ------------- | ------------------------- | ------------------------------ | ------------------ | ------ | ----------- |
| **dev**     | WeGig DEV     | `com.wegig.wegig.dev`     | `com.tosembanda.wegig.dev`     | wegig-dev          | ✅ On  | ❌ Off      |
| **staging** | WeGig STAGING | `com.wegig.wegig.staging` | `com.tosembanda.wegig.staging` | wegig-staging      | ⚠️ On  | ✅ On       |
| **prod**    | WeGig         | `com.wegig.wegig`         | `com.wegig.wegig`              | to-sem-banda-83e19 | ❌ Off | ✅ On       |

**Rodar por flavor:**

```bash
# Desenvolvimento (dev)
flutter run --flavor dev -t lib/main_dev.dart

# Homologação (staging)
flutter run --flavor staging -t lib/main_staging.dart

# Produção (prod)
flutter run --flavor prod -t lib/main_prod.dart
```

**Build automatizado:**

```bash
# Produção (AAB + obfuscation)
./.tools/scripts/build_release.sh prod

# Staging (APK para teste interno)
./.tools/scripts/build_release.sh staging

# Dev (APK rápido sem obfuscation)
./.tools/scripts/build_release.sh dev

# Especificar plataforma
./.tools/scripts/build_release.sh prod android
./.tools/scripts/build_release.sh staging ios
```

**Configuração por flavor:**

```dart
import 'package:wegig/config/app_config.dart';

// Verifica ambiente
if (AppConfig.isDevelopment) {
  debugPrint('Rodando em DEV');
}

// Usa configurações do flavor
final apiUrl = AppConfig.apiBaseUrl;
final enableLogs = AppConfig.enableLogs;
```

#### Checklist por plataforma

- **Android**: coloque cada `google-services.json` em `android/app/src/<flavor>/` (ex.: `src/dev/google-services.json`). Rode `flutter clean` após trocar arquivos para o Gradle detectar alterações.
- **iOS**: o scheme `WeGig-dev` usa `ios/Flutter/Dev.xcconfig` com `PRODUCT_BUNDLE_IDENTIFIER = com.wegig.wegig.dev`. O build phase `[CP] Copy GoogleService-Info.plist` agora copia automaticamente `ios/Firebase/GoogleService-Info-<flavor>.plist` para `WeGig/GoogleService-Info.plist` antes do build. Garanta que cada arquivo exista (`GoogleService-Info-dev.plist`, `-staging`, `-prod`).
- **Firebase Projects**: ⚠️ **CRITICAL** - Cada flavor aponta para um projeto Firebase isolado:
  - `dev` → `wegig-dev`
  - `staging` → `wegig-staging`
  - `prod` → `to-sem-banda-83e19`
  - Validação em runtime via `expectedProjectId` no bootstrap para evitar dados cruzados.

#### Script de sanidade do Firebase

Execute `dart run tool/print_firebase_context.dart <flavor>` dentro de `packages/app` para imprimir `projectId`, `appId`, `iosBundleId` e a API key mascarada. Exemplo:

```bash
cd packages/app
dart run tool/print_firebase_context.dart dev
```

O comando alerta quando `dev` não está ligado a `to-sem-banda-83e19` e ajuda a investigar mismatches antes de fazer login.

**Arquivos de configuração:**

- `lib/config/dev_config.dart` - Dev (logs ligados)
- `lib/config/staging_config.dart` - Staging (logs + Crashlytics)
- `lib/config/prod_config.dart` - Produção (logs desligados)
- `lib/config/app_config.dart` - Centraliza acesso aos configs

---

### Multi-Perfil (Instagram-style)

**Data Model:**

```
users/{uid}
  ├─ activeProfileId: String
  └─ email: String

profiles/{profileId}
  ├─ uid: String (Firebase Auth UID)
  ├─ name: String
  ├─ isBand: Boolean
  ├─ location: GeoPoint (obrigatório)
  ├─ city: String
  ├─ instruments: List<String>
  ├─ genres: List<String>
  └─ photoUrl: String
```

**State Management:**

```dart
// SEMPRE ler do Riverpod (nunca cache local)
final profileState = ref.read(profileProvider).value?.activeProfile;

// Invalidar cache após troca de perfil
ref.invalidate(profileProvider);
```

**Ownership Model:**

- Firestore rules: `resource.data.uid == request.auth.uid` (Firebase UID)
- App logic: `authorProfileId == activeProfile.profileId` (isolamento de perfis)

### 🍎 Sign in with Apple (flavor dev)

1. **Bundle Identifier correto**: `com.wegig.wegig.dev` (definido em `ios/Flutter/Dev.xcconfig`) deve estar registrado no Apple Developer Portal e ter a capability **Sign In with Apple** habilitada para o target `WeGig-dev`.
2. **Firebase Auth Provider**: no projeto `to-sem-banda-83e19`, habilite o provedor Apple e associe o mesmo Services ID usado no Apple Developer. Se trocar de projeto, atualize também os arquivos `GoogleService-Info-dev.plist`/`google-services.json`.
3. **Checklist de teste**:

- Rode `WeGig-dev` em dispositivo físico iOS.
- Faça login com o mesmo Apple ID duas vezes (instalação limpa + reinstalação) e confirme que o UID retornado pelo Firebase permanece idêntico.
- Se o UID mudar, verifique se o bundle ID corresponde ao provisionado e se o app aponta para o mesmo projeto Firebase do provedor Apple.

4. Consulte `ios/SIGN_IN_WITH_APPLE_SETUP.md` para screenshots e passos detalhados.

### Posts & Queries

**Campos Obrigatórios:**

```dart
{
  location: GeoPoint(lat, lng),        // Geosearch
  expiresAt: Timestamp(now + 30 days), // Auto-cleanup
  authorProfileId: String,              // Autor do post
  city: String,                         // Reverse geocoding
  createdAt: Timestamp,
  type: 'musician' | 'band'
}
```

**Query Padrão (todas queries devem seguir):**

```dart
FirebaseFirestore.instance.collection('posts')
  .where('expiresAt', isGreaterThan: Timestamp.now())
  // NÃO filtrar próprio perfil - usuário deve ver seus posts
  .orderBy('expiresAt')
  .orderBy('createdAt', descending: true)
  .limit(50);
```

**Indexes Necessários:**

```json
// firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "posts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "expiresAt", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
    // ... 12 outros indexes para filtros combinados
  ]
}
```

### Imagens (Performance Critical)

**❌ NUNCA usar `Image.network`** (memory leak + 80% mais lento)

**✅ SEMPRE usar:**

```dart
CachedNetworkImage(
  imageUrl: photoUrl,
  memCacheWidth: displayWidth * 2,  // Retina
  memCacheHeight: displayHeight * 2,
  placeholder: (_, __) => CircularProgressIndicator(),
  errorWidget: (_, __, ___) => Icon(Icons.error),
)
```

**Upload com Compressão (Isolate obrigatório):**

```dart
// Top-level function
Future<Uint8List> _compressImageIsolate(String path) async {
  final bytes = await File(path).readAsBytes();
  return await FlutterImageCompress.compressWithList(bytes, quality: 85);
}

// No StatefulWidget
final compressed = await compute(_compressImageIsolate, file.path);
```

### Cloud Functions (Notificações de Proximidade)

**Trigger:** `onCreate('posts/{postId}')`  
**Region:** `southamerica-east1` (São Paulo)

**Lógica:**

1. Query profiles com `notificationRadiusEnabled == true`
2. Calcular distância Haversine do post
3. Criar notificação se distância ≤ `notificationRadius` (default 20km)
4. Batch write max 500 notificações por post

**Deploy:**

```bash
cd functions
npm install
firebase deploy --only functions
firebase functions:log  # Monitor
```

---

## 🚀 Setup & Execução

### Pré-requisitos

- Flutter SDK 3.27.1+
- Dart SDK 3.10+
- Xcode 15+ (iOS) ou Android Studio (Android)
- Firebase CLI
- Node.js 18+ (Cloud Functions)
- Melos

### Instalação

1. **Clone & dependências:**

```bash
git clone https://github.com/wagnermecanica-code/ToSemBandaRepo.git
cd to_sem_banda
melos bootstrap
```

2. **Firebase config:**
   - Baixe `google-services.json` (Android) e `GoogleService-Info.plist` (iOS)
   - Coloque em `android/app/` e `ios/WeGig/`

3. **Environment variables (.env):**

```bash
cp .env.example .env
# Edite com suas chaves
```

Variáveis obrigatórias:

```
GOOGLE_MAPS_API_KEY=your_key_here
APP_ENV=development
FIREBASE_PROJECT_ID=your-project-id
```

4. **Firestore indexes:**

```bash
firebase deploy --only firestore:indexes
# Aguarde conclusão no console Firebase
firebase deploy --only firestore:rules
```

5. **Cloud Functions:**

```bash
cd functions
npm install
firebase deploy --only functions
```

6. **Dependências locais de mapas (quando aplicável):**

- O app usa um fork local de `google_maps_flutter` em `.tools/third_party/google_maps_flutter`
- Preserve o `dependency_overrides` de `packages/app/pubspec.yaml` ao atualizar ambiente ou CI

7. **Run:**

```bash
flutter run
# ou
flutter run --dart-define-from-file=.env
```

---

## 📁 Estrutura de Arquivos

```
lib/
├─ main.dart                    # Entry point + Firebase init
├─ firebase_options.dart        # Firebase config auto-gerado
├─ models/
│  ├─ profile.dart              # Profile data model
│  ├─ post.dart                 # Post data model
│  └─ search_params.dart        # Search filters
├─ pages/
│  ├─ auth_page.dart            # Login/cadastro
│  ├─ home_page.dart            # Mapa + posts (1213 linhas)
│  ├─ post_page.dart            # Criar post (940 linhas)
│  ├─ messages_page.dart        # Lista de chats
│  ├─ chat_detail_page.dart     # Chat em tempo real
│  ├─ view_profile_page.dart    # Visualizar perfil
│  ├─ edit_profile_page.dart    # Editar perfil
│  ├─ settings_page.dart        # Configurações
│  └─ bottom_nav_scaffold.dart  # Bottom navigation
├─ providers/
│  ├─ profile_provider.dart     # AsyncNotifier (perfil ativo)
│  └─ post_provider.dart        # Posts state
├─ repositories/
│  ├─ profile_repository.dart   # Profile CRUD
│  └─ post_repository.dart      # Post CRUD + geosearch
├─ services/
│  ├─ env_service.dart          # .env loader
│  ├─ marker_cache_service.dart # Map marker cache
│  ├─ notification_service.dart # Push notifications
│  └─ message_service.dart      # Chat logic
├─ theme/
│  ├─ app_theme.dart            # Material 3 theme
│  ├─ app_colors.dart           # Color palette
│  └─ app_typography.dart       # Text styles
├─ utils/
│  └─ debouncer.dart            # Debouncer & Throttler
└─ widgets/
   ├─ profile_switcher_bottom_sheet.dart
   └─ app_loading_overlay.dart

.tools/functions/
└─ index.js                     # Cloud Functions (190 linhas)

firestore.rules                 # Security rules
firestore.indexes.json          # 13 composite indexes
```

---

## 🐛 Troubleshooting

| Problema                                                               | Solução                                                                                                                                                                                                        |
| ---------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `[core/duplicate-app] A Firebase App named "[DEFAULT]" already exists` | Garante que apenas `bootstrapCoreServices` inicialize o Firebase (um por flavor). Se aparecer após hot restart, pare o app, rode `flutter clean`, e suba novamente usando o target correto.                    |
| `cloud_firestore/permission-denied` ao ler `/profiles`                 | Deploy as regras simplificadas (`firebase deploy --only firestore:rules`) e confirme que o usuário está autenticado. Em dev, o provider Apple precisa estar apontando para `to-sem-banda-83e19`.               |
| `Query/Index Errors`                                                   | Deploy indexes: `firebase deploy --only firestore:indexes`                                                                                                                                                     |
| `Missing Location Data`                                                | Execute: `.tools/scripts/check_posts.sh`                                                                                                                                                                       |
| `Profile State Bugs`                                                   | Sempre usar `ref.read(profileProvider).value?.activeProfile`                                                                                                                                                   |
| `Image Upload Freeze`                                                  | Certificar padrão `compute()` isolate (ver `post_page.dart:442`)                                                                                                                                               |
| `Cloud Functions Not Firing`                                           | Verificar logs: `firebase functions:log --only onPostCreated`                                                                                                                                                  |
| `LateInitializationError`                                              | Reiniciar app (hot restart) - Riverpod não suporta hot reload após logout                                                                                                                                      |
| Aviso de dSYM/Crashlytics no Xcode                                     | Confirme se o build phase `FlutterFire: flutterfire upload-crashlytics-symbols` está habilitado e se `firebase login` está ativo antes de arquivar.                                                            |
| Push não chegando / alerta sobre method swizzling                      | Verifique se o handler `_firebaseMessagingBackgroundHandler` está registrado uma única vez e protegido por `Firebase.apps.isEmpty`. Evite chamar `Firebase.initializeApp` em serviços ou isolates secundários. |

---

## 📚 Documentação Adicional

- **[Índice da documentação](./docs/README.md)** - ponto de entrada da base documental
- **[MVP macro](./MVP_Rev0.0.md)** - escopo funcional consolidado
- **[Resumo executivo do MVP](./docs/project-info/MVP_DESCRIPTION.md)** - baseline atual do produto
- **[Checklist do MVP](./docs/guides/MVP_CHECKLIST.md)** - baseline e próximos ajustes
- **[Changelog](./docs/changelog/CHANGELOG.md)** - histórico incremental do projeto
- **[Sessão de consolidação documental](./docs/sessions/SESSION_20_DOCUMENTATION_BASELINE_2026-04-19.md)** - contexto desta revisão
- **[Copilot Instructions](./.github/copilot-instructions.md)** - padrões técnicos do repositório

---

## 🔧 Build & Deploy

### iOS

```bash
flutter build ios --release
# Xcode → Product → Archive → Distribute
```

### Android

```bash
flutter build apk --release
# ou
flutter build appbundle --release
```

### Firestore

```bash
firebase deploy --only firestore:indexes
firebase deploy --only firestore:rules
```

### Cloud Functions

```bash
cd functions
firebase deploy --only functions
```

---

## 🚀 CI/CD Pipeline

O WeGig possui pipelines automatizados de CI/CD no GitHub Actions:

### Workflows Disponíveis

1. **CI - Build & Test** (`ci.yml`)
   - ✅ Análise estática e testes
   - ✅ Build iOS (sem codesign)
   - ✅ Build Android com APK artifact
   - ⏱️ ~15-25 minutos total

2. **iOS Build & Sign** (`ios-build.yml`)
   - ✅ Build com code signing
   - ✅ Export IPA + dSYM
   - ✅ Upload automático para TestFlight
   - ⏱️ ~20-30 minutos total

### Quick Start

```bash
# Testar CI localmente:
cd packages/app
flutter analyze
flutter test
flutter build ios --debug --no-codesign --flavor dev -t lib/main_dev.dart

# Trigger CI no GitHub:
git checkout -b feat/nova-feature
git push origin feat/nova-feature
gh pr create  # Executa ci.yml automaticamente
```

**Referências existentes:**

- [Guia de deploy](./docs/deployment/DEPLOY_GUIDE_WEGIG.md)
- [Code signing](./docs/code-signing/CODE_SIGNING_SETUP.md)
- [Secrets do GitHub](./docs/github-setup/GITHUB_SECRETS_SETUP.md)
- [Status atual de CI/CD](./docs/build-status/CI_CD_TESTING_BLOCKED.md)

---

## 📊 Status do Projeto

### Features Completas

- ✅ Auth multi-perfil (Firebase + Google)
- ✅ Posts efêmeros com geolocalização
- ✅ Chat em tempo real
- ✅ Notificações de proximidade (Cloud Functions)
- ✅ Busca geoespacial com filtros
- ✅ Galeria de imagens + compressão
- ✅ Cache de markers (performance)
- ✅ Design system Material 3
- ✅ Push notifications FCM (100% funcional)
- ✅ CI/CD pipelines (GitHub Actions)
- ✅ Monorepo migration (packages/app + packages/core_ui)
- ✅ Firebase dependencies updated (4.x/6.x series)

### Baseline documental atual (19/04/2026)

- ✅ **Versão documentada do app:** `1.0.14+19`
- ✅ **Monorepo ativo:** `packages/app` + `packages/core_ui`
- ✅ **Tipos de perfil:** músico, banda e espaço
- ✅ **Tipos de post:** `musician`, `band`, `sales`, `hiring`
- ✅ **Documentação central sincronizada:** README, MVP, checklist, índice e changelog
- ✅ **Sessão histórica registrada:** `SESSION_20_DOCUMENTATION_BASELINE_2026-04-19.md`

### Fechamento desta etapa (21/04/2026)

- ✅ `Minha Rede` consolidada como hub social com badge dedicado
- ✅ Preferências de conexão por perfil documentadas
- ✅ Loader padronizado documentado para superfícies-chave
- ✅ Site público alinhado à feature de conexões e publicado via GitHub Pages
- ✅ Instruções da IA revisadas para o estado atual do repositório

---

## 👥 Contribuindo

1. Fork o projeto
2. Crie uma branch: `git checkout -b feature/nova-funcionalidade`
3. Commit: `git commit -m 'Add: nova funcionalidade'`
4. Push: `git push origin feature/nova-funcionalidade`
5. Abra um Pull Request

---

## 📄 Licenciamento

Não há arquivo `LICENSE` na raiz do repositório neste momento. Até uma definição formal, trate este código como repositório de uso interno/proprietário.

---

## 📞 Contato

**Wagner Oliveira**  
📧 wagner_mecanica@hotmail.com  
🔗 [GitHub](https://github.com/wagnermecanica-code)
