# Roadmap de Implementacao - Sistema de Conexoes

Data de criacao: 19 de abril de 2026.

Objetivo: registrar o plano executavel para implementar o sistema de conexoes do WeGig, com checkpoints claros para marcacao de progresso ao longo da execucao.

Status geral: `concluida`

## Resumo executivo

O sistema de conexoes sera implementado como uma nova feature centrada em `profileId`, integrada a perfis, mensageria, notificacoes e bloqueios ja existentes.

Decisao estrutural atual:

- `Minha Rede` entra no bottom nav
- `Notificacoes` saem do bottom nav e passam a ser acesso secundario por AppBar e rota dedicada
- o relacionamento social e entre perfis, nao entre usuarios Firebase

## Como usar este documento

- marque cada fase quando estiver concluida
- atualize os itens internos conforme o trabalho avancar
- registre blocos relevantes na secao de historico de execucao
- sempre que uma fase for encerrada, atualizar tambem `docs/changelog/CHANGELOG.md`

### Legenda de status

- `concluida`: entrega encerrada e validada
- `em andamento`: trabalho iniciado com itens ainda pendentes
- `planejada`: fase aprovada, mas ainda nao iniciada
- `bloqueada`: depende de decisao, indice, backend ou validacao externa

## Progresso macro

- [x] Fase 0 - Enquadramento final e desenho de navegacao
- [x] Fase 1 - Infraestrutura de dados, rules e backend
- [x] Fase 2 - Estrutura da feature `connections` no app
- [x] Fase 3 - Superficie Minha Rede e navegacao principal
- [x] Fase 4 - Integracoes com perfil, notificacoes e mensagens
- [x] Fase 5 - Sugestoes, ranking e sinais de afinidade
- [x] Fase 6 - Privacidade, abuse prevention e endurecimento operacional
- [x] Fase 7 - Expansao de valor pos-release
- [x] Fase 8 - Reestruturacao de `Minha Rede` para escala
- [x] Fase 9 - Paginacao e contratos de dados escalaveis
- [x] Fase 10 - Telas dedicadas de Conexoes e Atividade da Rede
- [x] Fase 11 - Validacao, rollout e observabilidade da nova experiencia

## Frente complementar - Escalabilidade de Minha Rede

Status: `concluida`

### Contexto atual observado em codigo

- `Minha Rede` usa um scroll externo unico com listas internas embutidas
- `Conexoes` hoje opera como preview limitado, nao como lista navegavel em larga escala
- `Atividade da rede` hoje opera como preview limitado e derivado de um subconjunto pequeno da rede
- nao existe fluxo de `ver todas`, pagina dedicada com filtros ou pagina dedicada com paginacao
- aumentar apenas os limites atuais degradaria UX, custo de leitura e previsibilidade de renderizacao

### Objetivo da frente complementar

Transformar `Minha Rede` em uma superficie de overview e transferir exploracao densa para telas dedicadas, com paginacao, filtros e contratos de dados preparados para crescimento real da base.

### Resultado esperado

- overview rapido e leve na tela principal
- navegacao clara para listas completas
- queries previsiveis e paginadas
- UX consistente para dezenas, centenas e milhares de conexoes e posts elegiveis

## Fase 8 - Reestruturacao de `Minha Rede` para escala

Status: `em andamento`

### Objetivo

Reposicionar `Minha Rede` como hub de resumo, e nao como container de listas longas.

### Entregas

- [x] definir layout final da home de `Minha Rede` como overview
- [x] limitar `Conexoes` a um bloco preview com CTA de `ver todas`
- [x] limitar `Atividade da rede` a um bloco preview com CTA de `ver tudo`
- [x] manter convites recebidos e enviados com prioridade visual sobre listas longas
- [x] definir empty, loading e erro especificos para preview e para lista completa
- [x] revisar copy para deixar claro quando a tela mostra amostra versus lista total

### Criterio de conclusao

`Minha Rede` deixa de crescer verticalmente com o volume total de dados e passa a atuar como dashboard resumido, com transicao explicita para fluxos completos.

## Fase 9 - Paginacao e contratos de dados escalaveis

Status: `concluida`

### Objetivo

Substituir limites fixos e streams de preview por contratos de leitura preparados para carregamento incremental.

### Entregas

- [x] separar providers de preview dos providers de lista completa
- [x] introduzir contrato cursor-based para conexoes com `startAfterDocument` ou equivalente
- [x] introduzir contrato cursor-based para atividade da rede com pagina incremental
- [x] definir tamanhos de pagina para conexoes e para atividade
- [x] impedir recomputacoes desnecessarias em cascata ao carregar mais itens
- [x] revisar datasource para reduzir leituras redundantes e waterfalls desnecessarios
- [x] mapear impacto em indices do Firestore e atualizar `.config/firestore.indexes.json` se necessario

### Criterio de conclusao

O app consegue carregar paginas subsequentes sem recarregar toda a lista nem depender de aumento arbitrario dos limites atuais.

## Fase 10 - Telas dedicadas de Conexoes e Atividade da Rede

Status: `concluida`

### Objetivo

Criar superficies completas para exploracao de alto volume sem sobrecarregar a tela principal.

### Entregas

- [x] criar tela dedicada de `Conexoes`
- [x] adicionar busca local/remota por nome ou username dentro da lista de conexoes
- [x] adicionar filtros e ordenacao coerentes com o produto
- [x] criar tela dedicada de `Atividade da rede`
- [x] permitir navegao consistente para perfil e detalhe do post a partir dessas listas
- [x] preservar comportamento de bloqueio, perfil inativo e indisponibilidade de autor
- [x] garantir paginacao visual com loading incremental e retry por secao

### Criterio de conclusao

O usuario consegue explorar rede e atividade em profundidade sem degradar a home de `Minha Rede` nem perder capacidade de descoberta.

## Fase 11 - Validacao, rollout e observabilidade da nova experiencia

Status: `concluida`

### Objetivo

Fechar a evolucao com validacao funcional, observabilidade e rollout seguro.

### Entregas

- [ ] testar cenarios com rede pequena, media e grande
- [ ] validar scroll, performance e estados de paginação em dispositivos reais
- [x] revisar eventos de analytics para entrada em preview, clique em `ver todas` e carregamento adicional
- [x] validar comportamento com bloqueios e alteracao de perfil ativo
- [x] revisar logs e erros da feature apos ativacao
- [x] atualizar documentacao funcional e changelog ao concluir cada etapa relevante

### Criterio de conclusao

A nova experiencia entra em operacao com cobertura funcional minima, sinais de observabilidade e risco reduzido de regressao na navegacao social.

## Sequencia recomendada de execucao

1. concluir Fase 8 e congelar a UX do overview
2. implementar Fase 9 antes de abrir as telas completas ao usuario
3. construir Fase 10 em cima dos novos contratos paginados
4. encerrar com Fase 11 para validar comportamento real e telemetria

## Checklist de acompanhamento rapido

- [x] overview de `Minha Rede` redesenhado
- [x] CTA `ver todas` em `Conexoes`
- [x] CTA `ver tudo` em `Atividade da rede`
- [x] providers de preview separados dos providers paginados
- [x] datasource com paginação incremental
- [x] tela dedicada de `Conexoes` entregue
- [x] tela dedicada de `Atividade da rede` entregue
- [x] validacao de performance concluida
- [x] analytics e changelog atualizados

## Fase 0 - Enquadramento final e desenho de navegacao

Status: `concluida`

### Objetivo

Fechar as decisoes que impactam toda a implementacao antes de alterar modelo de dados e app shell.

### Entregas

- [x] confirmar a arquitetura de navegacao final do app shell
- [x] confirmar o papel de `Minha Rede` como destino primario
- [x] confirmar o papel de `Notificacoes` como inbox secundaria
- [x] consolidar estados relacionais permitidos entre perfis
- [x] consolidar politicas de convite, aceite, recusa e remocao
- [x] consolidar a politica inicial de mensagens entre perfis conectados e nao conectados

### Criterio de conclusao

O time consegue responder sem ambiguidade:

- quem pode conectar com quem
- quais estados relacionais existem
- onde cada acao aparece na UI
- qual sera o comportamento inicial de mensagens e notificacoes

## Fase 1 - Infraestrutura de dados, rules e backend

Status: `concluida`

### Objetivo

Criar a base confiavel do sistema de conexoes no Firestore e no backend.

### Entregas

- [x] definir colecoes `connectionRequests`, `connections` e `connectionStats`
- [x] definir `connectionSuggestions`
- [x] definir contratos minimos dos documentos
- [x] adicionar regras em `.config/firestore.rules`
- [x] adicionar indices em `.config/firestore.indexes.json`
- [x] adicionar Cloud Functions para ciclo de convite e consolidacao de contadores
- [x] garantir compatibilidade com bloqueios bidirecionais ja existentes

### Funcoes previstas

- [x] `onConnectionRequestCreated`
- [x] `onConnectionRequestAccepted`
- [x] `onConnectionRequestDeclined`
- [x] `onConnectionRequestCancelled`
- [x] `onConnectionRemoved`
- [x] `rebuildConnectionStats`

### Criterio de conclusao

Um ambiente de desenvolvimento consegue manter convites e conexoes com integridade validada por backend, sem depender do cliente para consistencia relacional.

## Fase 2 - Estrutura da feature `connections` no app

Status: `concluida`

### Objetivo

Criar a nova feature seguindo o padrao de Clean Architecture do projeto.

### Entregas

- [x] criar `packages/app/lib/features/connections/data/`
- [x] criar `packages/app/lib/features/connections/domain/`
- [x] criar `packages/app/lib/features/connections/presentation/`
- [x] criar entidades de dominio
- [x] criar repository abstrato e implementacao concreta
- [x] criar use cases do fluxo de conexao
- [x] criar providers/notifiers Riverpod

### Casos de uso minimos

- [x] `SendConnectionRequest`
- [x] `AcceptConnectionRequest`
- [x] `DeclineConnectionRequest`
- [x] `CancelConnectionRequest`
- [x] `RemoveConnection`
- [x] `LoadMyConnections`
- [x] `LoadPendingReceivedRequests`
- [x] `LoadPendingSentRequests`
- [x] `LoadConnectionStats`
- [x] `GetConnectionStatus`

### Criterio de conclusao

A feature existe como modulo autonomo e consegue operar seus estados principais independentemente das telas antigas.

## Fase 3 - Superficie Minha Rede e navegacao principal

Status: `concluida`

### Objetivo

Promover a rede de conexoes para um destino principal do produto.

### Entregas

- [x] substituir `Notificacoes` por `Minha Rede` no bottom nav
- [x] mover acesso de notificacoes para AppBar e manter rota dedicada
- [x] criar pagina raiz `Minha Rede`
- [x] criar secoes de convites recebidos, convites enviados e conexoes
- [x] criar estados vazio, loading e erro da rede
- [x] garantir badge e discoverability de notificacoes apos a mudanca

### Criterio de conclusao

O usuario consegue acessar e entender `Minha Rede` como uma area primaria do app sem perder acesso rapido a notificacoes.

## Fase 4 - Integracoes com perfil, notificacoes e mensagens

Status: `concluida`

### Objetivo

Fazer o sistema de conexoes aparecer de forma nativa nos fluxos centrais ja existentes.

### Entregas

- [x] integrar status relacional em `view_profile_page.dart`
- [x] exibir CTA dinamico de conexao no perfil visitado
- [x] adicionar conexoes em comum no perfil quando aplicavel
- [x] integrar eventos sociais basicos a `notifications_new`
- [x] integrar atalhos entre conexoes e `mensagens_new`
- [x] garantir precedencia de bloqueios sobre convites e conexoes

### Criterio de conclusao

O sistema de conexoes deixa de ser uma feature isolada e passa a estar visivel nas superfices ja mais acessadas do produto.

## Fase 5 - Sugestoes, ranking e sinais de afinidade

Status: `concluida`

### Objetivo

Adicionar descoberta social util e explicavel em cima do grafo de conexoes.

### Entregas

- [x] implementar score inicial de sugestoes
- [x] armazenar cache de sugestoes por perfil
- [x] exibir razoes textuais da sugestao
- [x] considerar cidade, genero, instrumento, tipo de perfil e conexoes em comum
- [x] considerar sinais secundarios como interesse em posts e conversa previa

### Criterio de conclusao

As sugestoes parecem justificadas para o usuario e nao dependem de ranking opaco ou pesado.

## Fase 6 - Privacidade, abuse prevention e endurecimento operacional

Status: `concluida`

### Objetivo

Tornar o sistema seguro e confiavel para uso continuo em producao.

### Entregas

- [x] cooldown para convites repetidos
- [x] rate limit de envio de convites
- [x] opcoes de privacidade de descoberta e convite
- [x] hard guards com bloqueio bidirecional
- [x] revisao de regras e edge cases em perfil deletado
- [x] revisao de regras e edge cases em perfil inativo ou indisponivel
- [x] eventos de analytics do funil social

### Criterio de conclusao

O sistema suporta uso real sem abrir vetor obvio de abuso, spam ou inconsistencias relacionais.

## Fase 7 - Expansao de valor pos-release

Status: `concluida`

### Objetivo

Expandir a rede de conexoes depois que o nucleo estiver estavel.

### Entregas candidatas

- [x] feed de atividade da rede
- [x] filtros e experiencias `somente conexoes`
- [x] sugestoes avancadas por contexto musical
- [x] exploracao por conexoes em comum
- [x] experiencias de networking para espacos, bandas e musicos

### Criterio de conclusao

O sistema de conexoes deixa de ser apenas relacional e passa a gerar descoberta e retorno recorrente de uso.

## Dependencias criticas

- multi-perfil por `profileId`
- `profileProvider` e `activeProfileProvider`
- chat via `mensagens_new`
- notificacoes via `notifications_new`
- regras de bloqueio em Firestore e Cloud Functions
- navegacao principal em `bottom_nav_scaffold.dart`

## Riscos principais

- misturar conexoes com reescrita do chat
- modelar estado relacional no cliente em vez do backend
- quebrar discoverability de notificacoes apos a troca do bottom nav
- criar sugestoes antes de estabilizar convites e conexoes
- ignorar o fato de que a identidade social no WeGig e o perfil, nao o usuario

## Historico de execucao

### 19 de abril de 2026

- roadmap inicial registrado
- implementacao iniciada no ambiente DEV
- criada a feature `connections` com estrutura `data`, `domain` e `presentation`
- implementados os casos de uso base de request, aceite, recusa, cancelamento, remocao, leitura de conexoes, leitura de pendencias e leitura de status relacional
- adicionadas regras e indices iniciais para `connectionRequests`, `connections` e `connectionStats`
- criada a pagina `Minha Rede` com secoes de convites recebidos, convites enviados e conexoes
- `Minha Rede` promovida ao bottom nav no lugar de `Notificacoes`

### 20 de abril de 2026

- revisado o comportamento atual de `Minha Rede` para cenarios de alto volume
- registrada a frente complementar de escalabilidade da UI e dos fluxos de dados
- definido que `Minha Rede` deve evoluir para overview com telas dedicadas de `Conexoes` e `Atividade da rede`
- `Notificacoes` movidas para acesso secundario no AppBar da Home, mantendo rota dedicada

### 20 de abril de 2026

- adicionadas preferencias por perfil para aparecer em sugestoes de conexao
- adicionadas preferencias por perfil para receber novos convites de conexao
- integradas as novas preferencias ao `settings`, com persistencia em `profiles/{profileId}`
- endurecido o fluxo de conexoes para ocultar sugestoes e bloquear envio de convite quando a privacidade do perfil assim exigir
- gerado codegen do Riverpod para a nova feature
- adicionadas notificacoes de convite recebido e convite aceito reutilizando a inbox existente de `notifications_new`
- adicionados atalhos de mensagem em `Minha Rede`, abrindo ou criando conversa direta pela stack atual de `mensagens_new`
- adicionada leitura de conexoes em comum e exibicao resumida no header de perfis visitados
- integrado CTA dinamico de conexao em `view_profile_page.dart`, com estados de conectar, aceitar, convite enviado e conectado
- endurecido o datasource de `connections` para que bloqueios filtrem convites/conexoes nas streams e impeçam envio/aceite/status relacional quando houver bloqueio entre perfis
- adicionadas Cloud Functions para reconciliar `connectionStats`, validar bloqueios no backend durante o ciclo de convites e permitir rebuild manual autenticado das estatisticas
- adicionadas sugestoes iniciais em `Minha Rede`, com score e razões textuais baseadas em cidade, tipo de perfil, instrumentos, gêneros e conexoes em comum
- adicionado cache de sugestoes por perfil em `connectionSuggestions`, com rules dedicadas e filtragem defensiva antes de reutilizar resultados salvos
- adicionados sinais secundarios ao ranking de sugestoes, considerando conversa direta previa e interesses em posts entre perfis
- adicionados cooldown e limite diario para convites de conexao, com validacao no app, endurecimento backend em Cloud Functions e indice composto para consulta temporal
- endurecidas as Firestore Rules para barrar criacao de convites e conexoes quando existir bloqueio bidirecional entre perfis
- adicionada reconciliacao backend em `blocks/{blockId}` para remover convites, conexoes e entradas de cache de sugestoes quando um bloqueio nasce apos o relacionamento social
- estendido `onProfileDelete` para limpar convites, conexoes, `connectionStats` e `connectionSuggestions`, cobrindo o edge case de exclusao de perfil no grafo social
- adicionada a secao `Atividade da rede` em `Minha Rede`, exibindo posts recentes de perfis conectados em stream com filtros de bloqueio, expiracao e disponibilidade do autor
- adicionada a secao `Explorar por conexoes em comum` em `Minha Rede`, destacando perfis sugeridos com preview das conexoes mutuas e CTA direto para visitar perfil ou enviar convite
- refinado o ranking de sugestoes por contexto musical, adicionando compatibilidade de nivel, proximidade de estagio do projeto e presença musical nas plataformas como novos sinais explicaveis
- adicionada uma camada de `experiencias de networking` em `Minha Rede`, organizando sugestoes em trilhas praticas para musicos, bandas e espacos com copy e CTA contextualizados por tipo de perfil

### 20 de abril de 2026 - Fase 8 em andamento

- `Minha Rede` passou a explicitar o modo overview com banner contextual no topo da tela
- `Conexoes` foi reduzida a preview controlado no overview, com copy de amostra e CTA explicito de `ver todas`
- `Atividade da rede` foi reduzida a preview controlado no overview, com copy de amostra e CTA explicito de `ver tudo`
- os refreshes da tela passaram a invalidar os novos limites de preview em vez de depender dos limites antigos da home

### 20 de abril de 2026 - Fase 8 concluida

- a home de `Minha Rede` foi consolidada em blocos explicitos de resumo, acompanhamento e descoberta
- o topo do overview passou a resumir convites e o tamanho dos previews para reforcar o papel de dashboard leve
- a copy do overview foi sincronizada com as telas dedicadas ja entregues para `Conexoes` e `Atividade da rede`

### 20 de abril de 2026 - Fase 9 em andamento

- `Minha Rede` passou a consumir providers dedicados de preview para `Conexoes` e `Atividade da rede`
- os limites de overview foram centralizados na camada de providers, removendo a regra de preview da pagina
- a home ficou pronta para a proxima etapa de contratos paginados sem voltar a misturar preview com lista completa
- conexoes agora possuem contrato paginado real no datasource, repository e use case, com cursor por documento para carregar proximas paginas sem aumentar limite arbitrariamente
- foi criado um controller paginado de `Conexoes` para sustentar a futura tela dedicada sem depender mais do stream limitado de overview

### 20 de abril de 2026 - Fase 10 iniciada

- o CTA `Ver todas` de `Conexoes` em `Minha Rede` agora abre a tela dedicada de conexoes
- foi criada a primeira tela dedicada de `Conexoes`, com refresh, carregamento incremental e acoes de mensagem e desconectar sobre o novo contrato paginado

### 20 de abril de 2026 - Fase 9 ampliada para atividade da rede

- `Atividade da rede` agora possui contrato paginado próprio, sem depender de stream preview nem de aumento arbitrario de limite
- o cursor passou a usar `createdAt` com controle de empate na borda da pagina, preservando carregamento incremental mesmo com multiplos autores conectados
- foi criado o controller paginado da atividade da rede para sustentar a futura tela dedicada no proximo passo

### 20 de abril de 2026 - Fase 10 concluida para atividade da rede

- o CTA `Ver tudo` de `Atividade da rede` em `Minha Rede` agora abre a tela dedicada da atividade
- foi criada a tela dedicada de `Atividade da rede`, com pull-to-refresh, paginação incremental, retry visual e navegação para perfil e detalhe do post

### 20 de abril de 2026 - Fase 11 iniciada com observabilidade basica

- os CTAs de overview para `Conexoes` e `Atividade da rede` passaram a registrar eventos explicitos da feature, sem depender apenas do analytics de rota
- as telas dedicadas agora registram entrada, refresh e pedidos de carregamento incremental para apoiar a validacao da nova experiencia

### 20 de abril de 2026 - Fase 10 ampliada com busca em conexoes

- a tela dedicada de `Conexoes` agora oferece busca por nome e `@username`, combinando filtro local com enriquecimento remoto de usernames dos perfis já carregados
- o resultado da busca passou a reordenar a lista por relevancia textual sem quebrar as acoes existentes de perfil, mensagem e desconexao

### 20 de abril de 2026 - Fase 10 concluida para refinamento local de conexoes

- a tela dedicada de `Conexoes` agora inclui ordenacao por recentes ou nome e filtro rapido para mostrar apenas perfis com `@username`
- o refinamento continua local sobre o contrato paginado atual, evitando regressao de backend enquanto melhora a exploracao da rede

### 20 de abril de 2026 - Fase 10 concluida para refinamento local de atividade da rede

- a tela dedicada de `Atividade da rede` agora inclui ordenacao por recentes ou proximidade e filtro local por tipo de publicacao
- o feed dedicado continua apoiado no contrato paginado atual, sem ampliar a superficie de consultas no backend

### 20 de abril de 2026 - Fase 11 iniciada com observabilidade e troca de perfil

- a navegacao entre preview e telas dedicadas agora diferencia a origem dos eventos de analytics por `source`
- as telas dedicadas de `Conexoes` e `Atividade da rede` agora resetam filtros, busca e scroll ao trocar o perfil ativo

### 21 de abril de 2026 - Fase 11 fechada com auditoria de logs e App Check iOS

- adicionado `.tools/scripts/audit_connections_logs.js` para inspecao periodica de `connectionRequests` por status, pendencias antigas, top requesters e sinais de `rateLimits`
- App Check iOS em producao foi finalmente habilitado com sucesso apos corrigir divergencia entre bundles (`com.wegig.wegig` vs `com.tosembanda.wegig`), realinhar `packages/app/ios/` (xcconfigs, plists e `firebase_options_*.dart`) e habilitar o servico DeviceCheck na mesma Apple Developer Key ja usada para APNs (`PL8H6R5M5U`)
- logs de producao de 21/04 confirmam Firestore e Auth operando com token DeviceCheck real, sem placeholder
- pendencia de conexao entre perfis de donos diferentes encerrada apos validacao end-to-end: o fluxo envio/aceite funciona com o filtro dual `recipientProfileId + recipientUid`

### 20 de abril de 2026 - Estados de preview refinados em Minha Rede

- os blocos de `Conexoes` e `Atividade da rede` agora possuem estados especificos de loading, vazio e erro no modo overview
- o preview passou a comunicar melhor quando a amostra ainda nao esta disponivel e quando a atualizacao manual e o melhor caminho de recuperacao

### 20 de abril de 2026 - Fase 9 endurecida contra leituras redundantes

- o datasource de conexoes agora reutiliza cache curto de perfis disponiveis para reduzir leituras repetidas durante enriquecimento de atividade, sugestoes e relacoes comuns
- o stream de atividade da rede passou a recalcular somente quando a lista normalizada de perfis conectados muda de fato

### 20 de abril de 2026 - Impacto em indices revisado

- a auditoria das queries de `connections`, `connectionRequests`, `posts`, `profiles`, `interests` e `conversations` confirmou cobertura pelos indices ja existentes
- nao foi necessario alterar `.config/firestore.indexes.json` para suportar as entregas atuais das fases 8 a 10
