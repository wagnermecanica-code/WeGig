# Session 20 - Documentation Baseline Consolidation

**Data:** 19 de abril de 2026  
**Objetivo:** alinhar o MVP, os índices de documentação e o histórico do repositório a uma baseline única e coerente.

## Motivação

Os documentos centrais do projeto estavam divergindo entre si:

- o MVP raiz já refletia marcos de 2026
- o resumo do MVP e o checklist ainda estavam presos a marcos de 2025
- os índices de documentação continham contagens e referências desatualizadas
- o README principal apontava para arquivos inexistentes e mantinha histórico vencido

## Arquivos atualizados

- `MVP_Rev0.0.md`
- `README.md`
- `docs/README.md`
- `docs/project-info/MVP_DESCRIPTION.md`
- `docs/guides/MVP_CHECKLIST.md`
- `docs/project-info/DOCUMENTATION_INDEX.md`
- `docs/changelog/CHANGELOG.md`

## Decisões tomadas

### 1. Definir documentos canônicos

Foi estabelecida a seguinte hierarquia:

1. `README.md` para operação do repositório
2. `MVP_Rev0.0.md` para visão macro do produto
3. `docs/project-info/MVP_DESCRIPTION.md` para resumo executivo atual
4. `docs/guides/MVP_CHECKLIST.md` para baseline e lacunas
5. `docs/changelog/CHANGELOG.md` para histórico incremental

### 2. Evitar contagens frágeis

Índices que dependiam de contagem manual de arquivos foram simplificados. A intenção é reduzir manutenção cosmética e focar em navegação estável.

### 3. Registrar baseline do app

Foi documentada a baseline atual do repositório:

- versão do app: `1.0.14+19`
- baseline de build local: Flutter `3.38.1`, Dart `3.10.0`
- monorepo com `packages/app` e `packages/core_ui`

## Resultado esperado

- menos contradição entre README, MVP e documentação auxiliar
- ponto de entrada claro para novos ciclos de desenvolvimento
- melhor rastreabilidade para futuras mudanças de produto

## Próximos passos sugeridos

- criar release notes formais quando a versão `1.0.14+19` tiver marco de distribuição fechado
- revisar documentos antigos por lote, migrando o que ainda for útil para categorias canônicas
- manter changelog e checklist como primeira atualização obrigatória em mudanças de escopo
