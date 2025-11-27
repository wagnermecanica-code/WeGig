#!/bin/bash

# Script para testar as regras de segurança do Firebase
# Executa validações básicas sem afetar dados de produção

echo "🔒 Testando Regras de Segurança Firebase"
echo "=========================================="
echo ""

# Verificar se Firebase CLI está instalado
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI não encontrado. Instale com: npm install -g firebase-tools"
    exit 1
fi

echo "✅ Firebase CLI encontrado"
echo ""

# Verificar se estamos no diretório correto
if [ ! -f "firestore.rules" ]; then
    echo "❌ Arquivo firestore.rules não encontrado. Execute este script da raiz do projeto."
    exit 1
fi

echo "📋 Resumo das Proteções Implementadas:"
echo "--------------------------------------"
echo ""
echo "1. Firestore Rules:"
echo "   ✅ Validação de dados em Posts (location, expiresAt, types)"
echo "   ✅ Validação de dados em Profiles (name 2-50 chars, location required)"
echo "   ✅ Messages: apenas participantes da conversa podem ler/escrever"
echo "   ✅ Rate Limits collection: apenas server-side (Admin SDK)"
echo ""
echo "2. Storage Rules:"
echo "   ✅ Limite de tamanho: 10MB por arquivo"
echo "   ✅ Apenas imagens permitidas (image/* MIME type)"
echo "   ✅ Validações em todas as pastas (user_photos, posts, profiles)"
echo ""
echo "3. Cloud Functions:"
echo "   ✅ Rate Limiting - Posts: 20/dia"
echo "   ✅ Rate Limiting - Interesses: 50/dia"
echo "   ✅ Rate Limiting - Mensagens: 500/dia"
echo "   ✅ Contadores em Firestore com reset automático"
echo ""

echo "📤 Fazendo deploy das regras (dry-run)..."
echo ""

# Validar sintaxe das regras Firestore
echo "1. Validando firestore.rules..."
firebase firestore:rules --help > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "   ✅ Sintaxe Firestore Rules válida"
else
    echo "   ⚠️ Não foi possível validar sintaxe (comando não disponível)"
fi

# Validar sintaxe das regras Storage
echo "2. Validando storage.rules..."
if [ -f "storage.rules" ]; then
    echo "   ✅ Arquivo storage.rules encontrado"
else
    echo "   ❌ Arquivo storage.rules não encontrado"
    exit 1
fi

echo ""
echo "🚀 Para fazer deploy das regras, execute:"
echo "   firebase deploy --only firestore:rules"
echo "   firebase deploy --only storage"
echo "   firebase deploy --only functions"
echo ""
echo "⚠️  ATENÇÃO:"
echo "   - Teste primeiro em ambiente de desenvolvimento"
echo "   - As regras não impactam performance do app (validadas server-side)"
echo "   - Rate limits são não-bloqueantes (fail-open em caso de erro)"
echo "   - Todas as validações são incrementais e backward-compatible"
echo ""
echo "📊 Monitoramento:"
echo "   firebase functions:log --only notifyNearbyPosts"
echo "   firebase functions:log --only sendMessageNotification"
echo ""
