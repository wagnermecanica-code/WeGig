# Relatório de Análise: Falha na Compilação do App WeGig (iOS/Xcode)

**Data:** 4 de dezembro de 2025  
**Projeto:** WeGig - Monorepo Flutter  
**Status:** ❌ Build Falhando

---

## 🔴 PROBLEMA PRINCIPAL IDENTIFICADO

### Erro Crítico: Package Resolution Failure

```
Error: Couldn't resolve the package 'wegig_app' in 'package:wegig_app/bootstrap/bootstrap_core.dart'.
Error: Couldn't resolve the package 'wegig_app' in 'package:wegig_app/firebase_options_dev.dart'.
Error: Couldn't resolve the package 'wegig_app' in 'package:wegig_app/main.dart'.
```

**Causa Raiz:** O compilador Flutter não está conseguindo resolver o package `wegig_app` durante a compilação iOS. Isso ocorre porque o Flutter está sendo executado do diretório raiz (`/Users/wagneroliveira/to_sem_banda`) mas o package está em `packages/app/`.

**Impacto:** ❌ Build completamente bloqueado - não é possível gerar o binário iOS.

---

## 1. LOG COMPLETO DA BUILD

### Erros de Compilação (Críticos)

```dart
packages/app/lib/main_dev.dart:7:8: Error: Not found:
'package:wegig_app/bootstrap/bootstrap_core.dart'

packages/app/lib/main_dev.dart:8:8: Error: Not found:
'package:wegig_app/firebase_options_dev.dart'

packages/app/lib/main_dev.dart:9:8: Error: Not found:
'package:wegig_app/main.dart'

packages/app/lib/main_dev.dart:14:22: Error: Undefined name 'DefaultFirebaseOptions'.

packages/app/lib/main_dev.dart:13:9: Error: Method not found: 'bootstrapCoreServices'.

packages/app/lib/main_dev.dart:22:37: Error: Method not found: 'WeGigApp'.
```

### Exceção do Frontend Compiler

```
Unhandled exception:
FileSystemException(uri=org-dartlang-untranslatable-uri:package%3Awegig_app%2Fbootstrap%2Fbootstrap_core.dart;
message=StandardFileSystem only supports file:* and data:* URIs)

Target kernel_snapshot_program failed: Exception
Failed to package /Users/wagneroliveira/to_sem_banda.
Command PhaseScriptExecution failed with a nonzero exit code
```

### Warnings (Não-bloqueantes)

#### Firebase Analytics

```
warning: explicit cast to '[String : Any]' is required for dictionary literals
```

#### Firebase Core

```
warning: incompatible pointer types assigning to 'NSString * _Nullable' from 'NSNull * _Nonnull'
```

#### Firebase Auth

- Variáveis não utilizadas (`capturedCompletion`)
- Uso de APIs depreciadas:
  - `keyWindow` (iOS 13.0+)
  - `fetchSignInMethodsForEmail:completion:`
  - `updateEmail:completion:`

#### Firebase Messaging

```
warning: 'UNNotificationPresentationOptionAlert' is deprecated: first deprecated in iOS 14.0
```

#### Cloud Firestore

```
warning: 'setIndexConfigurationFromJSON:completion:' is deprecated
```

#### gRPC/Abseil

```
warning: Run script build phase 'Create Symlinks to Header Folders' will be run during every build
because it does not specify any outputs.
```

---

## 2. DEPENDÊNCIAS

### CocoaPods Instalados (70 pods total)

**Firebase SDK:** v12.4.0

- FirebaseCore: 12.4.0
- FirebaseAuth: 12.4.0
- FirebaseFirestore: 12.4.0
- FirebaseAnalytics: 12.4.0
- FirebaseCrashlytics: 12.4.0
- FirebaseMessaging: 12.4.0
- FirebaseStorage: 12.4.0

**Google Services:**

- GoogleMaps: 9.4.0
- GoogleSignIn: 8.0.0
- GoogleUtilities: 8.1.0
- Google-Maps-iOS-Utils: 6.1.0

**Outras Dependências:**

- abseil: 1.20240722.0
- gRPC-Core: 1.69.0
- gRPC-C++: 1.69.0
- BoringSSL-GRPC: 0.0.37
- leveldb-library: 1.22.6
- TOCropViewController: 2.8.0
- SDWebImage: 5.21.4

### Conflitos de Versão

✅ **Nenhum conflito detectado** - Todas as dependências Firebase estão na mesma versão (12.4.0).

⚠️ **Warnings de Deprecação:**

- Várias APIs Firebase estão depreciadas mas ainda funcionais
- APIs UIKit antigas (iOS 13/14) ainda em uso

---

## 3. CONFIGURAÇÃO DO PROJETO

### Informações Básicas

**Nome do Package:** `wegig_app`  
**Bundle Identifier:** `com.example.toSemBanda` (precisa ser atualizado)  
**Versão:** 1.0.1+2

### iOS Target Configuration

```yaml
IPHONEOS_DEPLOYMENT_TARGET: 15.0
Xcode Version: 26.0.1
iOS SDK: iPhoneOS26.0.sdk
Build Configuration: Debug
Scheme: Runner (não Dev)
```

### Otimizações Aplicadas no Podfile

```ruby
config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf'
config.build_settings['COMPILER_INDEX_STORE_ENABLE'] = 'NO'
config.build_settings['ENABLE_BITCODE'] = 'NO'
config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone' # Debug only
config.build_settings['GCC_OPTIMIZATION_LEVEL'] = '0' # Debug only
```

---

## 4. ASSINATURA E PROVISIONAMENTO

### Configuração de Code Signing

```
CODE_SIGNING_ALLOWED = YES
CODE_SIGNING_REQUIRED = YES
CODE_SIGN_IDENTITY = iPhone Developer
AD_HOC_CODE_SIGNING_ALLOWED = NO
```

### Status

⚠️ **Build Atual:** `--no-codesign` (desabilitado para debug)

**Nota:** Para deploy em device físico, será necessário:

1. Configurar Development Team
2. Configurar provisioning profiles
3. Atualizar bundle identifier

---

## 5. WARNINGS NO CI/CD

❌ **Não aplicável** - Build local, não há pipeline CI/CD configurado no momento.

**GitHub Actions Status:** Não verificado nesta análise.

---

## 6. AMBIENTE

### Versões do Sistema

```
macOS: 15.6.1 (Build 24G90)
Xcode: 26.0.1 (Build 17A400)
Flutter: 3.38.1 (stable channel)
Dart: 3.10.0
CocoaPods: 1.16.2
```

### Ferramentas Utilizadas

- **Gerenciador de Dependências:** CocoaPods
- **Package Manager:** Flutter pub
- **Build System:** Xcode Build System (não legacy)
- **Flavor Management:** flutter_flavorizr (configurado mas não funcional)

---

## 🔧 SOLUÇÃO RECOMENDADA

### Problema 1: Package Resolution (CRÍTICO)

O Flutter não consegue resolver `wegig_app` porque:

1. O comando está sendo executado do root do projeto (`/Users/wagneroliveira/to_sem_banda`)
2. O `pubspec.yaml` com `name: wegig_app` está em `packages/app/`
3. O Flutter não está configurado para trabalhar com a estrutura de monorepo

**Soluções:**

#### Opção A: Executar do diretório correto (RECOMENDADO)

```bash
cd /Users/wagneroliveira/to_sem_banda/packages/app
flutter build ios --debug --no-codesign -t lib/main_dev.dart
```

#### Opção B: Configurar pubspec.yaml no root

Criar um `pubspec.yaml` no root que aponte para o package app.

#### Opção C: Ajustar imports

Mudar os imports de `package:wegig_app/...` para caminhos relativos (não recomendado).

### Problema 2: Flavor Scheme Ausente

O scheme `dev` foi criado mas não está sendo reconhecido corretamente.

**Solução:**

```bash
# Verificar se o scheme existe
ls /Users/wagneroliveira/to_sem_banda/ios/Runner.xcodeproj/xcshareddata/xcschemes/

# Se necessário, usar o scheme Runner sem flavor
flutter build ios --debug --no-codesign -t packages/app/lib/main_dev.dart
```

### Problema 3: Warnings de Deprecação

**Solução:** Não bloqueante. Atualizar Firebase plugins futuramente:

```bash
flutter pub upgrade firebase_core firebase_auth firebase_messaging
```

---

## 📊 RESUMO EXECUTIVO

| Categoria              | Status          | Severidade |
| ---------------------- | --------------- | ---------- |
| Package Resolution     | ❌ Falhando     | 🔴 Crítica |
| CocoaPods Dependencies | ✅ OK           | 🟢 Baixa   |
| Code Signing           | ⚠️ Desabilitado | 🟡 Média   |
| Deprecation Warnings   | ⚠️ Presente     | 🟡 Baixa   |
| Build Performance      | ✅ Otimizado    | 🟢 Baixa   |
| Xcode Version          | ✅ Atualizado   | 🟢 Baixa   |

---

## 🎯 PRÓXIMOS PASSOS

1. ✅ **Imediato:** Executar build do diretório correto (`packages/app/`)
2. ⚠️ **Curto Prazo:** Configurar monorepo adequadamente ou mover app para root
3. 📋 **Médio Prazo:** Atualizar plugins Firebase para eliminar warnings
4. 🔐 **Antes do Deploy:** Configurar code signing e provisioning profiles
5. 🏗️ **Otimização:** Implementar CI/CD com GitHub Actions

---

**Gerado em:** 4 de dezembro de 2025  
**Ferramenta:** Copilot Code Analysis  
**Arquivo de Log Completo:** Disponível no terminal de saída
