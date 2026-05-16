# Auditoria de Documentação Legada

Data: 20 de abril de 2026.

Objetivo: classificar o conteúdo de `docs/legacy/` e `docs/Old/` para reduzir duplicidade documental sem perder histórico útil.

## Critérios usados

- `KEEP_HISTORICAL`: manter como registro técnico ou operacional de um ponto no tempo.
- `CONSOLIDATE_INTO_CANONICAL`: conteúdo ainda útil, mas que deve migrar para documentação canônica.
- `DELETE_AFTER_ARCHIVE`: documento operacional pontual ou snapshot obsoleto que pode sair após confirmação simples.

## Classificação por arquivo

| Arquivo                                              | Classificação                | Ação recomendada                                                                            | Observação                                                                  |
| ---------------------------------------------------- | ---------------------------- | ------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| `docs/legacy/CLEANUP_LEGACY_FINAL.md`                | `KEEP_HISTORICAL`            | Mover futuramente para `docs/sessions/` ou manter arquivado com contexto temporal           | Checklist histórico de limpeza estrutural; útil como trilha de decisão.     |
| `docs/legacy/DEBUG_INTERESTED_USERS.md`              | `KEEP_HISTORICAL`            | Consolidar cópia limpa em `docs/troubleshooting/`                                           | Investigação de bug bem delimitada e reutilizável como troubleshooting.     |
| `docs/legacy/DELETAR_POSTS.md`                       | `DELETE_AFTER_ARCHIVE`       | Confirmar se a operação já foi executada; depois remover                                    | Procedimento pontual de saneamento de dados, sem valor contínuo alto.       |
| `docs/legacy/EDIT_POST_UI_IMPROVEMENTS.md`           | `CONSOLIDATE_INTO_CANONICAL` | Extrair o que ainda for válido para `docs/design/` ou documentação da feature post          | Mistura decisões visuais e progresso de implementação.                      |
| `docs/legacy/FIRESTORE_INDEXES_REQUIRED.md`          | `CONSOLIDATE_INTO_CANONICAL` | Validar cobertura pelos documentos atuais de Firestore e remover depois                     | Lista antiga e parcial de índices; não deve continuar como fonte principal. |
| `docs/legacy/FIRESTORE_INDEXES_REVIEW_2025-11-29.md` | `KEEP_HISTORICAL`            | Preservar como revisão datada e, se necessário, referenciar a fonte viva atual              | Registro técnico valioso, mas temporal.                                     |
| `docs/legacy/IMPROVEMENTS_DOCUMENTATION.md`          | `CONSOLIDATE_INTO_CANONICAL` | Quebrar por domínio em design, acessibilidade e profile                                     | Documento guarda-chuva, com alta duplicidade e baixa governança.            |
| `docs/legacy/MULTIPLE_PROFILES_IMPROVEMENTS.md`      | `DELETE_AFTER_ARCHIVE`       | Remover após confirmar que `MULTIPLE_PROFILES_IMPROVEMENTS_V2.md` o substitui integralmente | Versão intermediária redundante.                                            |
| `docs/legacy/MULTIPLE_PROFILES_IMPROVEMENTS_V2.md`   | `CONSOLIDATE_INTO_CANONICAL` | Migrar para `docs/features/` ou documentação próxima da feature profile                     | Conteúdo ainda relevante, mas no lugar errado.                              |
| `docs/legacy/NOTIFICATION_SYSTEM_STATUS.md`          | `DELETE_AFTER_ARCHIVE`       | Confirmar se existe fonte viva equivalente; remover se estiver congelado                    | Snapshot de status com alto risco de obsolescência.                         |
| `docs/legacy/PROBLEMA_COORDENADAS.md`                | `KEEP_HISTORICAL`            | Consolidar cópia limpa em `docs/troubleshooting/`                                           | Boa investigação de causa raiz, com valor histórico real.                   |

## Síntese

- Total revisado em `docs/legacy/`: 11 arquivos.
- Manter como histórico: 4 arquivos.
- Consolidar em documentação canônica: 4 arquivos.
- Remover após arquivo/confirmação: 3 arquivos.
- `docs/Old/` não contém documentação útil neste momento; o conteúdo observado é apenas metadado local do macOS.

## Ordem de execução recomendada

1. Promover primeiro o que tem valor recorrente para `docs/troubleshooting/`, `docs/design/` e `docs/features/`.
2. Preservar snapshots técnicos datados em `docs/audits/` ou `docs/sessions/`, sem tratá-los como fonte viva.
3. Remover apenas os documentos classificados como `DELETE_AFTER_ARCHIVE` depois de uma checagem curta no código ou no histórico.

## Decisão operacional desta revisão

- Nenhum documento legado foi movido ou apagado nesta etapa.
- A revisão cria uma baseline para uma limpeza posterior, sem risco de perda acidental de contexto.
- O item presente em `docs/Old/` foi tratado como ruído local, não como artefato de histórico.

## Execução realizada em 19 de abril de 2026

### Documentos promovidos para fonte canônica

- `docs/troubleshooting/INTERESTED_USERS_SECTION.md`
- `docs/troubleshooting/MAP_DISTANCE_FILTER.md`
- `docs/features/MULTIPLE_PROFILES_IMPLEMENTATION.md`
- `docs/design/POST_UI_SYSTEM.md`

### Documentos removidos de `docs/legacy/`

- `DELETAR_POSTS.md`
- `EDIT_POST_UI_IMPROVEMENTS.md`
- `FIRESTORE_INDEXES_REQUIRED.md`
- `IMPROVEMENTS_DOCUMENTATION.md`
- `MULTIPLE_PROFILES_IMPROVEMENTS.md`
- `MULTIPLE_PROFILES_IMPROVEMENTS_V2.md`
- `NOTIFICATION_SYSTEM_STATUS.md`

### Estado após execução

- `docs/legacy/` fica reduzido aos documentos com valor histórico direto.
- Os itens removidos estavam cobertos por documentação canônica nova, pelo código atual ou por fontes operacionais mais confiáveis.
