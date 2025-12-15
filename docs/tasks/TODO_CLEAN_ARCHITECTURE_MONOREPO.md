# TODO: Clean Architecture & Monorepo - ✅ CONCLUÍDO!

**Objetivo:** Finalizar a migração completa para Clean Architecture + Monorepo antes de retomar flavors  
**Status Final:** ✅ **100% COMPLETO** | 7/7 features | 0 erros | lib/ removido  
**Data Início:** 28 de novembro de 2025  
**Data Conclusão:** 29 de novembro de 2025 (1 dia!)

---

## 🎉 RESUMO EXECUTIVO

**Missão cumprida em 1 dia!** A migração para Clean Architecture + Monorepo está **100% completa**.

### 📊 Números da Migração

- **Features refatoradas:** 7/7 (100%)
- **Erros eliminados:** ~1.030 erros → 0 erros
- **Código legado removido:** 96 arquivos (26.785 linhas)
- **Arquitetura:** Clean Architecture + Feature-First + Monorepo
- **Tempo total:** ~24 horas (28/11 → 29/11/2025)

### ✅ O que foi entregue

1. **Todas as features com Clean Architecture** (Auth, Profile, Home, Post, Messages, Notifications, Settings)
2. **Monorepo funcional** (packages/app + packages/core_ui)
3. **0 erros de compilação** em packages/app
4. **Código legado removido** (lib/ limpo)
5. **App rodando no iPhone** com navegação funcional
6. **Router com profile guard** (cria perfil automaticamente se não existir)
7. **Transação Firestore corrigida** (READ→WRITE order)

### 🚀 Próximos Passos

**Opção 1: Retomar Flavors** (conforme planejado no TODO)

- Adaptar estrutura de flavors para monorepo
- Configurar Firebase por flavor (dev, staging, prod)
- Testar builds por flavor

**Opção 2: Continuar Desenvolvimento**

- App está pronto para novas features
- Arquitetura sólida e escalável
- 0 débitos técnicos bloqueantes

---

## 📊 Status Atual - ✅ MIGRAÇÃO COMPLETA!

### ✅ Completo (7 features - 0 erros)

- **packages/app/lib/features/auth/** - Autenticação (email, Google, Apple) ✅
- **packages/app/lib/features/profile/** - Multi-perfil com Clean Architecture ✅
- **packages/app/lib/features/notifications/** - Sistema de notificações ✅
- **packages/app/lib/features/home/** - Home page com busca geolocalizada ✅
- **packages/app/lib/features/settings/** - Configurações do usuário ✅
- **packages/app/lib/features/messages/** - Chat e conversas ✅
- **packages/app/lib/features/post/** - Criação/edição de posts ✅

### ✅ Core UI Completo

- **packages/core_ui/lib/features/** - Entities centralizadas (Profile, Post, Message, Conversation, Notification) ✅
- **packages/core_ui/lib/theme/** - Sistema de design unificado ✅
- **packages/core_ui/lib/navigation/** - BottomNavScaffold ✅
- **packages/core_ui/lib/models/** - SearchParams compartilhado ✅

### 🗑️ Legado - REMOVIDO

- **lib/** - Código antigo REMOVIDO (96 arquivos, 26.785 linhas) ✅
- Mantidos apenas: `firebase_options.dart`, `flavors.dart`

---

## 🎯 Plano de Ação

### FASE 1: Corrigir Core UI (PRIORIDADE MÁXIMA) 🔥

**Problema:** `packages/core_ui` tem dependências de arquivos que não existem mais

#### 1.1. Mover Features Faltando para Core UI

- [ ] **Criar `packages/core_ui/lib/features/profile/`**

  - [ ] Mover `domain/entities/profile_entity.dart` de app para core_ui
  - [ ] Mover `domain/repositories/i_profile_repository.dart` para core_ui
  - [ ] Atualizar imports em `packages/core_ui/lib/di/profile_providers.dart`
  - [ ] Atualizar imports em `packages/core_ui/lib/profile_result.dart`

- [ ] **Criar `packages/core_ui/lib/features/post/`**

  - [ ] Mover `domain/entities/post_entity.dart` de app para core_ui
  - [ ] Atualizar imports em `packages/core_ui/lib/post_result.dart`

- [ ] **Criar `packages/core_ui/lib/features/messages/`**

  - [ ] Mover `domain/entities/conversation_entity.dart` de app para core_ui
  - [ ] Mover `domain/entities/message_entity.dart` de app para core_ui
  - [ ] Atualizar imports em `packages/core_ui/lib/messages_result.dart`

- [ ] **Criar `packages/core_ui/lib/features/notifications/`**
  - [ ] Mover `domain/entities/notification_entity.dart` de app para core_ui
  - [ ] Mover `domain/services/notification_service.dart` para core_ui (se necessário)
  - [ ] Atualizar imports em `packages/core_ui/lib/navigation/bottom_nav_scaffold.dart`

#### 1.2. Mover Theme para Core UI

- [ ] **Mover `packages/app/lib/core/theme/` → `packages/core_ui/lib/theme/`**
  - [ ] `app_colors.dart`
  - [ ] `app_typography.dart`
  - [ ] `app_theme.dart`
  - [ ] Atualizar todos os imports em core_ui

#### 1.3. Criar SearchParams em Core UI

- [ ] **Criar `packages/core_ui/lib/models/search_params.dart`**
  - [ ] Copiar de `packages/app/lib/models/search_params.dart`
  - [ ] Atualizar import em `bottom_nav_scaffold.dart`

---

### FASE 2: Refatorar Packages Structure

**Objetivo:** Organizar melhor a separação de responsabilidades

#### 2.1. Definir Responsabilidades Claras

**packages/app (Application Layer)**

- ✅ Features específicas da aplicação
- ✅ Páginas Flutter (UI específica)
- ✅ Providers específicos de features
- ✅ Firebase initialization
- ✅ Roteamento (go_router)

**packages/core_ui (Shared Layer)**

- ✅ Entities compartilhadas (ProfileEntity, PostEntity, etc)
- ✅ Interfaces de repositórios (contratos)
- ✅ Theme system (AppColors, AppTypography)
- ✅ Widgets reutilizáveis
- ✅ Result types (AuthResult, ProfileResult)
- ✅ Global providers (profileProvider, authProvider)
- ✅ Navigation scaffold

#### 2.2. Mover Arquivos Conforme Responsabilidade

- [ ] **Entities para core_ui** (já iniciado na Fase 1)
- [ ] **Services abstratos para core_ui** (interfaces apenas)
- [ ] **Services concretos permanecem em app** (implementações Firebase)
- [ ] **Providers globais em core_ui** (profile, auth)
- [ ] **Providers de features em app** (post, messages, notifications)

---

### FASE 3: Migrar Features Restantes para Clean Architecture

#### 3.1. Messages Feature

- [ ] **Criar estrutura Clean Architecture em `packages/app/lib/features/messages/`**

  ```
  messages/
  ├── domain/
  │   ├── entities/          # ConversationEntity, MessageEntity (já existem)
  │   ├── repositories/
  │   │   └── i_messages_repository.dart
  │   └── usecases/
  │       ├── send_message.dart
  │       ├── get_conversations.dart
  │       └── mark_as_read.dart
  ├── data/
  │   ├── datasources/
  │   │   └── messages_remote_datasource.dart
  │   └── repositories/
  │       └── messages_repository_impl.dart
  └── presentation/
      ├── providers/
      │   └── messages_provider.dart
      ├── pages/
      │   ├── messages_page.dart
      │   └── chat_detail_page.dart
      └── widgets/
          ├── conversation_card.dart
          └── message_bubble.dart
  ```

- [ ] **Migrar lógica de `lib/` para nova estrutura**
  - [ ] Extrair código de negócio para use cases
  - [ ] Separar acesso a dados em datasource
  - [ ] Implementar repository com interface
  - [ ] Atualizar providers para usar use cases

#### 3.2. Post Feature

- [ ] **Criar estrutura Clean Architecture em `packages/app/lib/features/post/`**

  ```
  post/
  ├── domain/
  │   ├── entities/          # PostEntity (já existe)
  │   ├── repositories/
  │   │   └── i_post_repository.dart
  │   └── usecases/
  │       ├── create_post.dart
  │       ├── update_post.dart
  │       ├── delete_post.dart
  │       └── get_nearby_posts.dart
  ├── data/
  │   ├── datasources/
  │   │   └── post_remote_datasource.dart
  │   └── repositories/
  │       └── post_repository_impl.dart
  └── presentation/
      ├── providers/
      │   └── post_provider.dart
      ├── pages/
      │   └── post_page.dart
      └── widgets/
          └── post_form.dart
  ```

- [ ] **Migrar lógica de `lib/` para nova estrutura**
  - [ ] Separar validação em domain
  - [ ] Implementar repository
  - [ ] Criar use cases
  - [ ] Atualizar providers

---

### FASE 4: Resolver Conflitos de Imports

#### 4.1. Padronizar Package Imports

- [ ] **Substituir todos imports relativos por package imports**

  ```bash
  # Em packages/app/
  import '../../../domain/entities/profile_entity.dart'  # ❌
  import 'package:wegig_app/features/profile/domain/entities/profile_entity.dart'  # ✅

  # Em packages/core_ui/
  import '../theme/app_colors.dart'  # ❌
  import 'package:core_ui/theme/app_colors.dart'  # ✅
  ```

- [ ] **Rodar script de conversão**
  ```bash
  cd packages/app
  # Script automático para converter relative → package imports
  ```

#### 4.2. Resolver Package Name Conflicts

- [ ] **Verificar pubspec.yaml**

  - `packages/app/pubspec.yaml`: name deve ser `wegig_app`
  - `packages/core_ui/pubspec.yaml`: name deve ser `core_ui`

- [ ] **Atualizar imports inconsistentes**
  - Buscar por `package:to_sem_banda/` e substituir por `package:wegig_app/`
  - Verificar se `bottom_nav_scaffold.dart` usa imports corretos

---

### FASE 5: Testes e Validação

#### 5.1. Executar Build e Corrigir Erros

- [ ] **Build packages/app**

  ```bash
  cd packages/app
  flutter pub get
  flutter analyze
  flutter build apk --debug
  ```

- [ ] **Corrigir erros de compilação**
  - Anotar todos os erros
  - Priorizar por categoria (imports, tipos, etc)
  - Corrigir em lotes

#### 5.2. Rodar Testes Existentes

- [ ] **Executar testes unitários**
  ```bash
  cd packages/app
  flutter test
  ```
  - Verificar se os 53 testes continuam passando
  - Corrigir testes quebrados após refatoração

#### 5.3. Testes Manuais

- [ ] **Testar fluxos críticos**
  - [ ] Login/Logout
  - [ ] Criar perfil
  - [ ] Criar post
  - [ ] Enviar mensagem
  - [ ] Receber notificação

---

### FASE 6: Limpeza Final

#### 6.1. Remover Código Legado

- [ ] **Backup antes de deletar**

  ```bash
  git checkout -b backup-legacy-code
  git add lib/
  git commit -m "Backup: código legado antes de remoção"
  git checkout main
  ```

- [ ] **Deletar lib/ legado**

  ```bash
  # APENAS após confirmar que app funciona 100%
  rm -rf lib/features
  rm -rf lib/models
  rm -rf lib/services
  rm -rf lib/repositories
  rm -rf lib/providers
  ```

- [ ] **Manter apenas arquivos essenciais em lib/**
  - `lib/main.dart` (redirect para packages/app)
  - `lib/firebase_options.dart` (gerado pelo FlutterFire CLI)

#### 6.2. Documentação

- [ ] **Atualizar README.md**

  - Explicar estrutura monorepo
  - Documentar como rodar app
  - Adicionar guia de contribuição

- [ ] **Criar MIGRATION_COMPLETED.md**
  - Resumo da migração
  - Antes/depois (estatísticas)
  - Lições aprendidas

---

## 🚀 FASE 7: Retomar Flavors (APÓS FASES 1-6)

Apenas quando `packages/app` estiver 100% funcional:

### 7.1. Adaptar Flavors para Monorepo

- [ ] **Criar estrutura de flavors em packages/app**
  ```
  packages/app/
  ├── android/app/
  │   ├── build.gradle.kts       # Configurar productFlavors
  │   └── src/
  │       ├── dev/AndroidManifest.xml
  │       ├── staging/AndroidManifest.xml
  │       └── prod/AndroidManifest.xml
  ├── ios/Flutter/
  │   ├── Dev.xcconfig
  │   ├── Staging.xcconfig
  │   └── Prod.xcconfig
  └── lib/
      ├── config/
      │   ├── dev_config.dart
      │   ├── staging_config.dart
      │   └── prod_config.dart
      ├── main_dev.dart
      ├── main_staging.dart
      └── main_prod.dart
  ```

### 7.2. Configurar Firebase por Flavor

- [ ] **Criar 3 projetos Firebase**

  - `to-sem-banda-dev`
  - `to-sem-banda-staging`
  - `to-sem-banda-prod` (já existe)

- [ ] **Gerar configs por flavor**

  ```bash
  cd packages/app

  # Dev
  flutterfire configure --project=to-sem-banda-dev \
    --out=lib/firebase_options_dev.dart \
    --ios-bundle-id=com.tosembanda.wegig.dev \
    --android-package-name=com.tosembanda.wegig.dev

  # Staging
  flutterfire configure --project=to-sem-banda-staging \
    --out=lib/firebase_options_staging.dart \
    --ios-bundle-id=com.tosembanda.wegig.staging \
    --android-package-name=com.tosembanda.wegig.staging

  # Prod
  flutterfire configure --project=to-sem-banda-prod \
    --out=lib/firebase_options_prod.dart \
    --ios-bundle-id=com.tosembanda.wegig \
    --android-package-name=com.tosembanda.wegig
  ```

### 7.3. Atualizar Scripts de Build

- [ ] **Adaptar `scripts/build_release.sh` para monorepo**
  - Atualizar paths para `packages/app`
  - Testar build de cada flavor
  - Validar obfuscação

---

## 📋 Checklist Rápido (Copiar para Issues)

### Sprint 1: Core UI Fixes (2-3 dias)

- [ ] Mover entities para core_ui
- [ ] Mover theme para core_ui
- [ ] Criar SearchParams em core_ui
- [ ] Corrigir imports em profile_providers.dart
- [ ] Corrigir imports em bottom_nav_scaffold.dart

### Sprint 2: Messages Feature (2-3 dias)

- [ ] Criar estrutura Clean Architecture
- [ ] Migrar lógica de negócio para use cases
- [ ] Implementar repository pattern
- [ ] Atualizar providers
- [ ] Testes unitários

### Sprint 3: Post Feature (2-3 dias)

- [ ] Criar estrutura Clean Architecture
- [ ] Migrar lógica de validação
- [ ] Implementar repository pattern
- [ ] Atualizar providers
- [ ] Testes unitários

### Sprint 4: Build & Testes (1-2 dias)

- [ ] Resolver imports conflicts
- [ ] Build sem erros
- [ ] 53 testes passando
- [ ] Testes manuais críticos

### Sprint 5: Limpeza (1 dia)

- [ ] Backup código legado
- [ ] Remover lib/ antigo
- [ ] Atualizar documentação
- [ ] Code review final

### Sprint 6: Flavors (3-4 dias)

- [ ] Adaptar para monorepo
- [ ] Configurar Firebase
- [ ] Testar builds
- [ ] Deploy

---

## 🎯 Prioridades

### P0 - CRÍTICO (fazer AGORA)

1. Mover entities para core_ui (resolve 80% dos erros)
2. Mover theme para core_ui (resolve imports de AppColors)
3. Criar SearchParams em core_ui (resolve bottom_nav_scaffold)

### P1 - ALTO (próxima semana)

4. Migrar Messages para Clean Architecture
5. Migrar Post para Clean Architecture
6. Resolver imports conflicts

### P2 - MÉDIO (pode esperar)

7. Remover código legado de lib/
8. Atualizar documentação completa
9. Code review e refactoring

### P3 - BAIXO (após MVP funcional)

10. Flavors em monorepo
11. Deploy staging/production
12. Monitoramento e analytics

---

## 🚨 Riscos e Mitigações

| Risco                              | Probabilidade | Impacto | Mitigação                                                  |
| ---------------------------------- | ------------- | ------- | ---------------------------------------------------------- |
| Quebrar código em produção         | Médio         | Alto    | Trabalhar em branch separada, backups frequentes           |
| Imports circulares core_ui ↔ app   | Alto          | Médio   | Definir dependências claras: core_ui não depende de app    |
| Testes quebrarem após migração     | Alto          | Médio   | Rodar testes após cada mudança, não deixar acumular        |
| Conflitos de merge com outros devs | Baixo         | Alto    | Comunicar mudanças grandes, trabalhar em features isoladas |
| Perder tempo com código legado     | Médio         | Médio   | Não tentar consertar lib/, focar apenas em packages/app    |

---

## 📊 Métricas de Sucesso

### ✅ ANTES (28 de novembro de 2025)

- ⚠️ packages/app: **~100 erros** (profile_providers deletado)
- ❌ lib/: **880 erros** (código legado)
- ❌ core_ui: **~50 erros de imports**
- ⚠️ Testes: **53 passando** (mas com erros de compilação)
- ⚠️ Features refatoradas: **5/7** (Messages e Post incompletos)
- ❌ App não rodava no device

### ✅ DEPOIS (29 de novembro de 2025) - CONCLUÍDO!

- ✅ packages/app: **0 erros** (915 info/warnings não-bloqueantes)
- ✅ packages/core_ui: **0 erros**
- ✅ lib/: **REMOVIDO** (96 arquivos, 26.785 linhas deletadas)
- ✅ Testes: **53 passando**
- ✅ Features refatoradas: **7/7** (100% com Clean Architecture)
- ✅ App roda no iPhone ✅
- ✅ Router com profile guard ✅
- ✅ Transação Firestore corrigida ✅
- ⏸️ Flavors: **próximo passo**

---

## 🔄 Processo Iterativo

**NÃO tentar fazer tudo de uma vez!**

Cada fase deve seguir:

1. Fazer mudanças pequenas e incrementais
2. Rodar `flutter analyze` constantemente
3. Rodar `flutter test` após cada mudança
4. Commit frequente com mensagens descritivas
5. Criar branch separada para mudanças grandes

```bash
# Exemplo de workflow por fase
git checkout -b fase-1-core-ui-fixes
# Fazer mudanças da Fase 1
flutter analyze  # Verificar erros
flutter test     # Verificar testes
git add .
git commit -m "Fase 1: Mover entities e theme para core_ui"
git push origin fase-1-core-ui-fixes
# Abrir PR, code review, merge
# Repetir para próxima fase
```

---

## 📝 Notas Importantes

### 1. Não Tocar em lib/ (Legado)

- **NUNCA** tentar consertar erros em `lib/`
- Apenas copiar código útil para `packages/app`
- Deletar `lib/` apenas no final, quando tudo funcionar

### 2. Core UI é Shared, App é Específico

- **core_ui**: código compartilhado, sem lógica de negócio específica do app
- **app**: features específicas, Firebase, providers de features

### 3. Entities São Compartilhadas

- ProfileEntity, PostEntity, MessageEntity → **core_ui**
- Repositórios concretos → **app**
- Interfaces de repositórios → **core_ui** (opcional)

### 4. Testes São Essenciais

- Não pular testes para "ir mais rápido"
- Testes evitam regressões
- 53 testes já passando = baseline de qualidade

---

## ✅ MIGRAÇÃO COMPLETA! (29/11/2025)

**Critérios de aceitação - TODOS ATENDIDOS:**

1. ✅ `flutter analyze packages/app` = **0 erros** (915 info não-bloqueantes)
2. ✅ `flutter analyze packages/core_ui` = **0 erros**
3. ✅ `flutter test packages/app` = **53 testes passando**
4. ✅ `flutter build ios --debug` = **sucesso** (242.7s)
5. ✅ App roda no iPhone sem crashes
6. ✅ Router com profile guard funcionando
7. ✅ Código legado removido (96 arquivos)
8. ✅ Documentação atualizada

**🎉 PRONTO PARA:** → Retomar flavors ou continuar desenvolvimento!

---

## 🤝 Próximos Passos Imediatos

**COMEÇAR AGORA (Ordem de execução):**

1. **Criar branch nova**

   ```bash
   git checkout -b feat/complete-monorepo-migration
   ```

2. **Fase 1.1: Mover Entities (30 min)**

   - ProfileEntity → core_ui
   - PostEntity → core_ui
   - MessageEntity → core_ui
   - ConversationEntity → core_ui
   - NotificationEntity → core_ui

3. **Fase 1.2: Mover Theme (15 min)**

   - app_colors.dart → core_ui
   - app_typography.dart → core_ui
   - app_theme.dart → core_ui

4. **Fase 1.3: Criar SearchParams (10 min)**

   - Copiar para core_ui/lib/models/

5. **Verificar compilação (5 min)**
   ```bash
   cd packages/app
   flutter pub get
   flutter analyze
   ```

**Estimativa total Fase 1:** ~1 hora

**Se Fase 1 funcionar:** Partir para Fase 2 (Messages)

**Se Fase 1 falhar:** Pedir ajuda e revisitar arquitetura

---

**🎯 Meta:** Clean Architecture + Monorepo 100% funcional em **7-10 dias**

**📅 Deadline sugerido:** 6 de dezembro de 2025

**🚀 Depois:** Flavors em 3-4 dias

**📦 Total:** App production-ready em **~2 semanas**
