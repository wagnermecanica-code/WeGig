# Índice de Documentação Técnica WeGig

Este documento organiza a documentação do projeto por finalidade e identifica quais arquivos devem ser tratados como referência principal.

## Documentos canônicos

- `README.md`: visão operacional do repositório
- `MVP_Rev0.0.md`: especificação macro do MVP
- `docs/project-info/MVP_DESCRIPTION.md`: resumo executivo atual do produto
- `docs/guides/MVP_CHECKLIST.md`: checklist de baseline e prontidão
- `docs/changelog/CHANGELOG.md`: histórico incremental de mudanças

## Estrutura por categoria

### `/sessions/`

Registro cronológico de sessões relevantes de desenvolvimento, migração e consolidação documental.

### `/architecture/`

Documentos de arquitetura, migração técnica e padrões estruturais.

### `/guides/`

Guias operacionais e tutoriais para setup, fluxo de desenvolvimento e uso das features.

### `/features/`

Documentação funcional por feature. Para múltiplos perfis, usar `docs/features/MULTIPLE_PROFILES_IMPLEMENTATION.md` como referência resumida.

### `/reports/`

Relatórios de progresso, auditorias de status e resumos de execução.

### `/deployment/`

Instruções de deploy e operação de backend.

### `/setup/`

Configuração inicial de ambiente, flavors, deep links e dependências críticas.

### `/security/`

Documentação de segurança, checklists e auditorias.

### `/project-info/`

Documentos estruturantes do projeto, organização do repositório e visão de produto.

### `/sprints/`

Marcos por sprint, relatórios de conclusão e entregas agrupadas.

### `/tasks/`

Backlog operacional, checklists de teste e listas de trabalho.

### `/fix-reports/`

Relatórios de correções aplicadas, causas raiz e validações.

### `/legacy/` e `/Old/`

Histórico antigo mantido apenas para consulta. Não usar como fonte principal sem checar os documentos canônicos. A classificação mais recente está em `docs/audits/LEGACY_DOCUMENTATION_AUDIT_2026-04-20.md`.

## Ordem recomendada de leitura

1. `README.md`
2. `MVP_Rev0.0.md`
3. `docs/project-info/MVP_DESCRIPTION.md`
4. `docs/guides/MVP_CHECKLIST.md`
5. Documentos específicos da área em que você vai atuar
6. Para troubleshooting recorrente, priorize `docs/troubleshooting/INTERESTED_USERS_SECTION.md` e `docs/troubleshooting/MAP_DISTANCE_FILTER.md`
7. Para acompanhar a implementação do sistema de conexões, use `docs/tasks/CONNECTIONS_IMPLEMENTATION_ROADMAP_2026-04-19.md`
8. Para o fechamento desta etapa e a sincronização entre app, site e documentação da IA, use `docs/sessions/SESSION_21_STAGE_CLOSURE_2026-04-21.md`

## Regras de manutenção

- Evite hardcode de contagens de arquivos e métricas voláteis neste índice.
- Sempre que um documento novo alterar fluxo de leitura, atualize este arquivo e `docs/README.md`.
- Para registrar mudanças de documentação com impacto histórico, crie também uma entrada em `docs/changelog/CHANGELOG.md` e, quando fizer sentido, uma nota em `/sessions/`.
- Quando revisar `docs/legacy/`, registre a decisão de manter, consolidar ou remover em `docs/audits/` antes de apagar qualquer arquivo.

## Última atualização

21 de abril de 2026, durante o fechamento da etapa de Conexões, site público e sincronização documental.
