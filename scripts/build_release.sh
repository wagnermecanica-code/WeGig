#!/bin/bash

# Script para build de produção com ofuscação
# Gera builds seguros para Android e iOS

set -e # Exit on error

echo "🔒 Tô Sem Banda - Build de Produção com Ofuscação"
echo "=================================================="
echo ""

# Verificar se Flutter está instalado
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter não encontrado. Instale: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter encontrado: $(flutter --version | head -1)"
echo ""

# Limpar builds anteriores
echo "🧹 Limpando builds anteriores..."
flutter clean
flutter pub get
echo ""

# Diretório para símbolos de debug
SYMBOLS_DIR="build/app/outputs/symbols"
mkdir -p $SYMBOLS_DIR

# Build Android (APK)
build_android_apk() {
    echo "📦 Building Android APK (Release + Obfuscated)..."
    flutter build apk \
        --release \
        --obfuscate \
        --split-debug-info=$SYMBOLS_DIR/android \
        --target-platform android-arm,android-arm64,android-x64
    
    echo ""
    echo "✅ Android APK criado:"
    echo "   📁 build/app/outputs/flutter-apk/app-release.apk"
    echo "   🔒 Símbolos de debug: $SYMBOLS_DIR/android/"
    echo ""
}

# Build Android (App Bundle)
build_android_bundle() {
    echo "📦 Building Android App Bundle (Release + Obfuscated)..."
    flutter build appbundle \
        --release \
        --obfuscate \
        --split-debug-info=$SYMBOLS_DIR/android-bundle
    
    echo ""
    echo "✅ Android App Bundle criado:"
    echo "   📁 build/app/outputs/bundle/release/app-release.aab"
    echo "   🔒 Símbolos de debug: $SYMBOLS_DIR/android-bundle/"
    echo ""
}

# Build iOS
build_ios() {
    echo "📦 Building iOS (Release + Obfuscated)..."
    
    # Verificar se está no macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo "⚠️  iOS build apenas disponível no macOS"
        return
    fi
    
    flutter build ios \
        --release \
        --obfuscate \
        --split-debug-info=$SYMBOLS_DIR/ios
    
    echo ""
    echo "✅ iOS build criado:"
    echo "   📁 build/ios/iphoneos/Runner.app"
    echo "   🔒 Símbolos de debug: $SYMBOLS_DIR/ios/"
    echo ""
    echo "⚠️  Para deploy na App Store, abra o Xcode:"
    echo "   open ios/Runner.xcworkspace"
    echo "   Product → Archive → Distribute App"
    echo ""
}

# Menu de opções
echo "Escolha a plataforma:"
echo "  1) Android APK"
echo "  2) Android App Bundle (Google Play)"
echo "  3) iOS"
echo "  4) Todas"
echo ""
read -p "Opção [1-4]: " option

case $option in
    1)
        build_android_apk
        ;;
    2)
        build_android_bundle
        ;;
    3)
        build_ios
        ;;
    4)
        build_android_apk
        build_android_bundle
        build_ios
        ;;
    *)
        echo "❌ Opção inválida"
        exit 1
        ;;
esac

# Resumo de segurança
echo ""
echo "🔒 Proteções de Segurança Aplicadas:"
echo "======================================"
echo "✅ Ofuscação de código (--obfuscate)"
echo "✅ Símbolos de debug separados (--split-debug-info)"
echo "✅ ProGuard habilitado (Android)"
echo "✅ Minify habilitado (Android)"
echo "✅ Shrink resources habilitado (Android)"
echo ""
echo "⚠️  IMPORTANTE:"
echo "   - Guarde os símbolos de debug em local seguro (necessários para stack traces)"
echo "   - NÃO faça commit dos símbolos de debug no Git"
echo "   - Os símbolos estão em: $SYMBOLS_DIR/"
echo ""
echo "📊 Monitoramento de Crashes:"
echo "   - Firebase Crashlytics já está configurado"
echo "   - Faça upload dos símbolos: firebase crashlytics:symbols:upload $SYMBOLS_DIR/"
echo ""
echo "✅ Build concluído com sucesso!"
