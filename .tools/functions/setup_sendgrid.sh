#!/bin/bash

# Script para configurar SendGrid no .env local das Cloud Functions
# Execute: bash .config/functions/setup_sendgrid.sh

echo "🔧 Configurando SendGrid para notificações de denúncias..."
echo ""

# Verificar se Firebase CLI está instalado
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI não encontrado. Instale com: npm install -g firebase-tools"
    exit 1
fi

# Verificar se está logado no Firebase
if ! firebase projects:list &> /dev/null; then
    echo "❌ Não está logado no Firebase. Execute: firebase login"
    exit 1
fi

echo "📧 Configuração SendGrid para contato@wegig.com.br"
echo ""
echo "📝 Você precisará da API key do SendGrid com permissão de envio"
echo ""

read -sp "🔑 SendGrid API key: " SENDGRID_API_KEY
echo ""

if [ -z "$SENDGRID_API_KEY" ]; then
    echo "❌ API key não fornecida"
    exit 1
fi

echo ""
echo "🔄 Atualizando .config/functions/.env..."
echo ""

if grep -q '^SENDGRID_API_KEY=' .config/functions/.env; then
    sed -i.bak "s|^SENDGRID_API_KEY=.*|SENDGRID_API_KEY=$SENDGRID_API_KEY|" .config/functions/.env
else
    printf '\nSENDGRID_API_KEY=%s\n' "$SENDGRID_API_KEY" >> .config/functions/.env
fi

rm -f .config/functions/.env.bak

echo "  ✅ .env atualizado com sucesso"

echo ""
echo "🎉 Configuração completa!"
echo ""
echo "📋 Próximos passos:"
echo ""
echo "   1. DEPLOY DAS FUNÇÕES:"
echo "      firebase deploy --only functions --project wegig-dev"
echo "      firebase deploy --only functions --project wegig-staging"
echo "      firebase deploy --only functions --project to-sem-banda-83e19"
echo ""
echo "   2. OU USE O SCRIPT DE DEPLOY:"
echo "      bash .config/functions/deploy_all_envs.sh"
echo ""
echo "📬 Teste: Crie uma denúncia no app para receber o primeiro email em contato@wegig.com.br"