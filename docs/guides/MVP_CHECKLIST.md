# WeGig - MVP Checklist

**Atualizado em:** 21 de abril de 2026  
**Versão do app:** 1.0.15+20  
**Objetivo:** registrar o estado atual do MVP e deixar claro o que é baseline consolidada versus o que ainda depende de validação operacional.

## Critérios de baseline

### Produto

- [x] Proposta de valor documentada para músicos, bandas e espaços
- [x] Tipos de perfil consolidados: `musician`, `band`, `space`
- [x] Tipos de post consolidados: `musician`, `band`, `sales`, `hiring`
- [x] Fluxo principal de autenticação e criação de perfil documentado
- [x] Descoberta geográfica por feed e mapa documentada
- [x] Camada social por perfil com Minha Rede e conexões documentada
- [x] Controles de privacidade de conexões por perfil documentados
- [x] Mensageria em tempo real documentada
- [x] Notificações e automações principais documentadas

### Arquitetura e código

- [x] Monorepo Melos documentado
- [x] Separação `packages/app` e `packages/core_ui` documentada
- [x] Padrão de feature-first com Clean Architecture documentado
- [x] Fluxo de providers Riverpod e cadeia datasource -> repository -> use case documentado
- [x] Ambientes DEV, STAGING e PROD documentados
- [x] Dependência de Firebase e Cloud Functions documentada
- [x] Collections e fluxos centrais de conexões documentados
- [x] Loader visual padronizado documentado nas convenções do app
- [x] Fork local de `google_maps_flutter` documentado para operação do repositório

### Operação

- [x] Versão atual do app registrada (`1.0.15+20`)
- [x] Baseline local de build registrada (Flutter 3.38.1 / Dart 3.10.0)
- [x] Comandos críticos de bootstrap, build e deploy documentados
- [x] Histórico incremental mantido em changelog
- [x] Sessão de consolidação documental registrada
- [x] Instruções da IA atualizadas para o estado atual do repositório
- [x] Site público alinhado à proposta atual de Conexões e Minha Rede

### Histórico e governança documental

- [x] Documento macro do MVP atualizado
- [x] Resumo executivo do MVP atualizado
- [x] Índices de documentação atualizados
- [x] README principal apontando para documentos válidos
- [x] Changelog registrando a atualização documental
- [x] Baseline documental reflete Conexões e Minha Rede

## Itens que exigem validação contínua

- [ ] Confirmar status de publicação atual nas lojas antes de qualquer comunicação externa
- [ ] Registrar release notes formais quando a versão `1.0.15+20` tiver marco de distribuição fechado
- [ ] Revisar contagens voláteis de testes, índices e funções sempre a partir de evidência atual, sem manter números fixos em documentos centrais
- [ ] Validar continuamente cooldown, limites e observabilidade da feature de conexões conforme evolução operacional

## Fonte de verdade por assunto

| Assunto                    | Documento principal                                    |
| -------------------------- | ------------------------------------------------------ |
| Visão macro do MVP         | `MVP_Rev0.0.md`                                        |
| Resumo executivo           | `docs/project-info/MVP_DESCRIPTION.md`                 |
| Histórico incremental      | `docs/changelog/CHANGELOG.md`                          |
| Navegação da documentação  | `docs/project-info/DOCUMENTATION_INDEX.md`             |
| Contexto desta atualização | `docs/sessions/SESSION_21_STAGE_CLOSURE_2026-04-21.md` |

## Regra de atualização

Se uma entrega alterar escopo, arquitetura, rollout ou marcos do produto, este checklist deve ser revisado no mesmo ciclo para evitar nova divergência entre MVP, README e changelog.
