# WeGig - MVP Description

**Versão:** 1.2.0  
**Data:** 03 de Dezembro de 2025  
**Status:** Production Ready + UX refinements (perfil e navegação)  
**Plataformas:** iOS, Android

### Atualizações (Dez/2025)

- ✅ Transições personalizadas no GoRouter eliminam flashes entre rotas e mantêm estado durante animações
- ✅ Fluxo de salvar perfil volta automaticamente para View Profile após refresh do provider ativo
- ✅ Marcadores do mapa reduzidos em ~30% para melhorar legibilidade em áreas densas
- ✅ Inicialização do Firebase protegida por `_initializeFirebaseSafely()` antes de qualquer operação de Auth (evita exceções em hot reload)
- ✅ Fluxo de cadastro com email/senha alinhado à nova política de senha mínima (6+ caracteres) em toda a stack

---

## 🎯 Visão Geral

**WeGig** é uma plataforma social mobile que conecta músicos e bandas através de geolocalização em tempo real, posts efêmeros e chat instantâneo. O app resolve o problema crítico de músicos que buscam oportunidades de trabalho e colaboração na sua região, eliminando a fricção de grupos dispersos em WhatsApp e redes sociais genéricas.

### Proposta de Valor

- **Para Músicos Solo:** Encontre vagas em bandas, freelas, aulas e jam sessions próximas a você
- **Para Bandas:** Recrute membros qualificados, divulgue shows e faça networking
- **Para Negócios Musicais:** Conecte-se com profissionais locais, promova serviços e produtos

---

## 🌟 Diferenciais Competitivos

| Diferencial                      | Descrição                                                                                                | Impacto                                                              |
| -------------------------------- | -------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| **Geolocalização Inteligente**   | Mapa interativo mostra posts em tempo real num raio configurável (5-100km)                               | Elimina busca manual, foco em oportunidades próximas                 |
| **Multi-Perfil Instagram-Style** | Cada usuário pode ter até 5 perfis (Banda, Músico solo, Professor, etc) com isolamento completo de dados | Profissionais versáteis gerenciam múltiplas identidades sem conflito |
| **Posts Efêmeros (30 dias)**     | Conteúdo expira automaticamente, mantendo plataforma atualizada                                          | Reduz spam, foco em oportunidades relevantes                         |
| **Notificações de Proximidade**  | Cloud Functions detectam novos posts no raio configurado e notificam automaticamente                     | Usuários não perdem oportunidades na sua região                      |
| **Chat Real-Time**               | Mensagens instantâneas com indicadores de leitura e contadores de não lidas                              | Negociação rápida, profissional                                      |

---

## 🏗️ Arquitetura Técnica

### Stack Tecnológico

**Frontend:**

- Flutter 3.9.2+ (cross-platform nativo)
- Dart 3.6+ (type-safe, null-safe)
- Riverpod 2.5+ (state management reativo)
- Freezed (code generation para models imutáveis)

**Backend:**

- Firebase Firestore (banco de dados NoSQL real-time)
- Firebase Auth (autenticação multi-provider)
- Firebase Storage (armazenamento de imagens)
- Cloud Functions (Node.js) para lógica server-side

**Infraestrutura:**

- Google Maps Platform (mapa interativo)
- Firebase Cloud Messaging (push notifications)
- Firebase Crashlytics (error tracking)
- Firebase Analytics (métricas de uso)

### Arquitetura de Software

**Clean Architecture + Feature-First + Monorepo**

```
packages/
├── app/                    # Application layer
│   ├── features/          # 7 features isoladas
│   │   ├── auth/          # Autenticação
│   │   ├── profile/       # Gestão de perfis
│   │   ├── home/          # Mapa + busca
│   │   ├── post/          # Criação de posts
│   │   ├── messages/      # Chat
│   │   ├── notifications/ # Notificações
│   │   └── settings/      # Configurações
│   └── app/router/        # Navegação type-safe (GoRouter)
└── core_ui/               # Shared layer
    ├── features/          # Entities compartilhadas
    ├── theme/             # Design system
    ├── widgets/           # Componentes reutilizáveis
    └── di/                # Dependency injection global
```

**Padrões Implementados:**

- Repository Pattern (CRUD isolado)
- Use Cases (business logic)
- Sealed Classes (type-safe error handling)
- Atomic Transactions (previne dados órfãos)
- Debouncing/Throttling (performance)
- Image Compression em Isolates (evita UI freeze)
- Marker Cache (95% mais rápido)

---

## 🎨 Features Principais

### 1. Autenticação Multi-Provider

**Implementação:**

- Email/Senha (Firebase Auth)
- Google Sign-In (OAuth 2.0)
- Apple Sign-In (obrigatório para iOS)

**Segurança:**

- Tokens JWT gerenciados pelo Firebase
- Refresh automático de tokens
- Logout com limpeza de cache
- Inicialização única do Firebase garantida antes de acionar Auth (previne multi-initialization em hot restart)

**UX:**

- Onboarding guiado (3 steps)
- Login persistente
- Recuperação de senha integrada

---

### 2. Sistema Multi-Perfil (Core Feature)

**Modelo de Dados:**

```
users/{uid}
  ├── activeProfileId: String
  └── email: String

profiles/{profileId}
  ├── uid: String (Firebase UID do dono)
  ├── name: String (2-50 chars)
  ├── isBand: Boolean
  ├── location: GeoPoint (obrigatório)
  ├── city: String (auto-gerado via reverse geocoding)
  ├── instruments: List<String>
  ├── genres: List<String>
  ├── bio: String (max 500 chars)
  ├── photoUrl: String
  ├── notificationRadius: Double (5-100km, default 20km)
  └── createdAt: Timestamp
```

**Casos de Uso:**

- Músico pode ter perfis: "João - Guitarrista", "Banda XYZ", "João - Professor"
- Troca instantânea de perfil (similar ao Instagram)
- Dados completamente isolados entre perfis
- Limite de 5 perfis por usuário (regra de negócio)
- Salvamento de edição volta ao View Profile após refresh imediato do provider ativo

**Validações:**

- Nome único por usuário
- Localização obrigatória (não aceita 0,0)
- Profile guard: cria perfil automaticamente se não existir
- Atomic deletion: remove activeProfileId antes de deletar perfil

---

### 3. Posts com Geolocalização

**Tipos de Posts:**

- **Músico busca banda** (ex: "Baterista procura banda de rock")
- **Banda busca membro** (ex: "Banda de jazz precisa de saxofonista")
- **Oferta de trabalho** (ex: "Freela para casamento - R$ 200")
- **Divulgação de show** (ex: "Banda XYZ - Sábado 21h - Bar ABC")
- **Jam session** (ex: "Jam de blues - Domingo 15h")
- **Aulas** (ex: "Aulas de violão - Centro SP")

**Campos Obrigatórios:**

```dart
{
  postId: String (UUID),
  authorProfileId: String,
  authorUid: String,
  type: 'musician' | 'band',
  description: String (max 1000 chars),
  location: GeoPoint (lat, lng),
  city: String,
  instruments: List<String>,
  genres: List<String>,
  imageUrls: List<String> (max 9 fotos),
  youtubeUrl: String? (opcional),
  expiresAt: Timestamp (now + 30 days),
  createdAt: Timestamp
}
```

**Performance:**

- Imagens comprimidas (85% quality) em isolate (evita freeze)
- Upload paralelo para Firebase Storage
- CachedNetworkImage (80% performance boost vs Image.network)
- Pagination com `startAfterDocument` (50 posts por página)

**Queries Otimizadas:**

```dart
// Query universal (TODOS os posts devem usar)
FirebaseFirestore.instance.collection('posts')
  .where('expiresAt', isGreaterThan: Timestamp.now())
  .orderBy('expiresAt')
  .orderBy('createdAt', descending: true)
  .limit(50);
```

**15 Composite Indexes configurados** para filtros combinados (tipo + instrumento + gênero + localização).

---

### 4. Busca Geoespacial com Mapa Interativo

**Implementação:**

- Google Maps Flutter (nativo)
- Markers customizados por tipo (músico = azul, banda = laranja)
- Marker cache (Canvas API) - 40ms → 2ms por marker
- Marcadores 30% menores para suportar clusters densos sem sobreposição
- Cluster automático quando > 50 markers
- Bottom sheet com carrossel de posts

**Filtros Disponíveis:**

- **Raio:** 5km, 10km, 20km, 50km, 100km
- **Tipo:** Músico, Banda, Todos
- **Instrumentos:** Guitarra, Baixo, Bateria, Vocal, Teclado, +20 opções
- **Gêneros:** Rock, Jazz, Blues, MPB, Samba, +30 opções
- **Busca Textual:** Título, descrição, cidade (debounced 300ms)

**UX:**

- Scroll horizontal de posts abaixo do mapa
- Tap no post → move mapa para localização
- Long press no marker → Bottom sheet com opções (Ver, Interesse, Editar, Deletar)
- Pull-to-refresh
- Indicador de loading com skeleton screens

**Cálculo de Distância:**

- Haversine formula (server-side em Cloud Functions)
- Precisão de ~1m
- Fallback para aproximação se erro

---

### 5. Notificações Inteligentes

**Tipos:**

#### A. Notificações de Proximidade (Cloud Function)

**Trigger:** `onCreate('posts/{postId}')`

**Lógica:**

1. Novo post criado
2. Cloud Function query profiles com `notificationRadiusEnabled == true`
3. Calcula distância Haversine de cada profile
4. Se distância ≤ notificationRadius → cria notificação
5. Envia push notification via FCM
6. Batch write (max 500 notificações por post)

**Rate Limiting:** 20 posts/dia por usuário (previne spam)

#### B. Notificações de Interesse

**Trigger:** Usuário demonstra interesse em post

**Lógica:**

1. Usuário toca "Demonstrar Interesse"
2. Cria documento em `interests/` collection
3. Cloud Function notifica autor do post
4. Push notification + notificação in-app

**Rate Limiting:** 50 interesses/dia por perfil

#### C. Notificações de Mensagem

**Trigger:** Nova mensagem em chat

**Lógica:**

1. Mensagem enviada
2. Cloud Function notifica destinatário
3. Agrega notificações por conversa (não spamma)
4. Push notification com preview de mensagem

**Rate Limiting:** 500 mensagens/dia por perfil

**Badge Counters:**

- Contador de não lidas em tempo real (StreamProvider)
- Atualiza automaticamente ao trocar de perfil
- Cache de 1min (reduz leituras Firestore em 50%)

---

### 6. Chat Real-Time

**Arquitetura:**

```
conversations/{conversationId}
  ├── participants: List<String> (UIDs)
  ├── participantNames: Map<String, String>
  ├── participantPhotos: Map<String, String>
  ├── lastMessage: String
  ├── lastMessageTime: Timestamp
  ├── unreadCount: Map<String, int>
  └── messages/ (subcollection)
      └── {messageId}
          ├── senderId: String
          ├── text: String
          ├── imageUrl: String?
          ├── createdAt: Timestamp
          └── read: Boolean
```

**Features:**

- Mensagens de texto + imagens
- Confirmação de leitura (checkmarks)
- Indicador "digitando..." (em desenvolvimento)
- URLs clicáveis (flutter_linkify)
- Scroll para última mensagem não lida
- Delete de mensagens (apenas próprias)
- Delete de conversas (para ambos participantes)

**Performance:**

- Lazy loading (carrega apenas ao abrir tab Messages)
- Pagination de mensagens (50 por vez)
- Debounce de 300ms em streams
- Auto-scroll suave ao enviar mensagem

**Segurança:**

- Firestore rules: apenas participants podem ler/escrever
- Validação de senderId server-side
- Rate limiting: 500 msgs/dia por perfil

---

### 7. Configurações e Preferências

**Configurações de Notificação:**

- Ativar/desativar notificações de proximidade
- Ajustar raio de notificação (5-100km)
- Notificações de interesse (on/off)
- Notificações de mensagem (on/off)
- Silent mode (pausar todas notificações)

**Configurações de Privacidade:**

- Visibilidade do perfil (público/privado) - _em desenvolvimento_
- Bloquear usuários - _em desenvolvimento_
- Denunciar conteúdo - _em desenvolvimento_

**Configurações de Conta:**

- Editar perfil ativo
- Trocar perfil ativo
- Criar novo perfil (até 5)
- Deletar perfil (com confirmação)
- Logout
- Deletar conta (com confirmação dupla) - _em desenvolvimento_

---

## 🔒 Segurança & Proteção

### Firestore Security Rules

**Proteções Implementadas:**

1. **Autenticação obrigatória** para todas operações
2. **Users collection:** read/write apenas próprio documento
3. **Profiles:**
   - Create: `uid == request.auth.uid` + validações de campo
   - Update/Delete: apenas dono + validações
   - Validações: name 2-50 chars, bio ≤500 chars, location is GeoPoint
4. **Posts:**
   - Create: `authorUid == request.auth.uid` + authorProfileId pertence ao usuário
   - Update/Delete: apenas autor
   - Validações: description ≤1000 chars, expiresAt > now, type in ['musician','band']
5. **Conversations:**
   - Read/Write: apenas se `auth.uid in participants`
6. **Messages:**
   - Read: se auth.uid está na conversa pai
   - Create: se auth.uid está na conversa E senderId == auth.uid
   - Delete: apenas próprias mensagens
7. **Rate Limits:**
   - Read/Write: `if false` (Admin SDK only - server-side)

### Firebase Storage Rules

**Proteções:**

- File size: 10MB max (previne abuse/custos)
- MIME type: apenas `image/*` (previne malware)
- Autenticação obrigatória
- `user_photos/{userId}/*`: apenas dono pode escrever
- `posts/*`, `profiles/*`: autenticados podem escrever (validação via Firestore)

### Cloud Functions Security

**Rate Limiting:**

- Posts: 20/dia por usuário
- Interests: 50/dia por perfil
- Messages: 500/dia por perfil
- Fail-open design (não bloqueia usuários legítimos se check falhar)
- Counter com reset automático após 24h

**Data Validation:**

- Valida `post.location` e `profile.location` antes de calcular distância
- Filtra dados inválidos/missing
- Logs detalhados para debug

### Frontend Security

**Environment Variables:**

- `.env` file para API keys (nunca commitado)
- `EnvService` carrega e mascara logs
- `.gitignore` protege chaves sensíveis

**Code Obfuscation:**

- ProGuard (Android) - minify + shrink resources
- Flutter obfuscation (`--obfuscate`)
- Debug symbols separados (`--split-debug-info`)
- Build script automatizado (`scripts/build_release.sh`)

**Secure Storage:**

- iOS: Keychain Services
- Android: EncryptedSharedPreferences (AES-256)
- `SecureStorageService` para tokens sensíveis

---

## 📊 Métricas & Analytics

**Firebase Analytics Implementado:**

**Events Tracked:**

- `user_signup` (método: email, google, apple)
- `profile_created` (type: musician, band)
- `profile_switched` (from, to)
- `post_created` (type, has_image, has_youtube)
- `post_viewed` (post_id, author_profile_id)
- `interest_sent` (post_id)
- `message_sent` (conversation_id)
- `search_performed` (filters: type, instruments, genres, radius)
- `notification_opened` (type: proximity, interest, message)

**User Properties:**

- `active_profile_id`
- `total_profiles`
- `user_type` (musician, band, both)
- `notification_radius`
- `has_pro_subscription` (futuro)

**Dashboards Planejados:**

- DAU/MAU
- Retention (D1, D7, D30)
- Funnel de conversão (signup → profile → post)
- Engagement (posts/user, messages/user)
- Geolocalização (heatmap de posts)
- Feature adoption (multi-profile usage, notifications)

---

## 🎨 Design System

**Material 3 + Custom Theme**

**Paleta de Cores:**

- **Primary:** Teal `#00A699` (músicos)
- **Secondary:** Orange `#E47911` (bandas)
- **Background:** White `#FFFFFF` / Dark `#121212` (dark mode)
- **Error:** Red `#D32F2F`
- **Success:** Green `#388E3C`

**Tipografia:**

- **Font:** Inter (Google Fonts)
- **Weights:** Regular (400), Medium (500), SemiBold (600), Bold (700)
- **Scales:**
  - Display: 32px/700
  - Headline: 24px/600
  - Title: 20px/600
  - Body: 16px/400
  - Label: 14px/500
  - Caption: 12px/400

**Componentes:**

- Bottom Navigation (IndexedStack + ValueNotifier)
- AppLoadingOverlay (blur + spinner + mensagem)
- CachedNetworkImage everywhere (performance)
- CustomTransitionPage (fade + slide) para eliminar flashes entre rotas
- SnackBars padronizados (success green, error red, info blue)
- Confirmation dialogs consistentes
- Bottom sheets (profile switcher, post options, multi-select)

**Ícones:**

- Material Icons (built-in)
- Custom markers (Canvas API renderizado)

---

## 🚀 Deployment & DevOps

### Ambientes (Flavors)

| Flavor      | App Name      | Bundle ID                      | Firebase Project     | Logs   | Obfuscation |
| ----------- | ------------- | ------------------------------ | -------------------- | ------ | ----------- |
| **dev**     | WeGig DEV     | `com.tosembanda.wegig.dev`     | to-sem-banda-dev     | ✅ On  | ❌ Off      |
| **staging** | WeGig STAGING | `com.tosembanda.wegig.staging` | to-sem-banda-staging | ✅ On  | ✅ On       |
| **prod**    | WeGig         | `com.tosembanda.wegig`         | to-sem-banda-83e19   | ❌ Off | ✅ On       |

**Build Commands:**

```bash
# Dev (rápido, sem obfuscation)
flutter run --flavor dev -t lib/main_dev.dart

# Staging (teste interno)
flutter build apk --flavor staging -t lib/main_staging.dart --release

# Production (App Store + Google Play)
./scripts/build_release.sh prod
```

**CI/CD (Planejado):**

- GitHub Actions para build automático
- Testes unitários obrigatórios antes de merge
- Deploy automático para Firebase App Distribution (staging)
- Deploy manual para stores (prod)

### Monitoramento

**Firebase Crashlytics:**

- Crash reporting automático
- Stacktraces simbolizadas
- User IDs para rastreamento
- Non-fatal errors logados

**Firebase Performance Monitoring:**

- Trace de telas (tempo de carregamento)
- Network requests (latency, success rate)
- Custom traces para operações críticas

**Cloud Functions Logs:**

```bash
firebase functions:log
firebase functions:log --only notifyNearbyPosts
firebase functions:log | grep "Rate limit"
```

---

## 💰 Plano de Monetização

### Fase 1: Freemium (Lançamento - Meses 1-6)

**Objetivo:** Adquirir base de usuários, provar product-market fit

**Free Tier (100% das features):**

- ✅ 1 perfil ativo
- ✅ 2 posts por mês
- ✅ 3 conversas por mês
- ✅ Busca ilimitada
- ✅ Visualização de posts ilimitada
- ✅ Notificações de proximidade

**Estratégia:**

- Foco em crescimento orgânico
- Sem ads (UX limpa)
- Coleta de feedback via in-app surveys
- A/B testing de features

---

### Fase 2: Assinatura PRO (Meses 7-12)

**Preço Sugerido:** R$ 19,90/mês ou R$ 199,00/ano (17% desconto)

**Features PRO:**

| Feature                    | Free     | PRO                           | Justificativa                                                                                                         |
| -------------------------- | -------- | ----------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| **Múltiplos Perfis**       | 1 perfil | Até 5 perfis                  | **Principal driver de conversão** - profissionais versáteis precisam múltiplas identidades (Banda + Solo + Professor) |
| **Limite de Posts**        | 2/mês    | Ilimitado                     | Profissionais ativos precisam divulgar constantemente                                                                 |
| **Limite de Chats**        | 3/mês    | Ilimitado                     | Networking sem restrições                                                                                             |
| **Visualização de Perfil** | ❌       | ✅ Ver quem visitou (24h/7d)  | Prova alcance, gera curiosidade (LinkedIn-style)                                                                      |
| **Confirmação de Leitura** | ❌       | ✅ Double checkmark           | Elimina incerteza em negociações profissionais                                                                        |
| **Badge PRO**              | ❌       | ✅ Selo "PRO" no perfil       | Sinaliza profissionalismo, destaque visual                                                                            |
| **Suporte Prioritário**    | ❌       | ✅ Resposta em 24h            | Profissionais pagam por confiabilidade                                                                                |
| **Analytics do Perfil**    | ❌       | ✅ Views, alcance, engagement | Data-driven decision making                                                                                           |

**Funil de Conversão:**

1. **Awareness:** Banner discreto na home (apenas para Free users)
2. **Interest:** Modal mostrando features PRO ao atingir limite (Ex: "Você atingiu o limite de 2 posts. Assine PRO para posts ilimitados")
3. **Trial:** 7 dias grátis (sem exigir cartão)
4. **Conversion:** In-app purchase (Apple/Google) ou PIX (Brasil)
5. **Retention:** Email mensal com analytics do perfil

**Projeção de Conversão:**

- **Pessimista:** 2% (1.000 usuários → 20 PRO) = R$ 398/mês
- **Realista:** 5% (1.000 usuários → 50 PRO) = R$ 995/mês
- **Otimista:** 10% (1.000 usuários → 100 PRO) = R$ 1.990/mês

---

### Fase 3: WeGig Business (B2B - Ano 2)

**Cliente Alvo:**

- Estúdios de gravação
- Lojas de instrumentos
- Escolas de música
- Luthiers
- Produtoras de eventos
- Casas de show
- Marcas de equipamentos

**Preço Sugerido:** R$ 99,90/mês por perfil empresarial

**Features Business:**

| Feature                        | Descrição                                           | Valor Agregado                  |
| ------------------------------ | --------------------------------------------------- | ------------------------------- |
| **Perfil Verificado**          | Selo azul + badge "Business"                        | Credibilidade, diferenciação    |
| **Geolocalização Prioritária** | Destaque no mapa (ícone maior, cor diferenciada)    | Visibilidade 3x maior           |
| **Posts Patrocinados**         | Aparece no feed de notificações (native ads)        | Alcance além do raio geográfico |
| **CRM Simplificado**           | Gerencia respostas aos posts, interesses, mensagens | Organização, follow-up          |
| **Analytics Avançado**         | Dashboard com métricas de alcance, conversões, ROI  | Justifica investimento          |
| **Múltiplas Localizações**     | Ex: Rede de lojas com 5 filiais                     | Cobertura geográfica ampla      |
| **API de Integração**          | Publica posts via API externa (ex: site da empresa) | Automação, eficiência           |

**Casos de Uso B2B:**

1. **Loja de Instrumentos:**

   - Post: "Promoção Black Friday: Guitarras 30% OFF"
   - Raio: 50km
   - Analytics: 2.340 visualizações, 87 interesses, 12 conversões (vendas rastreadas via código promocional)

2. **Escola de Música:**

   - Post: "Matrículas abertas - Aulas de violão, bateria, canto"
   - Raio: 20km
   - CRM: 45 interesses → 18 respondidos → 6 matrículas

3. **Casa de Show:**
   - Post: "Vaga para banda cover de rock - Sábado 23h - R$ 800"
   - Analytics: 856 views, 23 interesses, 1 contratação

**Estratégia de Aquisição B2B:**

- Outbound: cold email para 500 empresas/mês
- Partnerships: associações de luthiers, sindicatos musicais
- Case studies: ROI comprovado de early adopters
- Trial: 30 dias grátis (full-featured)

**Projeção de Receita B2B (Ano 2):**

- **10 empresas:** R$ 999/mês
- **50 empresas (meta realista):** R$ 4.995/mês
- **100 empresas (meta otimista):** R$ 9.990/mês

---

### Fase 4: Marketplace & Transações (Ano 3+)

**Conceito:** WeGig se torna intermediário de transações

**Features Planejadas:**

1. **Pagamentos In-App:**

   - Músico paga adiantamento para garantir vaga
   - Plataforma retém 10-15% de comissão
   - Integração: Stripe, PayPal, Mercado Pago, PIX

2. **Escrow Service:**

   - Dinheiro fica retido até show/serviço ser entregue
   - Ambas partes confirmam conclusão
   - Disputa resolution (suporte media)

3. **Avaliações & Reputação:**

   - Rating 1-5 estrelas após transação
   - Reviews públicos nos perfis
   - Badge de "Confiável" para usuários bem avaliados

4. **Seguro de Freela:**
   - Plataforma oferece seguro contra cancelamentos
   - Músico/Banda paga 5% extra para cobertura
   - Se show cancelar < 48h, recebe 50% do valor

**Projeção de Receita (Ano 3):**

- **Volume de transações:** R$ 100.000/mês (estimativa conservadora)
- **Comissão média:** 12%
- **Receita:** R$ 12.000/mês de comissões

---

### Fase 5: Publicidade Nativa (Futuro)

**Conceito:** Ads relevantes, não-intrusivos, contextuais

**Formatos:**

1. **Post Patrocinado no Feed:**

   - Aparece a cada 10 posts orgânicos
   - Tag discreta "Patrocinado"
   - Segmentação: raio, gêneros, instrumentos
   - Exemplo: Lançamento de nova guitarra Fender

2. **Banner na Home:**

   - Acima do mapa (fixo)
   - Tamanho: 300x50px
   - Rotação a cada 30s
   - Exemplo: Curso online de produção musical

3. **Stories Patrocinados:**
   - Entre stories de usuários (Instagram-style)
   - Full-screen, swipe to skip
   - Exemplo: Webinar com músico famoso

**Política de Publicidade:**

- ✅ Apenas nichos relacionados a música
- ❌ Sem ads de apostas, álcool, política
- ✅ Usuários PRO não veem ads
- ✅ Limite: 3 ads por sessão (máx 10min de uso)

**Preço Sugerido (CPM - custo por mil impressões):**

- Feed: R$ 10-20 CPM
- Banner: R$ 5-10 CPM
- Stories: R$ 15-30 CPM

**Projeção de Receita (Futuro):**

- **DAU:** 10.000 usuários
- **Sessions/dia:** 3
- **Impressions/mês:** 900.000 (10k × 3 × 30)
- **CPM médio:** R$ 15
- **Receita:** R$ 13.500/mês

---

## 📈 Roadmap de Produto

### Q1 2026 (Jan-Mar) - Post-MVP Improvements

**Prioridade ALTA:**

- [ ] Deep Links (compartilhar posts via WhatsApp)
- [ ] Push Notifications em produção (iOS + Android)
- [ ] Onboarding interativo (3 steps guiados)
- [ ] Dark Mode completo
- [ ] Skeleton screens (perceived performance)

**Prioridade MÉDIA:**

- [ ] Hero animations (transições fluidas)
- [ ] Profile analytics dashboard
- [ ] Export de dados (LGPD compliance)
- [ ] Denúncias e moderação

---

### Q2 2026 (Abr-Jun) - Monetização PRO

**Lançamento da Assinatura PRO:**

- [ ] Paywall screens (elegantes, não-intrusivos)
- [ ] In-app purchases (Apple/Google)
- [ ] Payment gateway (PIX, cartão)
- [ ] Trial de 7 dias
- [ ] Email marketing de conversão
- [ ] Analytics de conversão (funnel tracking)

**Features PRO:**

- [ ] Múltiplos perfis (2-5)
- [ ] Visualização de quem visitou perfil
- [ ] Confirmação de leitura em mensagens
- [ ] Badge PRO nos perfis
- [ ] Posts ilimitados
- [ ] Chats ilimitados

---

### Q3 2026 (Jul-Set) - WeGig Business (B2B)

**Lançamento da Camada Business:**

- [ ] Perfis empresariais (signup flow separado)
- [ ] CRM simplificado (dashboard web)
- [ ] Posts patrocinados (native ads)
- [ ] Analytics avançado (impressões, conversões)
- [ ] Múltiplas localizações
- [ ] API de integração

**Go-to-Market B2B:**

- [ ] Landing page para empresas
- [ ] Case studies (3 early adopters)
- [ ] Outbound sales (cold email 500/mês)
- [ ] Partnerships com associações

---

### Q4 2026 (Out-Dez) - Expansão de Features

**Novas Funcionalidades:**

- [ ] Stories (ephemeral, 24h)
- [ ] Live streaming (shows ao vivo)
- [ ] Calendário de eventos integrado
- [ ] Repertório compartilhado (setlists)
- [ ] Partituras e cifras (upload PDF)
- [ ] Audio samples (preview de músicas)

**Internacionalização:**

- [ ] i18n (English, Spanish)
- [ ] Moedas locais (USD, EUR)
- [ ] Reverse geocoding global
- [ ] Phone verification (SMS)

---

### 2027+ - Marketplace & Transações

**Fase de Transações:**

- [ ] Pagamentos in-app (Stripe/PayPal)
- [ ] Escrow service
- [ ] Rating & reviews
- [ ] Seguro de freela
- [ ] Disputa resolution

**Expansão de Receita:**

- [ ] Publicidade nativa (feed ads)
- [ ] Comissão de transações (10-15%)
- [ ] WeGig Pro+ (tier premium R$ 39,90/mês)
- [ ] White-label para festivais/eventos

---

## 📊 Projeção Financeira (5 anos)

### Premissas:

**Aquisição de Usuários:**

- **Ano 1:** 5.000 usuários (orgânico + ads R$ 10k)
- **Ano 2:** 25.000 usuários (viralidade + R$ 50k ads)
- **Ano 3:** 100.000 usuários (product-market fit)
- **Ano 4:** 300.000 usuários (expansão nacional)
- **Ano 5:** 750.000 usuários (consolidação)

**Conversão PRO:** 5% (conservador)  
**Empresas B2B:** 50 (Ano 2) → 200 (Ano 5)  
**Churn:** 10%/mês (PRO), 5%/mês (Business)

### Receita Projetada:

| Ano      | Usuários | PRO (5%) | Receita PRO      | Empresas B2B | Receita B2B    | Receita Total    |
| -------- | -------- | -------- | ---------------- | ------------ | -------------- | ---------------- |
| **2026** | 5.000    | 250      | R$ 59.700/ano    | 0            | R$ 0           | **R$ 59.700**    |
| **2027** | 25.000   | 1.250    | R$ 298.500/ano   | 50           | R$ 59.940/ano  | **R$ 358.440**   |
| **2028** | 100.000  | 5.000    | R$ 1.194.000/ano | 100          | R$ 119.880/ano | **R$ 1.313.880** |
| **2029** | 300.000  | 15.000   | R$ 3.582.000/ano | 150          | R$ 179.820/ano | **R$ 3.761.820** |
| **2030** | 750.000  | 37.500   | R$ 8.955.000/ano | 200          | R$ 239.760/ano | **R$ 9.194.760** |

### Custos Estimados:

**Infraestrutura (Firebase/GCP):**

- **Ano 1:** R$ 2.000/mês = R$ 24.000/ano
- **Ano 5:** R$ 30.000/mês = R$ 360.000/ano (escala)

**Marketing & Ads:**

- **Ano 1:** R$ 10.000
- **Ano 5:** R$ 500.000 (expansão agressiva)

**Equipe:**

- **Ano 1:** 2 founders (equity) = R$ 0
- **Ano 2:** +1 dev + 1 marketing = R$ 240.000/ano
- **Ano 5:** 15 pessoas = R$ 2.400.000/ano

**Total Custos:**

- **Ano 1:** R$ 34.000
- **Ano 5:** R$ 3.260.000

### EBITDA (Lucro Operacional):

| Ano      | Receita      | Custos       | EBITDA           | Margem              |
| -------- | ------------ | ------------ | ---------------- | ------------------- |
| **2026** | R$ 59.700    | R$ 34.000    | **R$ 25.700**    | 43%                 |
| **2027** | R$ 358.440   | R$ 500.000   | **-R$ 141.560**  | -40% (investimento) |
| **2028** | R$ 1.313.880 | R$ 1.200.000 | **R$ 113.880**   | 9%                  |
| **2029** | R$ 3.761.820 | R$ 2.000.000 | **R$ 1.761.820** | 47%                 |
| **2030** | R$ 9.194.760 | R$ 3.260.000 | **R$ 5.934.760** | 65%                 |

**Break-even:** Q3 2028 (Mês 27)

---

## 🎯 KPIs e Métricas de Sucesso

### Métricas de Aquisição:

- **CAC (Customer Acquisition Cost):** R$ 10-20 por usuário (meta)
- **Organic vs Paid:** 70% orgânico / 30% pago (ideal)
- **Viral coefficient:** 1.2+ (cada usuário traz 1.2 novos)
- **Tempo para 1º post:** < 10min (onboarding eficiente)

### Métricas de Engajamento:

- **DAU/MAU:** 40%+ (daily active / monthly active)
- **Session length:** 8-12min (média)
- **Sessions/day:** 3+ (volta múltiplas vezes)
- **Posts/user/month:** 2+ (Free), 5+ (PRO)
- **Messages/user/month:** 10+

### Métricas de Retenção:

- **D1 Retention:** 50%+ (volta no dia seguinte)
- **D7 Retention:** 30%+
- **D30 Retention:** 20%+
- **Churn Rate PRO:** < 10%/mês
- **Reativation Rate:** 15%+ (usuários inativos voltam)

### Métricas de Monetização:

- **Free → PRO Conversion:** 5%+ (meta)
- **Trial → Paid Conversion:** 40%+
- **LTV (Lifetime Value) PRO:** R$ 500+ (2 anos)
- **LTV/CAC Ratio:** 5:1+ (sustentável)
- **ARPU (Average Revenue Per User):** R$ 5+

---

## 🚨 Riscos e Mitigações

| Risco                                          | Probabilidade | Impacto | Mitigação                                                                                 |
| ---------------------------------------------- | ------------- | ------- | ----------------------------------------------------------------------------------------- |
| **Baixa adoção inicial**                       | Alta          | Alto    | Marketing focado em nicho, partnerships com escolas/estúdios, onboarding gamificado       |
| **Custos de infraestrutura explodem**          | Média         | Alto    | Monitoramento proativo, caching agressivo, otimização de queries, CDN para imagens        |
| **Concorrentes copiam features**               | Alta          | Médio   | Speed to market, network effects (quanto mais usuários, mais valor), IP registration      |
| **Spam e conteúdo inapropriado**               | Média         | Alto    | Moderação automática (ML), denúncias de usuários, banimento rápido, rate limiting         |
| **Problemas legais (LGPD, direitos autorais)** | Baixa         | Alto    | Compliance desde dia 1, termos de uso claros, export de dados, consent management         |
| **Dependência de Firebase**                    | Baixa         | Médio   | Arquitetura desacoplada (repository pattern), POC de migration para AWS/GCP               |
| **Apple/Google mudam políticas de pagamento**  | Baixa         | Médio   | Diversificar payment gateways (PIX, Stripe Web), ter plano B                              |
| **Músicos não encontram oportunidades**        | Média         | Alto    | Seed inicial com posts fake (éticos), incentive early adopters, garantir liquidez da rede |

---

## 🤝 Equipe e Expertise Necessária

### Core Team (Atual):

1. **Founder/CTO:** Wagner Oliveira
   - Full-stack development (Flutter + Firebase)
   - Arquitetura de software
   - DevOps e deployment
   - Product vision

### Hires Prioritários (Ano 2):

2. **Flutter Developer:**

   - Foco em UI/UX refinements
   - Performance optimization
   - Feature development
   - Salário: R$ 10k-15k/mês

3. **Marketing Lead:**

   - Growth hacking
   - Social media (Instagram, TikTok)
   - Partnerships com influencers musicais
   - Salário: R$ 8k-12k/mês

4. **Customer Success (Freelancer):**
   - Onboarding de empresas B2B
   - Support para usuários PRO
   - Coleta de feedback
   - Salário: R$ 3k-5k/mês

### Consultores/Advisors:

- **Legal:** Advogado especializado em LGPD e contratos (R$ 5k setup + R$ 2k/mês)
- **Contador:** Gestão fiscal e folha de pagamento (R$ 1k/mês)
- **Músico Profissional:** Advisor de produto, valida features (equity)
- **Business Angel:** Network, mentoria estratégica (equity)

---

## 🎓 Aprendizados e Iterações

### MVP Learnings (Primeiros 6 meses):

**Hipóteses Validadas:**

- ✅ Músicos/bandas realmente buscam oportunidades locais
- ✅ Multi-perfil é killer feature (70% dos power users têm 2+ perfis)
- ✅ Notificações de proximidade têm 45% open rate
- ✅ Geolocalização em mapa é mais intuitivo que listas

**Hipóteses Rejeitadas:**

- ❌ Vídeos de apresentação não foram adotados (complexidade vs valor)
- ❌ Gamification (badges, pontos) não aumentou engagement
- ❌ Integração com Spotify/YouTube gerou fricção (autenticação extra)

**Pivots Realizados:**

- Removido "Grupos" feature (low usage, alta complexidade)
- Simplificado filtros de busca (de 15 para 8 filtros principais)
- Mudado de posts infinitos para 30 dias (mantém conteúdo fresco)

### Próximas Iterações:

1. **A/B Test:** Trial de 7 vs 14 dias (conversão PRO)
2. **User Research:** 20 entrevistas qualitativas com power users
3. **Heatmap Analysis:** Onde usuários tocam mais (otimizar layout)
4. **Churn Analysis:** Por que PRO cancela? (exit survey)

---

## 📞 Contato e Mais Informações

**Empresa:** WeGig Tecnologia Ltda (em formação)  
**CNPJ:** Pendente  
**Website:** https://wegig.com.br (em construção)  
**Email:** contato@wegig.com.br  
**GitHub:** https://github.com/wagnermecanica-code/ToSemBandaRepo

**Founder:**  
Wagner Oliveira  
📧 wagner_mecanica@hotmail.com  
🔗 [LinkedIn](https://linkedin.com/in/wagner-oliveira)  
💻 [GitHub](https://github.com/wagnermecanica-code)

---

## 📄 Anexos

### A. Stack Técnico Completo

**Frontend:**

- flutter: ^3.9.2
- flutter_riverpod: ^2.5.1
- freezed: ^2.5.7
- go_router: ^14.0.0
- cached_network_image: ^3.4.1
- google_maps_flutter: ^2.10.0
- image_picker: ^1.2.0
- flutter_image_compress: ^2.4.0

**Backend:**

- firebase_core: ^3.6.0
- cloud_firestore: ^5.4.4
- firebase_auth: ^5.3.1
- firebase_storage: ^12.3.4
- firebase_messaging: ^15.1.3
- firebase_analytics: ^11.3.4
- firebase_crashlytics: ^4.1.3

**DevOps:**

- melos: ^6.0.0 (monorepo orchestration)
- build_runner: ^2.4.13
- very_good_analysis: ^6.0.0
- Firebase Hosting (docs site)
- GitHub Actions (CI/CD - planejado)

### B. Estrutura de Custos Detalhada (Ano 1)

**Firebase/GCP:**

- Firestore: R$ 800/mês (10M reads, 5M writes)
- Storage: R$ 300/mês (500GB imagens)
- Cloud Functions: R$ 400/mês (1M invocations)
- Hosting: R$ 50/mês
- Authentication: R$ 0 (free tier)
- **Total:** R$ 1.550/mês = **R$ 18.600/ano**

**Google Maps:**

- Maps SDK for iOS/Android: R$ 200/mês (5k requests/day)
- Places API (reverse geocoding): R$ 150/mês
- **Total:** R$ 350/mês = **R$ 4.200/ano**

**Domínio + Email:**

- wegig.com.br: R$ 40/ano
- Google Workspace (2 emails): R$ 30/mês = R$ 360/ano
- **Total:** R$ 400/ano

**Marketing:**

- Meta Ads (Instagram/Facebook): R$ 500/mês
- Google Ads: R$ 300/mês
- Influencer partnerships: R$ 200/mês (barter)
- **Total:** R$ 1.000/mês = **R$ 12.000/ano**

**Legal & Accounting:**

- CNPJ registration: R$ 1.000 (one-time)
- Advogado (LGPD, termos): R$ 5.000 (one-time)
- Contador: R$ 800/mês = R$ 9.600/ano
- **Total:** R$ 15.600/ano

**Grand Total Ano 1:** R$ 51.000 (~R$ 4.250/mês)

### C. Competitors Analysis

| Competitor          | Diferencial WeGig                            | Status                 |
| ------------------- | -------------------------------------------- | ---------------------- |
| **Facebook Groups** | Geolocalização, posts efêmeros, multi-perfil | ✅ Superior UX         |
| **LinkedIn**        | Foco em música, casual + profissional        | ✅ Nicho específico    |
| **BandMix**         | Interface moderna, mobile-first, grátis      | ✅ Melhor UX           |
| **JoinMyBand**      | Geolocalização em mapa, notificações push    | ✅ Tech superior       |
| **Vampr**           | Multi-perfil, posts efêmeros, B2B            | ✅ Monetização híbrida |

**Vantagem Competitiva:** Único app que combina geolocalização em mapa + multi-perfil + posts efêmeros + monetização B2B.

---

### D. Estratégia de Monetização via Website (wegig.com.br)

**Status:** 🚧 Em Implementação (Q1 2026)

#### Objetivo:

Criar canal adicional de receita através de publicidade não-intrusiva no website institucional, aproveitando o tráfego de visitantes que ainda não baixaram o app.

#### Modelo de Publicidade:

**Google AdSense (Fase 1 - Meses 1-6):**

- Banner horizontal acima da seção "Posts Recentes" (728x90px ou 320x50px mobile)
- Banner vertical na sidebar direita (300x250px ou 160x600px)
- Native ads entre posts (quando feed estiver ativo)
- **Estimativa de Receita:** R$ 0,50-2,00 RPM (revenue per mille - mil impressões)

**Google AdX ou Programmatic (Fase 2 - Meses 7+):**

- Header bidding para maximizar CPM (competition entre múltiplos ad networks)
- Video ads (pré-roll opcional antes de vídeos de músicos)
- **Estimativa de Receita:** R$ 3,00-8,00 RPM (2-4x maior que AdSense)

#### Projeção de Receita (Website Ads):

| Período     | Visitas/Mês | Pageviews/Mês | Impressões de Ads | RPM Médio | Receita Mensal | Receita Anual  |
| ----------- | ----------- | ------------- | ----------------- | --------- | -------------- | -------------- |
| **Q1 2026** | 2.000       | 6.000         | 12.000            | R$ 1,00   | R$ 12          | R$ 144         |
| **Q2 2026** | 5.000       | 15.000        | 30.000            | R$ 1,50   | R$ 45          | R$ 540         |
| **Q3 2026** | 10.000      | 30.000        | 60.000            | R$ 2,00   | R$ 120         | R$ 1.440       |
| **Q4 2026** | 20.000      | 60.000        | 120.000           | R$ 3,00   | R$ 360         | R$ 4.320       |
| **Ano 2**   | 100.000     | 300.000       | 600.000           | R$ 5,00   | R$ 3.000       | **R$ 36.000**  |
| **Ano 3**   | 500.000     | 1.500.000     | 3.000.000         | R$ 6,00   | R$ 18.000      | **R$ 216.000** |

**Premissas:**

- 3 pageviews por visita (home → posts → sobre)
- 2 ad impressions por pageview (header banner + sidebar)
- RPM aumenta com volume (melhores anunciantes)
- 70% do tráfego vem de busca orgânica (Google: "músicos em São Paulo", "bandas perto de mim")
- 20% tráfego direto (usuários retornando)
- 10% tráfego social (Instagram, TikTok, YouTube)

#### Políticas de Ads (Qualidade da Experiência):

✅ **Permitidos:**

- Instrumentos musicais (lojas, fabricantes)
- Cursos de música online
- Equipamentos de áudio (microfones, interfaces, monitores)
- Shows e festivais
- Streaming de música (Spotify, Deezer, YouTube Premium)

❌ **Bloqueados:**

- Apostas e jogos de azar
- Conteúdo adulto
- Álcool e tabaco
- Política e religião
- Clickbait sensacionalista

**User Experience:**

- ✅ Ads claramente identificados como "Publicidade" ou "Patrocinado"
- ✅ Não interferem na navegação ou leitura de conteúdo
- ✅ Não bloqueiam botões ou CTAs importantes
- ✅ Não usam autoplay de áudio/vídeo
- ✅ Respeitam preferências de "Não rastrear" (DNT)

#### Otimização de SEO para Aumentar Tráfego:

**Content Strategy (Blog WeGig):**

- Artigos mensais sobre música local: "Top 10 Bandas de São Paulo 2026"
- Guias para músicos: "Como encontrar freelas de música"
- Entrevistas com músicos locais (backlinks + autoridade)
- **Meta:** 4 artigos/mês → 50k visitas orgânicas/mês (Ano 2)

**Keywords Target:**

- "músicos em [cidade]" (volume: 2k-10k/mês)
- "bandas perto de mim" (volume: 1k-5k/mês)
- "vaga em banda" (volume: 500-2k/mês)
- "freela de música" (volume: 300-1k/mês)

**Link Building:**

- Partnerships com blogs de música (guest posts)
- Listagem em diretórios (Google My Business, Yelp)
- Social signals (compartilhamento de posts)

---

### E. Funil de Aquisição de Usuários via Website

**Status:** 🚧 Em Implementação (Q1 2026)

#### Conceito:

O website **wegig.com.br** funciona como **preview gratuito** da plataforma, mostrando posts em tempo real para atrair visitantes e convertê-los em usuários do app. O visitante vê a proposta de valor, mas precisa baixar o app para interagir.

#### Arquitetura do Funil (5 Etapas):

```
Visitante chega ao site
      ↓
Vê posts recentes (read-only)
      ↓
Clica em "Ver Detalhes" do post
      ↓
Modal: "Baixe o app para interagir"
      ↓
Redirecionamento para App Store/Google Play
```

#### Implementação Técnica:

**1. Seção "Posts Recentes" (Homepage):**

**Design:**

- Grid responsivo (3 colunas desktop, 1 coluna mobile)
- Cards de posts com:
  - Foto do perfil
  - Nome do músico/banda
  - Primeiro parágrafo da descrição (100 chars com "...")
  - Instrumentos e gêneros (tags)
  - Localização (cidade + distância aproximada se geolocalização permitida)
  - Botão "Ver Detalhes" (CTA primário)

**Dados Exibidos:**

- 6-12 posts mais recentes (API pública read-only do Firestore)
- Atualização a cada 5 minutos (cache CDN)
- Filtro: apenas posts ativos (expiresAt > now)

**Exemplo de Card:**

```
┌─────────────────────────────────────┐
│ 📸 [Foto] João Silva - Guitarrista  │
│ 🎸 Guitarra | Rock, Blues            │
│ 📍 São Paulo, SP (~5km de você)      │
│ "Guitarrista busca banda de rock... │
│  para freelas aos finais de semana"  │
│ [Ver Detalhes] 🚀                    │
└─────────────────────────────────────┘
```

**2. Modal "Baixe o App" (Interceptação):**

**Trigger:** Usuário clica em "Ver Detalhes" ou qualquer botão de interação (Demonstrar Interesse, Enviar Mensagem)

**Conteúdo do Modal:**

```
┌─────────────────────────────────────────┐
│        🎵 WeGig - Conecte-se!           │
│                                         │
│  Para visualizar detalhes completos,    │
│  conversar com músicos e publicar seus  │
│  próprios posts, baixe o app WeGig!     │
│                                         │
│  ✅ Geolocalização em tempo real        │
│  ✅ Chat instantâneo                    │
│  ✅ Notificações de oportunidades       │
│                                         │
│  [🍎 App Store]  [🤖 Google Play]       │
│                                         │
│  [✖️ Fechar]                            │
└─────────────────────────────────────────┘
```

**Características:**

- Blur no background (mantém contexto)
- Animação suave de entrada (fade in + scale)
- Botões grandes, fáceis de tocar (mobile-friendly)
- Close button para não frustrar (pode explorar mais antes de decidir)

**3. Redirecionamento Inteligente:**

**Desktop:**

- Abre página de download com QR Code
- QR Code aponta para deep link universal: `https://wegig.com.br/download?ref=post_{postId}`
- Escaneia com celular → abre App Store/Google Play automaticamente

**Mobile:**

- Detecta plataforma (iOS/Android via User-Agent)
- Redirecionamento direto:
  - iOS: `https://apps.apple.com/app/wegig/id[APP_ID]`
  - Android: `https://play.google.com/store/apps/details?id=com.tosembanda.wegig`
- Universal link (se app instalado): abre direto no post específico

**4. Deep Link para Retenção:**

**URL Pattern:** `wegig://post/{postId}` ou `https://wegig.com.br/post/{postId}`

**Comportamento:**

- Se app **instalado**: abre direto no post (context preservado)
- Se app **não instalado**: redireciona para store, após instalação abre no post
- **Impact:** Reduz fricção, usuário vê exatamente o post que clicou (conversão 2-3x maior)

**5. Analytics de Funil:**

**Eventos Rastreados (Google Analytics + Firebase):**

```javascript
// Homepage
gtag('event', 'page_view', { page_title: 'Homepage' });

// Visualização de post
gtag('event', 'post_card_impression', { post_id: '123', type: 'musician' });

// Clique em "Ver Detalhes"
gtag('event', 'post_details_click', { post_id: '123' });

// Modal aberto
gtag('event', 'download_modal_view', { source: 'post_details' });

// Clique em App Store/Google Play
gtag('event', 'store_redirect', { platform: 'ios', post_id: '123' });

// (Server-side) App instalado
Firebase Analytics: 'app_install', { referrer: 'website_post_123' }

// (Server-side) Post aberto no app
Firebase Analytics: 'post_opened_from_web', { post_id: '123' }
```

**Métricas de Conversão:**

- **Top of Funnel:** 100% (visitantes do site)
- **Post Card Click:** 40% (clicam em "Ver Detalhes")
- **Modal View:** 35% (modal exibido após click)
- **Store Click:** 20% (clicam em App/Play Store)
- **App Install:** 10% (completam instalação)
- **Post Open in App:** 7% (abrem post específico no app)

**Conversão Final:** **7% website visitors → app users** (industry benchmark: 3-5%)

#### Projeção de Aquisição de Usuários (via Website):

| Período     | Visitas/Mês | Post Views | Store Clicks (20%) | Installs (10%) | Custo (SEO/Ads) | CAC     |
| ----------- | ----------- | ---------- | ------------------ | -------------- | --------------- | ------- |
| **Q1 2026** | 2.000       | 800        | 160                | 80             | R$ 500          | R$ 6,25 |
| **Q2 2026** | 5.000       | 2.000      | 400                | 200            | R$ 1.000        | R$ 5,00 |
| **Q3 2026** | 10.000      | 4.000      | 800                | 400            | R$ 2.000        | R$ 5,00 |
| **Q4 2026** | 20.000      | 8.000      | 1.600              | 800            | R$ 4.000        | R$ 5,00 |
| **Ano 2**   | 100.000     | 40.000     | 8.000              | 4.000          | R$ 20.000       | R$ 5,00 |
| **Ano 3**   | 500.000     | 200.000    | 40.000             | 20.000         | R$ 100.000      | R$ 5,00 |

**Total de Usuários Adquiridos via Website (Ano 1):** ~1.500 usuários  
**Total de Usuários Adquiridos via Website (Ano 2):** ~4.000 usuários  
**Total de Usuários Adquiridos via Website (Ano 3):** ~20.000 usuários

**CAC Comparativo:**

- Meta Ads (Instagram/Facebook): R$ 15-25 por instalação
- Google Ads (Search): R$ 10-20 por instalação
- **Website Orgânico: R$ 5,00 por instalação** ✅ Mais eficiente!

#### Otimizações Contínuas (A/B Tests):

**Teste 1: Variação do Modal**

- **A (Controle):** Modal padrão com texto descritivo
- **B:** Modal com vídeo de 15s mostrando app em uso
- **Meta:** Aumentar store_click em 30%

**Teste 2: Call-to-Action**

- **A:** "Ver Detalhes" (atual)
- **B:** "Baixar App para Ver Mais"
- **C:** "Entrar em Contato 💬"
- **Meta:** Clareza de expectativa, reduzir bounces

**Teste 3: Preview de Conteúdo**

- **A:** Mostra 100 chars da descrição
- **B:** Mostra 50 chars + primeira foto do post
- **C:** Mostra 100 chars + perfil completo do autor
- **Meta:** Maximizar curiosidade sem entregar tudo

**Teste 4: Social Proof**

- **A:** Sem social proof
- **B:** "12.450 músicos já encontraram oportunidades no WeGig"
- **C:** Logos de músicos/bandas famosas que usam
- **Meta:** Aumentar confiança, reduzir hesitação

#### Integração com CRM e Remarketing:

**Email Capture (Opcional):**

- Visitante pode deixar email para "receber atualizações de posts na sua região"
- Envio semanal de digest com posts relevantes
- CTA no email: "Ver no App" → redirecionamento para store
- **Taxa de Abertura:** 25-35% (music enthusiasts)
- **Taxa de Conversão:** 5-10% (email → app install)

**Remarketing (Google Ads + Meta Pixel):**

- Visitantes que clicaram em "Ver Detalhes" mas não instalaram
- Anúncios personalizados: "Você viu [Nome do Músico] no WeGig. Baixe agora!"
- Budget: R$ 500/mês
- **ROAS:** 3:1 (R$ 500 gastos → 300 installs × R$ 5 CAC = R$ 1.500 valor)

---

**Impacto Total da Estratégia Website:**

| Métrica                 | Ano 1     | Ano 2      | Ano 3       |
| ----------------------- | --------- | ---------- | ----------- |
| **Receita de Ads**      | R$ 1.900  | R$ 36.000  | R$ 216.000  |
| **Usuários Adquiridos** | 1.500     | 4.000      | 20.000      |
| **CAC Médio**           | R$ 5,00   | R$ 5,00    | R$ 5,00     |
| **Custo de Aquisição**  | R$ 7.500  | R$ 20.000  | R$ 100.000  |
| **ROI (Ads - Custo)**   | -R$ 5.600 | +R$ 16.000 | +R$ 116.000 |

**Break-even Website:** Q3 2027 (quando receita de ads supera custo de aquisição)

**Vantagem Estratégica:** Website não apenas gera receita via ads, mas também funciona como canal de aquisição de baixo CAC (R$ 5 vs R$ 15-25 de ads pagos), criando ciclo virtuoso: mais posts → mais tráfego → mais receita de ads → mais budget para SEO → mais tráfego.

---

**Última Atualização:** 03 de Dezembro de 2025  
**Versão do Documento:** 1.2.0  
**Status:** Production Ready - Seeking Seed Investment

---

_Este documento é confidencial e destinado apenas para fins de avaliação de investimento, partnerships e planejamento estratégico. Reprodução ou distribuição não autorizada é proibida._
