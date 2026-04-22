### 🛡️ App Check iOS produção habilitado (21/04/2026)

- plists, xcconfigs e `firebase_options_*.dart` em `packages/app/ios/` realinhados para os bundles `com.tosembanda.wegig[.dev|.staging]` e os novos App IDs registrados no Firebase
- DeviceCheck habilitado na mesma Apple Developer Key já usada para APNs (`PL8H6R5M5U`); runs de produção agora emitem tokens reais sem cair em placeholder
- enforcement permanece desligado até concluir paridade de Android/Play Integrity

### 🤝 Minha Rede - Fase 11 concluída com auditoria de conexões (21/04/2026)

- adicionado `.tools/scripts/audit_connections_logs.js` para checagem periódica dos sinais da feature de conexões em produção
- o roadmap `docs/tasks/CONNECTIONS_IMPLEMENTATION_ROADMAP_2026-04-19.md` agora registra a Fase 11 como concluída, fechando o ciclo de validação, rollout e observabilidade

### 🤝 Minha Rede - overview consolidado como dashboard (20/04/2026)

- a home de `Minha Rede` foi reorganizada em blocos explícitos de acompanhamento e descoberta, reforçando o papel de overview
- o topo da tela agora resume convites, preview de conexões e preview de atividade para orientar a navegação sem voltar a crescer verticalmente
- a copy da home foi sincronizada com as telas dedicadas já entregues para `Conexões` e `Atividade da rede`

### 🤝 Minha Rede - auditoria de índices concluída (20/04/2026)

- a revisão das queries da feature confirmou que os índices atuais do Firestore já cobrem conexões, atividade da rede, convites, sugestões e consultas auxiliares
- nenhuma alteração adicional foi necessária em `.config/firestore.indexes.json` para a superfície entregue até aqui

### 🤝 Minha Rede - redução de leituras redundantes (20/04/2026)

- o datasource de conexões agora usa cache curto de perfis disponíveis para evitar leituras repetidas durante enriquecimento da atividade e outras consultas derivadas
- o stream de atividade da rede passou a ignorar recomputações quando a lista efetiva de perfis conectados não mudou

### 🤝 Minha Rede - estados específicos no overview (20/04/2026)

- os previews de `Conexões` e `Atividade da rede` agora exibem estados próprios de loading, vazio e erro no overview
- os estados de erro no overview passaram a oferecer ação explícita de nova tentativa via atualização da tela

### 🤝 Minha Rede - telemetria e troca de perfil nas telas dedicadas (20/04/2026)

- as interações de preview e das telas dedicadas agora registram `source` nos principais eventos de analytics da feature
- as telas dedicadas de `Conexões` e `Atividade da rede` agora limpam refinamentos locais ao trocar o perfil ativo, evitando estado stale entre perfis

### 🤝 Minha Rede - filtros e ordenação em atividade da rede (20/04/2026)

- a tela dedicada de `Atividade da rede` agora permite ordenar por recentes ou proximidade e filtrar localmente por tipo de publicação
- os controles atuam sobre a lista já carregada, preservando o contrato paginado e a navegação para perfil e detalhe do post

### 🤝 Minha Rede - filtros e ordenação em conexões (20/04/2026)

- a tela dedicada de `Conexões` agora permite ordenar por recentes ou nome A-Z e filtrar rapidamente perfis com `@username`
- os novos controles operam localmente sobre a lista já carregada, preservando o contrato paginado e a UX principal da feature

### 🤝 Minha Rede - busca na tela dedicada de conexões (20/04/2026)

- a tela dedicada de `Conexões` agora permite buscar por nome e `@username`, com campo de busca no cabeçalho da lista
- a listagem passa a enriquecer usernames dos perfis já carregados para melhorar descoberta sem alterar o contrato paginado da feature

### 🤝 Minha Rede - observabilidade inicial das telas dedicadas (20/04/2026)

- os CTAs do overview para `Conexões` e `Atividade da rede` agora registram eventos específicos da feature antes da navegação
- as telas dedicadas passaram a registrar entrada, refresh e `load more`, melhorando a leitura de adoção e comportamento da nova experiência

### 🤝 Minha Rede - tela dedicada de atividade da rede (20/04/2026)

- o CTA `Ver tudo` de `Atividade da rede` agora navega para uma tela dedicada da rede
- a nova tela de `Atividade da rede` usa o controller paginado já preparado, com pull-to-refresh, carregamento incremental e navegação para perfil e detalhe do post

### 🤝 Minha Rede - contrato paginado de atividade da rede (20/04/2026)

- adicionada leitura paginada real para `Atividade da rede`, com cursor por data e controle de empate na fronteira da página
- definidos tamanhos de página para conexões e atividade, preparando a próxima tela dedicada sem reaproveitar limites de overview

### 🤝 Minha Rede - tela dedicada de conexões (20/04/2026)

- o CTA `Ver todas` de `Conexões` agora navega para a nova tela dedicada da rede
- a tela dedicada de `Conexões` já usa paginação incremental, pull-to-refresh e mantém as ações centrais de mensagem e desconexão

### 🤝 Minha Rede - contrato paginado de conexoes (20/04/2026)

- adicionada leitura paginada real de conexoes com cursor baseado em documento, preparada para `load more` sem reconsultar toda a lista
- criado controller paginado de `Conexoes`, alinhando a feature ao padrao de listas incrementais ja usado em outras areas do app

# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).

## [1.0.2] - 2025-12-22 (Build 5)

### 🗺️ Mapa - Normalização de Markers

- **Problema:** Markers no Android apareciam muito maiores que no iOS
- **Causa:** O `widget_to_marker` usa diferentes `pixelRatio` por plataforma
- **Solução:** Tamanhos específicos por plataforma:
  - Android: Size(32, 43), pixelRatio 2.5
  - iOS: Size(46.9, 62.7), pixelRatio 3.0
- **Arquivos:** `wegig_pin_descriptor_builder.dart`, `wegig_cluster_renderer.dart`

### 🎨 UI/UX - PostDetailPage

- **Problema:** Card do vídeo do YouTube colado na borda inferior (Android)
- **Solução:** Adicionado `SizedBox(height: 24)` após o card do YouTube
- **Arquivos:** `post_detail_page.dart`

### 📝 Formulários - Campo YouTube

- **Problema:** Texto de aviso do campo YouTube não quebrava linha
- **Solução:** Adicionado `helperMaxLines: 2` no InputDecoration
- **Arquivos:** `post_page.dart`, `edit_profile_page.dart`

### 🔒 Segurança - Exclusão de Conta

- **Melhoria:** Fluxo de reautenticação para exclusão de conta aprimorado
- **Arquivos:** `account_settings_page.dart`

---

## [Não Publicado]

### 🔐 Segurança de deeplink - isolamento por perfil em push de mensagens (22/04/2026)

- Corrigido um vazamento de contexto entre perfis do mesmo usuário no toque de push `newMessage`, que podia abrir conversa fora do perfil ativo.
- O app agora valida `recipientProfileId` contra o perfil ativo antes de processar o deeplink de mensagem (incluindo fluxo deferred no estado terminated).
- O `ChatNewController` passou a bloquear inicialização de stream quando o perfil ativo não pertence a `participantProfiles` da conversa.
- A Cloud Function `sendMessageNotification` passou a enviar `recipientProfileId` no payload da push para suportar o guard de segurança no cliente.
- Hotfix adicional: `isGroup` no payload FCM de `data` foi normalizado para string (`"true"`/`"false"`) para evitar `messaging/invalid-payload`.

### 🤝 Convites de conexão - reconciliação pós-envio no cliente (22/04/2026)

- Corrigido o fluxo de envio para revalidar no servidor alguns segundos após o create, cobrindo remoções automáticas feitas por Cloud Functions (rate limit, cooldown ou bloqueio)
- Quando o convite é removido logo após a criação, a ação agora falha de forma explícita e o estado otimista é revertido, evitando botão preso em `Convite enviado`
- O ajuste elimina o cenário em que o Firestore gravava e removia o convite em seguida enquanto as telas de `Convites enviados` e `Convites recebidos` permaneciam vazias

### 🧭 Fechamento de etapa - alinhamento final de app, IA e site (21/04/2026)

- Atualizadas as instruções da IA em `.github/copilot-instructions.md` para refletir `connections`, badge social, preferências por perfil, fork local de `google_maps_flutter` e o loader padronizado
- README, índices de documentação e documentos canônicos foram sincronizados com o estado atual do app e com o encerramento desta etapa
- Registrada a sessão `docs/sessions/SESSION_21_STAGE_CLOSURE_2026-04-21.md` para consolidar decisões, escopo e artefatos desta fase

### 🤝 Fechamento funcional de Minha Rede e preferências sociais (21/04/2026)

- `Minha Rede` foi consolidada como hub social principal com badge dedicado no bottom nav e contagem unificada no seletor de perfis
- Configurações por perfil passaram a incluir `allowConnectionSuggestions` e `allowConnectionRequests`, persistidas no backend e expostas na UI de settings
- A troca de perfil passou a limpar cache compartilhado de bloqueios para reduzir estado stale entre perfis nas superfícies sociais

### 🎛️ Padronização de loading e estado visual (21/04/2026)

- Introduzido e propagado `AppRadioPulseLoader` como loader visual padrão em overlays, settings, profile switcher, report flow e superfícies centrais do app
- A padronização reduz divergência visual entre telas e simplifica futuras mudanças na identidade de loading

### 🌐 Site público e publicação via GitHub Pages (21/04/2026)

- O site em `docs/` foi atualizado para comunicar `Conexões` e `Minha Rede` como parte central do posicionamento do produto
- Adicionado workflow dedicado de GitHub Pages para publicar `docs/` e manter `wegig.com.br` alinhado ao estado corrente do produto
- Aplicado cache-busting de CSS e refinado o visual dos cards de funcionalidades para refletir a nova etapa

### 📘 Baseline documental - MVP com Conexões (21/04/2026)

- Atualizado `MVP_Rev0.0.md` para refletir `Conexões / Minha Rede` como feature principal do MVP
- Revisado o escopo macro de produto para incluir grafo social por perfil, atividade da rede e notificações sociais
- Sincronizados `docs/project-info/MVP_DESCRIPTION.md` e `docs/guides/MVP_CHECKLIST.md` com a baseline documental da nova feature

### 🤝 Implementacao inicial - sistema de conexoes (19/04/2026)

- Criada a feature `packages/app/lib/features/connections/` com datasource, repository, entidades, use cases, providers Riverpod e pagina `Minha Rede`
- Implementado o fluxo base de conexao em DEV: enviar convite, aceitar, recusar, cancelar, remover conexao, consultar status e acompanhar contadores
- Adicionados `connectionRequests`, `connections` e `connectionStats` ao modelo do Firestore, com regras e indices iniciais para consultas do app
- `Minha Rede` substituiu `Notificações` no bottom nav
- O datasource de conexoes agora respeita bloqueios em ambos os sentidos, filtrando convites/conexoes bloqueados nas streams e barrando envio/aceite/status quando houver bloqueio entre perfis
- `Notificações` passaram a ter acesso secundario pelo AppBar da Home, mantendo a rota dedicada existente
- `view_profile_page.dart` passou a exibir CTA dinamico de conexao para perfis visitados, com estados de conectar, aceitar, convite enviado e conectado
- Convites enviados e convites aceitos agora geram notificacoes sociais na inbox existente, reaproveitando o fluxo de `notifications_new` com deep link para o perfil remetente
- `Minha Rede` agora oferece atalho de mensagem nas conexoes ativas, abrindo ou criando conversa direta via `mensagens_new`
- Perfis visitados agora exibem conexoes em comum de forma resumida no header, calculadas a partir do grafo atual de `connections`
- `.config/functions/index.js` agora inclui triggers de ciclo de conexao para reconciliar `connectionStats`, endurecer bloqueios no backend e permitir rebuild manual autenticado das estatisticas
- `Minha Rede` agora exibe sugestões de conexão com score inicial e razões textuais baseadas em cidade, tipo de perfil, instrumentos, gêneros e conexões em comum
- Sugestões de conexão agora usam cache por perfil em `connectionSuggestions`, com rules dedicadas e filtragem defensiva para não reapresentar perfis bloqueados, pendentes ou já conectados
- O score de sugestões agora também considera conversa prévia e interesse em posts entre perfis como sinais secundários de afinidade
- Convites de conexão agora respeitam cooldown e limite diário, com validação no app, endurecimento espelhado nas Cloud Functions e índice dedicado para a janela temporal de envio
- Firestore Rules agora barram criação de convites e conexões entre perfis com bloqueio bidirecional, reduzindo dependência de validação apenas no cliente
- `.config/functions/index.js` agora reconcilia bloqueios novos contra o grafo social, removendo convites, conexões e sugestões cacheadas quando um bloqueio é criado depois da relação já existir
- `onProfileDelete` agora também limpa artefatos do sistema de conexões, removendo convites, conexões, stats e cache de sugestões quando um perfil é excluído
- O funil social agora registra eventos de analytics na `Minha Rede` e nas ações centrais de conexão, cobrindo entrada na tela, abertura de sugestão, envio, aceite, recusa, cancelamento, remoção e abertura de conversa
- O datasource de conexões agora trata perfis indisponíveis como inelegíveis para o grafo social, barrando novas interações e filtrando sugestões, conexões em comum, convites e conexões sem identidade mínima válida
- A Home agora suporta o filtro global `somente conexões`, reaproveitando o grafo social para mostrar apenas posts próprios e de perfis conectados, com controle exposto no modal de filtros
- `Minha Rede` agora exibe atividade recente das conexões com posts publicados pela rede, em stream, com navegação para perfil e detalhe do post e filtragem por bloqueio, expiração e disponibilidade do autor
- `Minha Rede` agora inclui a seção `Explorar por conexões em comum`, priorizando perfis sugeridos com laços mútuos e exibindo preview das conexões compartilhadas antes da visita ao perfil ou envio do convite
- O ranking de sugestões agora usa contexto musical mais rico, incluindo compatibilidade de nível, estágio de carreira/projeto e presença ativa nas plataformas musicais para priorização e explicação textual
- `Minha Rede` agora segmenta sugestões em experiências de networking para músicos, bandas e espaços, aproximando cada perfil dos contatos mais úteis para formação, agenda, circulação e programação

### 🤝 Roadmap de implementacao - sistema de conexoes (19/04/2026)

- Criado `docs/tasks/CONNECTIONS_IMPLEMENTATION_ROADMAP_2026-04-19.md` como plano vivo para execucao completa do sistema de conexoes
- Atualizados os indices de documentacao para apontar para o roadmap operacional da feature

### 🤝 Escalabilidade de Minha Rede - roadmap complementar (20/04/2026)

- Expandido `docs/tasks/CONNECTIONS_IMPLEMENTATION_ROADMAP_2026-04-19.md` com a trilha de escalabilidade de `Minha Rede`
- Adicionadas as fases 8 a 11 para acompanhar overview, paginacao, telas dedicadas de `Conexoes` e `Atividade da rede`, e validacao final
- Incluida legenda de status, checklist rapido e criterios de conclusao para permitir acompanhamento continuo da implementacao

### 🤝 Minha Rede - inicio da Fase 8 do overview (20/04/2026)

- `Minha Rede` agora explicita seu papel de overview com copy contextual no topo da tela
- `Conexoes` passou a usar preview reduzido com indicacao de amostra e CTA explicito de `ver todas`
- `Atividade da rede` passou a usar preview reduzido com indicacao de amostra e CTA explicito de `ver tudo`
- O refresh da tela foi alinhado aos novos limites de preview para evitar depender dos limites longos anteriores na home

### 🚀 Preparação de release para lojas (21/04/2026)

- Atualizado o versionamento do app para `1.0.15+20` como base do próximo upload para Apple e Google
- Sincronizados os documentos canônicos que expõem a versão atual do produto com o novo release number

### 🤝 Minha Rede - inicio da Fase 9 dos contratos de preview (20/04/2026)

- `Conexoes` e `Atividade da rede` agora usam providers de preview dedicados, separados dos providers base de lista
- os limites do overview foram centralizados na camada de providers para reduzir acoplamento da home com a estrategia de leitura
- a home ficou preparada para a proxima etapa de providers paginados sem reintroduzir limites diretamente na UI

### 🗃️ Revisão de documentação legada (20/04/2026)

#### Governança de histórico

- Criada a auditoria `docs/audits/LEGACY_DOCUMENTATION_AUDIT_2026-04-20.md` para classificar os documentos de `docs/legacy/`
- Definida a regra de registrar em `docs/audits/` qualquer futura decisão de manter, consolidar ou remover documentação legada
- `docs/Old/` identificado como pasta sem conteúdo documental relevante nesta revisão
- Executadas as promoções canônicas para troubleshooting, design e múltiplos perfis
- Removidos de `docs/legacy/` os arquivos já cobertos por documentação nova, por `.config/firestore.indexes.json` ou por arquitetura atual do app

### 📚 Atualização documental (19/04/2026)

#### Baseline do MVP e histórico

- Consolidada a baseline documental do produto em torno da versão `1.0.14+19`
- Atualizados os documentos centrais de MVP, checklist e índice de documentação
- Criada a sessão `SESSION_20_DOCUMENTATION_BASELINE_2026-04-19.md` para registrar a motivação e as decisões desta revisão
- README principal revisado para remover referências quebradas e apontar para documentos existentes

#### Governança documental

- Definidos como documentos canônicos: `README.md`, `MVP_Rev0.0.md`, `docs/project-info/MVP_DESCRIPTION.md`, `docs/guides/MVP_CHECKLIST.md` e `docs/changelog/CHANGELOG.md`
- Índices simplificados para evitar contagens manuais frágeis e reduzir divergências futuras

### 🔒 Sprint 1: Correções Críticas de Segurança (09/12/2025)

#### Firestore Index - Notifications Type Filter

- **Problema:** Aba "Interesses" mostrava "Ops! Algo de errado" ao carregar
- **Causa:** Query com filtro `type` requer índice composto que não existia
- **Solução:** Adicionado índice `recipientUid + recipientProfileId + type + createdAt`
- **Deploy:** ✅ `firebase deploy --only firestore:indexes --project wegig-dev`
- **Impacto:** Aba "Interesses" funciona corretamente
- **Arquivos:** `.config/firestore.indexes.json`

#### Firestore Security Rules - Profile Ownership Validation

- **Problema:** Usuário A poderia potencialmente ler notificações de perfil de usuário B
- **Causa:** Security Rules validavam apenas `recipientUid`, não ownership do `recipientProfileId`
- **Solução:** Nova função `ownsProfile()` + validação em todas operações de notificações
- **Deploy:** ✅ `firebase deploy --only firestore:rules --project wegig-dev`
- **Impacto:** 🔒 Isolamento multi-perfil garantido
- **Arquivos:** `.config/firestore.rules`

#### Cloud Functions - FCM Token Ownership & Expiration

- **Problema:** Push notifications enviadas para tokens sem validação de ownership ou expiração
- **Causa:** `sendPushToProfile()` buscava todos os tokens do perfil sem validação
- **Solução:**
  - Nova função `getValidTokensForProfile(profileId, expectedUid)`
  - Valida que profileId pertence ao expectedUid
  - Rejeita tokens com mais de 60 dias
- **Deploy:** ⚠️ Parcial (principais funções deployadas)
- **Impacto:** 🔒 Tokens validados, delivery rate melhora ~20-30%
- **Arquivos:** `.tools/functions/index.js`

### 🛠️ Flutter SDK Patches (09/12/2025)

#### CupertinoDynamicColor.toARGB32()

- **Problema:** Build iOS falhava com "missing implementations for Color.toARGB32"
- **Causa:** Flutter 3.27.1 incompatível com Dart engine mais recente
- **Solução:** Patch local adicionando método `toARGB32()` retornando `_effectiveColor.value`
- **Arquivos:** `.fvm/flutter_sdk/packages/flutter/lib/src/cupertino/colors.dart`

#### SemanticsData.elevation

- **Problema:** Build iOS falhava com "No named parameter 'elevation'"
- **Causa:** API nativa não aceita mais parâmetro elevation diretamente
- **Solução:** Patch local com fallback `elevation: data.elevation ?? 0.0`
- **Arquivos:** `.fvm/flutter_sdk/packages/flutter/lib/src/semantics/semantics.dart`

**Documentação:** `docs/setup/FLUTTER_SDK_PATCHES.md`

### 🚨 Correções Críticas (08/12/2025)

#### Firestore Security Rules - Posts Permission Denied

- **Problema:** Ao salvar um post, o app mostrava erro "Firebase access denied" (Permission Denied)
- **Causa:** As Security Rules verificavam campos `uid` e `profileUid`, mas a `PostEntity.toFirestore()` salvava com `authorUid` e `authorProfileId`
- **Solução:** Atualizado `.config/firestore.rules` para verificar `authorUid` ao invés de `uid`
- **Deploy:** Regras publicadas em todos os ambientes (DEV, STAGING, PROD)
- **Impacto:** ✅ Posts podem ser criados/editados/deletados corretamente
- **Arquivos:** `.config/firestore.rules`

#### Firestore Security Rules - Conversations Query Permission Denied

- **Problema:** Ao clicar em "Enviar mensagem" na ViewProfilePage, erro de acesso negado ao buscar conversas existentes
- **Causa:** A regra `allow read` usava `isConversationMember()` que faz `get()` no documento - isso não funciona para queries, apenas para leituras diretas
- **Solução:** Alterado `read` e `update/delete` para usar `resource.data` diretamente ao invés de `isConversationMember()`
- **Deploy:** Regras publicadas em todos os ambientes (DEV, STAGING, PROD)
- **Impacto:** ✅ Queries em conversations funcionam corretamente
- **Arquivos:** `.config/firestore.rules`

### 🚨 Correções Críticas (06/12/2025)

#### GoRouter Navigation Fix

- **Problema:** Navegação para `/profile/:profileId` e `/post/:postId` resultava em redirect infinito para `/home`
- **Causa:** Lógica de redirect sempre retornava `/home` para usuários autenticados, ignorando rota de destino
- **Solução:** Adicionada verificação de rotas permitidas - só redireciona de `/auth`, `/loading`, `/profiles/new`
- **Impacto:** ✅ Navegação de PostCard para detalhes agora funciona corretamente
- **Arquivos:** `app_router.dart`, `home_page.dart`

#### Firebase Multi-Ambiente

- **Problema:** `main_prod.dart` tinha `expectedProjectId: 'wegig-dev'` (projeto errado)
- **Problema:** `firebase_options_prod.dart` apontava para `projectId: 'wegig-dev'` (deveria ser `to-sem-banda-83e19`)
- **Problema:** `main_staging.dart` tinha `expectedProjectId: 'to-sem-banda-staging'` (inconsistente com `google-services.json`)
- **Solução:**
  - PROD: `expectedProjectId` → `'to-sem-banda-83e19'`
  - STAGING: `expectedProjectId` → `'wegig-staging'`
  - PROD: `firebase_options_prod.dart` projectId e storageBucket corrigidos
- **Impacto:** 🔒 Isolamento de ambientes garantido, dados de teste nunca irão para PROD
- **Arquivos:** `main_prod.dart`, `main_staging.dart`, `firebase_options_prod.dart`

#### Notificações - Latência e Erros

- **Problema:** Bottom sheet de notificações mostrava "Erro ao carregar notificações" para perfis sem notificações
- **Problema:** Latência de 300ms ao abrir notificações
- **Causa:** Stream sem tratamento de erros + debounce alto + query incorreta
- **Solução:**
  - Debounce reduzido: 300ms → 50ms (6x mais rápido)
  - `handleError()` retorna lista vazia ao invés de propagar erro
  - Query corrigida: `recipientUid` (Security Rules) + filtro client-side por `profileId`
  - NotificationsModal: erro tratado como estado vazio (melhor UX)
- **Impacto:** ⚡ Abertura instantânea, sem flashes de erro
- **Arquivos:** `notification_service.dart`, `bottom_nav_scaffold.dart`

### 🛠️ Melhorias de Performance

#### Memory Leaks

- **home_page.dart:** Removido `ref.read()` no `dispose()` (pode causar crash se provider já foi descartado)
- **profile_transition_overlay.dart:** Adicionado `try-catch` em `Navigator.pop()` (contexto pode estar disposed)
- **notifications_page.dart:** ScrollControllers agora tem `dispose()` correto sem listeners inline
- **Impacto:** 📉 Zero memory leaks detectados em 8 pontos auditados

#### Stream Optimization

- **Debounce reduzido:** `streamActiveProfileNotifications()`, `streamUnreadCount()`, `getNotifications()`
- **Antes:** 300ms (latência perceptível)
- **Depois:** 50ms (imperceptível ao usuário)
- **Impacto:** ⚡ 83% redução de latência

### 🎨 UI/UX

#### Empty States

- Removidos botões desnecessários de empty states (notificações, mensagens)
- Mensagens simplificadas e mais diretas
- Ícones padronizados (Iconsax)

#### Debug Logging

- Adicionados logs detalhados em GestureDetectors do PostCard:
  - `📍 PostCard: Tap na foto do post {postId}`
  - `📍 PostCard: Tap no nome do perfil {profileId}`
  - `📍 PostCard: Tap no header do post {postId}`
- Facilita debugging de navegação

### 📚 Documentação

#### README.md

- Atualizada tabela de flavors com Android package names
- Corrigida documentação de Firebase Projects (isolamento de ambientes)
- Adicionadas últimas correções (06/12/2025)

#### Auditoria Firebase

- Criado relatório completo de auditoria multi-ambiente
- Validação de `google-services.json` por flavor
- Validação de `GoogleService-Info-*.plist` por flavor
- Build.gradle.kts verificado (flavors corretos)
- iOS Build Phase verificado (cópia automática de plist)

---

## [1.0.0] - 2025-12-04

### Adicionado

- Monorepo migration completa (`packages/app` + `packages/core_ui`)
- CI/CD pipelines (GitHub Actions)
- Firebase dependencies atualizadas (20 packages)
- Code signing documentação completa
- Apple Sign-In funcionando

### Corrigido

- Bundle ID corrigido para `com.wegig.wegig.dev`
- Apple Sign-In "invalid-credential" erro resolvido
- APIs depreciadas (Riverpod, Google Maps, Color)

### Atualizado

- Flutter 3.27.1
- Dart 3.10
- Firebase Core 4.x series
- Riverpod 3.x

---

## [0.9.0] - 2025-11-30

### Multi-Profile Refactoring

#### Adicionado

- Sistema multi-perfil estilo Instagram
- Troca de perfil instantânea
- Isolamento completo de dados entre perfis
- `ProfileNotifier` com `AsyncNotifier` pattern
- Validação em runtime de ownership

#### Corrigido

- Permission-denied em Messages e Notifications
- Queries agora usam `recipientUid` + filtro client-side
- Security Rules atualizadas
- Memory leaks em 8 pontos críticos

#### Performance

- Cache de markers (95% mais rápido)
- Lazy loading de streams
- Debounce otimizado em notificações
- Badge counter com cache de 1 minuto

---

## [0.8.0] - 2025-11-15

### Cloud Functions

#### Adicionado

- Notificações de proximidade
- Auto-cleanup de posts expirados
- Geofencing com raio configurável (5-100km)

### Firestore

#### Adicionado

- 12 índices compostos para queries otimizadas
- Security Rules com ownership model
- Expiração automática de posts (30 dias)

---

## [0.7.0] - 2025-11-01

### Chat em Tempo Real

#### Adicionado

- Mensagens instantâneas
- Contador de não lidas
- Marcação automática como lida
- Lazy loading de streams

---

## [0.6.0] - 2025-10-15

### Geosearch & Maps

#### Adicionado

- Google Maps com markers customizados
- Filtro por proximidade
- Reverse geocoding para cidade
- Pagination de posts

---

## Versionamento

Formato: `MAJOR.MINOR.PATCH`

- **MAJOR:** Mudanças incompatíveis na API
- **MINOR:** Novas funcionalidades (compatível)
- **PATCH:** Correções de bugs (compatível)

---

**Legenda:**

- 🚨 Correção crítica
- ⚡ Performance
- 🔒 Segurança
- 📉 Bug fix
- ✨ Nova feature
- 📚 Documentação
- 🎨 UI/UX
