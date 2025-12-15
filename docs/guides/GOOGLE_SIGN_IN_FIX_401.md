# 🚨 CORREÇÃO RÁPIDA - Google Sign-In Erro 401

**Erro**: "The Auth Client was not found" (401)  
**Data**: 28 de novembro de 2025

---

## ⚡ Solução Rápida (5 minutos)

### 1️⃣ Acessar Google Cloud Console

🔗 **Link direto**: https://console.cloud.google.com/apis/credentials?project=to-sem-banda-83e19

### 2️⃣ Criar OAuth Client ID para iOS

**No Google Cloud Console:**

1. Click em **"+ CRIAR CREDENCIAIS"** (topo da página)
2. Selecione **"ID do cliente OAuth"**
3. Preencher formulário:
   - **Tipo de aplicativo**: iOS
   - **Nome**: `WeGig iOS`
   - **Bundle ID**: `com.example.toSemBanda` ⚠️ **EXATO - copie e cole!**
4. Click **CRIAR**

### 3️⃣ Copiar o Client ID gerado

Após criar, você verá algo como:

```
ID do cliente: 278498777601-XXXXXXXXXXXXXXXX.apps.googleusercontent.com
```

**📋 COPIE esse Client ID completo!**

### 4️⃣ Atualizar Info.plist

Edite o arquivo: `ios/WeGig/Info.plist`

Procure por:

```xml
<key>GIDClientID</key>
<string>278498777601-osk6e3v6oe0nih2r7u7vnnvd47b1n8mf.apps.googleusercontent.com</string>
```

**SUBSTITUA** pelo Client ID que você copiou no passo 3.

### 5️⃣ Atualizar CFBundleURLSchemes

**No mesmo arquivo Info.plist**, procure por:

```xml
<key>CFBundleURLSchemes</key>
<array>
    <string>com.googleusercontent.apps.278498777601-osk6e3v6oe0nih2r7u7vnnvd47b1n8mf</string>
</array>
```

**SUBSTITUA** pelo reverso do seu Client ID:

- Se Client ID é: `278498777601-abc123xyz.apps.googleusercontent.com`
- URL Scheme deve ser: `com.googleusercontent.apps.278498777601-abc123xyz`

### 6️⃣ Baixar GoogleService-Info.plist atualizado

1. Acesse: https://console.firebase.google.com/project/to-sem-banda-83e19/settings/general
2. Role até seção **Seus apps**
3. Procure o app **iOS** (ícone Apple)
4. Click em **GoogleService-Info.plist** (botão download)
5. **SUBSTITUA** o arquivo em `ios/GoogleService-Info.plist`

### 7️⃣ Limpar build e testar

```bash
# Terminal - na pasta raiz do projeto
flutter clean
cd ios
rm -rf Pods Podfile.lock build
pod install
cd ..
flutter run
```

---

## 📋 Informações do Projeto

**Bundle ID (iOS)**: `com.example.toSemBanda`  
**Project ID (Firebase)**: `to-sem-banda-83e19`  
**GCM Sender ID**: `278498777601`

---

## ✅ Verificação Rápida

Após seguir os passos:

1. ✅ Client ID iOS criado no Google Cloud Console
2. ✅ `GIDClientID` atualizado no Info.plist
3. ✅ `CFBundleURLSchemes` atualizado no Info.plist
4. ✅ GoogleService-Info.plist baixado e substituído
5. ✅ Build limpo executado
6. ✅ App testado

---

## 🆘 Se o erro persistir

**Verificar se Bundle ID está correto:**

```bash
grep -A 2 "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj
# Deve mostrar: com.example.toSemBanda
```

**Logs detalhados:**

```bash
flutter run --verbose | grep -i "google\|oauth\|401"
```

**Verificar credenciais no Google Cloud:**

- Deve ter 2 Client IDs:
  1. **Web client** (auto created by Google Service)
  2. **iOS client** (o que você criou agora)

---

## 📞 Links Úteis

- **Google Cloud Console**: https://console.cloud.google.com/apis/credentials?project=to-sem-banda-83e19
- **Firebase Console**: https://console.firebase.google.com/project/to-sem-banda-83e19
- **Documentação Google Sign-In**: https://pub.dev/packages/google_sign_in

---

**⏱️ Tempo estimado**: 5-10 minutos  
**🎯 Prioridade**: ALTA (bloqueia autenticação)
