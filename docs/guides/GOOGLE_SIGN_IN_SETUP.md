# Google Sign-In Setup - Correção Erro 401

**Data**: 28 de novembro de 2025  
**Erro**: "The Auth Client was not found" - 401  
**Causa**: OAuth Client ID do iOS não configurado ou incorreto no Google Cloud Console

---

## 🔴 Problema Identificado

O `GIDClientID` no `Info.plist` está correto:

```xml
<key>GIDClientID</key>
<string>278498777601-osk6e3v6oe0nih2r7u7vnnvd47b1n8mf.apps.googleusercontent.com</string>
```

**Porém**: Esse Client ID pode não estar habilitado ou está faltando o **iOS Client ID** no Google Cloud Console.

---

## ✅ Solução: Configurar Google Cloud Console

### Passo 1: Acessar Google Cloud Console

1. Acesse: https://console.cloud.google.com
2. Selecione o projeto: **to-sem-banda-83e19**
3. Menu lateral: **APIs e Serviços > Credenciais**

### Passo 2: Verificar/Criar OAuth 2.0 Client ID para iOS

**Verificar se existe:**

- Deve haver um Client ID tipo **"iOS"**
- Nome: algo como "iOS client (auto created by Google Service)"

**Se NÃO existir, criar novo:**

1. Click em **"+ CRIAR CREDENCIAIS"**
2. Selecione **"ID do cliente OAuth"**
3. Tipo de aplicativo: **iOS**
4. Preencher:
   - **Nome**: `WeGig iOS`
   - **Bundle ID**: `com.example.toSemBanda` (mesmo do GoogleService-Info.plist)
5. Click **CRIAR**

### Passo 3: Obter o Client ID correto

Após criar, você verá:

```
Client ID (iOS): 278498777601-XXXXXXXXXXXXXXXXXXXXXXXX.apps.googleusercontent.com
```

**IMPORTANTE**: Esse é o Client ID que deve estar no `Info.plist`!

### Passo 4: Atualizar Info.plist (se necessário)

Edite: `ios/WeGig/Info.plist`

```xml
<key>GIDClientID</key>
<string>278498777601-XXXXXXXXXXXXXXXXXXXXXXXX.apps.googleusercontent.com</string>

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.278498777601-XXXXXXXXXXXXXXXXXXXXXXXX</string>
        </array>
    </dict>
</array>
```

**ATENÇÃO**: O URL Scheme deve ser o **REVERSO** do Client ID:

- Client ID: `278498777601-abc123.apps.googleusercontent.com`
- URL Scheme: `com.googleusercontent.apps.278498777601-abc123`

---

## 🔧 Passo 5: Baixar novo GoogleService-Info.plist

**CRÍTICO**: Após criar/atualizar Client ID:

1. Firebase Console: https://console.firebase.google.com
2. Projeto: **to-sem-banda-83e19**
3. Configurações do projeto (ícone engrenagem) > **Configurações do projeto**
4. Aba **Geral**
5. Role até **Seus apps** > seção **iOS**
6. Click em **GoogleService-Info.plist** (download)
7. **SUBSTITUIR** o arquivo em `ios/GoogleService-Info.plist`

---

## 🔑 Passo 6: Verificar SHA-1 (Android) - Não aplicável para iOS

iOS não usa SHA-1. **Pular este passo.**

---

## 📝 Passo 7: Limpar build e testar

```bash
# 1. Limpar build
flutter clean
cd ios
rm -rf Pods Podfile.lock build
pod install
cd ..

# 2. Executar
flutter run
```

---

## 🔍 Diagnóstico Atual (Info.plist)

**Client ID atual:**

```
278498777601-osk6e3v6oe0nih2r7u7vnnvd47b1n8mf.apps.googleusercontent.com
```

**Bundle ID:**

```
com.example.toSemBanda
```

**Verificações necessárias:**

1. ✅ `GIDClientID` está presente no Info.plist
2. ✅ `CFBundleURLSchemes` está configurado
3. ❌ **VERIFICAR**: Client ID existe no Google Cloud Console?
4. ❌ **VERIFICAR**: Client ID tem Bundle ID correto (`com.example.toSemBanda`)?

---

## 🚨 Erro 401 - Causas Comuns

1. **Client ID não existe no Google Cloud Console**

   - Solução: Criar OAuth Client ID para iOS

2. **Bundle ID não corresponde**

   - Google Cloud: `com.example.toSemBanda`
   - Xcode: deve ser o mesmo
   - Verificar em: `ios/Runner.xcodeproj/project.pbxproj` (buscar `PRODUCT_BUNDLE_IDENTIFIER`)

3. **Client ID desabilitado**

   - Google Cloud Console > Credenciais > Verificar se está ativo

4. **GoogleService-Info.plist desatualizado**

   - Baixar versão mais recente do Firebase Console

5. **Cache do Google Sign-In**
   - Código já tem `_googleSignIn.signOut()` antes de login

---

## 🎯 Próximos Passos (Execute nesta ordem)

### 1. Verificar Google Cloud Console

```
1. Acesse: https://console.cloud.google.com
2. Projeto: to-sem-banda-83e19
3. APIs e Serviços > Credenciais
4. Procurar: OAuth 2.0 Client ID tipo "iOS"
5. Se NÃO existir, criar conforme "Passo 2" acima
```

### 2. Verificar Bundle ID

```bash
# No terminal:
cd ios
grep -r "PRODUCT_BUNDLE_IDENTIFIER" Runner.xcodeproj/project.pbxproj

# Deve retornar: com.example.toSemBanda
```

### 3. Se Client ID mudou, atualizar Info.plist

```bash
# Editar manualmente ou executar:
# (substituir XXXXXXXX pelo Client ID correto)
```

### 4. Baixar GoogleService-Info.plist atualizado

```
Firebase Console > Download > Substituir arquivo
```

### 5. Limpar e testar

```bash
flutter clean
cd ios && rm -rf Pods build Podfile.lock && pod install && cd ..
flutter run
```

---

## 📞 Suporte

**Se o erro persistir após seguir todos os passos:**

1. Verificar logs do Xcode:

   ```bash
   flutter run --verbose
   ```

2. Buscar por mensagens:

   - "Google Sign-In"
   - "GIDSignIn"
   - "OAuth"
   - "401"

3. Verificar se `google_sign_in` está atualizado:

   ```yaml
   # pubspec.yaml
   google_sign_in: ^6.3.0
   ```

4. Documentação oficial:
   - https://pub.dev/packages/google_sign_in
   - https://developers.google.com/identity/sign-in/ios/start

---

## ✅ Checklist de Verificação

- [ ] Client ID iOS existe no Google Cloud Console
- [ ] Bundle ID corresponde (`com.example.toSemBanda`)
- [ ] `GIDClientID` no Info.plist está correto
- [ ] `CFBundleURLSchemes` no Info.plist está correto (reverso do Client ID)
- [ ] GoogleService-Info.plist está atualizado (baixado recentemente)
- [ ] Build limpo (`flutter clean` + `pod install`)
- [ ] App rodando em dispositivo físico ou simulador iOS 14+

---

**Última atualização**: 28 de novembro de 2025
