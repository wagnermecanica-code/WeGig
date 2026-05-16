# Session 21 - Stage Closure and Documentation Sync

**Data:** 21 de abril de 2026  
**Objetivo:** encerrar a etapa atual de desenvolvimento alinhando app, site público, documentação canônica e instruções da IA.

## Escopo consolidado

Esta sessão registra o fechamento da etapa em que `Conexões / Minha Rede` deixou de ser apenas uma feature em implementação e passou a orientar:

- a superfície social principal do app
- as preferências por perfil relacionadas à rede
- a comunicação institucional do site
- a documentação usada por pessoas e pela IA de desenvolvimento

## O que foi considerado baseline nesta etapa

### App

- `Minha Rede` consolidada como hub social principal no bottom nav
- badge social dedicado na navegação principal
- badge unificado no seletor de perfis somando notificações, mensagens e rede
- preferências por perfil para aparecer em sugestões e receber convites
- limpeza de cache compartilhado de bloqueios ao trocar o perfil ativo
- padronização de loading com `AppRadioPulseLoader` nas superfícies principais

### Site público

- cards e copy do site atualizados para refletir `Conexões` e `Minha Rede`
- publicação automatizada de `docs/` via GitHub Pages
- refinamentos visuais e cache-busting para garantir propagação da nova versão

### Documentação e IA

- atualização dos documentos canônicos de produto e operação
- atualização dos índices de navegação documental
- revisão de `.github/copilot-instructions.md` para refletir as convenções atuais do repositório

## Arquivos de referência desta etapa

- `README.md`
- `MVP_Rev0.0.md`
- `docs/project-info/MVP_DESCRIPTION.md`
- `docs/guides/MVP_CHECKLIST.md`
- `docs/changelog/CHANGELOG.md`
- `docs/README.md`
- `docs/project-info/DOCUMENTATION_INDEX.md`
- `.github/copilot-instructions.md`

## Decisões tomadas

### 1. IA também é documentação operacional

As instruções em `.github/copilot-instructions.md` passam a ser tratadas como artefato de manutenção obrigatória quando o fluxo principal do produto ou as convenções técnicas mudarem.

### 2. O estado social do produto precisa aparecer em todos os pontos de entrada

Não basta o código refletir `Minha Rede`. README, resumo do MVP, checklist, changelog, índices e site institucional precisam comunicar a mesma direção de produto.

### 3. Histórico incremental deve registrar fechamento de etapa, não apenas features isoladas

Além do changelog, esta sessão existe para explicar o recorte do fechamento: app, site, documentação e IA foram ajustados no mesmo ciclo porque fazem parte da mesma entrega percebida.

## Resultado esperado

- menos divergência entre o comportamento atual do app e o que a documentação afirma
- melhor contexto para novas sessões de desenvolvimento
- menor chance de a IA propor mudanças desalinhadas com o fluxo social atual do produto

## Próximo critério de atualização

Na próxima etapa que alterar fluxo social, convenções de build, estratégia de publicação do site ou contratos operacionais da IA, atualizar primeiro:

1. `docs/changelog/CHANGELOG.md`
2. `docs/guides/MVP_CHECKLIST.md`
3. `docs/project-info/MVP_DESCRIPTION.md`
4. `.github/copilot-instructions.md`
5. esta pasta `docs/sessions/` quando a mudança caracterizar um novo marco
