#!/bin/bash

# Script para configurar SMTP GoDaddy no Firebase Functions
# Execute: bash .config/functions/setup_smtp.sh

echo "🔧 Configurando SMTP GoDaddy para notificações de denúncias..."
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

echo "📧 Configuração SMTP GoDaddy para contato@wegig.com.br"
echo ""
echo "📝 Você precisará das credenciais do email no GoDaddy:"
echo "   - Email: contato@wegig.com.br"
echo "   - Senha: A senha do email (não a senha da conta GoDaddy)"
echo ""
echo "🔒 Configurações SMTP do GoDaddy (já pré-configuradas):"
echo "   - Host: smtpout.secureserver.net"
echo "   - Porta: 465 (SSL)"
echo ""

read -p "📧 Email (contato@wegig.com.br): " SMTP_USER
SMTP_USER=${SMTP_USER:-contato@wegig.com.br}

read -sp "🔑 Senha do email: " SMTP_PASS
echo ""

if [ -z "$SMTP_PASS" ]; then
    echo "❌ Senha não fornecida"
    exit 1
fi

echo ""
echo "🔄 Configurando SMTP no Firebase Functions para todos os ambientes..."
echo ""

# Configurar para todos os ambientes
for ENV in dev staging prod; do
    PROJECT_ID=""
    case $ENV in
        dev) PROJECT_ID="wegig-dev" ;;
        staging) PROJECT_ID="wegig-staging" ;;
        prod) PROJECT_ID="to-sem-banda-83e19" ;;
    esac

    echo "  📤 Configurando para $ENV ($PROJECT_ID)..."

    firebase functions:config:set \
        smtp.host="smtpout.secureserver.net" \
        smtp.port="465" \
        smtp.user="$SMTP_USER" \
        smtp.pass="$SMTP_PASS" \
        --project "$PROJECT_ID" 2>/dev/null

    if [ $? -eq 0 ]; then
        echo "  ✅ $ENV configurado com sucesso"
    else
        echo "  ❌ Erro ao configurar $ENV (verifique se você tem acesso ao projeto)"
    fi
done

echo ""
echo "🎉 Configuração completa!"
echo ""
echo "📋 Próximos passos:"
echo ""
echo "   1. DEPLOY DAS FUNÇÕES:"
echo "      cd .config"
echo "      firebase deploy --only functions --project wegig-dev        # DEV"
echo "      firebase deploy --only functions --project wegig-staging    # STAGING"  
echo "      firebase deploy --only functions --project to-sem-banda-83e19  # PROD"
echo ""
echo "   2. OU USE O SCRIPT DE DEPLOY:"
echo "      bash .config/functions/deploy_all_envs.sh"
echo ""
echo "📬 Teste: Crie uma denúncia no app para receber o primeiro email em contato@wegig.com.br"
echo ""
echo "⚠️  NOTA: Se encontrar problemas de autenticação, verifique:"
echo "   - A senha está correta (senha do email, não da conta GoDaddy)"
echo "   - O email permite envio via SMTP (configurações no painel GoDaddy)"