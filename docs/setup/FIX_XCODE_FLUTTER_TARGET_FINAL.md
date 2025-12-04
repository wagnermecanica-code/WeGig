# 🔧 Solução Definitiva: Erro "Improperly formatted define flag" no Xcode

**Data:** 30 de Novembro de 2025  
**Status:** ✅ **RESOLVIDO**

## 📋 Problema

Ao buildar o app iOS via Xcode, ocorria erro:

```
Improperly formatted define flag: "FLUTTER_TARGET="lib/main.dart"
```

### Causa Raiz

O arquivo `Flutter/flutter_export_environment.sh` é gerado automaticamente pelo Flutter com aspas aninhadas:

```bash
export "FLUTTER_TARGET="lib/main.dart"  # ❌ ERRADO
```

Deveria ser:

```bash
export "FLUTTER_TARGET=lib/main_dev.dart"  # ✅ CORRETO
```

## ✅ Solução Implementada

### Abordagem: Run Script Phase Pós-Flutter

Criamos um script que executa **APÓS** o Flutter gerar os arquivos, corrigindo as aspas:

**Arquivo:** `packages/app/ios/Runner/FixFlutterTarget.sh`

```bash
#!/bin/bash

# Script executado APÓS Flutter gerar flutter_export_environment.sh
# Corrige o problema das aspas aninhadas

ENV_FILE="${SRCROOT}/Flutter/flutter_export_environment.sh"

if [ ! -f "$ENV_FILE" ]; then
    echo "❌ flutter_export_environment.sh não encontrado"
    exit 0
fi

echo "🔧 Corrigindo FLUTTER_TARGET em $ENV_FILE..."

# Detectar qual flavor está sendo usado baseado na configuração
if [[ "$CONFIGURATION" == *"dev"* ]]; then
    TARGET="lib/main_dev.dart"
    echo "📱 Flavor: DEV"
elif [[ "$CONFIGURATION" == *"staging"* ]]; then
    TARGET="lib/main_staging.dart"
    echo "📱 Flavor: STAGING"
else
    TARGET="lib/main_prod.dart"
    echo "📱 Flavor: PRODUCTION"
fi

# Substituir a linha com problema
sed -i '' 's|export "FLUTTER_TARGET=".*"|export "FLUTTER_TARGET='$TARGET'"|g' "$ENV_FILE"

echo "✅ FLUTTER_TARGET configurado para: $TARGET"
cat "$ENV_FILE" | grep FLUTTER_TARGET
```

### Configuração no Xcode

**Build Phases → Run Script (adicionado ao final):**

```bash
# Fix FLUTTER_TARGET nested quotes
"$SRCROOT/Runner/FixFlutterTarget.sh"
```

**Configurações:**

- ✅ Shell: `/bin/bash`
- ✅ Nome: "Fix Flutter Target"
- ✅ "Based on dependency analysis": **DESMARCADO** (sempre executar)
- ✅ Posição: **APÓS** todos os outros Run Scripts

## 🚀 Como Usar

### Opção 1: Flutter CLI (RECOMENDADO)

```bash
cd packages/app

# DEV
flutter run -d <device-id> --flavor dev -t lib/main_dev.dart

# STAGING
flutter run -d <device-id> --flavor staging -t lib/main_staging.dart

# PROD
flutter run -d <device-id> --flavor prod -t lib/main_prod.dart
```

### Opção 2: Xcode

1. Abrir workspace:

   ```bash
   open packages/app/ios/Runner.xcworkspace
   ```

2. **Selecionar scheme correto** no dropdown (topo):

   - `dev` → para desenvolvimento
   - `staging` → para staging
   - `Runner` → para produção

3. Clicar em ▶️ Run

## 🧪 Validação

Para verificar se o script está funcionando:

```bash
# Após build, verificar o arquivo gerado:
cat packages/app/ios/Flutter/flutter_export_environment.sh | grep FLUTTER_TARGET

# Deve mostrar (sem aspas aninhadas):
export "FLUTTER_TARGET=lib/main_dev.dart"  # ✅ CORRETO
```

## 📝 Histórico

### Tentativas Anteriores (Falharam)

1. **PreActions em BuildAction** → Executava ANTES do Flutter gerar o arquivo, então era sobrescrito
2. **Modificação via sed em PreAction** → Problemas de escape de caracteres
3. **Modificação via grep+echo em PreAction** → Timing incorreto (antes do Flutter)

### Solução Final (Funciona)

✅ **Run Script Phase pós-Flutter** → Executa DEPOIS do Flutter gerar, corrige o arquivo final

## 🎯 Por Que Funciona

A ordem de execução é:

1. **Compile Sources**
2. **Run Script: "Run Script" (Flutter tools)** → Gera `flutter_export_environment.sh` com aspas erradas
3. **Run Script: "Fix Flutter Target"** ⭐ → Corrige as aspas
4. **Link Binary**
5. **Embed Frameworks**

O script detecta automaticamente o flavor baseado em `$CONFIGURATION` e aplica o target correto.

## 🔗 Arquivos Relacionados

- `packages/app/ios/Runner/FixFlutterTarget.sh` - Script de correção
- `packages/app/ios/Runner.xcodeproj/project.pbxproj` - Configuração do Run Script Phase
- `packages/app/ios/Flutter/flutter_export_environment.sh` - Arquivo corrigido (gerado automaticamente)

## ⚠️ Importante

- ✅ O script é **não-destrutivo** (sai silenciosamente se arquivo não existir)
- ✅ Detecta **automaticamente** o flavor pela configuration
- ✅ Funciona para **todos os flavors** (dev, staging, prod)
- ✅ Compatível com **builds via CLI e Xcode**

---

**Status Final:** 🎉 **PROBLEMA RESOLVIDO**
