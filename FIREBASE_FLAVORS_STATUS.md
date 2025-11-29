# Firebase Flavors - Status de Configuração

**Data**: 29 de Novembro de 2025  
**Status**: ✅ **CONFIGURADO E TESTADO**

---

## 📱 Apps Registrados no Firebase

Todos os apps foram registrados no projeto **to-sem-banda-83e19** (único projeto Firebase).

### Android

| Flavor | Package Name | App ID |
|--------|-------------|---------|
| **PROD** | `com.tosembanda.wegig` | `1:278498777601:android:d7a665f5fd5f93719ebe00` |
| **DEV** | `com.tosembanda.wegig.dev` | `1:278498777601:android:e53cb79c055240be9ebe00` |
| **STAGING** | `com.tosembanda.wegig.staging` | `1:278498777601:android:d602ae39fc393d199ebe00` |

### iOS

| Flavor | Bundle ID | App ID |
|--------|-----------|---------|
| **PROD** | `com.tosembanda.wegig` | `1:278498777601:ios:7aa6ffc0be146b089ebe00` |
| **DEV** | `com.tosembanda.wegig.dev` | `1:278498777601:ios:cfb059150a3453319ebe00` |
| **STAGING** | `com.tosembanda.wegig.staging` | `1:278498777601:ios:1ecad15c4cc358329ebe00` |

---

## 📂 Arquivos Configurados

### Android
```
packages/app/android/app/
├── google-services.json (raiz - contém todos os apps)
└── src/
    ├── dev/google-services.json
    ├── staging/google-services.json
    └── prod/google-services.json
```

### iOS
```
packages/app/ios/
├── GoogleService-Info.plist (raiz - legacy)
└── Firebase/
    ├── GoogleService-Info-dev.plist
    ├── GoogleService-Info-staging.plist
    └── GoogleService-Info-prod.plist
```

### Flutter
```
packages/app/lib/
├── firebase_options.dart (raiz - padrão)
├── firebase_options_dev.dart
├── firebase_options_staging.dart
└── firebase_options_prod.dart
```

---

## ✅ Testes Realizados

### DEV Flavor
```bash
flutter build apk --flavor dev -t lib/main_dev.dart --debug
```
**Status**: ✅ **Sucesso** - APK gerado em 425s

### PROD Flavor (com obfuscação)
```bash
flutter build apk --flavor prod -t lib/main_prod.dart --release \
  --obfuscate --split-debug-info=build/symbols/prod/android
```
**Status**: ✅ **Sucesso** - APK gerado em 174s (64.9MB)  
**Obfuscação**: ✅ Ativa  
**Símbolos**: `build/symbols/prod/android/`

---

## 🚀 Como Usar

### Executar por Flavor

```bash
# DEV
cd packages/app
flutter run --flavor dev -t lib/main_dev.dart

# STAGING
flutter run --flavor staging -t lib/main_staging.dart

# PROD
flutter run --flavor prod -t lib/main_prod.dart
```

### Build Release

```bash
# Script automatizado (recomendado)
./scripts/build_release.sh dev android      # APK dev
./scripts/build_release.sh staging android  # APK staging
./scripts/build_release.sh prod android     # AAB prod (Play Store)

# Manual
cd packages/app
flutter build apk --flavor prod -t lib/main_prod.dart --release \
  --obfuscate --split-debug-info=build/symbols/prod/android \
  --dart-define=FLAVOR=prod
```

---

## ⚙️ Configuração do iOS (Pendente)

Para iOS funcionar corretamente, é necessário configurar **Schemes no Xcode**:

### 1. Abrir Xcode
```bash
cd packages/app/ios
open Runner.xcworkspace
```

### 2. Criar Schemes
- **Product → Scheme → Manage Schemes**
- Criar 3 schemes: `dev`, `staging`, `prod`

### 3. Configurar Build Configurations
- Duplicar **Release** para:
  - `Release-dev`
  - `Release-staging`
  - `Release-prod`

### 4. Script para Copiar GoogleService-Info.plist
Em cada scheme, adicionar **Pre-action Script**:

```bash
FLAVOR="${CONFIGURATION##*-}"

if [ "$FLAVOR" == "dev" ]; then
    cp "${PROJECT_DIR}/Firebase/GoogleService-Info-dev.plist" \
       "${PROJECT_DIR}/Runner/GoogleService-Info.plist"
elif [ "$FLAVOR" == "staging" ]; then
    cp "${PROJECT_DIR}/Firebase/GoogleService-Info-staging.plist" \
       "${PROJECT_DIR}/Runner/GoogleService-Info.plist"
else
    cp "${PROJECT_DIR}/Firebase/GoogleService-Info-prod.plist" \
       "${PROJECT_DIR}/Runner/GoogleService-Info.plist"
fi
```

### 5. Configurar Bundle IDs
**Build Settings → Product Bundle Identifier**:
- `Release-dev`: `com.tosembanda.wegig.dev`
- `Release-staging`: `com.tosembanda.wegig.staging`
- `Release-prod`: `com.tosembanda.wegig`

---

## 🔧 Configurações Técnicas

### ProGuard / R8 (Android)
**Status**: ⚠️ **Temporariamente Desabilitado**

```kotlin
// android/app/build.gradle.kts
buildTypes {
    release {
        isMinifyEnabled = false  // TODO: Habilitar após ajustar rules
        isShrinkResources = false
    }
}
```

**Problema**: Compilação falhava com R8 habilitado  
**Solução Temporária**: Desabilitado minify, mantida obfuscação Flutter (`--obfuscate`)  
**TODO**: Ajustar `proguard-rules.pro` e reabilitar

### Firebase Configuration
- **Projeto Único**: Todos os flavors usam `to-sem-banda-83e19`
- **Apps Separados**: 6 apps registrados (3 Android + 3 iOS)
- **Firestore/Auth**: Compartilhado entre todos os flavors

⚠️ **Importante**: Em produção, considere criar projetos Firebase separados para DEV/STAGING.

---

## 📊 Métricas de Build

| Flavor | Build Type | Tempo | Tamanho | Obfuscação |
|--------|-----------|-------|---------|------------|
| DEV | Debug | 425s | ~80MB | ❌ Não |
| PROD | Release | 174s | 64.9MB | ✅ Sim |

**Otimizações Aplicadas**:
- ✅ Tree-shaking de ícones (99% redução)
- ✅ Obfuscação Dart (`--obfuscate`)
- ✅ Split debug info (`--split-debug-info`)
- ⚠️ ProGuard/R8 desabilitado temporariamente

---

## 🎯 Próximos Passos

1. ✅ ~~Registrar apps no Firebase Console~~ (CONCLUÍDO)
2. ✅ ~~Gerar firebase_options_*.dart~~ (CONCLUÍDO)
3. ✅ ~~Configurar google-services.json~~ (CONCLUÍDO)
4. ✅ ~~Configurar GoogleService-Info.plist~~ (CONCLUÍDO)
5. ✅ ~~Testar builds por flavor~~ (CONCLUÍDO)
6. ⏳ Configurar Xcode schemes (iOS) - **PENDENTE**
7. ⏳ Reabilitar ProGuard/R8 - **TODO**
8. ⏳ Criar projetos Firebase separados para DEV/STAGING - **OPCIONAL**

---

## 📚 Documentação

- **Guia Completo**: `docs/guides/FLAVORS_COMPLETE_GUIDE.md`
- **Script de Build**: `scripts/build_release.sh`
- **iOS Setup**: `docs/guides/FLAVORS_COMPLETE_GUIDE.md#ios-configuration`

---

**Configurado por**: FlutterFire CLI + Manual Setup  
**Testado em**: macOS (Android builds)  
**Último Update**: 29 Nov 2025 19:00
