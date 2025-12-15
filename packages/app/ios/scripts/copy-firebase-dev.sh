#!/bin/bash

# Script para copiar GoogleService-Info correto para DEV
echo "🔧 Configurando Firebase para DEV flavor..."

# Definir caminhos
PROJECT_DIR="${SRCROOT}"
FIREBASE_DIR="${PROJECT_DIR}/Firebase"
PLIST_DEV="${FIREBASE_DIR}/GoogleService-Info-dev.plist"
PLIST_TARGET="${PROJECT_DIR}/WeGig/GoogleService-Info.plist"

# Copiar arquivo correto
if [ -f "$PLIST_DEV" ]; then
    cp "$PLIST_DEV" "$PLIST_TARGET"
    echo "✅ GoogleService-Info-dev.plist copiado com sucesso"
else
    echo "❌ ERRO: $PLIST_DEV não encontrado!"
    exit 1
fi
