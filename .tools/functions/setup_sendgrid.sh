#!/bin/bash

# Script para configurar SendGrid no Firebase Functions
# Execute: bash .config/functions/setup_sendgrid.sh

echo "🔧 Configurando SendGrid para notificações de admin..."

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

echo "📝 Você precisa de uma chave API do SendGrid:"
echo "   1. Acesse: https://app.sendgrid.com/settings/api_keys"
echo "   2. Crie uma nova API Key com permissões 'Mail Send'"
echo "   3. Copie a chave gerada"
echo ""

read -p "🔑 Cole sua SendGrid API Key: " SENDGRID_KEY

if [ -z "$SENDGRID_KEY" ]; then
    echo "❌ Chave API não fornecida"
    exit 1
fi

echo "🔄 Configurando chave no Firebase Functions..."

# Configurar para todos os ambientes
for ENV in dev staging prod; do
    PROJECT_ID=""
    case $ENV in
        dev) PROJECT_ID="wegig-dev" ;;
        staging) PROJECT_ID="wegig-staging" ;;
        prod) PROJECT_ID="to-sem-banda-83e19" ;;
    esac

    echo "  📤 Configurando para $ENV ($PROJECT_ID)..."

    firebase functions:config:set sendgrid.key="$SENDGRID_KEY" --project $PROJECT_ID

    if [ $? -eq 0 ]; then
        echo "  ✅ $ENV configurado com sucesso"
    else
        echo "  ❌ Erro ao configurar $ENV"
    fi
done

echo ""
echo "🎉 Configuração completa!"
echo ""
echo "📧 Próximos passos:"
echo "   1. No SendGrid Dashboard, verifique o domínio 'wegig.app'"
echo "   2. Adicione 'noreply@wegig.app' como email verificado"
echo "   3. Configure SPF/DKIM para melhor deliverability"
echo "   4. Deploy as funções: firebase deploy --only functions --project <env>"
echo ""
echo "📬 Teste: Crie uma denúncia no app para receber o primeiro email"