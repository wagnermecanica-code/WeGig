# 🔧 Bundle ID Resolution Report - Apple Sign-In Fix

**Data:** 4 de dezembro de 2025
**Status:** ✅ RESOLVIDO
**Problema:** Erro "invalid-credential" no Apple Sign-In

---

## 📋 Problema Identificado

O app estava apresentando erro `invalid-credential` durante tentativas de login com Apple Sign-In devido a incompatibilidade entre o bundle ID do app e o registrado no Firebase Console.

### ❌ Configuração Incorreta
- **Bundle ID do App:** `com.wegig.dev.app`
- **Bundle ID no Firebase:** `com.tosembanda.wegig.dev`
- **Resultado:** Firebase rejeitava autenticação

---

## ✅ Solução Implementada

### 1. Revertidos Bundle IDs para Valores Originais

| Componente | Bundle ID Anterior | Bundle ID Corrigido |
|------------|-------------------|-------------------|
| Runner (Dev) | `com.wegig.dev.app` | `com.tosembanda.wegig.dev` |
| RunnerTests | `com.wegig.dev.app.RennerTests` | `com.tosembanda.wegig.dev.RennerTests` |

### 2. Arquivos Atualizados

#### Configurações iOS
- ✅ `packages/app/ios/Flutter/Dev.xcconfig`
- ✅ `packages/app/ios/Firebase/GoogleService-Info-dev.plist`
- ✅ `packages/app/ios/Runner/GoogleService-Info.plist`
- ✅ `packages/app/ios/Runner.xcodeproj/project.pbxproj`

#### Documentação
- ✅ `packages/app/ios/XCODE_SCHEMES_SETUP.md`
- ✅ `CODE_SIGNING_SETUP.md`
- ✅ `XCODE_BUILD_ANALYSIS_COMPLETE_04DEC2025.md`

### 3. Commit Realizado
```bash
fix: Revert iOS bundle IDs to match Firebase Console registration

- Runner: com.tosembanda.wegig.dev (matches wegig-dev Firebase project)
- RunnerTests: com.tosembanda.wegig.dev.RennerTests
- Updated xcconfig, project.pbxproj, Firebase plists
- Fixes Apple Sign-In 'invalid-credential' error
```

---

## 🎯 Resultado Esperado

- ✅ Apple Sign-In deve funcionar sem erro "invalid-credential"
- ✅ Firebase Auth valida corretamente as credenciais
- ✅ Bundle IDs consistentes entre app e Firebase Console

---

## 📝 Próximos Passos

1. **Testar Apple Sign-In**: Executar app e verificar se login funciona
2. **Monitorar Logs**: Confirmar ausência de erros de autenticação
3. **Code Signing**: Atualizar provisioning profiles se necessário

---

## 🔍 Verificação

Para verificar se a correção funcionou:

```bash
# Verificar bundle ID atual
cd packages/app
flutter run --flavor dev --target=lib/main_dev.dart --device-id=SEU_DEVICE_ID

# Nos logs, procurar por:
# iosBundleId=com.tosembanda.wegig.dev
```

**Status:** ✅ Bundle IDs corrigidos e documentação atualizada</content>
<parameter name="filePath">/Users/wagneroliveira/to_sem_banda/BUNDLE_ID_RESOLUTION_REPORT.md