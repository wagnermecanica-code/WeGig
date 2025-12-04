# iOS Flavors - Configuração Completa ✅

**Data:** 30 de Novembro de 2025  
**Status:** ✅ 100% FUNCIONAL

## 📋 Resumo

Flutter iOS flavors totalmente configurados e funcionais. O comando `flutter run --flavor dev` agora funciona corretamente.

## 🎯 O Que Foi Feito

### 1. Schemes Corretas (Flutter CLI Compatible)

```
Antes: Runner-dev, Runner-staging
Depois: dev, staging
```

**Por quê?** Flutter espera que `--flavor dev` corresponda a um scheme chamado `dev` (não `Runner-dev`).

### 2. Build Configurations Completas

**Projeto (global) - 9 configurações:**

- Debug, Release, Profile (base)
- Debug-dev, Release-dev, Profile-dev
- Debug-staging, Release-staging, Profile-staging

**Runner Target - 9 configurações:**

- Debug, Release, Profile (base)
- Debug-dev, Release-dev, Profile-dev
- Debug-staging, Release-staging, Profile-staging

### 3. CocoaPods Integração

**Podfile atualizado:**

```ruby
project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
  'Debug-dev' => :debug,
  'Release-dev' => :release,
  'Profile-dev' => :release,
  'Debug-staging' => :debug,
  'Release-staging' => :release,
  'Profile-staging' => :release,
}
```

**Arquivos gerados (30 totais):**

- 24x `.xcfilelist` (input/output files para frameworks e resources)
- 6x `.xcconfig` (configurações do CocoaPods por flavor)

### 4. Schemes Configuration

**dev.xcscheme:**

- TestAction: `Debug-dev`
- LaunchAction: `Debug-dev`
- ProfileAction: `Profile-dev`
- AnalyzeAction: `Debug-dev`
- ArchiveAction: `Release-dev`
- Pre-action: Copia `GoogleService-Info-dev.plist`
- Command-line arg: `--dart-define=FLAVOR=dev`

**staging.xcscheme:**

- TestAction: `Debug-staging`
- LaunchAction: `Debug-staging`
- ProfileAction: `Profile-staging`
- AnalyzeAction: `Debug-staging`
- ArchiveAction: `Release-staging`
- Pre-action: Copia `GoogleService-Info-staging.plist`
- Command-line arg: `--dart-define=FLAVOR=staging`

## 🚀 Como Usar

### Desenvolvimento (Dev Flavor)

```bash
cd packages/app

# Rodar no iPhone
flutter run --flavor dev -t lib/main_dev.dart

# Build debug
flutter build ios --flavor dev -t lib/main_dev.dart --debug

# Build release
flutter build ios --flavor dev -t lib/main_dev.dart --release
```

### Staging

```bash
cd packages/app

# Rodar no iPhone
flutter run --flavor staging -t lib/main_staging.dart

# Build release
flutter build ios --flavor staging -t lib/main_staging.dart --release
```

### Produção

```bash
cd packages/app

# Build release (sem flavor, usa configuração padrão)
flutter build ios -t lib/main_prod.dart --release

# Ou especificando explicitamente
flutter run --flavor prod -t lib/main_prod.dart
```

## 🛠️ Scripts de Automação Criados

### 1. `add_flavor_configs.rb`

Cria build configurations no projeto (nível global).

### 2. `create_runner_configs.sh`

Script Bash + Python para criar primeira configuração do Runner target.

### 3. `create_remaining_configs.py` ⭐

**Script principal** que cria todas as 5 configurações restantes do Runner target:

- Release-dev
- Profile-dev
- Debug-staging
- Release-staging
- Profile-staging

**Uso:**

```bash
cd packages/app/ios
python3 create_remaining_configs.py
```

## 📁 Arquivos Importantes

### Configuração

- `ios/Runner.xcodeproj/project.pbxproj` - Projeto Xcode (editado automaticamente)
- `ios/Podfile` - Configuração CocoaPods com flavors
- `ios/Runner.xcodeproj/xcshareddata/xcschemes/dev.xcscheme`
- `ios/Runner.xcodeproj/xcshareddata/xcschemes/staging.xcscheme`

### Firebase Configs

- `ios/Firebase/GoogleService-Info-dev.plist`
- `ios/Firebase/GoogleService-Info-staging.plist`
- `ios/Firebase/GoogleService-Info-prod.plist`
- `ios/Runner/GoogleService-Info.plist` (copiado dinamicamente via pre-action)

### Entry Points

- `lib/main_dev.dart` - Dev environment
- `lib/main_staging.dart` - Staging environment
- `lib/main_prod.dart` - Production environment

## 🔍 Troubleshooting

### Erro: "Bundle identifier is missing"

**Causa:** Configuração do Runner target não foi criada.  
**Solução:** Rodar `python3 create_remaining_configs.py`

### Erro: "Unable to load contents of file list"

**Causa:** CocoaPods não gerou `.xcfilelist` para a configuração.  
**Solução:**

1. Atualizar `Podfile` com a configuração
2. Rodar `pod install`

### Erro: "You must specify a --flavor option"

**Causa:** Scheme não corresponde ao nome do flavor.  
**Solução:** Renomear scheme de `Runner-dev` para `dev`

### Pod install travado

**Solução:**

```bash
cd packages/app/ios
rm -rf Pods Podfile.lock .symlinks
pod install --repo-update
```

## ✅ Validação

Para verificar se está tudo configurado:

```bash
cd packages/app/ios

# 1. Verificar schemes
xcodebuild -project Runner.xcodeproj -list

# Deve mostrar:
#   Schemes:
#     Runner
#     dev
#     staging

# 2. Verificar configurações do Runner target
grep -A 10 "Build configuration list for PBXNativeTarget" Runner.xcodeproj/project.pbxproj

# Deve mostrar todas as 9 configurações

# 3. Verificar arquivos CocoaPods
ls -1 "Pods/Target Support Files/Pods-Runner/" | grep -E "(dev|staging)"

# Deve mostrar 30 arquivos (.xcfilelist e .xcconfig)
```

## 🎉 Resultado Final

✅ **Flutter CLI funciona:** `flutter run --flavor dev`  
✅ **Xcode funciona:** Scheme "dev" compila e roda  
✅ **CocoaPods funciona:** Todos os .xcfilelist gerados  
✅ **Firebase funciona:** Configs corretos por flavor  
✅ **Build funciona:** Debug, Release, Profile por flavor

---

**Próximos passos:** Testar no dispositivo físico e validar as 9 bottom sheets do app! 🚀
