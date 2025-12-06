#!/bin/bash

# ========================================
# WeGig - Build Script Automatizado
# ========================================
# Suporta 3 flavors: dev, staging, prod
# Uso: ./scripts/build_release.sh [dev|staging|prod] [platform]
# Exemplos:
#   ./scripts/build_release.sh prod
#   ./scripts/build_release.sh staging android
#   ./scripts/build_release.sh dev ios
# ========================================

set -e # Exit on error

# ========== CORES PARA OUTPUT ==========
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ========== FUNÇÕES DE UTILIDADE ==========
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

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# ========== VALIDAÇÕES ==========
# Verificar se Flutter está instalado
if ! command -v flutter &> /dev/null; then
    print_error "Flutter não encontrado. Instale: https://flutter.dev/docs/get-started/install"
    exit 1
fi

print_success "Flutter encontrado: $(flutter --version | head -1)"
echo ""

# Verificar argumento do flavor
FLAVOR="${1:-prod}" # Default: prod
PLATFORM="${2:-all}" # Default: all

if [[ ! "$FLAVOR" =~ ^(dev|staging|prod)$ ]]; then
    print_error "Flavor inválido: $FLAVOR"
    echo ""
    echo "Uso: $0 [dev|staging|prod] [android|ios|all]"
    echo ""
    echo "Flavors disponíveis:"
    echo "  dev     - Desenvolvimento (logs habilitados, Firebase dev)"
    echo "  staging - Homologação (logs habilitados, Crashlytics)"
    echo "  prod    - Produção (logs desabilitados, build otimizado)"
    echo ""
    echo "Plataformas:"
    echo "  android - APK + AAB (App Bundle)"
    echo "  ios     - iOS build (apenas macOS)"
    echo "  all     - Todas as plataformas (default)"
    exit 1
fi

# ========== CONFIGURAÇÃO DO FLAVOR ==========
print_header "🚀 WeGig - Build Automatizado"
echo ""
print_info "Flavor: $FLAVOR"
print_info "Plataforma: $PLATFORM"
echo ""

# Configurações específicas por flavor
case $FLAVOR in
    dev)
        FLAVOR_NAME="DEV"
        FLAVOR_COLOR="${BLUE}🔵${NC}"
        OBFUSCATE="false"
        BUNDLE_ONLY="false"
        ;;
    staging)
        FLAVOR_NAME="STAGING"
        FLAVOR_COLOR="${YELLOW}🟣${NC}"
        OBFUSCATE="true"
        BUNDLE_ONLY="false"
        ;;
    prod)
        FLAVOR_NAME="PRODUCTION"
        FLAVOR_COLOR="${RED}🔴${NC}"
        OBFUSCATE="true"
        BUNDLE_ONLY="true" # Produção gera apenas Bundle (Google Play)
        ;;
esac

echo -e "Buildando: ${FLAVOR_COLOR} $FLAVOR_NAME"
echo ""

# ========== LIMPEZA E PREPARAÇÃO ==========
print_info "Limpando builds anteriores..."
flutter clean
flutter pub get
echo ""

# Diretório para símbolos de debug
SYMBOLS_DIR="build/symbols/$FLAVOR"
mkdir -p "$SYMBOLS_DIR"

# ========== FUNÇÕES DE BUILD ==========

# Build Android APK
build_android_apk() {
    print_header "📦 Building Android APK - $FLAVOR_NAME"
    
    local BUILD_ARGS="--flavor $FLAVOR --target lib/main_$FLAVOR.dart --release --no-tree-shake-icons --dart-define=FLAVOR=$FLAVOR"
    
    if [[ "$OBFUSCATE" == "true" ]]; then
        BUILD_ARGS="$BUILD_ARGS --obfuscate --split-debug-info=$SYMBOLS_DIR/android"
        print_info "Obfuscação habilitada"
    fi
    
    print_info "Executando: flutter build apk $BUILD_ARGS"
    flutter build apk $BUILD_ARGS
    
    echo ""
    print_success "Android APK criado!"
    print_info "📁 build/app/outputs/flutter-apk/app-$FLAVOR-release.apk"
    
    if [[ "$OBFUSCATE" == "true" ]]; then
        print_info "🔒 Símbolos: $SYMBOLS_DIR/android/"
    fi
    echo ""
}

# Build Android App Bundle (AAB)
build_android_bundle() {
    print_header "📦 Building Android App Bundle - $FLAVOR_NAME"
    
    local BUILD_ARGS="--flavor $FLAVOR --target lib/main_$FLAVOR.dart --release --no-tree-shake-icons --dart-define=FLAVOR=$FLAVOR"
    
    if [[ "$OBFUSCATE" == "true" ]]; then
        BUILD_ARGS="$BUILD_ARGS --obfuscate --split-debug-info=$SYMBOLS_DIR/android-bundle"
        print_info "Obfuscação habilitada"
    fi
    
    print_info "Executando: flutter build appbundle $BUILD_ARGS"
    flutter build appbundle $BUILD_ARGS
    
    echo ""
    print_success "Android App Bundle criado!"
    print_info "📁 build/app/outputs/bundle/${FLAVOR}Release/app-$FLAVOR-release.aab"
    
    if [[ "$OBFUSCATE" == "true" ]]; then
        print_info "🔒 Símbolos: $SYMBOLS_DIR/android-bundle/"
    fi
    echo ""
}

# Build iOS
build_ios() {
    print_header "📱 Building iOS - $FLAVOR_NAME"
    
    # Verificar se está no macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_warning "iOS build apenas disponível no macOS"
        return
    fi
    
    local BUILD_ARGS="--flavor $FLAVOR --target lib/main_$FLAVOR.dart --release --no-tree-shake-icons --dart-define=FLAVOR=$FLAVOR"
    
    if [[ "$OBFUSCATE" == "true" ]]; then
        BUILD_ARGS="$BUILD_ARGS --obfuscate --split-debug-info=$SYMBOLS_DIR/ios"
        print_info "Obfuscação habilitada"
    fi
    
    print_info "Executando: flutter build ios $BUILD_ARGS"
    flutter build ios $BUILD_ARGS
    
    echo ""
    print_success "iOS build criado!"
    print_info "📁 build/ios/iphoneos/WeGig.app"
    
    if [[ "$OBFUSCATE" == "true" ]]; then
        print_info "🔒 Símbolos: $SYMBOLS_DIR/ios/"
    fi
    
    echo ""
    print_warning "Para deploy na App Store:"
    echo "   1. Abra: open ios/WeGig.xcworkspace"
    echo "   2. Xcode → Product → Archive"
    echo "   3. Distribute App → App Store Connect"
    echo ""
}

# ========== EXECUÇÃO DOS BUILDS ==========

case $PLATFORM in
    android)
        if [[ "$BUNDLE_ONLY" == "true" ]]; then
            # Produção: apenas Bundle (Google Play)
            build_android_bundle
        else
            # Dev/Staging: APK para teste interno
            build_android_apk
        fi
        ;;
    ios)
        build_ios
        ;;
    all)
        if [[ "$BUNDLE_ONLY" == "true" ]]; then
            build_android_bundle
        else
            build_android_apk
        fi
        build_ios
        ;;
    *)
        print_error "Plataforma inválida: $PLATFORM"
        exit 1
        ;;
esac

# ========== RESUMO FINAL ==========
print_header "🎉 Build Concluído!"
echo ""
print_success "Flavor: $FLAVOR_NAME"
print_success "Plataforma: $PLATFORM"

if [[ "$OBFUSCATE" == "true" ]]; then
    echo ""
    print_header "🔒 Proteções de Segurança Aplicadas"
    echo ""
    echo "✅ Ofuscação de código (--obfuscate)"
    echo "✅ Símbolos de debug separados (--split-debug-info)"
    echo "✅ ProGuard habilitado (Android)"
    echo "✅ Minify habilitado (Android)"
    echo "✅ Shrink resources habilitado (Android)"
    echo "✅ Tree shaking desabilitado (--no-tree-shake-icons)"
    echo ""
    print_warning "IMPORTANTE: Guarde os símbolos de debug!"
    print_info "📁 Símbolos em: $SYMBOLS_DIR/"
    print_info "🚫 NÃO faça commit dos símbolos no Git"
    echo ""
    print_info "📊 Upload para Crashlytics:"
    echo "   firebase crashlytics:symbols:upload $SYMBOLS_DIR/"
fi

echo ""
print_success "✅ Build de $FLAVOR_NAME concluído com sucesso!"
echo ""

# Exibir tamanho dos arquivos gerados
if [[ -f "build/app/outputs/flutter-apk/app-$FLAVOR-release.apk" ]]; then
    APK_SIZE=$(du -h "build/app/outputs/flutter-apk/app-$FLAVOR-release.apk" | cut -f1)
    print_info "📦 APK: $APK_SIZE"
fi

if [[ -f "build/app/outputs/bundle/${FLAVOR}Release/app-$FLAVOR-release.aab" ]]; then
    AAB_SIZE=$(du -h "build/app/outputs/bundle/${FLAVOR}Release/app-$FLAVOR-release.aab" | cut -f1)
    print_info "📦 AAB: $AAB_SIZE"
fi

echo ""
