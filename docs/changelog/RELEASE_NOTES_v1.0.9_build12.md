# Release Notes - WeGig v1.0.9 (Build 12)

**Data:** 22 de Fevereiro de 2026
**Versão:** 1.0.9
**Build:** 12
**Versão Anterior:** 1.0.8 (Build 11)

---

## 📱 O Que Há de Novo (What's New)

### 🇧🇷 Português (Brasil) - Google Play Store

```
🎸 Novidades da versão 1.0.9

✨ Novidades
• Curtir comentários — toque no coração para curtir comentários de outros músicos
• Notificações de curtida em comentários — saiba quando curtiram seu comentário
• Chip de expiração nos posts — veja facilmente quando um post expira
• Renovação rápida de posts expirados

🐛 Correções
• Vídeos do YouTube agora abrem em tela cheia com rotação correta
• Notificações push no iOS agora navegam corretamente ao tocar
• Melhorias na entrega de push notifications no iOS

🔒 Segurança & Infraestrutura
• Correções no payload APNS para entrega confiável no iOS
• Filtro de tokens de plataformas não-mobile nas Cloud Functions
• Regras do Firestore atualizadas para curtidas em comentários

Conecte-se com músicos e bandas perto de você! 🎵
```

### 🇧🇷 Português (Brasil) - Apple App Store

```
🎸 Novidades

• Curtir comentários nos posts
• Notificações quando curtirem seu comentário
• Chip de expiração nos posts
• Renovação rápida de posts expirados
• Correção de tela cheia do YouTube
• Melhorias na navegação por push notifications

Encontre músicos e bandas na sua região! 🎵
```

---

### 🇺🇸 English (US) - Google Play Store

```
🎸 What's New in 1.0.9

✨ New Features
• Like comments — tap the heart to like other musicians' comments
• Comment like notifications — know when someone liked your comment
• Post expiration chip — easily see when a post expires
• Quick renewal of expired posts

🐛 Bug Fixes
• YouTube videos now open fullscreen with correct rotation
• iOS push notifications now navigate correctly on tap
• Improved push notification delivery on iOS

🔒 Security & Infrastructure
• APNS payload fixes for reliable iOS delivery
• Non-mobile platform token filtering in Cloud Functions
• Firestore rules updated for comment likes

Connect with musicians and bands near you! 🎵
```

### 🇺🇸 English (US) - Apple App Store

```
🎸 What's New

• Like comments on posts
• Notifications when someone likes your comment
• Post expiration chip
• Quick renewal of expired posts
• YouTube fullscreen fix
• Push notification navigation improvements

Find musicians and bands in your area! 🎵
```

---

## 📋 Changelog Técnico

### ✨ Novas Funcionalidades

| Feature                | Descrição                                               | Arquivos Principais                                                             |
| ---------------------- | ------------------------------------------------------- | ------------------------------------------------------------------------------- |
| Curtir Comentários     | Curtir/descurtir comentários com coração + contador     | `comment_entity.dart`, `comment_item_widget.dart`, `comments_bottom_sheet.dart` |
| Notificação de Curtida | Push + in-app notification quando curtem seu comentário | `sendCommentLikeNotification` (Cloud Function), `notification_entity.dart`      |
| Chip de Expiração      | Badge visual mostrando tempo restante do post           | `post_card_widget.dart`, `post_detail_page.dart`                                |
| Renovação de Post      | Botão para renovar posts expirados diretamente          | `post_detail_page.dart`, `post_repository.dart`                                 |

### 🐛 Correções de Bugs

| Bug                 | Descrição                                                              | Arquivos                                              |
| ------------------- | ---------------------------------------------------------------------- | ----------------------------------------------------- |
| YouTube Fullscreen  | Vídeo não rotava para landscape em fullscreen                          | Orientação desbloqueada no player                     |
| iOS Push Navigation | Tocar na push notification não navegava para o conteúdo correto        | `push_notification_router.dart`                       |
| APNS Payload        | `contentAvailable: true` (camelCase errado) → `"content-available": 1` | `comment_notification.js`, `nearby_posts_override.js` |
| Token Filtering     | Tokens de web/desktop causavam `third-party-auth-error`                | `comment_notification.js`, `nearby_posts_override.js` |

### 🔒 Segurança

| Melhoria        | Descrição                                                                              |
| --------------- | -------------------------------------------------------------------------------------- |
| Firestore Rules | Comentários permitem update apenas de `likeCount` e `likedBy`                          |
| APNS Headers    | Adicionado `apns-priority: 10` + `alert` object para entrega confiável                 |
| Token Filtering | Filtro de plataformas não-mobile (web/linux/windows/macos) em todas as Cloud Functions |
| Rate Limiting   | 200 curtidas por dia por perfil (proteção anti-spam)                                   |

### ⚙️ Cloud Functions (15 funções)

| Função                        | Mudança                                                   |
| ----------------------------- | --------------------------------------------------------- |
| `sendCommentLikeNotification` | **NOVA** — onUpdate em comments, detecta novos likers     |
| `sendCommentNotification`     | Fix APNS payload + filtro de tokens não-mobile            |
| `notifyNearbyPosts`           | Fix APNS headers + `content-available` + filtro de tokens |
| Demais 12 funções             | Atualizadas (sem mudanças lógicas)                        |

---

## 🚀 Deploy Checklist

### Pré-Deploy

- [x] Versão atualizada: `1.0.9+12` em `pubspec.yaml`
- [ ] Build limpo: `flutter clean && melos bootstrap`
- [ ] Codegen: `melos run build_runner`
- [ ] Testes: `cd packages/app && flutter test`

### Firebase (já deployado)

```bash
# Todos os 3 ambientes deployados ✅
# Functions: 15/15 em dev, staging e prod
# Rules + Indexes: deployados em dev, staging e prod
```

- [x] `firebase deploy --only functions --project wegig-dev`
- [x] `firebase deploy --only functions --project wegig-staging`
- [x] `firebase deploy --only functions --project to-sem-banda-83e19`
- [x] `firebase deploy --only firestore:rules,firestore:indexes --project wegig-dev`
- [x] `firebase deploy --only firestore:rules,firestore:indexes --project wegig-staging`
- [x] `firebase deploy --only firestore:rules,firestore:indexes --project to-sem-banda-83e19`

### Android (Google Play Console)

```bash
cd packages/app
flutter build appbundle --flavor prod -t lib/main_prod.dart --release
# Output: build/app/outputs/bundle/prodRelease/app-prod-release.aab
```

**Upload:**

1. Google Play Console → WeGig → Versões → Produção
2. Criar nova versão
3. Upload do AAB
4. Preencher release notes (pt-BR e en-US)
5. Revisar e publicar

### iOS (App Store Connect)

```bash
cd packages/app
flutter build ipa --flavor prod -t lib/main_prod.dart --release
# Ou via Xcode: Product → Archive → Distribute App
```

**Upload:**

1. App Store Connect → WeGig → Nova Versão (1.0.9)
2. Upload via Xcode ou Transporter
3. Preencher "O Que Há de Novo" (pt-BR e en-US)
4. Submeter para revisão

---

## 🔄 Rollback (se necessário)

Versão anterior disponível: **1.0.8 (Build 11)**

Firebase Rules/Functions podem ser revertidas via console do Firebase.

---

**Responsável:** Equipe WeGig
**Aprovação:** Pendente
