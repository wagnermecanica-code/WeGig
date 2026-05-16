# WeGig - MVP Description

**Versão documental:** 2.1  
**Data de atualização:** 21 de abril de 2026  
**Versão do app:** 1.0.15+20  
**Status:** baseline funcional consolidada para continuidade de desenvolvimento

## Objetivo

Este documento resume o estado atual do MVP do WeGig de forma executiva. Ele substitui descrições antigas focadas em marcos de 2025 e serve como referência curta para produto, arquitetura e escopo operacional.

## Resumo do produto

WeGig é uma plataforma social mobile voltada ao ecossistema musical local. O aplicativo conecta músicos, bandas e espaços musicais por meio de descoberta geográfica, publicações temporárias, conexões por perfil, troca de mensagens em tempo real e notificações relacionadas a interesse, proximidade, atividade de conversa e eventos sociais da rede.

O modelo central do produto é multi-perfil: uma mesma conta pode administrar perfis distintos, com identidade, histórico e contexto próprios.

## Escopo atual do MVP

### Perfis suportados

- `musician`: perfil individual de músico
- `band`: perfil de banda ou projeto musical
- `space`: perfil de espaço ou negócio musical

### Postagens suportadas

- `musician`: músico buscando banda, projeto ou colaboração
- `band`: banda buscando integrante
- `sales`: divulgação de serviços, promoções e ofertas de espaços
- `hiring`: oportunidades de trabalho, eventos e contratações

### Capacidades principais

- autenticação por Firebase com fluxo guiado por perfis
- múltiplos perfis por conta com troca de perfil e isolamento de contexto
- feed e mapa com filtros geográficos
- posts com expiração e mídia
- Minha Rede como hub social com convites, conexões, sugestões e atividade da rede
- badge social de Minha Rede integrado à navegação principal e ao seletor de perfis
- chat em tempo real entre perfis
- notificações de interesse, mensagens e proximidade
- notificações sociais para convites e aceite de conexão
- preferências por perfil para aparecer em sugestões e receber convites de conexão
- backend com Firestore, Storage e Cloud Functions

## Baseline técnica

| Item                 | Estado documentado                           |
| -------------------- | -------------------------------------------- |
| Repositório          | Monorepo Melos                               |
| App principal        | `packages/app`                               |
| Shared layer         | `packages/core_ui`                           |
| Ambientes            | DEV, STAGING, PROD                           |
| Backend              | Firebase Auth, Firestore, Storage, Functions |
| Mapa                 | `google_maps_flutter` via fork local         |
| Build baseline       | Flutter 3.38.1 / Dart 3.10.0                 |
| Versionamento do app | 1.0.15+20                                    |

## Documentos canônicos relacionados

- `MVP_Rev0.0.md`: especificação macro do MVP
- `README.md`: visão operacional do repositório
- `docs/guides/MVP_CHECKLIST.md`: checklist de prontidão atual
- `docs/changelog/CHANGELOG.md`: histórico incremental de mudanças
- `docs/project-info/DOCUMENTATION_INDEX.md`: mapa da documentação técnica

## Diretriz de manutenção

Sempre que o escopo do MVP mudar, atualize nesta ordem:

1. `docs/changelog/CHANGELOG.md`
2. `docs/guides/MVP_CHECKLIST.md`
3. `docs/project-info/MVP_DESCRIPTION.md`
4. `MVP_Rev0.0.md` quando a mudança alterar a visão macro do produto
5. `docs/project-info/DOCUMENTATION_INDEX.md` e `docs/README.md` se houver novos artefatos
6. `.github/copilot-instructions.md` quando a mudança alterar convenções úteis para a IA de desenvolvimento

## Observação histórica

Documentos anteriores ainda podem conter referências úteis sobre marcos de migração, auditorias e rollout de 2025. Eles continuam válidos como histórico, mas a leitura atual deve partir deste resumo e dos documentos canônicos listados acima.
