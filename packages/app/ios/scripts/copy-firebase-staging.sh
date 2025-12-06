#!/bin/bash

# Script para copiar GoogleService-Info correto para STAGING
echo "🔧 Configurando Firebase para STAGING flavor..."

# Definir caminhos
PROJECT_DIR="${SRCROOT}"
FIREBASE_DIR="${PROJECT_DIR}/Firebase"
PLIST_STAGING="${FIREBASE_DIR}/GoogleService-Info-staging.plist"
PLIST_TARGET="${PROJECT_DIR}/WeGig/GoogleService-Info.plist"

# Copiar arquivo correto
if [ -f "$PLIST_STAGING" ]; then
    cp "$PLIST_STAGING" "$PLIST_TARGET"
    echo "✅ GoogleService-Info-staging.plist copiado com sucesso"
else
    echo "❌ ERRO: $PLIST_STAGING não encontrado!"
    exit 1
fi
