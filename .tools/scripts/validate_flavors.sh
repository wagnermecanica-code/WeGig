#!/bin/bash

# ========================================
# Script de Validação de Flavors
# ========================================
# Verifica se todos os arquivos necessários
# para cada flavor estão presentes
# ========================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Contador de erros
ERRORS=0

print_header "🔍 Validação de Flavors - WeGig"
echo ""

# ========== VALIDAR ARQUIVOS DE CONFIGURAÇÃO ==========
print_header "📋 Arquivos de Configuração Dart"
echo ""

check_file() {
    if [[ -f "$1" ]]; then
        print_success "$1"
    else
        print_error "$1 - NÃO ENCONTRADO"
        ((ERRORS++))
    fi
}

check_file "lib/config/dev_config.dart"
check_file "lib/config/staging_config.dart"
check_file "lib/config/prod_config.dart"
check_file "lib/config/app_config.dart"

echo ""

# ========== VALIDAR FIREBASE CONFIGS (ANDROID) ==========
print_header "🤖 Firebase - Android"
echo ""

check_file "android/app/src/dev/google-services.json"
check_file "android/app/src/staging/google-services.json"
check_file "android/app/src/prod/google-services.json"

echo ""

# ========== VALIDAR FIREBASE CONFIGS (IOS) ==========
print_header "🍎 Firebase - iOS"
echo ""

check_file "ios/Firebase/dev/GoogleService-Info.plist"
check_file "ios/Firebase/staging/GoogleService-Info.plist"
check_file "ios/Firebase/prod/GoogleService-Info.plist"

echo ""

# ========== VALIDAR FIREBASE OPTIONS ==========
print_header "🔥 Firebase Options Dart"
echo ""

check_file "lib/firebase_options_dev.dart"
check_file "lib/firebase_options_staging.dart"
check_file "lib/firebase_options_prod.dart"

echo ""

# ========== VALIDAR TARGETS FLUTTER ==========
print_header "🎯 Flutter Targets"
echo ""

check_file "lib/main_dev.dart"
check_file "lib/main_staging.dart"
check_file "lib/main_prod.dart"

echo ""

# ========== VALIDAR SCRIPTS ==========
print_header "📜 Scripts de Build"
echo ""

check_file "scripts/build_release.sh"

if [[ -f "scripts/build_release.sh" ]]; then
    if [[ -x "scripts/build_release.sh" ]]; then
        print_success "build_release.sh é executável"
    else
        print_warning "build_release.sh não é executável"
        print_warning "Execute: chmod +x scripts/build_release.sh"
    fi
fi

echo ""

# ========== VALIDAR FLAVORIZR CONFIG ==========
print_header "⚙️  Configuração Flavorizr"
echo ""

check_file "flavorizr.yaml"

echo ""

# ========== RESULTADO FINAL ==========
print_header "📊 Resultado da Validação"
echo ""

if [[ $ERRORS -eq 0 ]]; then
    print_success "Todos os arquivos encontrados! ✨"
    echo ""
    print_success "Próximos passos:"
    echo "  1. flutter pub get"
    echo "  2. flutter pub run flutter_flavorizr"
    echo "  3. flutter run --flavor dev -t lib/main_dev.dart"
    echo ""
    exit 0
else
    print_error "Encontrados $ERRORS arquivos faltando"
    echo ""
    print_warning "Siga o guia de setup:"
    echo "  cat FLAVOR_SETUP_GUIDE.md"
    echo ""
    exit 1
fi
