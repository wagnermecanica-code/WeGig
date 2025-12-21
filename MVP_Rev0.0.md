# WeGig - Minimum Viable Product (MVP)

## Revisão 0.6 | 17 de Dezembro de 2025

---

## 📋 Sumário Executivo

**WeGig (18+)** é uma plataforma social móvel **exclusiva para maiores de 18 anos** que conecta músicos, bandas e espaços musicais através de busca geoespacial, posts efêmeros (30 dias de validade), mensagens em tempo real e notificações de proximidade. O sistema de múltiplos perfis (estilo Instagram) permite que um único usuário gerencie perfis de músico, banda e espaço (estúdios, escolas, luthierias, etc.) separadamente.

### Métricas do MVP

| Categoria               | Status                      |
| ----------------------- | --------------------------- |
| **Plataformas**         | iOS 15.0+ / Android API 24+ |
| **Ambientes**           | DEV / STAGING / PROD        |
| **Erros de Compilação** | 0 (packages/app)            |
| **Cobertura de Testes** | 270+ testes passando        |
| **Cloud Functions**     | 7 funções ativas            |
| **Firestore Indexes**   | 13 indexes compostos        |

---

## 🎯 1. Visão do Produto

### 1.1 Problema que Resolve

- Dificuldade de músicos encontrarem bandas e vice-versa na sua região
- Espaços musicais (estúdios, escolas, luthierias) sem visibilidade local
- Plataformas existentes não focam em geolocalização de músicos e serviços
- Falta de comunicação direta e em tempo real entre músicos e prestadores de serviço

### 1.2 Proposta de Valor

- **Busca Geoespacial**: Encontre músicos, bandas e espaços próximos com filtros por raio
- **Posts Efêmeros**: Anúncios com validade de 30 dias (auto-limpeza)
- **Multi-Perfil**: Gerencie perfis de músico, banda e espaço na mesma conta
- **Anúncios de Serviços**: Espaços podem criar anúncios com preços, promoções e WhatsApp
- **Chat em Tempo Real**: Comunicação instantânea entre usuários
- **Notificações Inteligentes**: Alertas de novos posts na sua região

### 1.3 Público-Alvo

- Músicos amadores e profissionais buscando bandas
- Bandas buscando músicos para completar formação
- **Espaços musicais** (estúdios de gravação/ensaio, escolas de música, luthierias, lojas de instrumentos, casas de show, produtoras de eventos, aluguel de equipamentos, selos/distribuidoras)

---

## 🏗️ 2. Arquitetura Técnica

### 2.1 Stack Tecnológico

| Camada               | Tecnologia     | Versão                              |
| -------------------- | -------------- | ----------------------------------- |
| **Frontend**         | Flutter        | 3.27.1+                             |
| **Linguagem**        | Dart           | 3.10+                               |
| **Backend**          | Firebase       | Firestore, Auth, Storage, Functions |
| **State Management** | Riverpod       | 2.x com Annotations                 |
| **Mapas**            | Google Maps    | SDK 9.4.0                           |
| **Cloud Functions**  | Node.js        | 20                                  |
| **CI/CD**            | GitHub Actions | Automated builds                    |

### 2.2 Arquitetura de Software

**Feature-First Clean Architecture** - Cada feature é um módulo auto-contido:

```
packages/app/lib/features/<feature>/
├── data/
│   ├── datasources/      → Firestore, APIs, Cache (Hive)
│   ├── models/           → DTOs (Data Transfer Objects)
│   └── repositories/     → Implementações concretas
├── domain/
│   ├── entities/         → Modelos de negócio puros
│   ├── repositories/     → Interfaces abstratas
│   └── usecases/         → Casos de uso (regras de negócio)
└── presentation/
    ├── pages/            → Telas completas
    ├── widgets/          → Componentes reutilizáveis
    └── providers/        → Gerenciamento de estado (Riverpod)
```

**Regra de Dependência**: `Presentation → Domain → Data` (camadas internas nunca dependem de externas)

### 2.3 Estrutura do Monorepo (Melos)

```
to_sem_banda/
├── packages/
│   ├── app/              → App Flutter principal (produção)
│   └── core_ui/          → Entidades, tema, widgets compartilhados
├── .config/
│   ├── functions/        → Cloud Functions (Node.js)
│   ├── firestore.rules   → Regras de segurança
│   └── firestore.indexes.json → Índices compostos
├── .tools/               → Scripts, third-party forks
└── docs/                 → Documentação técnica
```

### 2.4 Ambientes de Execução

| Ambiente    | Firebase Project   | Bundle ID (iOS)         | Package (Android)       | Logs   | Crashlytics |
| ----------- | ------------------ | ----------------------- | ----------------------- | ------ | ----------- |
| **DEV**     | wegig-dev          | com.wegig.wegig.dev     | com.wegig.wegig.dev     | ✅ ON  | ❌ OFF      |
| **STAGING** | wegig-staging      | com.wegig.wegig.staging | com.wegig.wegig.staging | ✅ ON  | ✅ ON       |
| **PROD**    | to-sem-banda-83e19 | com.wegig.wegig         | com.wegig.wegig         | ❌ OFF | ✅ ON       |

**Validação em Runtime**: O bootstrap valida `expectedProjectId` para prevenir dados cruzados entre ambientes.

---

## ✨ 3. Features Implementadas

### 3.1 Autenticação (auth/)

#### Funcionalidades

- ✅ Login com Email/Senha
- ✅ Login com Google Sign-In
- ✅ Login com Apple (iOS)
- ✅ Cadastro de novos usuários
- ✅ Recuperação de senha (email)
- ✅ Verificação de email
- ✅ Logout seguro
- ✅ Sessão persistente (Firebase Auth)

#### Fluxo de Autenticação

```
App Launch → Verificar Auth State
    ├── Não autenticado → /auth (Login/Cadastro)
    └── Autenticado → Verificar Perfis
            ├── Sem perfis → /profiles/new (Criar perfil)
            └── Com perfis → /home (Feed principal)
```

#### Implementação Técnica

- **Provider**: `authStateProvider` (stream de auth state)
- **Repository**: `AuthRepository` com `FirebaseAuth`
- **UseCases**: `SignInWithEmail`, `SignInWithGoogle`, `SignInWithApple`, `SignOut`

### 3.2 Multi-Perfil (profile/)

#### Funcionalidades

- ✅ Criar perfil de **músico**
- ✅ Criar perfil de **banda**
- ✅ Criar perfil de **espaço** (estúdios, escolas, luthierias, etc.)
- ✅ Limite de 5 perfis por conta
- ✅ Editar perfil (nome, foto, instrumentos, gêneros)
- ✅ Selecionar subtipo de espaço (9 categorias disponíveis)
- ✅ Definir localização (obrigatório)
- ✅ Alternar entre perfis (estilo Instagram)
- ✅ Upload de foto de perfil com compressão
- ✅ Deletar perfil com cleanup automático

#### Tipos de Perfil (ProfileType)

| Tipo       | Valor      | Descrição                                  |
| ---------- | ---------- | ------------------------------------------ |
| **Músico** | `musician` | Perfil individual de músico                |
| **Banda**  | `band`     | Perfil de banda/grupo musical              |
| **Espaço** | `space`    | Estúdios, escolas, luthierias, lojas, etc. |

#### Subtipos de Espaço (SpaceType)

| Subtipo                | Valor              | Label PT-BR                 |
| ---------------------- | ------------------ | --------------------------- |
| Estúdio de Gravação    | `recording_studio` | Estúdio de Gravação/Ensaios |
| Loja de Instrumentos   | `instrument_store` | Loja de Instrumentos        |
| Bar/Casa de Show       | `bar_venue`        | Bar/Casa de Show            |
| Escola de Música       | `music_school`     | Escola de Música            |
| Produtora de Eventos   | `event_producer`   | Produtora de Eventos        |
| Aluguel de Equipamento | `equipment_rental` | Aluguel de Equipamento      |
| Luthieria              | `luthier`          | Luthieria                   |
| Selo/Distribuidora     | `label`            | Selo/Distribuidora          |
| Outro                  | `other`            | Outro Espaço Musical        |

#### Modelo de Dados (Firestore)

```javascript
// profiles/{profileId}
{
  uid: "firebase-auth-uid",           // Proprietário
  profileId: "auto-generated-id",     // ID único
  name: "João Silva",
  profileType: "musician",            // "musician" | "band" | "space"
  spaceType: "recording_studio",      // Apenas para profileType=space
  isBand: false,                      // DEPRECATED - usar profileType
  instruments: ["guitarra", "baixo"], // Músicos/Bandas
  genres: ["rock", "blues"],          // Músicos/Bandas
  location: GeoPoint(lat, lng),       // Obrigatório
  city: "São Paulo",                  // Reverse geocoding
  photoUrl: "https://...",
  bio: "Músico profissional...",
  notificationRadiusEnabled: true,
  notificationRadius: 20,             // km
  createdAt: Timestamp,
  updatedAt: Timestamp
}

// users/{uid}
{
  email: "user@email.com",
  activeProfileId: "profile-id",      // Perfil ativo atual
  createdAt: Timestamp
}
```

#### Troca de Perfil

```dart
// Uso do ProfileSwitcher (centraliza invalidação de cache)
await ref.read(profileSwitcherNotifierProvider.notifier)
    .switchToProfile(newProfileId);
```

### 3.3 Posts Efêmeros (post/)

#### Funcionalidades

- ✅ Criar post com texto e imagens (até 9 fotos)
- ✅ Selecionar tipo de post (3 categorias)
- ✅ Selecionar gêneros musicais
- ✅ Selecionar instrumentos necessários
- ✅ Definir localização do post
- ✅ Galeria de imagens com carrossel
- ✅ Compressão de imagens em isolate (evita freeze de UI)
- ✅ Expiração automática após 30 dias
- ✅ Editar post (autor apenas)
- ✅ Deletar post (autor apenas)
- ✅ Visualizar detalhes do post
- ✅ Sistema de interesses ("Tenho Interesse" / "Salvar Anúncio")
- ✅ **Posts de Anúncio (sales)**: Título, preço, desconto, promoções, WhatsApp

#### Categorias de Post (PostType)

| Tipo        | Valor      | Cor       | Descrição                             |
| ----------- | ---------- | --------- | ------------------------------------- |
| **Músico**  | `musician` | Primary   | Músico procurando banda/colaboradores |
| **Banda**   | `band`     | Accent    | Banda procurando músicos              |
| **Anúncio** | `sales`    | SalesBlue | Espaços divulgando serviços/promoções |

#### Modelo de Dados

```javascript
// posts/{postId} - Músico/Banda
{
  authorUid: "firebase-auth-uid",
  authorProfileId: "profile-id",
  authorName: "João Silva",
  authorPhotoUrl: "https://...",
  type: "musician" | "band" | "sales",  // 3 categorias
  title: "Guitarrista procura banda",
  content: "Texto do post...",
  instruments: ["guitarra"],
  genres: ["rock"],
  level: "intermediario",
  seekingMusicians: ["baterista"],      // Apenas type=band
  availableFor: ["gig", "rehearsal"],
  photoUrls: ["url1", "url2"],          // Até 9 fotos
  youtubeLink: "https://...",
  location: GeoPoint(lat, lng),
  city: "São Paulo",
  neighborhood: "Centro",
  state: "SP",
  createdAt: Timestamp,
  expiresAt: Timestamp                  // +30 dias
}

// posts/{postId} - Anúncio de Espaço (sales)
{
  authorUid: "firebase-auth-uid",
  authorProfileId: "profile-id",
  authorName: "Studio XYZ",
  authorPhotoUrl: "https://...",
  type: "sales",                        // Categoria de anúncio
  title: "Promoção Gravação",           // Obrigatório para sales
  content: "Descrição do serviço...",
  salesType: "Gravação",                // Tipo de serviço
  price: 150.00,                        // Preço base
  discountMode: "percentage" | "fixed", // Tipo de desconto
  discountValue: 20,                    // Valor do desconto
  promoStartDate: Timestamp,            // Início da promoção
  promoEndDate: Timestamp,              // Fim da promoção
  whatsappNumber: "+5511999999999",     // Contato direto
  photoUrls: ["url1", "url2"],
  location: GeoPoint(lat, lng),
  city: "São Paulo",
  createdAt: Timestamp,
  expiresAt: Timestamp
}
```

#### Query Obrigatória (Expiração)

```dart
// TODAS as queries de posts DEVEM incluir:
.where('expiresAt', isGreaterThan: Timestamp.now())
.orderBy('expiresAt')
```

### 3.4 Home / Busca Geoespacial (home/)

#### Funcionalidades

- ✅ Mapa interativo com Google Maps
- ✅ Markers customizados para posts (3 cores por tipo)
- ✅ Clustering de markers (performance)
- ✅ Filtro por raio de proximidade (5-100km)
- ✅ Filtro por tipo (músico/banda/anúncio)
- ✅ Filtro por gêneros musicais
- ✅ Filtro por instrumentos
- ✅ **Filtros específicos de anúncios**:
  - Tipo de serviço (salesTypes)
  - Faixa de preço (minPrice/maxPrice)
  - Apenas com desconto (onlyWithDiscount)
  - Apenas promoções ativas (onlyActivePromos)
- ✅ Busca por @username
- ✅ Lista de posts em formato de cards
- ✅ Alternar entre visualização mapa/lista
- ✅ Pull-to-refresh
- ✅ Paginação com `startAfterDocument`
- ✅ Cache de markers (95% mais rápido)
- ✅ Reverse geocoding para detecção de cidade

#### Busca por Proximidade

```dart
// Cálculo de distância Haversine para filtro de raio
final distance = calculateHaversineDistance(
  userLat, userLng, postLat, postLng
);
if (distance <= selectedRadiusKm) {
  // Incluir no resultado
}
```

### 3.5 Mensagens / Chat (mensagens_new/)

#### Funcionalidades

- ✅ Lista de conversas por perfil
- ✅ Chat em tempo real (Firestore streams)
- ✅ Enviar mensagens de texto
- ✅ Contador de mensagens não lidas
- ✅ Marcação automática como lida ao abrir
- ✅ Ordenação por última mensagem
- ✅ Iniciar conversa a partir de post
- ✅ Iniciar conversa a partir de perfil
- ✅ Lazy loading de streams

#### Modelo de Dados

```javascript
// conversations/{conversationId}
{
  participants: ["uid1", "uid2"],           // Auth UIDs
  participantProfiles: ["profile1", "profile2"],
  profileUid: ["uid1", "uid2"],             // Fallback
  lastMessage: "Olá, vi seu post...",
  lastMessageAt: Timestamp,
  lastMessageSenderId: "uid1",
  unreadCount: { "profile1": 0, "profile2": 2 },
  createdAt: Timestamp
}

// conversations/{conversationId}/messages/{messageId}
{
  senderId: "uid",
  senderProfileId: "profile-id",
  senderName: "João",
  text: "Mensagem aqui",
  createdAt: Timestamp,
  readBy: ["profile1"],
  reactions: {},
  deletedForProfiles: []
}
```

### 3.6 Notificações (notifications_new/)

#### Funcionalidades

- ✅ Notificações in-app (badge de contagem)
- ✅ Push notifications (FCM)
- ✅ Notificações de proximidade (novos posts na região)
- ✅ Notificações de interesse (alguém interessou no seu post)
- ✅ Notificações de mensagens (novas mensagens)
- ✅ Marcar como lida
- ✅ Deletar notificação
- ✅ Streams em tempo real
- ✅ Cleanup automático de notificações expiradas

#### Modelo de Dados

```javascript
// notifications/{notificationId}
{
  recipientUid: "firebase-auth-uid",
  recipientProfileId: "profile-id",
  type: "nearby_post" | "interest" | "message",
  title: "Novo músico na sua região!",
  body: "João está procurando banda...",
  data: {
    postId: "...",
    senderProfileId: "..."
  },
  read: false,
  createdAt: Timestamp,
  expiresAt: Timestamp
}
```

### 3.7 Configurações (settings/)

#### Funcionalidades

- ✅ Configurar raio de notificações (5-100km)
- ✅ Habilitar/desabilitar notificações de proximidade
- ✅ Gerenciar perfis (criar, editar, deletar)
- ✅ Informações da conta
- ✅ Logout
- ✅ Termos de uso
- ✅ Política de privacidade
- ✅ Sobre o app

### 3.8 Sistema de Denúncias (report/)

#### Funcionalidades

- ✅ Denunciar posts (conteúdo inadequado, spam, etc.)
- ✅ Denunciar perfis (comportamento abusivo, fake, etc.)
- ✅ 8 categorias de denúncia disponíveis
- ✅ Campo de descrição adicional (obrigatório)
- ✅ Prevenção de denúncias duplicadas
- ✅ Feedback visual ao usuário
- ✅ Notificação automática para administradores via email (SendGrid)
- ✅ Dashboard administrativo web para gerenciamento

#### Categorias de Denúncia

| Categoria               | Valor               | Descrição                                 |
| ----------------------- | ------------------- | ----------------------------------------- |
| Spam                    | `spam`              | Conteúdo promocional não solicitado       |
| Conteúdo Impróprio      | `inappropriate`     | Material ofensivo ou inadequado           |
| Golpe/Fraude            | `scam`              | Tentativa de fraude ou engano             |
| Informações Falsas      | `false_information` | Dados incorretos ou enganosos             |
| Assédio                 | `harassment`        | Comportamento intimidador ou abusivo      |
| Discurso de Ódio        | `hate_speech`       | Conteúdo discriminatório                  |
| Violação de Privacidade | `privacy_violation` | Exposição de dados pessoais sem permissão |
| Outro                   | `other`             | Outras violações não listadas             |

#### Modelo de Dados

```javascript
// reports/{reportId}
{
  reporterId: "profile-id",               // Quem denunciou
  reporterUid: "firebase-auth-uid",       // Auth UID do denunciante
  targetType: "post" | "profile",         // Tipo do alvo
  targetId: "post-id ou profile-id",      // ID do conteúdo denunciado
  targetOwnerId: "profile-id-do-dono",    // Dono do conteúdo (opcional)
  category: "spam",                       // Categoria da denúncia
  description: "Texto explicativo...",    // Descrição detalhada (obrigatório)
  status: "pending" | "reviewed" | "resolved" | "dismissed",
  adminNotes: "Notas do admin...",        // Notas internas
  reviewedAt: Timestamp,                  // Data da revisão
  reviewedBy: "admin-uid",                // Admin que revisou
  createdAt: Timestamp
}
```

#### Dashboard Administrativo

O sistema inclui um dashboard web para administradores gerenciarem denúncias:

- **Tecnologia**: React + Vite + Firebase
- **Localização**: `.config/admin-dashboard/`
- **Funcionalidades**:
  - Lista de denúncias com filtros por status e categoria
  - Visualização de detalhes da denúncia
  - Ações: Marcar como revisado, resolver, dispensar
  - Campo de notas do administrador
  - Estatísticas de denúncias

#### Notificações para Admins (SendGrid)

Quando uma denúncia é criada, uma notificação por email é enviada automaticamente para os administradores via Cloud Function integrada com SendGrid.

```javascript
// Cloud Function: sendReportNotification
// Trigger: reports.onCreate
// Ação: Envia email para admins com detalhes da denúncia
```

---

## ☁️ 4. Cloud Functions

### 4.1 Funções Implementadas

| Função                        | Trigger              | Descrição                                           |
| ----------------------------- | -------------------- | --------------------------------------------------- |
| `notifyNearbyPosts`           | `posts.onCreate`     | Notifica perfis quando novo post é criado na região |
| `sendInterestNotification`    | `interests.onCreate` | Notifica autor quando alguém demonstra interesse    |
| `sendMessageNotification`     | `messages.onCreate`  | Notifica destinatário de nova mensagem              |
| `cleanupExpiredNotifications` | Scheduled (daily)    | Limpa notificações expiradas                        |
| `onProfileDelete`             | `profiles.onDelete`  | Cleanup de posts e Storage quando perfil é deletado |
| `sendReportNotification`      | `reports.onCreate`   | Notifica admins via SendGrid sobre nova denúncia    |
| `updateReportStatus`          | HTTP Callable        | Atualiza status de denúncia via dashboard admin     |

### 4.2 Região de Deploy

**southamerica-east1** (São Paulo) - Menor latência para usuários brasileiros

### 4.3 Rate Limiting

- 20 posts por usuário por dia (proteção contra spam)
- Implementado via contadores no Firestore

### 4.4 Notificações de Proximidade (Algoritmo)

```javascript
1. Post criado → Trigger onCreate
2. Obter location (GeoPoint) do post
3. Query: profiles com notificationRadiusEnabled = true
4. Para cada perfil:
   a. Calcular distância Haversine
   b. Se distância <= notificationRadius do perfil:
      - Criar notificação in-app
      - Enviar push notification (FCM)
5. Batch write (max 500 notificações por post)
```

---

## 🔒 5. Segurança

### 5.1 Firestore Security Rules

#### Princípios Aplicados

- **Autenticação Obrigatória**: Todas as operações requerem `request.auth != null`
- **Ownership Validation**: Usuários só podem modificar seus próprios dados
- **Field-Level Security**: Validação de campos obrigatórios em creates
- **Multi-Profile Isolation**: Dados isolados por `profileId`, não apenas `uid`

#### Regras por Collection

| Collection        | Read                     | Create             | Update              | Delete            |
| ----------------- | ------------------------ | ------------------ | ------------------- | ----------------- |
| **profiles**      | Autenticado              | Próprio uid        | Próprio uid         | Próprio uid       |
| **users**         | Próprio                  | Próprio            | Próprio             | Próprio           |
| **posts**         | Autenticado              | Próprio authorUid  | Próprio authorUid   | Próprio authorUid |
| **conversations** | Participante             | Participante       | Participante        | Participante      |
| **messages**      | Participante da conversa | Participante       | Sender ou reactions | Sender            |
| **notifications** | Próprio recipientUid     | Autenticado        | Próprio             | Próprio           |
| **interests**     | Autenticado              | Próprio profileUid | Próprio             | Próprio           |
| **blocks**        | Próprio                  | Próprio            | Próprio             | Próprio           |
| **reports**       | Próprio reporterUid      | Autenticado        | Admin only          | Admin only        |

### 5.2 Validações Implementadas

```javascript
// Exemplo: Criar post
allow create: if isSignedIn()
  && request.resource.data.authorUid == request.auth.uid;

// Exemplo: Enviar mensagem
allow create: if isSignedIn()
  && canAccessConversation()
  && request.resource.data.senderId == request.auth.uid;

// Exemplo: Atualizar mensagem (reactions)
allow update: if isSignedIn() && (
  resource.data.senderId == request.auth.uid ||
  (canAccessConversation() &&
   request.resource.data.diff(resource.data)
     .affectedKeys().hasOnly(['reactions', 'deletedForProfiles']))
);
```

### 5.3 Proteções Adicionais

- **Environment Isolation**: Validação de projectId em runtime
- **Sensitive Data**: Credenciais em arquivos de configuração por flavor
- **API Keys**: Restrições por bundle ID no Google Cloud Console
- **FCM Tokens**: Subcoleção por perfil, acesso restrito

---

## 🎨 6. Design System

### 6.1 Cores

| Token          | Hex     | Uso                              |
| -------------- | ------- | -------------------------------- |
| **Primary**    | #37475A | Elementos principais, músicos    |
| **Accent**     | #E47911 | Destaques, bandas                |
| **SalesBlue**  | #007EB9 | Espaços e anúncios (posts sales) |
| **Badge**      | #FF2828 | Notificações, alertas            |
| **Background** | #F5F5F5 | Fundo claro                      |
| **Surface**    | #FFFFFF | Cards, modais                    |
| **OnPrimary**  | #FFFFFF | Texto sobre primary              |

#### Cores por Tipo de Perfil/Post

| Tipo   | Cor       | Hex     | Uso em Markers e UI   |
| ------ | --------- | ------- | --------------------- |
| Músico | Primary   | #37475A | Markers cinza-azulado |
| Banda  | Accent    | #E47911 | Markers laranja       |
| Espaço | SalesBlue | #007EB9 | Markers azul          |

### 6.2 Tipografia

| Estilo              | Font  | Size | Weight   |
| ------------------- | ----- | ---- | -------- |
| **Headline Large**  | Inter | 32sp | Bold     |
| **Headline Medium** | Inter | 28sp | SemiBold |
| **Title Large**     | Inter | 22sp | SemiBold |
| **Title Medium**    | Inter | 16sp | Medium   |
| **Body Large**      | Inter | 16sp | Regular  |
| **Body Medium**     | Inter | 14sp | Regular  |
| **Label Large**     | Inter | 14sp | Medium   |

### 6.3 Componentes Compartilhados (core_ui)

- `AppButton` - Botões padronizados
- `AppTextField` - Campos de entrada
- `AppCard` - Cards de conteúdo
- `ProfileAvatar` - Avatar com placeholder
- `LoadingOverlay` - Overlay de carregamento
- `AppSnackbar` - Mensagens de feedback
- `Debouncer` - Utility para debounce

---

## ⚡ 7. Performance & Boas Práticas

### 7.1 Otimizações Implementadas

| Área         | Técnica                        | Ganho                                                         |
| ------------ | ------------------------------ | ------------------------------------------------------------- |
| **Imagens**  | CachedNetworkImage             | -80% memória                                                  |
| **Upload**   | FlutterImageCompress (isolate) | Sem freeze de UI                                              |
| **Markers**  | MarkerCacheService             | 95% mais rápido (6 tipos: músico/banda/sales x normal/active) |
| **Streams**  | distinctUntilChanged           | Evita rebuilds                                                |
| **Queries**  | startAfterDocument             | Paginação eficiente                                           |
| **Debounce** | 50ms em streams                | Reduz latência                                                |

### 7.2 Memory Leak Prevention

```dart
// OBRIGATÓRIO em todos os providers com streams
ref.onDispose(() {
  _streamController.close();
  _subscription.cancel();
});
```

### 7.3 Padrões de Código

#### Nunca Fazer

```dart
// ❌ Memory leak + lento
Image.network(url)

// ❌ Freeze de UI
final bytes = await file.readAsBytes();
await compress(bytes); // Na main thread
```

#### Sempre Fazer

```dart
// ✅ Cache + performance
CachedNetworkImage(
  imageUrl: url,
  memCacheWidth: width * 2,  // Retina
)

// ✅ Em isolate
final compressed = await compute(_compressImage, path);
```

### 7.4 Riverpod Patterns

```dart
// Provider com AutoDispose
@riverpod
class FeatureNotifier extends _$FeatureNotifier {
  @override
  FutureOr<FeatureState> build() async {
    // Cleanup automático
    ref.onDispose(() => _cleanup());
    return _loadInitialData();
  }
}

// State com Freezed
@freezed
class FeatureState with _$FeatureState {
  const factory FeatureState({
    @Default([]) List<Item> items,
    @Default(false) bool isLoading,
    String? error,
  }) = _FeatureState;
}
```

---

## 🧪 8. Testes

### 8.1 Cobertura Atual

- **270+ testes** passando
- **Testes unitários**: UseCases, Repositories
- **Testes de widgets**: Pages principais
- **Testes de integração**: Fluxos críticos

### 8.2 Executar Testes

```bash
cd packages/app
flutter test --coverage
```

### 8.3 Estratégia de Testes

- **Domain**: Testes puros (sem dependências externas)
- **Data**: Mocks de Firestore/APIs
- **Presentation**: Widget tests com ProviderScope

---

## 🚀 9. CI/CD

### 9.1 GitHub Actions Workflows

| Workflow              | Trigger    | Ações                            |
| --------------------- | ---------- | -------------------------------- |
| **CI - Build & Test** | Push/PR    | Analyze, Test, Build iOS/Android |
| **iOS Build & Sign**  | Manual/Tag | Build, Sign, TestFlight          |

### 9.2 Pipeline de Build

```
Push → Lint/Analyze → Unit Tests → Build iOS → Build Android → Artifacts
```

### 9.3 Deploy Firebase

```bash
# Ordem importante (indexes primeiro)
firebase deploy --only firestore:indexes --project <env>  # Aguardar 5-10min
firebase deploy --only firestore:rules --project <env>
firebase deploy --only functions --project <env>
```

---

## 🌐 10. Website (wegig.com.br)

### 10.1 Visão Geral

O site institucional do WeGig serve como landing page, documentação legal e feed de posts em tempo real.

| Recurso                     | URL                                                                    | Descrição                                       |
| --------------------------- | ---------------------------------------------------------------------- | ----------------------------------------------- |
| **Landing Page**            | [wegig.com.br](https://wegig.com.br)                                   | Apresentação do app, funcionalidades e download |
| **Termos de Uso**           | [wegig.com.br/termos.html](https://wegig.com.br/termos.html)           | Termos e condições (v1.0 - Nov/2025)            |
| **Política de Privacidade** | [wegig.com.br/privacidade.html](https://wegig.com.br/privacidade.html) | LGPD, GDPR, CCPA compliance (v1.0 - Nov/2025)   |
| **API Docs**                | [wegig.com.br/api](https://wegig.com.br/api)                           | Documentação técnica (dartdoc)                  |

### 10.2 Hospedagem

- **Plataforma**: Firebase Hosting (projeto `to-sem-banda-83e19` - PROD)
- **Domínio**: wegig.com.br (CNAME configurado)
- **SSL**: Gerenciado pelo Firebase
- **CDN**: Global via Firebase

### 10.3 Estrutura de Arquivos

```
docs/                           → Pasta raiz do site (Firebase Hosting public)
├── index.html                  → Landing page principal
├── style.css                   → Estilos (Design System)
├── posts-feed.js               → Integração Firebase + Google Maps
├── termos.html                 → Termos de Uso
├── privacidade.html            → Política de Privacidade
├── CNAME                       → wegig.com.br
├── favicon-16.png              → Ícones
├── favicon-32.png
├── app_icon.png                → App icon (192x192)
├── LogoSite.png                → Logo footer
├── WeGigSloganTransparente.png → Logo header
├── WeGigSite.png               → Screenshot do app
└── api/                        → Documentação técnica gerada
```

### 10.4 Funcionalidades do Site

#### Feed de Posts em Tempo Real

O site exibe posts reais do Firebase Firestore (ambiente PROD) com:

- **Mapa interativo** com Google Maps (Map ID: `b7134f9dc59c2ad97d5b292e`)
- **Markers coloridos** por tipo (Músico, Banda, Espaço)
- **Carrossel auto-scroll** com últimos 20 posts
- **Sincronização em tempo real** via Firebase JS SDK 11.1.0

```javascript
// Cores dos markers (alinhadas com Design System)
const COLORS = {
  musician: "#37475A", // Primary - Músicos
  band: "#E47911", // Accent - Bandas
  sales: "#007EB9", // SalesBlue - Espaços
};
```

#### Seções da Landing Page

| Seção               | Descrição                                                              |
| ------------------- | ---------------------------------------------------------------------- |
| **Hero**            | Headline + CTA para download                                           |
| **Sobre**           | 4 stats principais (Geolocalizado, Multi-Perfil, Posts Efêmeros, Chat) |
| **Funcionalidades** | Grid com 9 features detalhadas                                         |
| **Posts Recentes**  | Mapa + carrossel em tempo real                                         |
| **Download**        | Badges App Store / Google Play                                         |
| **Footer**          | Links, contato e copyright                                             |

### 10.5 Documentação Legal

Os documentos legais estão em compliance com:

- **LGPD** - Lei nº 13.709/2018 (Brasil)
- **GDPR** - Regulamento (UE) 2016/679
- **CCPA** - California Consumer Privacy Act

| Documento               | Versão | Data       | Linhas |
| ----------------------- | ------ | ---------- | ------ |
| Termos de Uso           | 1.0    | 27/11/2025 | ~638   |
| Política de Privacidade | 1.0    | 27/11/2025 | ~1013  |

#### Contatos Oficiais

- **Geral**: contato@wegig.com.br
- **Privacidade/DPO**: privacidade@wegig.com.br

### 10.6 Deploy do Site

```bash
# Deploy via Firebase Hosting (da pasta .config/)
cd .config
firebase deploy --only hosting --project to-sem-banda-83e19
```

### 10.7 Redirect Automático

O site redireciona automaticamente acessos via domínios Firebase para o domínio customizado:

```javascript
// Redirect Firebase domain to custom domain
if (
  window.location.hostname.includes("web.app") ||
  window.location.hostname.includes("firebaseapp.com")
) {
  window.location.replace("https://wegig.com.br" + window.location.pathname);
}
```

---

## 📱 11. Comandos de Desenvolvimento

### 11.1 Setup Inicial

```bash
# Clone e dependências
git clone <repo>
cd to_sem_banda
melos bootstrap
```

### 11.2 Executar App

```bash
cd packages/app

# DEV
flutter run --flavor dev -t lib/main_dev.dart

# STAGING
flutter run --flavor staging -t lib/main_staging.dart

# PROD
flutter run --flavor prod -t lib/main_prod.dart
```

### 11.3 Code Generation

```bash
# Após modificar Freezed/JSON models
melos run build_runner
```

### 11.4 Limpar Cache

```bash
flutter clean && melos get && melos run build_runner
```

### 11.5 iOS Específico

```bash
cd packages/app/ios
rm -rf Pods Podfile.lock && pod install
```

---

## 🐛 12. Troubleshooting

| Problema                   | Solução                                                                 |
| -------------------------- | ----------------------------------------------------------------------- |
| Wrong directory error      | Comandos Flutter DEVEM rodar de `packages/app/`                         |
| Stale generated files      | `flutter clean && melos get && melos run build_runner`                  |
| iOS DerivedData issues     | `rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*`                 |
| Pod problems               | `cd ios && rm -rf Pods Podfile.lock && pod install`                     |
| Firestore index missing    | Deploy indexes primeiro, aguardar conclusão                             |
| Profile data not updating  | Usar `profileSwitcherNotifierProvider`                                  |
| Permission denied          | Verificar Security Rules e auth state                                   |
| Cloud Functions not firing | `firebase functions:log`                                                |
| Package name mismatch      | Verificar google-services.json e .plist têm package/bundle IDs corretos |

---

## 📊 13. Métricas de Qualidade

### 13.1 Code Quality

- ✅ 0 erros de compilação (packages/app)
- ✅ Análise estática passando
- ✅ Formatação consistente (dart format)
- ✅ Documentação inline

### 13.2 Arquitetura

- ✅ Feature-First Clean Architecture
- ✅ Separação de concerns
- ✅ Dependency Injection (Riverpod)
- ✅ SOLID principles

### 13.3 Segurança

- ✅ Auth obrigatório em todas operações
- ✅ Ownership validation
- ✅ Environment isolation
- ✅ Sensitive data protection

### 13.4 Performance

- ✅ Lazy loading de streams
- ✅ Image caching & compression
- ✅ Marker clustering
- ✅ Memory leak prevention

---

## 🗺️ 14. Roadmap Futuro (Pós-MVP)

### Fase 2 - Enhancements

- [x] ~~Perfis de espaços/estúdios~~ ✅ **Implementado no MVP**
- [x] ~~Posts de anúncio (sales)~~ ✅ **Implementado no MVP**
- [ ] Sistema de avaliações
- [ ] Portfólio de mídia (áudio/vídeo)
- [ ] Integração com Spotify/SoundCloud
- [ ] Deep Links (compartilhar posts via WhatsApp)
- [ ] Dark Mode completo

### Fase 3 - Social Features

- [ ] Grupos/comunidades por gênero
- [ ] Eventos e shows
- [ ] Sistema de badges/conquistas
- [ ] Stories efêmeros (24h)
- [ ] Live streaming (shows ao vivo)
- [ ] Calendário de eventos integrado

### Fase 4 - Monetização PRO (Futuro - A Definir)

- [ ] Assinatura PRO (R$ 19,90/mês ou R$ 199,00/ano)
- [ ] Limitação de features para Free Tier
- [ ] Badge PRO no perfil
- [ ] Visualização de quem visitou perfil
- [ ] Confirmação de leitura em mensagens
- [ ] Analytics do perfil

### Fase 5 - WeGig Business B2B (Futuro)

- [ ] Dashboard web para empresas (CRM simplificado)
- [ ] Perfil verificado (selo azul "Business")
- [ ] Posts patrocinados (native ads)
- [ ] Analytics avançado (impressões, conversões, ROI)
- [ ] API de integração externa

### Fase 6 - Marketplace & Transações (2027+)

- [ ] Pagamentos in-app (Stripe, PIX)
- [ ] Escrow service
- [ ] Rating & reviews
- [ ] Seguro de freela
- [ ] Comissão de transações (10-15%)

---

## 💰 15. Business Plan

### 15.1 Modelo de Negócio

O WeGig opera em um modelo **Freemium + B2B SaaS**, com monetização planejada para fases futuras:

| Fase               | Período   | Modelo                  | Status                       |
| ------------------ | --------- | ----------------------- | ---------------------------- |
| **1. Lançamento**  | Ano 1     | 100% Gratuito           | ✅ MVP Atual                 |
| **2. PRO**         | Ano 2     | Assinatura R$ 19,90/mês | 🔮 Futuro                    |
| **3. Business**    | Ano 2-3   | B2B R$ 99,90/mês        | 🔮 Futuro (estrutura pronta) |
| **4. Marketplace** | Ano 3+    | Comissão 10-15%         | 🔮 Futuro                    |
| **5. Ads**         | A definir | CPM R$ 10-30            | 🔮 Futuro                    |

### 15.2 Lançamento Gratuito (MVP Atual)

**Estratégia:** Todas as features disponíveis gratuitamente para acelerar adoção e validar product-market fit.

| Feature                     | Status        |
| --------------------------- | ------------- |
| Perfis ativos               | 5 (ilimitado) |
| Posts por mês               | Ilimitado     |
| Conversas por mês           | Ilimitado     |
| Busca geoespacial           | Ilimitada     |
| Notificações de proximidade | ✅ Ativas     |
| Posts de anúncio (sales)    | ✅ Disponível |
| Filtros avançados           | ✅ Todos      |

**Objetivo do Lançamento Gratuito:**

- Construir base de usuários orgânica
- Validar proposta de valor
- Coletar feedback para evolução do produto
- Criar network effects (quanto mais usuários, mais valor)

### 15.3 Assinatura PRO (Fase Futura)

**Preço Planejado:** R$ 19,90/mês ou R$ 199,00/ano (17% desconto)

**Nota:** No lançamento, todas estas features estarão disponíveis gratuitamente. A diferenciação PRO será implementada em fase futura.

| Feature                    | Gratuito (Atual) | PRO (Futuro)        |
| -------------------------- | ---------------- | ------------------- |
| **Múltiplos Perfis**       | Até 5            | Até 5               |
| **Limite de Posts**        | Ilimitado        | Ilimitado           |
| **Limite de Chats**        | Ilimitado        | Ilimitado           |
| **Visualização de Perfil** | ❌ (futuro)      | ✅ Ver quem visitou |
| **Confirmação de Leitura** | ❌ (futuro)      | ✅ Double checkmark |
| **Badge PRO**              | ❌               | ✅ Selo no perfil   |
| **Analytics do Perfil**    | ❌ (futuro)      | ✅ Views, alcance   |

### 15.4 WeGig Business B2B (Estrutura Preparada no MVP)

**Cliente Alvo:** Estúdios, escolas, luthierias, lojas, produtoras, casas de show

**Preço Sugerido:** R$ 99,90/mês por perfil empresarial

**Features Business (planejadas):**

| Feature                        | Descrição                         | Valor            |
| ------------------------------ | --------------------------------- | ---------------- |
| **Perfil Verificado**          | Selo azul + badge "Business"      | Credibilidade    |
| **Geolocalização Prioritária** | Destaque no mapa (ícone maior)    | 3x visibilidade  |
| **Posts Patrocinados**         | Native ads no feed                | Alcance ampliado |
| **CRM Simplificado**           | Dashboard de interesses/mensagens | Organização      |
| **Analytics Avançado**         | Dashboard com métricas e ROI      | Data-driven      |
| **Múltiplas Localizações**     | Rede de filiais                   | Cobertura ampla  |

**⚡ Estrutura Já Implementada no MVP:**

- ✅ `ProfileType.space` com 9 subtipos (SpaceType)
- ✅ `PostType.sales` com preços, descontos e WhatsApp
- ✅ Markers diferenciados por cor (SalesBlue)
- ✅ Filtros de busca específicos para anúncios

### 15.5 Projeção de Receita (5 anos)

| Ano      | Usuários | PRO (5%) | Receita PRO  | Empresas B2B | Receita B2B | **Total**        |
| -------- | -------- | -------- | ------------ | ------------ | ----------- | ---------------- |
| **2026** | 5.000    | 250      | R$ 59.700    | 0            | R$ 0        | **R$ 59.700**    |
| **2027** | 25.000   | 1.250    | R$ 298.500   | 50           | R$ 59.940   | **R$ 358.440**   |
| **2028** | 100.000  | 5.000    | R$ 1.194.000 | 100          | R$ 119.880  | **R$ 1.313.880** |
| **2029** | 300.000  | 15.000   | R$ 3.582.000 | 150          | R$ 179.820  | **R$ 3.761.820** |
| **2030** | 750.000  | 37.500   | R$ 8.955.000 | 200          | R$ 239.760  | **R$ 9.194.760** |

**Break-even:** Q3 2028 (Mês 27)

### 15.6 KPIs e Métricas de Sucesso

#### Aquisição

- **CAC:** R$ 10-20 por usuário (meta)
- **Viral coefficient:** 1.2+ (cada usuário traz 1.2 novos)
- **Tempo para 1º post:** < 10min

#### Engajamento

- **DAU/MAU:** 40%+
- **Session length:** 8-12min
- **Posts/user/month:** 2+ (Free), 5+ (PRO)

#### Retenção

- **D1 Retention:** 50%+
- **D7 Retention:** 30%+
- **D30 Retention:** 20%+
- **Churn PRO:** < 10%/mês

#### Monetização

- **Free → PRO Conversion:** 5%+
- **LTV PRO:** R$ 500+ (2 anos)
- **LTV/CAC Ratio:** 5:1+
- **ARPU:** R$ 5+

### 15.7 Riscos e Mitigações

| Risco                        | Probabilidade | Impacto | Mitigação                                               |
| ---------------------------- | ------------- | ------- | ------------------------------------------------------- |
| Baixa adoção inicial         | Alta          | Alto    | Marketing em nicho, partnerships, onboarding gamificado |
| Custos de infraestrutura     | Média         | Alto    | Monitoramento proativo, caching agressivo, CDN          |
| Concorrentes copiam features | Alta          | Médio   | Speed to market, network effects                        |
| Spam e conteúdo inapropriado | Média         | Alto    | Moderação automática, denúncias, rate limiting          |
| Problemas legais (LGPD)      | Baixa         | Alto    | Compliance desde dia 1, termos claros, export de dados  |

---

## 📞 16. Contato & Suporte

**Desenvolvedor**: Wagner Oliveira  
**Email**: wagner_mecanica@hotmail.com  
**GitHub**: [wagnermecanica-code](https://github.com/wagnermecanica-code)

**Contatos Oficiais WeGig:**

- **Geral**: contato@wegig.com.br
- **Privacidade/DPO**: privacidade@wegig.com.br
- **Website**: [wegig.com.br](https://wegig.com.br)

---

## 📄 17. Histórico de Revisões

| Versão  | Data       | Descrição                                                                    |
| ------- | ---------- | ---------------------------------------------------------------------------- |
| **0.0** | 15/12/2025 | Documento inicial do MVP                                                     |
| **0.1** | 15/12/2025 | Adicionado suporte a Espaços (profileType=space) e Anúncios (postType=sales) |
| **0.2** | 15/12/2025 | Adicionado Business Plan (seção 15) e Roadmap expandido                      |
| **0.3** | 15/12/2025 | Lançamento 100% gratuito; monetização movida para fase futura                |
| **0.4** | 15/12/2025 | Adicionada seção Website wegig.com.br (seção 10)                             |
| **0.5** | 15/12/2025 | Corrigidos package names e bundle IDs nos arquivos Firebase                  |
| **0.6** | 17/12/2025 | Sistema de Denúncias (reports) com SendGrid e Dashboard Admin                |

---

_Este documento representa o estado do MVP do WeGig na data de sua criação. Para informações atualizadas, consulte o README.md e a documentação em docs/._
