#!/bin/bash

# deploy_firestore_all_envs.sh
# Script para fazer deploy de Firestore rules e indexes para todos os ambientes
# Uso: ./.tools/scripts/deploy_firestore_all_envs.sh [dev|staging|prod|all]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(cd "$SCRIPT_DIR/../../.config" && pwd)"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔥 Firebase Deployment Script${NC}"
echo "=============================="
echo ""

# Função para fazer deploy em um ambiente
deploy_to_env() {
    local ENV=$1
    local PROJECT_ID=$2
    
    echo ""
    echo -e "${YELLOW}📦 Deploying to $(echo $ENV | tr '[:lower:]' '[:upper:]')...${NC}"
    echo "Project: $PROJECT_ID"
    echo ""
    
    cd "$CONFIG_DIR"
    
    # Deploy rules
    echo "1/3 Deploying Firestore Rules..."
    if firebase deploy --only firestore:rules --project "$PROJECT_ID"; then
        echo -e "${GREEN}✅ Rules deployed successfully${NC}"
    else
        echo -e "${RED}❌ Failed to deploy rules${NC}"
        return 1
    fi
    
    # Deploy indexes
    echo ""
    echo "2/3 Deploying Firestore Indexes..."
    if firebase deploy --only firestore:indexes --project "$PROJECT_ID"; then
        echo -e "${GREEN}✅ Indexes deployed successfully${NC}"
        echo -e "${YELLOW}⏳ Note: Indexes may take 5-10 minutes to build${NC}"
    else
        echo -e "${RED}❌ Failed to deploy indexes${NC}"
        return 1
    fi
    
    # Deploy storage rules
    echo ""
    echo "3/3 Deploying Storage Rules..."
    if firebase deploy --only storage --project "$PROJECT_ID"; then
        echo -e "${GREEN}✅ Storage rules deployed successfully${NC}"
    else
        echo -e "${RED}❌ Failed to deploy storage rules${NC}"
        return 1
    fi
    
    echo ""
    echo -e "${GREEN}✨ $(echo $ENV | tr '[:lower:]' '[:upper:]') deployment complete!${NC}"
    echo "Console: https://console.firebase.google.com/project/$PROJECT_ID"
    echo ""
}

# Processar argumentos
ENV=${1:-all}

case $ENV in
    dev)
        deploy_to_env "dev" "wegig-dev"
        ;;
    staging)
        deploy_to_env "staging" "wegig-staging"
        ;;
    prod)
        echo -e "${RED}⚠️  WARNING: Deploying to PRODUCTION${NC}"
        echo "This will affect live users!"
        echo ""
        read -p "Are you sure? (type 'yes' to continue): " CONFIRM
        
        if [ "$CONFIRM" != "yes" ]; then
            echo "Deployment cancelled"
            exit 0
        fi
        
        deploy_to_env "prod" "to-sem-banda-83e19"
        ;;
    all)
        echo -e "${BLUE}📋 Deploying to ALL environments${NC}"
        echo ""
        
        deploy_to_env "dev" "wegig-dev"
        deploy_to_env "staging" "wegig-staging"
        
        echo ""
        echo -e "${YELLOW}⚠️  Production deployment requires explicit confirmation${NC}"
        read -p "Deploy to PRODUCTION? (type 'yes' to continue): " CONFIRM
        
        if [ "$CONFIRM" = "yes" ]; then
            deploy_to_env "prod" "to-sem-banda-83e19"
        else
            echo -e "${YELLOW}⏭️  Skipping production deployment${NC}"
        fi
        ;;
    *)
        echo -e "${RED}❌ Invalid environment: $ENV${NC}"
        echo ""
        echo "Usage: $0 [dev|staging|prod|all]"
        echo ""
        echo "Examples:"
        echo "  $0 dev      # Deploy only to dev"
        echo "  $0 staging  # Deploy only to staging"
        echo "  $0 prod     # Deploy only to prod (requires confirmation)"
        echo "  $0 all      # Deploy to all environments"
        exit 1
        ;;
esac

echo ""
echo "=============================="
echo -e "${GREEN}✅ Deployment script completed${NC}"
echo ""
echo "Next steps:"
echo "1. Wait 5-10 minutes for indexes to build"
echo "2. Check Firebase Console for index status"
echo "3. Test app in each environment"
echo "4. Monitor error rates in Console"
echo ""
