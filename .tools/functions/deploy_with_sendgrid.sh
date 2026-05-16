#!/bin/bash

# Script para deploy das Cloud Functions com SendGrid
# Execute: bash .config/functions/deploy_with_sendgrid.sh <environment>

ENV=$1

if [ -z "$ENV" ]; then
    echo "❌ Ambiente não especificado. Use: dev, staging ou prod"
    exit 1
fi

# Mapear ambiente para project ID
case $ENV in
    dev) PROJECT_ID="wegig-dev" ;;
    staging) PROJECT_ID="wegig-staging" ;;
    prod) PROJECT_ID="to-sem-banda-83e19" ;;
    *) echo "❌ Ambiente inválido. Use: dev, staging ou prod"; exit 1 ;;
esac

echo "🚀 Fazendo deploy das funções para $ENV ($PROJECT_ID)..."

# Verificar se SendGrid está configurado no .env local das functions
echo "🔍 Verificando configuração do SendGrid no .env..."
if ! grep -q '^SENDGRID_API_KEY=.' .config/functions/.env; then
    echo "⚠️  SENDGRID_API_KEY não configurada em .config/functions/.env"
    echo "Execute: bash .config/functions/setup_sendgrid.sh"
    exit 1
fi

# Instalar dependências
echo "📦 Instalando dependências..."
cd .config/functions
npm install

# Deploy das funções
echo "⬆️  Fazendo deploy..."
firebase deploy --only functions --project $PROJECT_ID

if [ $? -eq 0 ]; then
    echo "✅ Deploy concluído com sucesso!"
    echo ""
    echo "📧 Notificações por email ativadas para $ENV"
    echo "📊 Dashboard admin: http://localhost:3001 (em desenvolvimento)"
    echo ""
    echo "🧪 Teste: Crie uma denúncia no app para receber notificação"
else
    echo "❌ Erro no deploy"
    exit 1
fi