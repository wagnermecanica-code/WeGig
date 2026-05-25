# WeGig - PRD, MVP Scope e Technical Architecture

**Data:** 25 de maio de 2026  
**Status:** nova versão consolidada com funcionalidades implementadas entre 15 e 25 de maio de 2026  
**Produto:** WeGig  
**Plataformas:** iOS, Android, site público e plataforma administrativa web  
**Documento relacionado:** `MVP_Rev0.0.md`, `docs/project-info/MVP_DESCRIPTION.md`, `docs/guides/MVP_CHECKLIST.md`, `docs/project-info/PRD_MVP_SCOPE_TECH_ARCHITECTURE_2026-05-17.md`

> Esta versão também incorpora a análise de esforço de engenharia necessária para reproduzir um produto com escopo semelhante ao WeGig, para servir como referência executiva e técnica do investimento já aplicado no desenvolvimento.

## 1. Visão Geral do Produto

WeGig é uma plataforma de networking musical local com superfície principal mobile e camadas web complementares para descoberta pública e operação administrativa. O produto conecta músicos, bandas, espaços musicais, técnicos e contratantes por meio de perfis profissionais, feed social, busca por localização, publicação de oportunidades, comentários, conexões sociais e conversa direta.

O aplicativo resolve a fragmentação atual do mercado musical independente: oportunidades aparecem em grupos de WhatsApp, perfis de Instagram, indicações informais e contatos dispersos. Esses canais funcionam para comunicação, mas não estruturam descoberta, reputação, filtros profissionais, localização, histórico de relacionamento e recorrência.

### Nome do projeto

WeGig.

### Problema que resolve

Músicos e contratantes têm dificuldade para se encontrar com velocidade, contexto e confiança. Bandas buscam integrantes, músicos buscam projetos, espaços divulgam serviços, contratantes precisam preencher oportunidades e a maior parte dessa dinâmica acontece em canais pouco organizados.

### Público-alvo

O MVP atende principalmente músicos, bandas, espaços musicais, técnicos do mercado musical e contratantes. Em ciclos posteriores, o produto expande a superfície para produtores, igrejas, casas de show, estúdios e outros negócios musicais.

### Diferencial principal

O diferencial do WeGig é combinar rede social, perfil musical, geolocalização e oportunidades em um mesmo ambiente verticalizado para música. Em vez de adaptar Instagram, WhatsApp ou marketplaces genéricos, o usuário encontra pessoas, projetos e gigs usando critérios próprios do mercado musical.

### Objetivo do MVP

Validar se uma rede social verticalizada para música consegue gerar descoberta local, engajamento recorrente e conversas qualificadas entre perfis musicais. O MVP deve provar que usuários criam perfis, publicam necessidades reais, encontram pessoas próximas e iniciam contatos dentro do app.

Além da definição funcional do produto, este PRD passa a registrar formalmente uma referência de esforço de engenharia para o WeGig, permitindo usar o próprio MVP como base de comparação de escopo, complexidade e investimento técnico acumulado.

### Declaração resumida

Plataforma de networking e oportunidades para músicos, bandas, espaços musicais, técnicos e contratantes, com app mobile como núcleo de criação de valor, site público para descoberta e distribuição web, e painel administrativo para moderação, analytics e operação.

### Atualizações implementadas no último mês

Esta versão incorpora as funcionalidades efetivamente implementadas no ciclo mais recente, com destaque para app, site e plataforma administrativa.

#### App mobile

- Lançamento da camada social `Minha Rede`, com convites, solicitações, sugestões de conexão e atividade social.
- Fluxos completos de conexão entre perfis, com preferências de privacidade escopadas ao perfil.
- Evolução do sistema de comentários e notificações relacionadas a comentários.
- Enriquecimento de tipos e dados de perfil, inclusive refinamento de tipos de perfil e campos profissionais.
- Melhorias em roteamento por notificação push, estados de loading, estabilidade e resiliência.
- Hardening de qualidade de dados com sanitização UTF-16, ajustes de snackbars e reforço do filtro de conteúdo ofensivo.

#### Site público

- Feed web com maior volume de posts ativos visíveis.
- Exibição correta de posts de contratação e venda em cards e mapa.
- Página de compartilhamento com preview (`share.html`) para distribuição de links.
- Publicação do dashboard administrativo em `wegig.com.br/admin` como superfície web operacional separada.

#### Plataforma administrativa

- Reescrita em TypeScript com estrutura mais próxima de Clean Architecture.
- RBAC, autenticação administrativa, guardas de rota e auditoria operacional.
- Dashboard executivo com indicadores consolidados.
- Analytics avançado, heatmap musical, reputação, feed admin e exportação XLSX.
- Moderação expandida para reports, comentários, catálogo e feedbacks.
- Aba de Crashlytics com indicadores de estabilidade, versões/plataformas afetadas, relatório exportável e métricas de crash-free users/sessions.
- Gestão de usuários com listagem completa, pesquisa por username, detalhe expandido, métricas de atividade e ação de reset de senha.

#### Infraestrutura, segurança e publicação

- Ajustes de regras e índices do Firestore para leitura administrativa autorizada e collection group de comentários.
- Publicação contínua do admin em GitHub Pages/hosting da documentação.
- Consolidação de artefatos de Crashlytics no repositório documental para apoio operacional.

## 2. Problema de Mercado

O mercado musical local é altamente relacional, mas pouco estruturado digitalmente. A descoberta de oportunidades depende de grupos fechados, indicação pessoal, publicações efêmeras em redes sociais e contatos fragmentados.

Músicos têm dificuldade de:

- encontrar gigs compatíveis com instrumento, estilo, disponibilidade e região;
- montar ou completar bandas;
- encontrar substitutos para apresentações urgentes;
- divulgar trabalho com contexto profissional;
- manter networking local fora de grupos informais;
- encontrar estúdios, casas de show, luthiers, escolas e serviços próximos;
- separar identidade pessoal de identidade musical ou de projetos diferentes.

Contratantes e espaços musicais têm dificuldade de:

- encontrar músicos rapidamente por instrumento, estilo e cidade;
- avaliar disponibilidade e adequação mínima antes do contato;
- divulgar oportunidades para uma audiência musical qualificada;
- manter histórico de conversas e interesses;
- operar fora de planilhas, grupos e listas manuais.

Instagram e WhatsApp são canais importantes, mas não são estruturados para matching profissional musical. Eles não oferecem filtros por instrumento, gênero musical, localização, tipo de perfil, disponibilidade, tipo de gig ou relacionamento entre perfis.

## 3. Público-Alvo (ICP)

### Segmentos prioritários do MVP

| Segmento                | Necessidade principal                                | Valor esperado                              |
| ----------------------- | ---------------------------------------------------- | ------------------------------------------- |
| Músicos freelancers     | Encontrar gigs, bandas e contatos locais             | Mais oportunidades e networking qualificado |
| Bandas                  | Encontrar integrantes e divulgar projetos            | Recrutamento musical mais rápido            |
| Espaços musicais        | Divulgar serviços, vagas e oportunidades             | Visibilidade local para público musical     |
| Técnicos                | Oferecer serviços técnicos e encontrar demanda local | Mais contratos e recorrência operacional    |
| Contratantes de eventos | Encontrar músicos e bandas para demandas específicas | Redução de tempo de busca                   |

### Segmentos adjacentes

- DJs;
- produtores musicais;
- casas de show;
- igrejas;
- estúdios;
- escolas de música;
- luthiers e lojas de instrumentos;
- produtores e organizadores de eventos.

### ICP inicial recomendado

O ICP inicial deve priorizar músicos e bandas em uma região urbana com densidade musical suficiente para efeito de rede local. A adoção inicial tende a ser maior em usuários que já participam de grupos de música, publicam conteúdo em redes sociais e buscam gigs ou colaborações com frequência.

### Perfil demográfico e comportamental

| Critério                  | Hipótese inicial                                                                 |
| ------------------------- | -------------------------------------------------------------------------------- |
| Idade média               | 18 a 45 anos                                                                     |
| Região inicial            | Uma cidade ou região metropolitana por ciclo beta                                |
| Nível profissional        | Amador avançado, semi-profissional e profissional independente                   |
| Comportamento digital     | Uso frequente de Instagram, WhatsApp, YouTube, TikTok e plataformas de streaming |
| Frequência de necessidade | Busca recorrente por contatos, projetos, serviços, ensaios, substituições e gigs |

## 4. Proposta de Valor

### Para músicos

- Conseguir gigs e oportunidades de colaboração.
- Criar um perfil musical com identidade própria.
- Encontrar músicos, bandas e espaços próximos.
- Divulgar trabalho com foto, bio, instrumentos, estilos e links.
- Receber mensagens e interesses de outros perfis musicais.
- Manter conexões profissionais separadas de redes pessoais.

### Para bandas

- Encontrar integrantes por instrumento, cidade e estilo.
- Publicar necessidades de formação ou contratação.
- Centralizar contatos com interessados.
- Manter presença pública do projeto.

### Para espaços musicais e negócios do setor

- Divulgar serviços, promoções, vagas, eventos e disponibilidade.
- Aparecer em buscas locais feitas por músicos.
- Receber contatos de perfis qualificados.
- Construir audiência dentro de uma comunidade musical verticalizada.

### Para técnicos

- Divulgar serviços como som, luz, produção, roadie, backline e operação técnica.
- Encontrar bandas, músicos, espaços e contratantes com demanda real.
- Construir reputação profissional em um contexto musical especializado.
- Participar da rede sem precisar se encaixar artificialmente como músico ou espaço.

### Para contratantes

- Encontrar músicos rapidamente.
- Filtrar por instrumento, localidade e estilo.
- Publicar oportunidades com descrição, cidade, data e orçamento.
- Iniciar conversas com interessados sem depender de múltiplos canais externos.

## 5. Escopo do MVP

O MVP deve focar nas funções que validam networking, descoberta local, engajamento social e demanda real por oportunidades musicais. Na evolução recente, o produto passou a operar em três superfícies complementares: app mobile, site público e plataforma administrativa. O núcleo funcional permanece concentrado em sete pilares:

1. Perfil musical.
2. Feed.
3. Busca e localização.
4. Publicação de gigs e oportunidades.
5. Chat.
6. Camada social de conexões.
7. Operação e observabilidade administrativas.

### Entra no MVP

- Autenticação por email, Google e Apple.
- Criação e edição de perfil musical.
- Suporte a múltiplos perfis por conta, com perfis de músico, banda, espaço, técnico e contratante.
- Feed com posts simples, mídia e expiração.
- Publicações de oportunidade, contratação, busca de músico/banda e anúncios de espaço.
- Busca ou descoberta por localização, instrumento, gênero e tipo de perfil/post.
- Interesse em posts e início de conversa.
- Chat básico entre perfis.
- Notificações essenciais de interesse, mensagem e atividade relevante.
- Comentários em posts e notificações associadas quando aplicável.
- Minha Rede com conexões, solicitações, sugestões e atividade social.
- Denúncia e bloqueio como camadas mínimas de segurança social.
- Analytics, crash reporting e métricas de funil.
- Site público para descoberta web de posts ativos e compartilhamento.
- Painel administrativo para moderação, analytics e operação do ecossistema.

### Não entra no MVP

- Marketplace transacional completo.
- Pagamentos, wallet, split, escrow ou repasse financeiro.
- Streaming de música nativo.
- IA avançada de matching.
- Videochamada.
- Lives.
- Monetização complexa.
- Assinaturas premium.
- Agenda integrada completa.
- Ranking público complexo.
- CRM para contratantes.
- Sistema de reputação com reviews públicos detalhados.

### Referência de esforço aplicada ao MVP

Este documento passa a incluir, como parte do MVP, uma referência de esforço de engenharia para o desenvolvimento do WeGig. O objetivo não é inflar escopo, mas registrar uma base concreta para estimar custo, prazo e complexidade de um produto com paridade funcional semelhante.

Resumo executivo da referência:

- estimativa realista para recriar um produto semelhante: `4.420 a 7.280 horas`;
- estimativa central recomendada para planejamento: `5.400 horas`;
- referência executiva conservadora para comunicação: `5.500 horas`;
- P80 aproximado: `6.600 horas`.

Essa referência deve ser interpretada como esforço acumulado de engenharia para um produto production-ready com app mobile, backend Firebase, regras, índices, funções serverless, observabilidade, dashboard administrativo, testes e documentação operacional mínima.

## 6. Funcionalidades do MVP (Core Features)

### V1 obrigatório

#### Cadastro e login

- Email e senha.
- Google Sign-In.
- Apple ID no iOS.
- Recuperação de senha.
- Sessão persistente.
- Fluxo obrigatório de criação de perfil após autenticação.

#### Perfil musical

- Foto.
- Nome artístico, nome da banda, nome do espaço, nome técnico/profissional ou nome do contratante.
- Bio curta.
- Tipo de perfil: músico, banda, espaço, técnico ou contratante.
- Instrumentos.
- Estilos musicais.
- Cidade e localização.
- Links externos, como Instagram, YouTube, Spotify, SoundCloud ou portfólio.
- Troca de perfil quando a conta possuir múltiplos perfis.

##### Tipos de perfil suportados no app

- `Músico`: perfil individual para instrumentistas, cantores, DJs e artistas que buscam gigs, projetos, networking e visibilidade profissional.
- `Banda`: perfil coletivo para grupos musicais que precisam divulgar projeto, recrutar integrantes, publicar necessidades e centralizar contatos.
- `Espaço`: perfil para estúdios, escolas, bares, casas de show, lojas, produtoras, luthierias e outros negócios/locais do ecossistema musical.
- `Técnico`: perfil para profissionais de suporte e operação, como técnicos de som, luz, produtores técnicos, roadies e funções correlatas.
- `Contratante`: perfil para quem busca músicos, bandas, técnicos ou serviços para eventos, projetos, celebrações e demandas recorrentes.

#### Feed social

- Lista de posts recentes e válidos.
- Posts com texto e mídia.
- Tipos de post para músico, banda, contratação e anúncio.
- Curtidas ou interesse, conforme o tipo de post.
- Comentários quando disponíveis no ciclo atual.
- Detalhe do post.
- Expiração automática para reduzir conteúdo obsoleto.

#### Busca e localização

- Filtros por cidade ou raio.
- Filtros por instrumento.
- Filtros por gênero musical.
- Filtros por tipo de perfil ou tipo de post.
- Visualização em lista e/ou mapa, conforme disponibilidade do app.

#### Match, interesse e gig

- Criar oportunidade de contratação.
- Informar descrição, cidade, data, orçamento ou cachê quando aplicável.
- Candidatar-se ou manifestar interesse.
- Ver interessados no próprio post.
- Iniciar conversa a partir de interesse ou perfil.

#### Chat

- Mensagens privadas entre perfis.
- Lista de conversas.
- Mensagens em tempo real.
- Notificação push de nova mensagem.
- Bloqueio impedindo continuidade de contato indesejado.

#### Conexões e camada social

- Minha Rede como hub social principal.
- Sugestões de conexão por proximidade e afinidade musical.
- Solicitações de conexão e gestão de status da relação.
- Atividade de rede e badges sociais por perfil.
- Preferências de privacidade para permitir sugestões e solicitações de conexão.

#### Notificações push

- Interesse em publicação.
- Nova mensagem.
- Oportunidades próximas ou relevantes.
- Convites e eventos sociais essenciais de rede.

#### Web público e distribuição

- Feed público com posts ativos.
- Renderização web de posts de contratação, venda e demais categorias suportadas.
- Página de compartilhamento com preview para links distribuídos fora do app.

#### Operação administrativa

- Dashboard executivo com métricas resumidas.
- Moderação de reports, comentários, catálogo e feedbacks.
- Analytics avançado com funil, retenção, churn, heatmap e reputação.
- Gestão de usuários com busca, atividade, perfil detalhado e ações operacionais.
- Observabilidade com Crashlytics, crash-free users/sessions e exportação de relatórios.

### V1.1

- Sugestões de conexão por proximidade e afinidade musical.
- Minha Rede como hub social de conexões, convites e atividade.
- Melhorias de filtros, ordenação e paginação em listas.
- Moderação operacional via painel administrativo.
- Preferências de privacidade por perfil.
- Métricas mais detalhadas de funil de oportunidade.
- Feed web público com melhor cobertura de posts ativos e tipologias suportadas.
- Observabilidade operacional com Crashlytics no admin.
- Gestão operacional de usuários e auditoria administrativa.

### Futuro

- Monetização premium.
- Destaque de gigs e perfis patrocinados.
- Matching assistido por IA.
- Reputação, avaliações e histórico de contratação.
- Agenda e disponibilidade.
- Pagamentos e contratos.
- Integrações com calendários e plataformas externas.
- Ferramentas avançadas para casas de show, igrejas, produtoras e contratantes recorrentes.

## 7. Funcionalidades Fora do MVP

Estas funcionalidades devem permanecer fora do MVP para evitar aumento excessivo de prazo, custo e risco técnico:

- marketplace completo;
- streaming de áudio ou vídeo;
- IA de matching avançado;
- videochamada;
- lives;
- monetização complexa;
- assinaturas premium;
- agenda integrada completa;
- wallet, pagamentos, split e escrow;
- contratação com assinatura digital;
- curadoria editorial ampla;
- sistema completo de anúncios self-service;
- ranking público com gamificação;
- ferramentas de produção musical;
- distribuição musical;
- upload de arquivos de áudio pesados como produto principal;
- CRM completo para contratantes.

## 8. Jornada do Usuário (User Flow)

### Fluxo principal do músico

```mermaid
flowchart TD
  A[Baixa o app] --> B[Cria conta]
  B --> C[Cria perfil musical]
  C --> D[Seleciona instrumentos, estilos e localização]
  D --> E[Explora feed e busca]
  E --> F[Encontra oportunidade ou perfil]
  F --> G[Manifesta interesse]
  G --> H[Inicia conversa]
  H --> I[Fecha gig ou conexão fora do app]
```

### Fluxo principal da banda

```mermaid
flowchart TD
  A[Cria perfil de banda] --> B[Publica necessidade]
  B --> C[Recebe interessados]
  C --> D[Avalia perfis]
  D --> E[Conversa no chat]
  E --> F[Marca ensaio ou teste]
```

### Fluxo principal do contratante ou espaço

```mermaid
flowchart TD
  A[Cria perfil de espaço ou contratante] --> B[Publica gig ou serviço]
  B --> C[Recebe interessados]
  C --> D[Filtra por perfil musical]
  D --> E[Conversa com candidatos]
  E --> F[Fecha contratação]
```

## 9. Wireframes / Telas

O MVP não exige design final para validação documental, mas deve ter wireframes low fidelity ou protótipos simples para as telas principais.

### Telas obrigatórias

| Tela            | Objetivo                                                       |
| --------------- | -------------------------------------------------------------- |
| Splash          | Inicialização, validação de sessão e ambiente                  |
| Login/Cadastro  | Entrada do usuário no produto                                  |
| Criar perfil    | Capturar identidade musical mínima                             |
| Home/feed       | Expor publicações e oportunidades recentes                     |
| Perfil          | Exibir identidade, instrumentos, estilos, links e posts        |
| Busca/Mapa      | Descobrir perfis e posts por localização e filtros             |
| Publicar        | Criar post, oportunidade, contratação ou anúncio               |
| Detalhe do post | Concentrar informação e ações de interesse                     |
| Chat            | Permitir conversa direta entre perfis                          |
| Notificações    | Mostrar eventos relevantes e reengajar o usuário               |
| Minha Rede      | Reunir conexões, convites e atividade social quando habilitado |
| Configurações   | Preferências, privacidade, bloqueios e conta                   |

### Superfícies web implementadas

| Tela / superfície   | Objetivo                                                                 |
| ------------------- | ------------------------------------------------------------------------ |
| Site público / feed | Expor posts ativos e descoberta web do ecossistema musical               |
| Share page          | Permitir compartilhamento com preview e deep link para conteúdo do app   |
| Admin / login       | Restringir acesso administrativo por autenticação e papel                |
| Admin / dashboard   | Dar visão executiva de saúde do produto e operação                       |
| Admin / analytics   | Operar indicadores avançados, retenção, churn, cohorts e exportação      |
| Admin / heatmap     | Visualizar concentração territorial de atividade musical                 |
| Admin / feed admin  | Inspecionar e administrar o feed operacionalmente                        |
| Admin / users       | Consultar, buscar e operar perfis/contas                                 |
| Admin / Crashlytics | Monitorar estabilidade, versões afetadas e exportar relatórios de falhas |
| Admin / audit       | Registrar ações administrativas e rastreabilidade operacional            |

### Artefatos recomendados

- Protótipo Figma ou wireframes low fidelity.
- Mapa de navegação do app.
- Fluxo de criação de perfil.
- Fluxo de publicação de gig.
- Fluxo de interesse e chat.
- Estados vazios, loading, erro e permissão negada.

## 10. Arquitetura Técnica (Alto Nível)

### Mobile

O app é desenvolvido em Flutter para iOS e Android, com monorepo Melos e separação entre app principal e biblioteca compartilhada de UI/domínio.

| Item             | Decisão                        |
| ---------------- | ------------------------------ |
| Framework mobile | Flutter                        |
| Linguagem        | Dart                           |
| Plataformas      | iOS e Android                  |
| State management | Riverpod com codegen           |
| Navegação        | GoRouter com extensões tipadas |
| Design system    | `packages/core_ui`             |

### Site público

| Item              | Decisão                                              |
| ----------------- | ---------------------------------------------------- |
| Framework web     | HTML/CSS/JS estático hospedado em `docs/`            |
| Objetivo          | Descoberta pública, feed web e distribuição de links |
| Conteúdo dinâmico | Feed de posts ativos e páginas públicas de apoio     |
| Publicação        | GitHub Pages / hosting estático do domínio           |

### Plataforma administrativa

| Item       | Decisão                                                            |
| ---------- | ------------------------------------------------------------------ |
| Framework  | React + Vite + TypeScript                                          |
| UI         | Tailwind + componentes compartilhados locais                       |
| Segurança  | Firebase Auth + RBAC + Firestore Rules para leitura administrativa |
| Publicação | `docs/admin/` com base `/admin/`                                   |
| Objetivo   | Moderação, analytics, reputação, usuários, auditoria e Crashlytics |

### Backend

| Item                | Decisão                                                               |
| ------------------- | --------------------------------------------------------------------- |
| Autenticação        | Firebase Auth                                                         |
| Banco principal     | Cloud Firestore                                                       |
| Storage de mídia    | Firebase Storage                                                      |
| Funções server-side | Cloud Functions Node.js 20                                            |
| Push notifications  | Firebase Cloud Messaging                                              |
| Crash reporting     | Firebase Crashlytics                                                  |
| Analytics           | Firebase Analytics, com possibilidade futura de Mixpanel ou Amplitude |

### Infraestrutura e ambientes

- Ambientes separados para desenvolvimento, staging e produção.
- Validação de projeto Firebase no bootstrap para evitar cruzamento de dados.
- Regras de segurança no Firestore.
- Índices compostos versionados.
- Cloud Functions na região `southamerica-east1`.
- Cache local e configuração de persistência do Firestore por flavor.

### Arquitetura de software

O app segue Clean Architecture por feature:

```text
packages/app/lib/features/<feature>/
  data/
    datasources/
    models/
    repositories/
  domain/
    entities/
    repositories/
    usecases/
  presentation/
    pages/
    providers/
    widgets/
```

As dependências fluem da apresentação para o domínio e depois para a camada de dados. Providers Riverpod fazem a injeção de dependência e notifiers orquestram estados de UI.

## 11. Estrutura de Dados

### User

```json
{
  "id": "firebase-auth-uid",
  "email": "user@example.com",
  "activeProfileId": "profile-id",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### Profile

```json
{
  "id": "profile-id",
  "uid": "firebase-auth-uid",
  "name": "João Silva",
  "username": "joaoguitar",
  "profileType": "musician",
  "photoUrl": "https://...",
  "bio": "Guitarrista de rock e blues",
  "instruments": ["guitarra"],
  "genres": ["rock", "blues"],
  "location": "GeoPoint",
  "city": "São Paulo",
  "links": ["https://instagram.com/..."],
  "allowConnectionSuggestions": true,
  "allowConnectionRequests": true,
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### Post

```json
{
  "id": "post-id",
  "authorProfileId": "profile-id",
  "type": "hiring",
  "title": "Procuro baixista para show",
  "description": "Show em bar no sábado",
  "mediaUrls": ["https://..."],
  "instruments": ["baixo"],
  "genres": ["rock"],
  "city": "São Paulo",
  "location": "GeoPoint",
  "budget": 500,
  "eventDate": "timestamp",
  "expiresAt": "timestamp",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### Interest

```json
{
  "id": "interest-id",
  "postId": "post-id",
  "postAuthorProfileId": "profile-id",
  "interestedProfileId": "profile-id",
  "status": "pending",
  "createdAt": "timestamp"
}
```

### Conversation

```json
{
  "id": "conversation-id",
  "participantProfileIds": ["profile-a", "profile-b"],
  "lastMessage": "Olá, tenho interesse na gig",
  "lastMessageAt": "timestamp",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### Connection

```json
{
  "id": "connection-id",
  "requesterProfileId": "profile-a",
  "targetProfileId": "profile-b",
  "status": "pending|accepted|declined|blocked",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### Message

```json
{
  "id": "message-id",
  "conversationId": "conversation-id",
  "senderProfileId": "profile-id",
  "text": "Ainda está disponível?",
  "createdAt": "timestamp",
  "readBy": ["profile-id"]
}
```

### Report

```json
{
  "id": "report-id",
  "reporterProfileId": "profile-id",
  "targetType": "post",
  "targetId": "post-id",
  "reason": "spam",
  "description": "Conteúdo repetitivo",
  "status": "open",
  "createdAt": "timestamp"
}
```

## 12. Regras de Negócio

- Uma conta pode ter múltiplos perfis, com limite operacional definido pelo produto.
- Cada perfil possui identidade e contexto próprios.
- Um músico pode ter múltiplos instrumentos.
- Um perfil pode publicar posts de acordo com permissões e tipo de perfil.
- Posts devem ter expiração para reduzir oportunidades obsoletas.
- Posts de contratação devem informar dados mínimos da oportunidade, como descrição e localidade.
- Comentários devem respeitar bloqueios, ownership e regras de moderação.
- Chat deve respeitar bloqueios entre perfis.
- Denúncias devem ser registradas com alvo, motivo e autor.
- Relações sociais devem considerar pedidos pendentes, aceitos, recusados e exclusões por bloqueio.
- Conteúdo de usuário deve passar por filtro de conteúdo ofensivo antes de escrita quando aplicável.
- Upload de mídia deve respeitar limites de tamanho, quantidade e compressão.
- Busca por posts ativos deve filtrar `expiresAt` e ordenar por expiração conforme índices do Firestore.
- Profile switching deve invalidar caches de feed, interesse e contexto social.
- Preferências de privacidade e conexão são escopadas ao perfil, não apenas à conta.
- FCM tokens permanecem vinculados à conta/dispositivo, mesmo com troca de perfil.
- A plataforma administrativa deve operar com RBAC, trilha de auditoria e tolerância a coleções legadas/vazias.

## 13. Estratégia de Monetização

A monetização não deve bloquear a validação do MVP. A primeira fase deve priorizar densidade de rede, recorrência e volume de oportunidades.

### Possibilidades futuras

| Modelo               | Descrição                                           | Momento recomendado                     |
| -------------------- | --------------------------------------------------- | --------------------------------------- |
| Assinatura premium   | Recursos avançados para músicos, bandas e espaços   | Após validação de retenção              |
| Destaque de gigs     | Oportunidades promovidas no feed/busca              | Após volume consistente de posts        |
| Perfil patrocinado   | Maior visibilidade para espaços, bandas ou serviços | Após tráfego local relevante            |
| Anúncios segmentados | Publicidade musical contextual                      | Após base ativa mensurável              |
| Taxa por contratação | Comissão ou fee sobre gigs fechadas                 | Apenas após fluxo transacional maduro   |
| Ferramentas B2B      | Planos para casas, igrejas, estúdios e produtoras   | Após demanda recorrente de contratantes |

## 14. KPIs do MVP

### Aquisição

- Downloads por canal.
- Custo de aquisição por usuário, quando houver mídia paga.
- Taxa de cadastro concluído.
- Taxa de criação de perfil após cadastro.

### Ativação

- Percentual de usuários com perfil completo.
- Tempo até primeira publicação.
- Tempo até primeira busca.
- Tempo até primeiro interesse ou mensagem.

### Engajamento

- Usuários ativos diários e mensais.
- Retenção D1, D7 e D30.
- Posts criados por semana.
- Gigs publicadas por mês.
- Interesses realizados.
- Mensagens enviadas.
- Conversas iniciadas.
- Conexões ou relações sociais criadas, quando habilitado.
- Comentários criados e taxa de posts comentados.

### Qualidade de marketplace/rede

- Taxa de posts com ao menos um interessado.
- Taxa de interesses que viram conversa.
- Taxa de conversas com resposta.
- Tempo médio até primeiro contato.
- Distribuição geográfica de usuários ativos.
- Densidade de perfis por cidade.
- Conversão de sugestão de conexão em relação aceita.

### Operação web e administrativa

- Posts ativos publicados no site público.
- Acessos ao site público e CTR em links compartilhados.
- Tempo de resposta operacional a reports e feedbacks.
- Cobertura de observabilidade do Crashlytics.
- Crash-free users e crash-free sessions.

### Segurança e saúde da comunidade

- Denúncias por mil usuários ativos.
- Tempo médio de resposta a denúncia.
- Bloqueios por mil conversas.
- Conteúdos removidos por violação.

## 15. Roadmap

### Fase 0 - Preparação

- Consolidar PRD, escopo e critérios de sucesso.
- Definir cidade ou região beta.
- Revisar regras de segurança, analytics e moderação.
- Preparar onboarding e comunicação de beta.

### Fase 1 - MVP

- Perfil musical.
- Feed.
- Busca/localização.
- Publicação de gigs e oportunidades.
- Interesse e chat.
- Notificações essenciais.
- Denúncia, bloqueio e privacidade mínima.

### Fase 2 - Beta fechado

- Lançamento controlado em uma cidade ou comunidade musical.
- Convites para músicos, bandas e espaços parceiros.
- Monitoramento de funil e retenção.
- Ajustes de UX e filtros.
- Validação qualitativa com entrevistas.
- Site público em operação para descoberta e compartilhamento.
- Admin dashboard em operação para acompanhamento do beta.

### Fase 3 - V1.1

- Minha Rede e recomendações sociais.
- Melhorias de descoberta e paginação.
- Painel de moderação mais completo.
- Notificações mais contextuais.
- Preparação para primeiras experiências de monetização leve.

### Status atual desta versão

- `Minha Rede`, conexões e atividade social já implementadas.
- Site público com melhorias de feed e share já implementado.
- Plataforma administrativa em produção com dashboard, analytics, moderação, usuários e Crashlytics.
- Observabilidade, auditoria operacional e métricas administrativas já fazem parte do produto entregue.

### Fase 4 - V2

- Monetização.
- Matching avançado.
- Ferramentas para contratantes recorrentes.
- Reputação e avaliações.
- Agenda e disponibilidade.
- Expansão para múltiplas cidades.

## 16. Segurança e Compliance

WeGig é uma rede social com conteúdo gerado por usuários, mensagens privadas e dados de localização. Segurança, privacidade e moderação devem estar presentes desde o MVP.

### LGPD e privacidade

- Coletar apenas dados necessários para a experiência principal.
- Informar finalidade de uso de localização, notificações e perfil público.
- Permitir atualização e exclusão de dados conforme política do produto.
- Manter termos de uso e política de privacidade disponíveis.
- Separar dados de conta e dados de perfil quando possível.

### Moderação

- Denúncia de usuários, posts e mensagens quando aplicável.
- Bloqueio entre perfis.
- Filtro de conteúdo ofensivo no cliente e backstop server-side.
- Painel operacional para revisão de denúncias.
- Painel administrativo com RBAC, trilha de auditoria e restrição por papel.
- Regras claras para remoção de conteúdo.

### Segurança técnica

- Firebase Auth para identidade.
- Regras de Firestore e Storage por ownership e permissões.
- Cloud Functions para rotinas sensíveis e notificações.
- App Check como camada adicional de proteção contra abuso de backend.
- Crashlytics e logs controlados por ambiente.
- Evitar exposição de segredos no app e no repositório.

## 17. Requisitos Não Funcionais

| Categoria        | Requisito                                                                               |
| ---------------- | --------------------------------------------------------------------------------------- |
| Performance      | Telas principais devem carregar rapidamente em redes móveis comuns                      |
| Escalabilidade   | Queries devem usar índices e paginação para listas de feed, busca, mensagens e conexões |
| Disponibilidade  | Backend deve depender de serviços gerenciados com alta disponibilidade                  |
| Resiliência      | App deve lidar com estados offline, timeouts e falhas parciais                          |
| Observabilidade  | Erros críticos devem ir para Crashlytics e eventos-chave para Analytics                 |
| Segurança        | Acesso a dados deve ser validado por regras e ownership                                 |
| Privacidade      | Localização e perfil público devem ter comunicação clara ao usuário                     |
| Manutenibilidade | Features devem seguir Clean Architecture e DI por providers                             |
| Testabilidade    | Regras de domínio devem ser testáveis sem Firebase real                                 |
| Acessibilidade   | Interface deve respeitar contraste, tamanhos de toque e estados compreensíveis          |

## 18. Stack de Analytics

### Dia 1

- Firebase Analytics para eventos de funil e comportamento.
- Firebase Crashlytics para falhas.
- Logs controlados por ambiente.
- Eventos de navegação e autenticação.
- Eventos de criação de perfil, post, interesse, chat e notificação.
- Dashboard administrativo como camada de leitura e operação sobre analytics e estabilidade.
- Exportação operacional de relatórios e planilhas para análises externas.

### Eventos mínimos recomendados

- `sign_up_started`
- `sign_up_completed`
- `profile_created`
- `profile_completed`
- `post_created`
- `post_viewed`
- `interest_sent`
- `conversation_started`
- `message_sent`
- `search_performed`
- `filter_applied`
- `notification_opened`
- `report_submitted`
- `profile_switched`
- `connection_request_sent`
- `connection_request_accepted`
- `comment_created`
- `admin_action_performed`

### Futuro

- Mixpanel ou Amplitude para análise de cohorts e funis avançados.
- BigQuery para análises de marketplace/rede.
- Dashboards por cidade, segmento e fonte de aquisição.

## 19. Critérios de Sucesso do MVP

O MVP será considerado validado se demonstrar que há uso recorrente e criação real de oportunidades entre perfis musicais.

### Critérios quantitativos sugeridos para 6 meses

- 5.000 usuários ativos mensais em uma ou poucas regiões de foco.
- 500 gigs ou oportunidades publicadas por mês.
- 30% ou mais dos novos usuários criando perfil completo.
- 25% ou mais dos posts recebendo ao menos um interesse.
- 40% ou mais dos interesses gerando conversa.
- Retenção D7 suficiente para indicar recorrência semanal de descoberta.
- Tempo médio até primeira ação de valor inferior a 10 minutos após criação de perfil.

### Critérios qualitativos

- Músicos relatam descoberta de pessoas ou oportunidades que não encontrariam facilmente em outros canais.
- Bandas conseguem receber candidatos relevantes.
- Contratantes e espaços conseguem publicar e receber contatos com menos atrito que WhatsApp/Instagram.
- Usuários entendem claramente por que manter o app instalado.

## 20. Estimativa de Desenvolvimento

Esta seção é parte integrante do MVP e deve ser usada como referência formal do esforço técnico necessário para construir e evoluir o WeGig. Ela combina uma visão prospectiva de implementação com uma leitura retrospectiva do esforço já embutido na base atual.

As estimativas abaixo consideram um time enxuto e um produto já orientado por Flutter/Firebase. Devem ser recalibradas conforme estado real do backlog, dívida técnica, qualidade dos designs e necessidade de refatoração.

### Equipe mínima recomendada

| Papel                      | Alocação sugerida |
| -------------------------- | ----------------- |
| Product Manager / Founder  | 0.5 a 1.0 FTE     |
| Flutter developer          | 1 a 2 FTE         |
| Backend/Firebase developer | 0.5 a 1 FTE       |
| Product designer           | 0.5 FTE           |
| QA                         | 0.25 a 0.5 FTE    |
| Growth/Community           | 0.5 FTE no beta   |

### Fases e esforço

| Fase                              | Duração sugerida | Entregas                                                         |
| --------------------------------- | ---------------- | ---------------------------------------------------------------- |
| Descoberta e fechamento de escopo | 1 a 2 semanas    | PRD final, métricas, fluxos e wireframes                         |
| Design e arquitetura detalhada    | 2 a 3 semanas    | Protótipo navegável, modelo de dados, eventos analytics          |
| Implementação MVP                 | 8 a 12 semanas   | Perfil, feed, busca, gigs, chat, notificações e moderação mínima |
| QA e hardening                    | 2 a 4 semanas    | Testes, correções, performance, regras e crash-free baseline     |
| Beta fechado                      | 4 a 8 semanas    | Comunidade inicial, métricas, entrevistas e iteração             |

### Faixa de horas

| Área                          | Estimativa      |
| ----------------------------- | --------------- |
| Produto e especificação       | 40 a 80 horas   |
| UX/UI                         | 80 a 160 horas  |
| Flutter                       | 400 a 800 horas |
| Firebase/Cloud Functions      | 120 a 240 horas |
| QA e testes                   | 120 a 240 horas |
| Analytics, release e operação | 60 a 120 horas  |

### Observação de custo

O custo final varia conforme senioridade, país, profundidade do design, qualidade esperada do beta e quanto da base atual será reaproveitada. Para controle de risco, o MVP não deve incorporar pagamentos, IA avançada, streaming ou marketplace transacional antes de validar densidade de rede e recorrência.

### Referência de esforço aplicado na base atual

Em 23 de maio de 2026 foi feita uma revisão estrutural do repositório para estimar o esforço necessário para recriar, do zero, um clone funcional do app com paridade razoável com a base atual. Esta leitura considera o produto já implementado, incluindo app mobile, backend Firebase, regras de segurança, índices, Cloud Functions, dashboard administrativo, testes e documentação operacional.

Esta análise deve ser considerada parte do artefato de MVP, pois registra não apenas o que o produto faz, mas também a magnitude real do esforço de engenharia necessário para chegar ao nível atual de maturidade.

#### Escopo técnico observado

| Área                 | Evidência na base atual                                                                           |
| -------------------- | ------------------------------------------------------------------------------------------------- |
| Monorepo             | Melos com app Flutter, pacote compartilhado, Functions, dashboard admin, docs e scripts           |
| App mobile           | `packages/app`, com 10 features principais e 248 arquivos Dart em `lib`                           |
| Pacote compartilhado | `packages/core_ui`, com 64 arquivos Dart para UI, tema, entidades, serviços e utilitários         |
| Código Dart manual   | Aproximadamente 86 mil linhas, excluindo arquivos gerados `.g.dart` e `.freezed.dart`             |
| Código gerado        | 50 arquivos gerados por Riverpod, Freezed e JSON serialization                                    |
| Backend serverless   | Cloud Functions Node.js com 18 arquivos JavaScript, cerca de 6 mil linhas e 23 funções exportadas |
| Firestore            | 434 linhas de regras de segurança e 37 índices compostos versionados                              |
| Admin                | Dashboard Vite + React para operação/moderação, com cerca de 643 linhas em `src`                  |
| Testes               | 34 arquivos de teste, com cerca de 6,6 mil linhas                                                 |

#### Distribuição por feature mobile

| Feature               | Arquivos Dart | Linhas aproximadas |
| --------------------- | ------------- | ------------------ |
| Auth                  | 17            | 4.366              |
| Comentários           | 9             | 2.718              |
| Conexões / Minha Rede | 31            | 16.683             |
| Home / mapa / feed    | 31            | 8.578              |
| Mensagens / chat      | 34            | 17.778             |
| Notificações          | 24            | 6.658              |
| Posts                 | 29            | 12.481             |
| Perfil / multi-perfil | 19            | 10.805             |
| Reports               | 3             | 961                |
| Settings              | 9             | 2.169              |

#### Estimativa para criar um clone do zero

Para um clone com paridade funcional razoável, desenvolvido por um engenheiro senior Flutter/Firebase, a estimativa realista fica entre 4.420 e 7.280 horas. A estimativa central para planejamento é de aproximadamente 5.400 horas, com P80 em torno de 6.600 horas.

| Bloco de trabalho                                         | Horas estimadas |
| --------------------------------------------------------- | --------------- |
| Setup monorepo, flavors, Firebase, CI e build nativo      | 160 a 280       |
| Design system, tema e componentes compartilhados          | 160 a 280       |
| Auth, onboarding e multi-perfil                           | 220 a 360       |
| Perfil, edição, troca de perfil, privacidade e bloqueios  | 300 a 500       |
| Posts, mídia, comentários, likes, filtros e cache         | 500 a 800       |
| Home, feed, mapa, geolocalização e markers                | 280 a 480       |
| Minha Rede, conexões, sugestões, atividades e badges      | 450 a 750       |
| Chat em tempo real, read receipts e contador de não lidas | 450 a 750       |
| Notificações push/in-app, badges e preferências           | 350 a 600       |
| Cloud Functions, rate limits, limpeza e triggers sociais  | 400 a 700       |
| Firestore schema, rules, indexes, migrações e segurança   | 180 a 320       |
| Reports, moderação, filtro de conteúdo e App Check        | 180 a 320       |
| Settings, permissões, deep links, share e analytics       | 180 a 320       |
| Admin dashboard básico                                    | 80 a 160        |
| Testes, QA, Crashlytics, hardening e correções de release | 450 a 800       |
| Documentação operacional mínima                           | 80 a 160        |

#### Leitura de calendário

| Configuração de equipe                                   | Tempo aproximado |
| -------------------------------------------------------- | ---------------- |
| 1 engenheiro senior solo, 35 horas produtivas por semana | 31 a 42 meses    |
| 2 engenheiros senior                                     | 16 a 22 meses    |
| 3 engenheiros com boa coordenação                        | 11 a 15 meses    |
| 4 a 5 pessoas incluindo QA, produto, design e backend    | 7 a 11 meses     |

#### Interpretação executiva

O maior custo acumulado do produto não está apenas na interface mobile. A complexidade relevante está na combinação de multi-perfil, bloqueios bidirecionais, badges por perfil, notificações contextuais, chat em tempo real, consultas Firestore com índices corretos, regras de segurança, cache, push tokens, geolocalização, flavors e hardening de release.

Para planejamento financeiro ou avaliação do esforço já aplicado, recomenda-se usar 5.500 horas como número-base para um clone production-ready, adicionando margem de risco de 20% a 25% quando houver incerteza sobre requisitos, qualidade de design, cobertura de QA ou necessidade de refazer integrações nativas.

#### Como usar esta referência no contexto do MVP

- Como base de comparação para propostas comerciais, captação, orçamento ou valuation técnico.
- Como evidência do esforço acumulado já investido no produto além do escopo conceitual do MVP.
- Como parâmetro para discutir prazo de evolução, tamanho de backlog e custo de reimplementação.
- Como insumo executivo para mostrar que o WeGig já ultrapassa um MVP conceitual simples e opera com camadas reais de produto, operação e observabilidade.

## Decisão de Produto Recomendada

O MVP inicial do WeGig deve focar somente em:

1. Perfil musical.
2. Feed.
3. Busca/localização.
4. Publicação de gigs.
5. Chat.

Esse recorte valida os pilares essenciais do negócio: networking, engajamento, efeito de rede local e demanda real por oportunidades musicais. O restante deve ser tratado como expansão após evidência de uso recorrente e conversas qualificadas dentro do app.
