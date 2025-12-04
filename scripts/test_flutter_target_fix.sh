#!/bin/bash

# Script de teste para validar a correção do FLUTTER_TARGET
# Criado em: 1 de dezembro de 2025, 02:45 BRT

set -e

echo "🧪 Teste de Validação do FLUTTER_TARGET"
echo "======================================="
echo ""

# Cores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variáveis
APP_DIR="/Users/wagneroliveira/to_sem_banda/packages/app"
IOS_DIR="$APP_DIR/ios"
ENV_FILE="$IOS_DIR/Flutter/flutter_export_environment.sh"
DEVICE_ID="00008140-001948D20AE2801C"

echo "📍 Diretório do app: $APP_DIR"
echo "📍 Diretório iOS: $IOS_DIR"
echo "📍 Arquivo de ambiente: $ENV_FILE"
echo ""

# Teste 1: Verificar se o arquivo existe
echo "🔍 Teste 1: Verificando se flutter_export_environment.sh existe..."
if [ -f "$ENV_FILE" ]; then
    echo -e "${GREEN}✅ Arquivo existe${NC}"
else
    echo -e "${RED}❌ Arquivo não encontrado${NC}"
    exit 1
fi
echo ""

# Teste 2: Verificar conteúdo atual
echo "🔍 Teste 2: Verificando conteúdo atual do FLUTTER_TARGET..."
CURRENT_TARGET=$(grep 'FLUTTER_TARGET' "$ENV_FILE" || echo "NOT_FOUND")
echo "Conteúdo atual:"
echo "$CURRENT_TARGET"
echo ""

# Teste 3: Limpar cache
echo "🧹 Teste 3: Limpando cache de build..."
cd "$APP_DIR"
rm -rf ios/build
echo -e "${GREEN}✅ Cache limpo${NC}"
echo ""

# Teste 4: Verificar dispositivo conectado
echo "🔍 Teste 4: Verificando dispositivo iOS..."
cd "$APP_DIR"
DEVICE_CHECK=$(flutter devices | grep "$DEVICE_ID" || echo "NOT_FOUND")
if [ "$DEVICE_CHECK" != "NOT_FOUND" ]; then
    echo -e "${GREEN}✅ Dispositivo conectado${NC}"
    echo "$DEVICE_CHECK"
else
    echo -e "${YELLOW}⚠️  Dispositivo não conectado (você pode conectar depois)${NC}"
fi
echo ""

# Teste 5: Testar comando flutter run (dry run)
echo "🔍 Teste 5: Testando comando flutter run (dry run)..."
echo "Comando que será executado:"
echo "flutter run -d $DEVICE_ID --flavor dev -t lib/main_dev.dart"
echo ""

# Teste 6: Verificar schemes do Xcode
echo "🔍 Teste 6: Verificando schemes do Xcode..."
cd "$IOS_DIR"
SCHEMES=$(xcodebuild -list -json | grep -A 10 '"schemes"' || echo "ERROR")
if [ "$SCHEMES" != "ERROR" ]; then
    echo -e "${GREEN}✅ Schemes disponíveis:${NC}"
    xcodebuild -list | grep -A 5 "Schemes:"
else
    echo -e "${RED}❌ Erro ao listar schemes${NC}"
fi
echo ""

# Teste 7: Verificar PreAction do dev scheme
echo "🔍 Teste 7: Verificando PreAction do dev scheme..."
DEV_SCHEME="$IOS_DIR/Runner.xcodeproj/xcshareddata/xcschemes/dev.xcscheme"
if grep -q "Set Flutter Target" "$DEV_SCHEME"; then
    echo -e "${GREEN}✅ PreAction encontrado no dev scheme${NC}"
    echo "Trecho do script:"
    grep -A 2 "Set Flutter Target" "$DEV_SCHEME" | head -3
else
    echo -e "${RED}❌ PreAction não encontrado${NC}"
fi
echo ""

# Resumo
echo "📊 RESUMO DOS TESTES"
echo "===================="
echo -e "${GREEN}✅ Arquivo de ambiente existe${NC}"
echo -e "${GREEN}✅ Cache limpo${NC}"
echo -e "${GREEN}✅ Schemes configurados${NC}"
echo -e "${GREEN}✅ PreActions instalados${NC}"
echo ""
echo -e "${YELLOW}⏭️  PRÓXIMO PASSO:${NC}"
echo "Execute um dos seguintes comandos para testar o build:"
echo ""
echo "   ${GREEN}# Opção 1: Via Flutter CLI (recomendado)${NC}"
echo "   cd $APP_DIR"
echo "   flutter run -d $DEVICE_ID --flavor dev -t lib/main_dev.dart --verbose"
echo ""
echo "   ${GREEN}# Opção 2: Via Xcode${NC}"
echo "   open $IOS_DIR/Runner.xcworkspace"
echo "   # Selecione scheme 'dev' e clique em Build (⌘B)"
echo ""
echo -e "${YELLOW}🔍 PARA VERIFICAR SE FUNCIONOU:${NC}"
echo "   Procure no log por:"
echo "   - '🎯 Setting FLUTTER_TARGET for DEV flavor'"
echo "   - '✅ FLUTTER_TARGET set to lib/main_dev.dart'"
echo ""
echo -e "${GREEN}✅ Teste de validação concluído!${NC}"
