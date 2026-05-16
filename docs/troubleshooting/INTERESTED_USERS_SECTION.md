# Troubleshooting - Seção de Interessados

Data de consolidação: 19 de abril de 2026.

Objetivo: registrar o comportamento esperado e o fluxo de diagnóstico quando a seção de interessados não aparece na tela de detalhe do post.

## Comportamento esperado

A seção de interessados só deve aparecer quando existe pelo menos um interesse registrado para o post.

- Aparece: quando 1 ou mais perfis demonstraram interesse.
- Não aparece: quando a lista de interessados está vazia.

Esse comportamento evita exibir um bloco vazio na UI.

## Sintomas comuns

### A seção não aparece, mas não há erro

Causa provável: ainda não existe interesse registrado para o post.

### A seção não aparece e há erro ao carregar interesses

Causas prováveis:

- índice ausente para consultas em `interests`
- regra de segurança bloqueando leitura
- documentos órfãos apontando para perfis inexistentes
- erro silencioso em carregamento assíncrono

## Checklist de diagnóstico

1. Confirmar se existe ao menos um documento em `interests` para o `postId` afetado.
2. Confirmar se os perfis referenciados por `interestedProfileId` ainda existem em `profiles`.
3. Validar os índices atuais do Firestore em `.config/firestore.indexes.json`.
4. Validar regras de leitura da coleção `interests` em `.config/firestore.rules`.
5. Revisar logs de carregamento da tela de detalhe do post.

## Logs úteis

Quando o problema reaparecer, os logs mais úteis são:

- início do carregamento para um `postId`
- quantidade de interesses retornados
- ids de perfis carregados
- quantidade final de perfis resolvidos

Se o carregamento ficar preso, vale rodar a app com logs mais verbosos e filtrar por `interessados` ou pelo identificador da tela.

## Decisão de manutenção

- O documento legado original foi preservado apenas como histórico técnico.
- Esta versão consolidada passa a ser a referência rápida para troubleshooting.
