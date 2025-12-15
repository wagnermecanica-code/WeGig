#!/bin/bash

# Script para Criar e Configurar Projetos Firebase Separados
# WeGig - DEV, STAGING, PROD
#
# Uso: ./scripts/setup_firebase_projects.sh

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   WeGig - Setup Firebase Projects             ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📖 Guia detalhado:${NC} docs/guides/FIREBASE_SEPARATE_PROJECTS_GUIDE.md"
echo ""

# Verificar se Firebase CLI está instalado
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}❌ Firebase CLI não encontrado${NC}"
    echo -e "${YELLOW}Instale: npm install -g firebase-tools${NC}"
    exit 1
fi

# Verificar se FlutterFire CLI está instalado
if ! command -v flutterfire &> /dev/null; then
    echo -e "${YELLOW}⚠️  FlutterFire CLI não encontrado - instalando...${NC}"
    dart pub global activate flutterfire_cli
fi

echo -e "${GREEN}✓ Firebase CLI: $(firebase --version)${NC}"
echo -e "${GREEN}✓ FlutterFire CLI instalado${NC}"
echo ""

# Login no Firebase (se necessário)
echo -e "${BLUE}🔐 Verificando autenticação...${NC}"
firebase login:list &> /dev/null || firebase login

echo ""
echo -e "${CYAN}════════════════════════════════════════════════${NC}"
echo -e "${CYAN}   PASSO 1: Criar Projetos no Firebase Console${NC}"
echo -e "${CYAN}════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Você precisa criar 2 novos projetos Firebase:${NC}"
echo ""
echo -e "${GREEN}1. Projeto DEV${NC}"
echo "   Nome: WeGig DEV"
echo "   Project ID: to-sem-banda-dev (ou similar)"
echo "   Location: southamerica-east1 (São Paulo)"
echo ""
echo -e "${GREEN}2. Projeto STAGING${NC}"
echo "   Nome: WeGig STAGING"
echo "   Project ID: to-sem-banda-staging (ou similar)"
echo "   Location: southamerica-east1 (São Paulo)"
echo ""
echo -e "${BLUE}🌐 Abra: https://console.firebase.google.com/${NC}"
echo ""
echo -e "${YELLOW}Instruções:${NC}"
echo "   1. Clique em 'Add project' ou 'Adicionar projeto'"
echo "   2. Digite o nome do projeto (WeGig DEV)"
echo "   3. Use o Project ID sugerido ou customize"
echo "   4. Desabilite Google Analytics (opcional)"
echo "   5. Aguarde criação (30-60 segundos)"
echo "   6. Repita para STAGING"
echo ""
read -p "$(echo -e ${CYAN}Pressione ENTER após criar os 2 projetos...${NC})" 

echo ""
echo -e "${CYAN}════════════════════════════════════════════════${NC}"
echo -e "${CYAN}   PASSO 2: Identificar Project IDs${NC}"
echo -e "${CYAN}════════════════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}📋 Projetos Firebase disponíveis:${NC}"
firebase projects:list

echo ""
echo -e "${GREEN}Digite os Project IDs criados:${NC}"
echo ""
read -p "$(echo -e ${YELLOW}Project ID DEV: ${NC})" DEV_PROJECT_ID
read -p "$(echo -e ${YELLOW}Project ID STAGING: ${NC})" STAGING_PROJECT_ID

# Validar IDs
if [ -z "$DEV_PROJECT_ID" ] || [ -z "$STAGING_PROJECT_ID" ]; then
    echo -e "${RED}❌ Project IDs não podem ser vazios${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✓ DEV Project: $DEV_PROJECT_ID${NC}"
echo -e "${GREEN}✓ STAGING Project: $STAGING_PROJECT_ID${NC}"
echo ""

# Confirmar
read -p "$(echo -e ${CYAN}Confirmar e continuar? (y/n): ${NC})" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Cancelado${NC}"
    exit 0
fi

echo ""
echo -e "${CYAN}════════════════════════════════════════════════${NC}"
echo -e "${CYAN}   PASSO 3: Configurar Firebase DEV${NC}"
echo -e "${CYAN}════════════════════════════════════════════════${NC}"
echo ""

cd packages/app

echo -e "${BLUE}🔧 Configurando DEV (Android + iOS)...${NC}"
flutterfire configure \
  --project="$DEV_PROJECT_ID" \
  --out=lib/firebase_options_dev.dart \
  --platforms=android,ios \
  --ios-bundle-id=com.tosembanda.wegig.dev \
  --android-package-name=com.tosembanda.wegig.dev \
  --yes

echo -e "${GREEN}✓ DEV configurado${NC}"
echo ""

echo -e "${CYAN}════════════════════════════════════════════════${NC}"
echo -e "${CYAN}   PASSO 4: Configurar Firebase STAGING${NC}"
echo -e "${CYAN}════════════════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}🔧 Configurando STAGING (Android + iOS)...${NC}"
flutterfire configure \
  --project="$STAGING_PROJECT_ID" \
  --out=lib/firebase_options_staging.dart \
  --platforms=android,ios \
  --ios-bundle-id=com.tosembanda.wegig.staging \
  --android-package-name=com.tosembanda.wegig.staging \
  --yes

echo -e "${GREEN}✓ STAGING configurado${NC}"
echo ""

echo -e "${CYAN}════════════════════════════════════════════════${NC}"
echo -e "${CYAN}   PASSO 5: Baixar google-services.json${NC}"
echo -e "${CYAN}════════════════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}📥 Baixando configurações Android...${NC}"

# Função para baixar google-services.json
download_google_services() {
    local project_id=$1
    local flavor=$2
    local package_name=$3
    
    echo -e "${YELLOW}   → Baixando google-services.json para $flavor...${NC}"
    
    # Tentar baixar via Firebase CLI (não funciona diretamente)
    # Alternativa: instruir download manual
    echo -e "${YELLOW}   ⚠️  Download manual necessário${NC}"
    echo ""
    echo "   1. Abra: https://console.firebase.google.com/project/$project_id/settings/general"
    echo "   2. Encontre o app Android: $package_name"
    echo "   3. Clique em 'google-services.json' para baixar"
    echo "   4. Salve em: android/app/src/$flavor/google-services.json"
    echo ""
}

download_google_services "$DEV_PROJECT_ID" "dev" "com.tosembanda.wegig.dev"
read -p "$(echo -e ${CYAN}Pressione ENTER após baixar google-services.json DEV...${NC})" 

download_google_services "$STAGING_PROJECT_ID" "staging" "com.tosembanda.wegig.staging"
read -p "$(echo -e ${CYAN}Pressione ENTER após baixar google-services.json STAGING...${NC})" 

echo ""
echo -e "${CYAN}════════════════════════════════════════════════${NC}"
echo -e "${CYAN}   PASSO 6: Configurar iOS (GoogleService-Info)${NC}"
echo -e "${CYAN}════════════════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}📥 Baixando configurações iOS...${NC}"

download_ios_plist() {
    local project_id=$1
    local flavor=$2
    local bundle_id=$3
    
    echo -e "${YELLOW}   → Baixando GoogleService-Info.plist para $flavor...${NC}"
    echo ""
    echo "   1. Abra: https://console.firebase.google.com/project/$project_id/settings/general"
    echo "   2. Encontre o app iOS: $bundle_id"
    echo "   3. Clique em 'GoogleService-Info.plist' para baixar"
    echo "   4. Salve em: ios/Firebase/GoogleService-Info-$flavor.plist"
    echo ""
}

download_ios_plist "$DEV_PROJECT_ID" "dev" "com.tosembanda.wegig.dev"
read -p "$(echo -e ${CYAN}Pressione ENTER após baixar GoogleService-Info.plist DEV...${NC})" 

download_ios_plist "$STAGING_PROJECT_ID" "staging" "com.tosembanda.wegig.staging"
read -p "$(echo -e ${CYAN}Pressione ENTER após baixar GoogleService-Info.plist STAGING...${NC})" 

echo ""
echo -e "${CYAN}════════════════════════════════════════════════${NC}"
echo -e "${CYAN}   PASSO 7: Habilitar Serviços Firebase${NC}"
echo -e "${CYAN}════════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}Para cada projeto (DEV e STAGING), habilite:${NC}"
echo ""
echo "   ✅ Authentication (Email/Password, Google, Apple)"
echo "   ✅ Firestore Database"
echo "   ✅ Storage"
echo "   ✅ Cloud Functions"
echo "   ✅ Crashlytics"
echo "   ✅ Cloud Messaging (FCM)"
echo ""
echo -e "${BLUE}🌐 DEV: https://console.firebase.google.com/project/$DEV_PROJECT_ID${NC}"
echo -e "${BLUE}🌐 STAGING: https://console.firebase.google.com/project/$STAGING_PROJECT_ID${NC}"
echo ""
read -p "$(echo -e ${CYAN}Pressione ENTER após habilitar serviços...${NC})" 

echo ""
echo -e "${CYAN}════════════════════════════════════════════════${NC}"
echo -e "${CYAN}   PASSO 8: Configurar Firestore Rules${NC}"
echo -e "${CYAN}════════════════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}📋 Copiando Firestore rules e indexes...${NC}"

# Copiar rules para cada projeto
echo -e "${YELLOW}   → Copiando regras do Firestore...${NC}"
echo ""
echo "   Execute os comandos:"
echo ""
echo -e "${GREEN}   # DEV${NC}"
echo "   firebase use $DEV_PROJECT_ID"
echo "   firebase deploy --only firestore:indexes"
echo "   firebase deploy --only firestore:rules"
echo ""
echo -e "${GREEN}   # STAGING${NC}"
echo "   firebase use $STAGING_PROJECT_ID"
echo "   firebase deploy --only firestore:indexes"
echo "   firebase deploy --only firestore:rules"
echo ""
read -p "$(echo -e ${CYAN}Pressione ENTER após copiar rules...${NC})" 

echo ""
echo -e "${CYAN}════════════════════════════════════════════════${NC}"
echo -e "${CYAN}   PASSO 9: Testar Configuração${NC}"
echo -e "${CYAN}════════════════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}🧪 Testando builds...${NC}"
echo ""

# Limpar e testar
flutter clean
flutter pub get

echo -e "${YELLOW}   → Testando build DEV...${NC}"
if flutter build apk --flavor dev -t lib/main_dev.dart --debug &> /tmp/build_dev.log; then
    echo -e "${GREEN}   ✓ Build DEV funcionando${NC}"
else
    echo -e "${RED}   ✗ Build DEV falhou - veja /tmp/build_dev.log${NC}"
fi

echo ""
echo -e "${YELLOW}   → Testando build STAGING...${NC}"
if flutter build apk --flavor staging -t lib/main_staging.dart --debug &> /tmp/build_staging.log; then
    echo -e "${GREEN}   ✓ Build STAGING funcionando${NC}"
else
    echo -e "${RED}   ✗ Build STAGING falhou - veja /tmp/build_staging.log${NC}"
fi

echo ""
echo -e "${CYAN}════════════════════════════════════════════════${NC}"
echo -e "${CYAN}   ✓ CONFIGURAÇÃO CONCLUÍDA${NC}"
echo -e "${CYAN}════════════════════════════════════════════════${NC}"
echo ""

echo -e "${GREEN}📊 Resumo:${NC}"
echo ""
echo "   DEV Project:     $DEV_PROJECT_ID"
echo "   STAGING Project: $STAGING_PROJECT_ID"
echo "   PROD Project:    to-sem-banda-83e19 (existente)"
echo ""
echo -e "${GREEN}✓ Firebase options gerados${NC}"
echo -e "${GREEN}✓ Apps Android registrados${NC}"
echo -e "${GREEN}✓ Apps iOS registrados${NC}"
echo ""

echo -e "${YELLOW}📝 Próximos Passos:${NC}"
echo ""
echo "   1. Verifique se todos os google-services.json foram baixados"
echo "   2. Verifique se todos os GoogleService-Info.plist foram baixados"
echo "   3. Configure Xcode schemes (veja FLAVORS_COMPLETE_GUIDE.md)"
echo "   4. Deploy Firestore rules e indexes"
echo "   5. Copie dados de teste para DEV (se necessário)"
echo ""

echo -e "${BLUE}📚 Documentação:${NC}"
echo "   - FIREBASE_FLAVORS_STATUS.md"
echo "   - docs/guides/FLAVORS_COMPLETE_GUIDE.md"
echo ""

echo -e "${GREEN}🚀 Agora você pode usar:${NC}"
echo ""
echo "   flutter run --flavor dev -t lib/main_dev.dart"
echo "   flutter run --flavor staging -t lib/main_staging.dart"
echo "   flutter run --flavor prod -t lib/main_prod.dart"
echo ""

echo -e "${CYAN}════════════════════════════════════════════════${NC}"
