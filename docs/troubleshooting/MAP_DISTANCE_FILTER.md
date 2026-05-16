# Troubleshooting - Pins do Mapa e Filtro de Distância

Data de consolidação: 19 de abril de 2026.

Objetivo: registrar a causa raiz já identificada para o caso em que posts existem, mas os pins não aparecem no mapa.

## Diagnóstico consolidado

O problema investigado não estava nas coordenadas dos posts, mas no filtro de distância aplicado no cliente.

## Causa raiz

- simuladores iOS podem iniciar em Cupertino, Califórnia
- os posts testados estavam em cidades brasileiras
- com filtro padrão restritivo, todos os resultados eram descartados antes da renderização

Na investigação histórica, a distância entre origem do simulador e destino real tornava os posts invisíveis mesmo com `GeoPoint` correto.

## Sinais de que é o mesmo problema

- logs mostram posts sendo processados, mas nenhum marker fica visível
- o `GeoPoint` do documento parece plausível para a cidade do post
- o mapa está centrado em localidade muito distante do conjunto de posts de teste

## Como verificar rapidamente

1. Confirmar a localização atual do dispositivo ou simulador.
2. Comparar com a cidade dos posts carregados.
3. Validar o raio de distância aplicado antes da renderização.
4. Conferir se o post continua visível ao ampliar temporariamente o alcance.

## Ação recomendada

Para ambientes de desenvolvimento e testes amplos, usar um raio padrão compatível com o cenário de teste ou explicitar claramente o filtro ativo para o usuário.

## Decisão de manutenção

- O documento legado original foi preservado como trilha de investigação.
- Esta versão consolidada é a referência atual para diagnosticar ausência de pins por filtro de distância.
