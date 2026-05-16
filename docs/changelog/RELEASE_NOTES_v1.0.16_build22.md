# Release Notes - WeGig 1.0.16 (Build 22)

Data: 16/05/2026
Plataformas: Android e iOS

## Destaques

- Correções de estabilidade em login, perfil, feed, imagens, Crashlytics e mapa.
- Melhorias na experiência de `Minha Rede` e `Sugestões`, com filtros mais consistentes e cards ajustados para Android.
- Preparação de versionamento para novo envio às lojas: `1.0.16+22`.

## Correções

- Corrigido fechamento do diálogo de recuperação de senha na tela de login.
- Evitado uso de imagens locais temporárias quando o arquivo já não existe.
- Preservada foto remota existente quando um caminho local inválido é encontrado no perfil.
- Evitado precache de imagens com caminhos locais inválidos no feed.
- Reduzido ruído do Crashlytics para falhas conhecidas de imagem/cache.
- Adicionadas proteções de lifecycle em fluxos assíncronos do feed.
- Mitigado risco de instabilidade de layout do Google Maps no Android.
- Corrigidos filtros e paginação da tela de sugestões de conexões.
- Ajustados cards de sugestões para evitar overflow visual no Android.

## Validação Recomendada

- Smoke test Android em produção/flavor `prod`.
- Smoke test iOS via Xcode/TestFlight, sem build iOS completo automático nesta preparação.
- Conferir login, recuperação de senha, edição de perfil com foto, feed com imagens, Home/mapa e tela de sugestões.
