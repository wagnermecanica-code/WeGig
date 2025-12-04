# 🚀 Guia Rápido: Deploy iOS com Flavors

**Data:** 30 de Novembro de 2025  
**Status:** ✅ FUNCIONAL (via Flutter CLI)

---

## ⚡ Como Rodar AGORA (Solução Mais Simples)

### Via Flutter CLI (RECOMENDADO) ✅

```bash
cd /Users/wagneroliveira/to_sem_banda/packages/app

# DEV (desenvolvimento)
flutter run -d 00008140-001948D20AE2801C --flavor dev -t lib/main_dev.dart

# STAGING (testes)
flutter run -d 00008140-001948D20AE2801C --flavor staging -t lib/main_staging.dart

# PROD (produção)
flutter run -d 00008140-001948D20AE2801C --flavor prod -t lib/main_prod.dart
```

**Observações:**

- ✅ **Especificar `--flavor` É OBRIGATÓRIO** para que o Xcode use o scheme correto
- ✅ ID do dispositivo pode ser obtido com `flutter devices`
- ✅ Dispositivo deve estar conectado (USB ou Wireless Debugging habilitado)

---

## 🔧 Solução do Erro "Improperly formatted define flag"

### O Problema

O arquivo `packages/app/ios/Flutter/flutter_export_environment.sh` é gerado automaticamente com aspas aninhadas:

```bash
export "FLUTTER_TARGET="lib/main.dart"  # ❌ ERRO!
```

Causa erro de parsing no Xcode:

```
Improperly formatted define flag: "FLUTTER_TARGET="lib/main.dart"
```

### Solução Automática (Run Script Phase)

**✅ Script Criado:** `packages/app/ios/Runner/FixFlutterTarget.sh`

**Como Adicionar no Xcode:**

1. Abra o workspace:

   ```bash
   open /Users/wagneroliveira/to_sem_banda/packages/app/ios/Runner.xcworkspace
   ```

2. No **Project Navigator** (esquerda), clique em **"Runner"** (ícone azul)

3. Selecione o target **"Runner"** (centro, aba superior)

4. Clique na aba **"Build Phases"**

5. Clique no **"+"** (canto superior esquerdo) → **"New Run Script Phase"**

6. **Arraste** o novo **"Run Script"** para o **FINAL** da lista (após "Embed Frameworks")

7. **Expanda** o Run Script e configure:

   - **Nome:** `Fix Flutter Target`
   - **Shell:** `/bin/bash`
   - **Script:**
     ```bash
     "$SRCROOT/Runner/FixFlutterTarget.sh"
     ```
   - **Desmarque:** "Based on dependency analysis"

8. **Salve** (Cmd+S) e feche o Xcode

### Solução Manual (Se Preferir)

Se o erro ocorrer novamente e você quiser corrigir manualmente:

```bash
# Corrige as aspas no arquivo gerado
sed -i '' 's|export "FLUTTER_TARGET=".*"|export "FLUTTER_TARGET=lib/main_dev.dart"|g' \
  packages/app/ios/Flutter/flutter_export_environment.sh

# Depois, rode novamente (SEM flutter clean)
flutter run -d 00008140-001948D20AE2801C --flavor dev -t lib/main_dev.dart
```

---

## 📱 Dispositivos Disponíveis

### Listar Dispositivos Conectados

```bash
flutter devices
```

**Exemplo de saída:**

```
iPhone 17,1 (mobile) • 00008140-001948D20AE2801C • ios • iOS 18.6.2 (wireless)
macOS (desktop)      • macos                     • darwin-arm64 • macOS 15.2 24C101
```

### Conectar iPhone via Wireless Debugging

1. Conecte o iPhone via USB (primeira vez)
2. Abra Xcode → **Window** → **Devices and Simulators**
3. Selecione seu iPhone → Marque **"Connect via network"**
4. Aguarde ícone de rede aparecer ao lado do iPhone
5. Desconecte o cabo USB
6. Rode `flutter devices` para verificar conexão wireless

---

## 🧪 Troubleshooting

### Erro: "Xcode build failed"

**Solução:**

```bash
cd packages/app
rm -rf ios/build
flutter clean
flutter pub get
flutter run -d <device-id> --flavor dev -t lib/main_dev.dart --verbose
```

### Erro: "No devices found"

**Solução:**

```bash
# Verificar dispositivos conectados
flutter devices

# Verificar se Xcode reconhece o dispositivo
open -a Xcode
# Window → Devices and Simulators
```

### Erro: "Code signing failed"

**Solução:**

1. Abra o workspace no Xcode:
   ```bash
   open packages/app/ios/Runner.xcworkspace
   ```
2. Selecione o target **"Runner"**
3. Aba **"Signing & Capabilities"**
4. Selecione seu **Team** (Apple Developer Account)
5. Aguarde Xcode configurar provisioning profiles
6. Feche o Xcode e rode `flutter run` novamente

### Build Muito Lento

**Primeira execução após `flutter clean`:**

- ✅ Normal: 5-10 minutos (pod install + compilação)
- ⚠️ Se demorar >15 minutos: cancele (Ctrl+C) e rode novamente

**Execuções subsequentes:**

- ✅ Normal: 2-3 minutos (apenas código alterado)

---

## 📋 Flavors Disponíveis

| Flavor      | Arquivo Entry Point     | Firebase Config                    | Uso                   |
| ----------- | ----------------------- | ---------------------------------- | --------------------- |
| **dev**     | `lib/main_dev.dart`     | `GoogleService-Info-dev.plist`     | Desenvolvimento local |
| **staging** | `lib/main_staging.dart` | `GoogleService-Info-staging.plist` | Testes pré-produção   |
| **prod**    | `lib/main_prod.dart`    | `GoogleService-Info-prod.plist`    | App Store (produção)  |

### Diferenças Entre Flavors

```dart
// packages/app/lib/config/app_config.dart
class AppConfig {
  static const bool isDevelopment = /* flavor-based */;

  // DEV
  enableDebugMode: true
  showPerformanceOverlay: true
  logLevel: 'verbose'

  // STAGING
  enableDebugMode: true
  showPerformanceOverlay: false
  logLevel: 'info'

  // PROD
  enableDebugMode: false
  showPerformanceOverlay: false
  logLevel: 'error'
}
```

---

## 🔗 Arquivos Relacionados

- **Script de correção:** `packages/app/ios/Runner/FixFlutterTarget.sh`
- **Documentação completa:** `docs/setup/FIX_XCODE_FLUTTER_TARGET_FINAL.md`
- **Flavors Android:** `packages/app/android/app/build.gradle.kts` (linhas 72-92)
- **Flavors iOS:** `packages/app/ios/Runner.xcodeproj/xcshareddata/xcschemes/*.xcscheme`
- **Firebase configs:** `packages/app/ios/Firebase/GoogleService-Info-*.plist`

---

## ✅ Status Final

| Componente         | Status           | Observações                          |
| ------------------ | ---------------- | ------------------------------------ |
| Flutter CLI        | ✅ FUNCIONA      | Use `--flavor` obrigatório           |
| Xcode Direct       | ⚠️ REQUER SCRIPT | Adicione Run Script Phase            |
| Flavors            | ✅ 100%          | dev, staging, prod configurados      |
| Wireless Debugging | ✅ HABILITADO    | Device ID: 00008140-001948D20AE2801C |

---

**Última Atualização:** 30 de Novembro de 2025, 10:00 BRT
