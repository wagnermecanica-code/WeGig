#!/bin/bash

# Script executado APÓS Flutter gerar flutter_export_environment.sh
# Corrige o problema das aspas aninhadas

ENV_FILE="${SRCROOT}/Flutter/flutter_export_environment.sh"

if [ ! -f "$ENV_FILE" ]; then
    echo "❌ flutter_export_environment.sh não encontrado"
    exit 0
fi

echo "🔧 Corrigindo FLUTTER_TARGET em $ENV_FILE..."

# Detectar qual flavor está sendo usado baseado na configuração
if [[ "$CONFIGURATION" == *"dev"* ]]; then
    TARGET="lib/main_dev.dart"
    echo "📱 Flavor: DEV"
elif [[ "$CONFIGURATION" == *"staging"* ]]; then
    TARGET="lib/main_staging.dart"
    echo "📱 Flavor: STAGING"
else
    TARGET="lib/main_prod.dart"
    echo "📱 Flavor: PRODUCTION"
fi

# Substituir a linha com problema
# De: export "FLUTTER_TARGET="lib/main.dart"
# Para: export "FLUTTER_TARGET=lib/main_dev.dart"

sed -i '' 's|export "FLUTTER_TARGET=".*"|export "FLUTTER_TARGET='$TARGET'"|g' "$ENV_FILE"

echo "✅ FLUTTER_TARGET configurado para: $TARGET"
cat "$ENV_FILE" | grep FLUTTER_TARGET
