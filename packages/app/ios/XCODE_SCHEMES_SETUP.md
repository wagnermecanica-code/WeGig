# 🍎 Configuração de Xcode Schemes para Flavors

**Tempo estimado:** 5-10 minutos  
**Pré-requisito:** Xcode instalado

---

## 📋 O Que Vamos Fazer

Configurar 3 schemes no Xcode para cada flavor (dev, staging, prod), permitindo selecionar qual ambiente executar diretamente do Xcode.

---

## 🚀 Passo 1: Abrir Projeto no Xcode

```bash
cd /Users/wagneroliveira/to_sem_banda/packages/app
open ios/Runner.xcworkspace
```

⚠️ **IMPORTANTE:** Abra o `.xcworkspace`, NÃO o `.xcodeproj`!

---

## 🔧 Passo 2: Criar Scheme DEV

### 2.1: Duplicar Scheme Runner

1. No Xcode, clique em **"Runner"** no topo (ao lado do seletor de dispositivo)
2. Selecione **"Manage Schemes..."** ou **"Edit Scheme..."**
3. Clique no botão **"+"** (ou clique no scheme "Runner" e pressione **⌘+D**)
4. Nome do novo scheme: **`Runner-dev`**
5. Clique **"Close"**

### 2.2: Configurar Build Configuration

1. Selecione o scheme **"Runner-dev"**
2. Clique em **"Edit Scheme..."** (ou **⌘+<**)
3. No menu lateral esquerdo, selecione **"Run"**
4. Na aba **"Info"**, em **"Build Configuration"**, selecione **"Debug"**
5. Expanda **"Pre-actions"** (abaixo de Info)
6. Clique em **"+"** → **"New Run Script Action"**
7. Cole este script:

```bash
# Script para copiar GoogleService-Info correto para DEV
echo "🔧 Configurando Firebase para DEV flavor..."

# Definir caminhos
PROJECT_DIR="${SRCROOT}"
FIREBASE_DIR="${PROJECT_DIR}/Firebase"
PLIST_DEV="${FIREBASE_DIR}/GoogleService-Info-dev.plist"
PLIST_TARGET="${PROJECT_DIR}/Runner/GoogleService-Info.plist"

# Copiar arquivo correto
if [ -f "$PLIST_DEV" ]; then
    cp "$PLIST_DEV" "$PLIST_TARGET"
    echo "✅ GoogleService-Info-dev.plist copiado com sucesso"
else
    echo "❌ ERRO: $PLIST_DEV não encontrado!"
    exit 1
fi
```

8. Em **"Provide build settings from"**, selecione **"Runner"**
9. Ainda em **"Run"**, vá para a aba **"Arguments"**
10. Em **"Arguments Passed On Launch"**, adicione:
    - `--dart-define=FLAVOR=dev`
11. Clique **"Close"**

---

## 🔧 Passo 3: Criar Scheme STAGING

Repita o Passo 2, mas com as seguintes mudanças:

### 3.1: Nome do Scheme

- **`Runner-staging`**

### 3.2: Pre-action Script

```bash
# Script para copiar GoogleService-Info correto para STAGING
echo "🔧 Configurando Firebase para STAGING flavor..."

PROJECT_DIR="${SRCROOT}"
FIREBASE_DIR="${PROJECT_DIR}/Firebase"
PLIST_STAGING="${FIREBASE_DIR}/GoogleService-Info-staging.plist"
PLIST_TARGET="${PROJECT_DIR}/Runner/GoogleService-Info.plist"

if [ -f "$PLIST_STAGING" ]; then
    cp "$PLIST_STAGING" "$PLIST_TARGET"
    echo "✅ GoogleService-Info-staging.plist copiado com sucesso"
else
    echo "❌ ERRO: $PLIST_STAGING não encontrado!"
    exit 1
fi
```

### 3.3: Arguments

- `--dart-define=FLAVOR=staging`

---

## 🔧 Passo 4: Configurar Scheme PROD

1. Edite o scheme **"Runner"** (original)
2. Siga os mesmos passos do Passo 2.2, mas use:

### 4.1: Pre-action Script

```bash
# Script para copiar GoogleService-Info correto para PROD
echo "🔧 Configurando Firebase para PROD flavor..."

PROJECT_DIR="${SRCROOT}"
FIREBASE_DIR="${PROJECT_DIR}/Firebase"
PLIST_PROD="${FIREBASE_DIR}/GoogleService-Info-prod.plist"
PLIST_TARGET="${PROJECT_DIR}/Runner/GoogleService-Info.plist"

if [ -f "$PLIST_PROD" ]; then
    cp "$PLIST_PROD" "$PLIST_TARGET"
    echo "✅ GoogleService-Info-prod.plist copiado com sucesso"
else
    echo "❌ ERRO: $PLIST_PROD não encontrado!"
    exit 1
fi
```

### 4.2: Arguments

- `--dart-define=FLAVOR=prod`

---

## 🎯 Passo 5: Configurar Bundle IDs (Opcional - Recomendado)

Para permitir instalação simultânea de DEV/STAGING/PROD no mesmo dispositivo:

### 5.1: Criar Build Configurations

1. No Xcode, selecione o projeto **"Runner"** no navegador (ícone azul)
2. Selecione o target **"Runner"**
3. Vá para a aba **"Build Settings"**
4. Procure por **"Product Bundle Identifier"**
5. Clique na seta ao lado de "Product Bundle Identifier" para expandir
6. Você verá: Debug, Release, Profile

### 5.2: Adicionar Configurações Customizadas

1. No projeto Runner (ícone azul), vá para a aba **"Info"**
2. Em **"Configurations"**, clique no **"+"** abaixo de Debug
3. Selecione **"Duplicate 'Debug' Configuration"**
4. Renomeie para **"Debug-dev"**
5. Repita para criar:
   - **"Debug-staging"**
   - **"Release-dev"**
   - **"Release-staging"**
   - **"Release-prod"** (ou renomeie Release existente)

### 5.3: Configurar Bundle IDs por Configuration

1. Volte para **"Build Settings"** do target Runner
2. Em **"Product Bundle Identifier"**, configure:
   - **Debug-dev**: `com.tosembanda.wegig.dev`
   - **Debug-staging**: `com.wegig.staging`
   - **Debug** (original): `com.wegig`
   - **Release-dev**: `com.tosembanda.wegig.dev`
   - **Release-staging**: `com.wegig.staging`
   - **Release**: `com.wegig`

### 5.4: Atualizar Schemes com Build Configurations

1. Edite **Runner-dev** → Run → Info → Build Configuration: **Debug-dev**
2. Edite **Runner-staging** → Run → Info → Build Configuration: **Debug-staging**
3. Edite **Runner** → Run → Info → Build Configuration: **Debug** (padrão)

---

## ✅ Passo 6: Testar Configuração

### 6.1: Testar DEV

1. Selecione scheme **"Runner-dev"**
2. Selecione um dispositivo/simulator
3. Pressione **⌘+R** ou clique no botão Play
4. Verifique no console do Xcode: `✅ GoogleService-Info-dev.plist copiado com sucesso`

### 6.2: Testar STAGING

1. Selecione scheme **"Runner-staging"**
2. Pressione **⌘+R**
3. Verifique no console: `✅ GoogleService-Info-staging.plist copiado com sucesso`

### 6.3: Testar PROD

1. Selecione scheme **"Runner"**
2. Pressione **⌘+R**
3. Verifique no console: `✅ GoogleService-Info-prod.plist copiado com sucesso`

---

## 🎨 Resultado Final

Depois de configurar, você terá:

```
Xcode Schemes:
├── Runner-dev       → Firebase DEV + Bundle ID .dev
├── Runner-staging   → Firebase STAGING + Bundle ID .staging
└── Runner           → Firebase PROD + Bundle ID (original)
```

No seletor de schemes do Xcode, você verá:

- **Runner-dev** ← Selecione para desenvolvimento
- **Runner-staging** ← Selecione para homologação
- **Runner** ← Selecione para produção

---

## 🐛 Troubleshooting

### Erro: "GoogleService-Info.plist not found"

**Causa:** Script não encontrou o arquivo  
**Solução:** Verifique se os arquivos existem em `ios/Firebase/`:

```bash
ls -la packages/app/ios/Firebase/
```

### Erro: "Build settings from Runner not found"

**Causa:** Opção "Provide build settings from" não selecionada  
**Solução:** No pre-action script, selecione **"Runner"** no dropdown

### App instala, mas crasha ao abrir

**Causa:** GoogleService-Info.plist errado sendo copiado  
**Solução:**

1. Verifique os logs do Xcode (⌘+Shift+Y)
2. Confirme qual .plist foi copiado
3. Force clean: **⌘+Shift+K**

### Múltiplas instalações no mesmo dispositivo não funcionam

**Causa:** Bundle IDs não configurados por configuration  
**Solução:** Siga o Passo 5 completamente

---

## 📚 Referências

- [Xcode Schemes Documentation](https://developer.apple.com/documentation/xcode/customizing-the-build-schemes-for-a-project)
- [Build Configurations](https://developer.apple.com/documentation/xcode/managing-build-configurations)
- **Guia Local**: `FLAVORS_COMPLETE_GUIDE.md`

---

**Tempo total:** 5-10 minutos (3 schemes × ~3 min cada)  
**Complexidade:** Intermediária  
**Resultado:** 3 ambientes isolados no iOS! 🎉
