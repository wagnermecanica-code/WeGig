#!/bin/bash

# Script para deploy das Cloud Functions em todos os ambientes
# Execute: bash .config/functions/deploy_all_envs.sh

set -e  # Sair em caso de erro

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")"

echo "🚀 Deploy de Cloud Functions para WeGig"
echo "========================================"
echo ""

# Verificar se está no diretório correto
if [ ! -f "$CONFIG_DIR/firebase.json" ]; then
    echo "❌ firebase.json não encontrado em $CONFIG_DIR"
    echo "   Execute este script da pasta .config/functions/"
    exit 1
fi

cd "$CONFIG_DIR"

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

echo "📦 Instalando dependências..."
cd functions
npm install
cd ..
echo "✅ Dependências instaladas"
echo ""

# Função para deploy
deploy_env() {
    local ENV=$1
    local PROJECT_ID=$2
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📤 Deploying to $ENV ($PROJECT_ID)..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    firebase deploy --only functions --project "$PROJECT_ID"
    
    if [ $? -eq 0 ]; then
        echo "✅ $ENV deploy concluído com sucesso"
    else
        echo "❌ Erro no deploy de $ENV"
        return 1
    fi
    echo ""
}

# Menu de seleção
echo "Selecione o ambiente para deploy:"
echo "  1) dev (wegig-dev)"
echo "  2) staging (wegig-staging)"
echo "  3) prod (to-sem-banda-83e19)"
echo "  4) TODOS os ambientes"
echo ""
read -p "Opção [1-4]: " OPTION

case $OPTION in
    1)
        deploy_env "dev" "wegig-dev"
        ;;
    2)
        deploy_env "staging" "wegig-staging"
        ;;
    3)
        echo "⚠️  ATENÇÃO: Você está prestes a fazer deploy em PRODUÇÃO!"
        read -p "Confirmar? (digite 'prod' para confirmar): " CONFIRM
        if [ "$CONFIRM" = "prod" ]; then
            deploy_env "prod" "to-sem-banda-83e19"
        else
            echo "❌ Deploy de produção cancelado"
            exit 1
        fi
        ;;
    4)
        echo "⚠️  ATENÇÃO: Deploy será feito em TODOS os ambientes (dev, staging, prod)"
        read -p "Confirmar? (digite 'all' para confirmar): " CONFIRM
        if [ "$CONFIRM" = "all" ]; then
            deploy_env "dev" "wegig-dev"
            deploy_env "staging" "wegig-staging"
            deploy_env "prod" "to-sem-banda-83e19"
        else
            echo "❌ Deploy cancelado"
            exit 1
        fi
        ;;
    *)
        echo "❌ Opção inválida"
        exit 1
        ;;
esac

echo ""
echo "========================================"
echo "🎉 Deploy concluído!"
echo "========================================"
echo ""
echo "📧 Funções de email de denúncia ativas!"
echo "   - Todas as denúncias serão enviadas para: contato@wegig.com.br"
echo "   - Usando SMTP GoDaddy (smtpout.secureserver.net)"
echo ""
echo "📋 Verifique os logs em:"
echo "   https://console.firebase.google.com/project/<PROJECT_ID>/functions/logs"
