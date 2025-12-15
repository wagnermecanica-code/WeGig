#!/bin/bash

# Script para copiar GoogleService-Info correto para PROD
echo "🔧 Configurando Firebase para PROD flavor..."

# Definir caminhos
PROJECT_DIR="${SRCROOT}"
FIREBASE_DIR="${PROJECT_DIR}/Firebase"
PLIST_PROD="${FIREBASE_DIR}/GoogleService-Info-prod.plist"
PLIST_TARGET="${PROJECT_DIR}/WeGig/GoogleService-Info.plist"

# Copiar arquivo correto
if [ -f "$PLIST_PROD" ]; then
    cp "$PLIST_PROD" "$PLIST_TARGET"
    echo "✅ GoogleService-Info-prod.plist copiado com sucesso"
else
    echo "❌ ERRO: $PLIST_PROD não encontrado!"
    exit 1
fi
