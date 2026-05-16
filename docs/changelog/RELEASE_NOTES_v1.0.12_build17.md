# Release Notes - WeGig v1.0.12 (Build 17)

**Data:** 23 de Março de 2026
**Versão:** 1.0.12
**Build:** 17
**Versão Anterior:** 1.0.11 (Build 14)

---

## 📱 O Que Há de Novo (What's New)

### 🇧🇷 Português (Brasil) - Google Play Store

```
🎸 Novidades da versão 1.0.12

✨ Novidades
• Comentários nos posts — comente, responda e curta comentários de outros músicos
• Compartilhar posts no chat — envie posts diretamente para conversas
• Novo tipo de perfil: Espaço Musical — estúdios, lojas, bares, escolas e mais
• Busca avançada — filtros por preço, desconto, tipo de evento, formato de gig e username
• Página de usuários bloqueados — gerencie seus bloqueios nas Configurações
• Feedback direto — envie sugestões e reporte problemas pelo app
• Contador de interessados clicável — toque no número para ver quem se interessou

🐛 Correções
• Crash corrigido na busca do mapa (setState assíncrono)
• Melhoria na estabilidade do app em dispositivos Android (proteção de libs nativas)
• Push notifications com navegação mais confiável no iOS
• Entrega de notificações aprimorada (filtro de tokens não-mobile)

🔒 Segurança & Infraestrutura
• Filtro de conteúdo ofensivo em textos (PT-BR)
• SDK do Facebook atualizado para compatibilidade com iOS 14+
• Integração TikTok Business SDK para atribuição de campanhas
• Regras do Firestore atualizadas para comentários e novo tipo de perfil
• Índice reverso de bloqueios para filtragem mais rápida

Conecte-se com músicos e bandas perto de você! 🎵
```

### 🇧🇷 Português (Brasil) - Apple App Store

```
🎸 Novidades

• Comentários nos posts — comente, responda e curta
• Compartilhar posts diretamente no chat
• Novo tipo de perfil: Espaço Musical (estúdios, lojas, bares, escolas)
• Busca avançada com filtros de preço, desconto e tipo de evento
• Gerenciamento de usuários bloqueados nas Configurações
• Envie feedback e sugestões direto pelo app
• Toque no contador de interessados para ver a lista completa
• Correções de estabilidade e performance

Encontre músicos e bandas na sua região! 🎵
```

---

### 🇺🇸 English (US) - Google Play Store

```
🎸 What's New in 1.0.12

✨ New Features
• Post comments — comment, reply, and like other musicians' comments
• Share posts to chat — send posts directly to conversations
• New profile type: Music Space — studios, stores, bars, schools and more
• Advanced search — filters by price, discount, event type, gig format, and username
• Blocked users page — manage your blocks from Settings
• In-app feedback — send suggestions and report issues directly
• Tappable interest counter — tap the number to see who's interested

🐛 Bug Fixes
• Fixed crash on map search (async setState)
• Improved app stability on Android devices (native lib protection)
• More reliable push notification navigation on iOS
• Enhanced notification delivery (non-mobile token filtering)

🔒 Security & Infrastructure
• Offensive content filter for text fields (PT-BR)
• Facebook SDK updated for iOS 14+ compatibility
• TikTok Business SDK integration for campaign attribution
• Firestore rules updated for comments and new profile type
• Reverse block index for faster content filtering

Connect with musicians and bands near you! 🎵
```

### 🇺🇸 English (US) - Apple App Store

```
🎸 What's New

• Post comments — comment, reply, and like
• Share posts directly in chat
• New profile type: Music Space (studios, stores, bars, schools)
• Advanced search with price, discount, and event type filters
• Manage blocked users from Settings
• Send feedback and suggestions directly from the app
• Tap interest counter to see the full list
• Stability and performance improvements

Find musicians and bands in your area! 🎵
```

---

## 📋 Changelog Técnico

### ✨ Novas Funcionalidades

| Feature                   | Descrição                                                         | Arquivos Principais                                            |
| ------------------------- | ----------------------------------------------------------------- | -------------------------------------------------------------- |
| Sistema de Comentários    | Comentar, responder, curtir comentários com bottom sheet dedicado | `features/comment/` (inteiro)                                  |
| Compartilhar Post no Chat | Enviar posts como cards ricos para conversas                      | `share_post_bottom_sheet.dart`, `shared_post_card_bubble.dart` |
| Perfil Espaço Musical     | Novo tipo de perfil para estúdios, lojas, bares, escolas          | `profile_entity.dart`, `profile_type.dart`                     |
| Busca Avançada v2         | Filtros de preço, desconto, evento, gig format, username          | `search_page_new.dart`, `search_params.dart`                   |
| Página de Bloqueados      | Gerenciamento de usuários bloqueados nas Configurações            | `blocked_users_page.dart`                                      |
| Feedback In-App           | Bottom sheet para enviar sugestões e reportar problemas           | `feedback_bottom_sheet.dart`                                   |
| Contador de Interessados  | Toque no número para ver lista completa de interessados           | `post_feed_page.dart`                                          |
| Filtro de Conteúdo        | Validação client-side de conteúdo ofensivo (PT-BR, leetspeak)     | `objectionable_content_filter.dart`                            |
| Constantes Musicais       | Catálogo centralizado de instrumentos, gêneros e níveis           | `music_constants.dart`                                         |
| TikTok Business SDK       | Tracking de eventos nativos (LaunchApp, Registration, etc.)       | `tiktok_service.dart`                                          |
| Push Notification Router  | Roteamento unificado de deep links via notificações               | `push_notification_router.dart`                                |

### 🐛 Correções de Bugs

| Bug                   | Descrição                                                    | Arquivo                         |
| --------------------- | ------------------------------------------------------------ | ------------------------------- |
| Crash setState async  | `setState(_onMapIdle)` passava Future como callback          | `home_page.dart`                |
| libflutter.so missing | Proteção contra stripping de libs nativas no Android         | `build.gradle.kts`              |
| Push iOS navegação    | Delays específicos de plataforma para deep linking confiável | `push_notification_router.dart` |
| Tokens não-mobile     | Filtragem de tokens web/desktop nas Cloud Functions          | `index.js`                      |

### 🔧 Build & Otimização (Build 16-17)

| Mudança                  | Descrição                                                                        | Arquivo              |
| ------------------------ | -------------------------------------------------------------------------------- | -------------------- |
| R8 Minificação           | Habilitado `isMinifyEnabled` e `isShrinkResources` para builds release           | `build.gradle.kts`   |
| Debug Symbols            | NDK `debugSymbolLevel = FULL` — .so.dbg auto-incluídos no AAB                    | `build.gradle.kts`   |
| Deobfuscation            | mapping.txt auto-incluído no AAB via R8                                          | `build.gradle.kts`   |
| ProGuard Rules           | Regras abrangentes para Facebook SDK, UCrop, Geolocator, OkHttp, Glide, etc.     | `proguard-rules.pro` |
| Remoção keepDebugSymbols | Removido bloco `packaging.jniLibs.keepDebugSymbols` (substituído por ndk config) | `build.gradle.kts`   |

### 🌐 Site (wegig.com.br)

| Mudança                  | Descrição                                                                  |
| ------------------------ | -------------------------------------------------------------------------- |
| Ícones Iconsax SVG       | Adicionados ícones inline SVG (Iconsax Linear) em todos os 9 feature cards |
| Ícones nos stat cards    | Adicionados ícones nos 6 stat cards da seção Sobre                         |
| Remoção CSS CDN quebrado | Removido link `iconsax@1.0.0/dist/css/iconsax.css` que retornava 404       |

### 🔒 Segurança & Infraestrutura

| Melhoria                    | Descrição                                                      |
| --------------------------- | -------------------------------------------------------------- |
| Facebook SDK 0.26.0         | Atualização de 0.19.2 → 0.26.0 (FBSDKCoreKit 18.0.3)           |
| Índice reverso de bloqueios | `blockedByProfileIds[]` sincronizado via Cloud Function        |
| Regras Firestore            | Atualizadas para comentários, curtidas e tipo de perfil Espaço |
| Rate limiting               | 200 curtidas de comentários por dia por perfil (anti-spam)     |
| Content filter              | ~30 termos PT-BR com normalização de leetspeak e diacríticos   |

### 📊 Mudanças em Modelos de Dados

| Entidade                | Campos Adicionados                                                                                                                    |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `PostEntity`            | `commentCount`, `forwardCount`                                                                                                        |
| `ProfileEntity`         | `profileType`, `spaceType`, `phone`, `operatingHours`, `website`, `amenities`, `updatedAt`                                            |
| `SearchParams`          | `eventTypes`, `gigFormats`, `venueSetups`, `budgetRanges`, `salesTypes`, `minPrice`, `maxPrice`, `onlyWithDiscount`, `searchUsername` |
| `CommentEntity`         | Nova entidade completa (id, text, likes, replies, parentComment)                                                                      |
| `ConversationNewEntity` | Suporte a posts compartilhados                                                                                                        |
| `MessageNewEntity`      | Tipo `sharedPost` com metadata do post                                                                                                |

---

## 🚀 Deploy Checklist

### Firebase (executar nesta ordem)

```bash
# 1. Índices (aguardar criação no console)
firebase deploy --only firestore:indexes --project to-sem-banda-83e19

# 2. Regras de segurança
firebase deploy --only firestore:rules --project to-sem-banda-83e19
firebase deploy --only storage --project to-sem-banda-83e19

# 3. Cloud Functions
firebase deploy --only functions --project to-sem-banda-83e19
```

### Android (Google Play Console)

```bash
# Build AAB
cd packages/app
flutter build appbundle --flavor prod -t lib/main_prod.dart --release

# Output: build/app/outputs/bundle/prodRelease/app-prod-release.aab
# Upload em: Google Play Console > Produção > Criar nova versão
```

### iOS (App Store Connect)

```bash
# Build IPA
cd packages/app
flutter build ipa --flavor prod -t lib/main_prod.dart --release

# Output: build/ios/ipa/WeGig.ipa
# Upload via Xcode Organizer ou Transporter
# App Store Connect > TestFlight > Aguardar processamento > Submeter para revisão
```

### Checklist Pré-Upload

- [ ] Firebase indexes deployados e ativos
- [ ] Firestore rules deployadas
- [ ] Storage rules deployadas
- [ ] Cloud Functions deployadas (15 funções)
- [ ] Build Android AAB sem erros
- [ ] Build iOS IPA sem erros
- [ ] Versão no pubspec.yaml: `1.0.12+17`
- [ ] Release notes colados no Google Play Console (PT-BR)
- [ ] Release notes colados no App Store Connect (PT-BR)
- [ ] TestFlight: build processado e testado
