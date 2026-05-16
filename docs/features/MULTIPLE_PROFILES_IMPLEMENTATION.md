# Implementação - Múltiplos Perfis

Data de consolidação: 19 de abril de 2026.

Objetivo: registrar o baseline funcional do sistema de múltiplos perfis sem depender dos documentos legados intermediários.

## Capacidades esperadas

- criação de mais de um perfil por conta
- troca explícita do perfil ativo
- edição de perfis existentes
- exclusão com validações de segurança
- isolamento de contexto entre perfis

## Regras funcionais

- o perfil principal não deve ser excluído
- a conta não deve ficar sem nenhum perfil válido
- a troca de perfil deve invalidar caches e refletir o novo contexto ativo
- fluxos dependentes do perfil ativo devem usar a camada atual de providers e navegação do app

## Referências atuais do projeto

- `packages/app/lib/features/profile/presentation/providers/profile_switcher_provider.dart`
- `packages/app/lib/features/profile/presentation/`
- `docs/guides/GUIA_RAPIDO_PERFIS.md`

## Notas de consolidação

Os documentos legados sobre múltiplos perfis registravam uma fase anterior baseada em `ProfileService` e em widgets da estrutura antiga.

O que continua válido e foi preservado aqui:

- necessidade de um ponto central para troca de perfil ativo
- validações de exclusão
- retorno consistente do identificador do perfil após operações de criação ou edição
- feedback visual claro ao usuário ao trocar de contexto

O que não deve mais ser tratado como fonte principal:

- caminhos antigos em `lib/pages/` e `lib/services/`
- detalhes de implementação desacoplados da arquitetura por feature atual

## Decisão de manutenção

- este arquivo passa a ser a referência canônica resumida para o tema
- detalhes operacionais para uso rápido continuam em `docs/guides/GUIA_RAPIDO_PERFIS.md`
