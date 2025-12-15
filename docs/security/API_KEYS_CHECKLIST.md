# ✅ Checklist de Verificação - API Keys

**Data**: 28 de novembro de 2025

---

## 📋 Status das Configurações

### ✅ Arquivos Atualizados

- [x] **`.env`** - Todas as API Keys configuradas
- [x] **`android/app/src/main/AndroidManifest.xml`** - Browser key para Google Maps
- [x] **`android/app/google-services.json`** - Android key (auto-gerenciado)
- [x] **`ios/GoogleService-Info.plist`** - iOS key (auto-gerenciado)
- [x] **`ios/WeGig/Info.plist`** - OAuth Client ID para Google Sign-In
- [x] **`.env.example`** - Template atualizado

---

## 🔑 API Keys Configuradas

### Firebase (Auto Created)

| Plataforma  | Key                                       | Status         |
| ----------- | ----------------------------------------- | -------------- |
| iOS         | `AIzaSyAe_WwvD3nN-VJlMZf2L_BRpIx-ne3P_-0` | ✅ Configurada |
| Android     | `AIzaSyC_QxHROqFRoIzCHBK_NFxu-GG6uMNS0uk` | ✅ Configurada |
| Browser/Web | `AIzaSyA3Rq-Fmlsrwn-fywriTBp7xZsOo7i5fyQ` | ✅ Configurada |

### Google Maps

| Plataforma | Key                                       | Arquivo                  | Status        |
| ---------- | ----------------------------------------- | ------------------------ | ------------- |
| Android    | `AIzaSyA3Rq-Fmlsrwn-fywriTBp7xZsOo7i5fyQ` | AndroidManifest.xml      | ✅ Atualizada |
| iOS        | `AIzaSyAe_WwvD3nN-VJlMZf2L_BRpIx-ne3P_-0` | GoogleService-Info.plist | ✅ OK         |

### Google Sign-In OAuth

| Tipo | Client ID                                          | Arquivo    | Status                  |
| ---- | -------------------------------------------------- | ---------- | ----------------------- |
| iOS  | `278498777601-osk6e3v6oe0nih2r7u7vnnvd47b1n8mf...` | Info.plist | ⚠️ Verificar no console |

---

## ⚠️ Ações Pendentes (Google Cloud Console)

### 1. Verificar API Keys existem

Acesse: https://console.cloud.google.com/apis/credentials?project=to-sem-banda-83e19

**Verificar que existem 3 API Keys:**

- [ ] iOS key (auto created by Firebase)
- [ ] Android key (auto created by Firebase)
- [ ] Browser key (auto created by Firebase)

### 2. Habilitar APIs necessárias

Acesse: https://console.cloud.google.com/apis/library?project=to-sem-banda-83e19

**Habilitar:**

- [ ] Maps SDK for Android
- [ ] Maps SDK for iOS
- [ ] Places API
- [ ] Geocoding API
- [ ] Firebase Authentication API
- [ ] Firebase Cloud Messaging API

### 3. Criar OAuth Client ID para iOS (Erro 401)

**CRÍTICO para Google Sign-In funcionar:**

Acesse: https://console.cloud.google.com/apis/credentials?project=to-sem-banda-83e19

1. [ ] Click "+ CRIAR CREDENCIAIS"
2. [ ] Selecionar "ID do cliente OAuth"
3. [ ] Tipo: **iOS**
4. [ ] Nome: `WeGig iOS`
5. [ ] Bundle ID: `com.example.toSemBanda`
6. [ ] Criar e copiar Client ID
7. [ ] Atualizar `GIDClientID` em `ios/WeGig/Info.plist`
8. [ ] Atualizar `CFBundleURLSchemes` com reverso do Client ID
9. [ ] Baixar novo `GoogleService-Info.plist` do Firebase Console
10. [ ] Substituir arquivo em `ios/GoogleService-Info.plist`

**Guia detalhado**: Ver `GOOGLE_SIGN_IN_FIX_401.md`

### 4. Verificar restrições das API Keys

**Para cada API Key no Google Cloud Console:**

**iOS key**:

- [ ] Restriction type: **iOS apps**
- [ ] Bundle ID: `com.example.toSemBanda`

**Android key**:

- [ ] Restriction type: **Android apps**
- [ ] Package name: `com.example.to_sem_banda`
- [ ] SHA-1 fingerprint: Adicionar (debug e release)

**Browser key**:

- [ ] Restriction type: **None** (para Google Maps Android)
- [ ] APIs habilitadas: Maps SDK for Android

---

## 🧪 Testes Necessários

### Antes de testar

```bash
flutter clean
cd ios && rm -rf Pods build Podfile.lock && pod install && cd ..
flutter run
```

### Funcionalidades para testar

**Google Maps:**

- [ ] Mapa carrega no Android
- [ ] Mapa carrega no iOS
- [ ] Pins aparecem corretamente
- [ ] Zoom funciona
- [ ] Localização atual funciona

**Google Sign-In:**

- [ ] Botão aparece na tela de login
- [ ] Click abre tela de seleção de conta
- [ ] Login completa com sucesso (iOS)
- [ ] Login completa com sucesso (Android)
- [ ] Cria documento `users/{uid}` no Firestore
- [ ] Redireciona para ProfileFormPage (novo usuário)

**Firebase Services:**

- [ ] Auth funciona (email/senha)
- [ ] Firestore lê/escreve dados
- [ ] Storage faz upload de imagens
- [ ] Cloud Messaging recebe notificações

---

## 📞 Suporte

### Google Maps não carrega

**Verificar:**

1. API Key correta no AndroidManifest/Info.plist
2. Maps SDK habilitado no Google Cloud Console
3. Restrições da API Key configuradas
4. SHA-1 fingerprint registrado (Android)

**Logs:**

```bash
flutter run --verbose | grep -i "maps\|google"
```

### Google Sign-In erro 401

**Causa**: OAuth Client ID não configurado

**Solução**: Seguir checklist item 3 acima

**Documentação**: `GOOGLE_SIGN_IN_FIX_401.md`

---

## 📚 Documentação Criada

- ✅ **`API_KEYS_SUMMARY.md`** - Resumo completo de todas as keys
- ✅ **`GOOGLE_SIGN_IN_FIX_401.md`** - Guia rápido correção erro 401
- ✅ **`GOOGLE_SIGN_IN_SETUP.md`** - Guia completo com troubleshooting
- ✅ **`.env`** - Arquivo de environment atualizado
- ✅ **`.env.example`** - Template atualizado

---

## 🎯 Próximo Passo CRÍTICO

**ANTES de testar o app, DEVE:**

1. ✅ Acessar Google Cloud Console
2. ✅ Criar OAuth Client ID para iOS (item 3 acima)
3. ✅ Atualizar Info.plist com novo Client ID
4. ✅ Baixar GoogleService-Info.plist atualizado

**Sem isso, Google Sign-In NÃO funcionará no iOS (erro 401)**

---

**Status**: 🟡 Configuração parcial - Aguardando criação OAuth Client ID iOS  
**Última atualização**: 28 de novembro de 2025
