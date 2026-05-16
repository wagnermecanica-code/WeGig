# Sistema de UI - Fluxo de Post

Data de consolidação: 19 de abril de 2026.

Objetivo: concentrar decisões de interface recorrentes do fluxo de criação e edição de posts sem carregar o ruído histórico dos documentos legados.

## Princípios preservados

- agrupar o formulário em seções visuais claras
- destacar validações em tempo real
- manter CTA principal fixo e sempre visível quando fizer sentido
- oferecer feedback imediato para upload, loading e erros
- tratar mídia externa, como YouTube, com pré-visualização segura

## Padrões recomendados para telas de post

### Estrutura visual

- seções em cards ou blocos bem separados
- ícones ou marcadores visuais por categoria do formulário
- hierarquia tipográfica simples e consistente
- espaçamento regular entre grupos de campos

### Feedback de estado

- indicador explícito durante salvamento
- mensagens claras para limites de seleção, por exemplo gêneros e instrumentos
- sinalização quando localização ou mídia ainda não foi validada

### Ação principal

- botão principal destacado
- rótulo objetivo para publicar ou atualizar
- estado de loading no próprio botão

## Consolidação dos legados

Os documentos antigos misturavam decisões úteis de UX com detalhes históricos de branding e implementação já superados.

O que segue útil:

- organização por seções
- feedback de validação no próprio formulário
- preview de mídia quando aplicável
- CTA persistente nas ações críticas

O que foi descartado como referência canônica:

- paleta antiga do período `Tô Sem Banda`
- caminhos de arquivos da arquitetura anterior
- trechos de implementação específicos sem aderência garantida ao código atual

## Decisão de manutenção

- este arquivo substitui os documentos legados de melhorias de UI do fluxo de post como referência resumida
- wireframes amplos e decisões gerais de interface continuam em `docs/design/WIREFRAME.md`
