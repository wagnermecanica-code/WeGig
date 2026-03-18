# Release Notes - WeGig v1.0.7 (Build 10)

**Data:** 23 de Janeiro de 2026  
**Versão:** 1.0.7  
**Build:** 10  
**Versão Anterior:** 1.0.6 (Build 9)

---

## 📱 O Que Há de Novo (What's New)

### 🇧🇷 Português (Brasil) - Google Play Store

```
🎸 Novidades da versão 1.0.7

✨ Melhorias
• Deep links para compartilhamento de posts funcionando
• Verificação de idade 18+ no cadastro para maior segurança
• Correções de compatibilidade com Android 15

🐛 Correções
• Corrigido problema de visualização de posts expirados
• Melhorias na exibição de perfis no mapa
• Ajustes no editor de fotos para telas modernas

🔒 Segurança
• Validação aprimorada de tokens de notificação
• Melhorias nas regras de acesso ao banco de dados

Conecte-se com músicos e bandas perto de você! 🎵
```

### 🇧🇷 Português (Brasil) - Apple App Store

```
🎸 Novidades

• Deep links para compartilhar posts
• Verificação de idade no cadastro
• Correções de visualização de posts
• Melhorias de estabilidade e segurança

Encontre músicos e bandas na sua região! 🎵
```

---

### 🇺🇸 English (US) - Google Play Store

```
🎸 What's New in 1.0.7

✨ Improvements
• Deep links for post sharing now working
• Age verification (18+) during signup for safety
• Android 15 compatibility fixes

🐛 Bug Fixes
• Fixed expired posts display issue
• Improved profile markers on map
• Photo editor adjustments for modern screens

🔒 Security
• Enhanced push notification token validation
• Database access rules improvements

Connect with musicians and bands near you! 🎵
```

### 🇺🇸 English (US) - Apple App Store

```
🎸 What's New

• Deep links for sharing posts
• Age verification during signup
• Post display fixes
• Stability and security improvements

Find musicians and bands in your area! 🎵
```

---

## 📋 Changelog Técnico

### ✨ Novas Funcionalidades

| Feature              | Descrição                                                   | Arquivos Principais                                 |
| -------------------- | ----------------------------------------------------------- | --------------------------------------------------- |
| Deep Linking         | Links compartilháveis abrem posts/perfis diretamente no app | `deep_link_generator.dart`, `app_router.dart`       |
| Verificação 18+      | Dialog de confirmação de idade no signup                    | `age_verification_dialog.dart`, `auth_page.dart`    |
| Bloqueio de Usuários | Interface para gerenciar usuários bloqueados                | `blocked_users_page.dart`, `blocked_relations.dart` |

### 🐛 Correções de Bugs

| Bug                         | Descrição                                                          | Arquivos                                                           |
| --------------------------- | ------------------------------------------------------------------ | ------------------------------------------------------------------ |
| ViewProfile Posts Expirados | Posts expirados não apareciam corretamente na tela de perfil       | `view_profile_page.dart`                                           |
| Status Bar Android 15       | API `setStatusBarColor` deprecada substituída por `statusBarLight` | `image_crop_helper.dart`, `edit_profile_page.dart`                 |
| Markers no Mapa             | Normalização de tamanho entre Android e iOS                        | `wegig_pin_descriptor_builder.dart`, `wegig_cluster_renderer.dart` |

### 🔒 Segurança

| Melhoria             | Descrição                                              |
| -------------------- | ------------------------------------------------------ |
| FCM Token Validation | Tokens de push validam ownership e expiração (60 dias) |
| Firestore Rules      | Validação de ownership em notificações multi-perfil    |
| Firestore Indexes    | Novo índice para filtro por tipo de notificação        |

### ⚙️ Compatibilidade

| Plataforma  | Mudança                                                    |
| ----------- | ---------------------------------------------------------- |
| Android 15+ | Removido uso de `Window.setStatusBarColor()` (deprecado)   |
| Android 16  | Aviso sobre `UCropActivity` orientation lock (não crítico) |

---

## 🚀 Deploy Checklist

### Pré-Deploy

- [ ] Versão atualizada: `1.0.7+10` em `pubspec.yaml`
- [ ] Build limpo: `flutter clean && melos bootstrap`
- [ ] Codegen: `melos run build_runner`
- [ ] Testes: `cd packages/app && flutter test`

### Firebase (se houver mudanças)

```bash
# Indexes
firebase deploy --only firestore:indexes --project wegig-dev
firebase deploy --only firestore:indexes --project wegig-staging
firebase deploy --only firestore:indexes --project to-sem-banda-83e19

# Rules
firebase deploy --only firestore:rules --project wegig-dev
firebase deploy --only firestore:rules --project wegig-staging
firebase deploy --only firestore:rules --project to-sem-banda-83e19

# Functions
firebase deploy --only functions --project wegig-dev
firebase deploy --only functions --project wegig-staging
firebase deploy --only functions --project to-sem-banda-83e19
```

### Android (Google Play Console)

```bash
# Build AAB
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
# Build IPA
cd packages/app
flutter build ipa --flavor prod -t lib/main_prod.dart --release

# Ou via Xcode
open ios/WeGig.xcworkspace
# Product → Archive → Distribute App → App Store Connect
```

**Upload:**

1. App Store Connect → WeGig → Nova Versão (1.0.7)
2. Upload via Xcode ou Transporter
3. Preencher "O Que Há de Novo" (pt-BR e en-US)
4. Submeter para revisão

---

## 📊 Métricas de Impacto Esperado

| Métrica       | Expectativa                          |
| ------------- | ------------------------------------ |
| Crash Rate    | Redução com fixes de compatibilidade |
| Push Delivery | +20-30% com validação de tokens      |
| UX em Tablets | Melhoria com fixes de layout         |

---

## 🔄 Rollback (se necessário)

Versão anterior disponível: **1.0.6 (Build 9)**

Firebase Rules/Functions podem ser revertidas via:

```bash
firebase deploy --only firestore:rules --project <env> --force
# Usando backup anterior
```

---

**Responsável:** Equipe WeGig  
**Aprovação:** Pendente
