# API Keys - Resumo de Configuração

**Data**: 28 de novembro de 2025  
**Projeto Firebase**: to-sem-banda-83e19  
**App**: WeGig

---

## 📋 API Keys Configuradas

### 🔥 Firebase API Keys (Auto Created)

| Plataforma  | API Key                                   | Uso                                 |
| ----------- | ----------------------------------------- | ----------------------------------- |
| **iOS**     | `AIzaSyAe_WwvD3nN-VJlMZf2L_BRpIx-ne3P_-0` | Firebase Services + Google Maps iOS |
| **Android** | `AIzaSyC_QxHROqFRoIzCHBK_NFxu-GG6uMNS0uk` | Firebase Services                   |
| **Browser** | `AIzaSyA3Rq-Fmlsrwn-fywriTBp7xZsOo7i5fyQ` | Firebase Web + Google Maps Android  |

### 🗺️ Google Maps API Keys

| Plataforma  | API Key                                   | Arquivo                                    |
| ----------- | ----------------------------------------- | ------------------------------------------ |
| **Android** | `AIzaSyA3Rq-Fmlsrwn-fywriTBp7xZsOo7i5fyQ` | `android/app/src/main/AndroidManifest.xml` |
| **iOS**     | `AIzaSyAe_WwvD3nN-VJlMZf2L_BRpIx-ne3P_-0` | Configurado via GoogleService-Info.plist   |

### 🔐 Google Sign-In OAuth Client IDs

| Tipo    | Client ID                                                                  | Arquivo                               |
| ------- | -------------------------------------------------------------------------- | ------------------------------------- |
| **iOS** | `278498777601-osk6e3v6oe0nih2r7u7vnnvd47b1n8mf.apps.googleusercontent.com` | `ios/WeGig/Info.plist` (GIDClientID) |
| **Web** | `278498777601-osk6e3v6oe0nih2r7u7vnnvd47b1n8mf.apps.googleusercontent.com` | Usado no backend Firebase             |

---

## 📁 Arquivos Atualizados

### ✅ `.env` (Desenvolvimento)

```dotenv
# Firebase
FIREBASE_API_KEY_IOS=AIzaSyAe_WwvD3nN-VJlMZf2L_BRpIx-ne3P_-0
FIREBASE_API_KEY_ANDROID=AIzaSyC_QxHROqFRoIzCHBK_NFxu-GG6uMNS0uk
FIREBASE_API_KEY_WEB=AIzaSyA3Rq-Fmlsrwn-fywriTBp7xZsOo7i5fyQ

# Google Maps
GOOGLE_MAPS_API_KEY_ANDROID=AIzaSyA3Rq-Fmlsrwn-fywriTBp7xZsOo7i5fyQ
GOOGLE_MAPS_API_KEY_IOS=AIzaSyAe_WwvD3nN-VJlMZf2L_BRpIx-ne3P_-0

# OAuth
GOOGLE_OAUTH_CLIENT_ID_IOS=278498777601-osk6e3v6oe0nih2r7u7vnnvd47b1n8mf.apps.googleusercontent.com
```

### ✅ `android/app/src/main/AndroidManifest.xml`

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyA3Rq-Fmlsrwn-fywriTBp7xZsOo7i5fyQ" />
```

**Mudança**: `AIzaSyCx9HCECrISrL-auox1RUMBU0IYGec4_PQ` → `AIzaSyA3Rq-Fmlsrwn-fywriTBp7xZsOo7i5fyQ`

### ✅ `android/app/google-services.json`

```json
"api_key": [
  {
    "current_key": "AIzaSyC_QxHROqFRoIzCHBK_NFxu-GG6uMNS0uk"
  }
]
```

**Status**: ✅ Correto (auto-gerenciado pelo Firebase)

### ✅ `ios/GoogleService-Info.plist`

```xml
<key>API_KEY</key>
<string>AIzaSyAe_WwvD3nN-VJlMZf2L_BRpIx-ne3P_-0</string>
```

**Status**: ✅ Correto (auto-gerenciado pelo Firebase)

### ✅ `ios/WeGig/Info.plist`

```xml
<key>GIDClientID</key>
<string>278498777601-osk6e3v6oe0nih2r7u7vnnvd47b1n8mf.apps.googleusercontent.com</string>
```

**Status**: ✅ Correto para Google Sign-In

---

## 🔑 Informações Importantes

### Firebase Project

- **Project ID**: `to-sem-banda-83e19`
- **Project Number**: `278498777601`
- **Storage Bucket**: `to-sem-banda-83e19.firebasestorage.app`

### Bundle IDs

- **iOS**: `com.example.toSemBanda`
- **Android**: `com.example.to_sem_banda`

### API Restrictions (Google Cloud Console)

**IMPORTANTE**: Verificar se as API Keys estão restritas corretamente:

1. **iOS key** (`AIzaSyAe_WwvD3nN-VJlMZf2L_BRpIx-ne3P_-0`)

   - Restrição: **iOS apps**
   - Bundle ID permitido: `com.example.toSemBanda`

2. **Android key** (`AIzaSyC_QxHROqFRoIzCHBK_NFxu-GG6uMNS0uk`)

   - Restrição: **Android apps**
   - Package name permitido: `com.example.to_sem_banda`

3. **Browser key** (`AIzaSyA3Rq-Fmlsrwn-fywriTBp7xZsOo7i5fyQ`)
   - Restrição: **None** ou **HTTP referrers**
   - Usado para: Google Maps Android SDK

---

## ✅ Próximos Passos

### 1. Verificar Google Cloud Console

Acesse: https://console.cloud.google.com/apis/credentials?project=to-sem-banda-83e19

**Verificar que as 3 API Keys existem:**

- ✅ iOS key (auto created by Firebase)
- ✅ Android key (auto created by Firebase)
- ✅ Browser key (auto created by Firebase)

### 2. Habilitar APIs Necessárias

**Google Cloud Console > APIs & Services > Library**

Habilitar:

- ✅ Maps SDK for Android
- ✅ Maps SDK for iOS
- ✅ Places API (para autocomplete de localização)
- ✅ Geocoding API (para conversão de coordenadas)
- ✅ Firebase Authentication API
- ✅ Firebase Cloud Messaging API

### 3. Configurar OAuth Client ID para iOS

**Para corrigir erro 401 do Google Sign-In:**

1. Google Cloud Console > Credenciais
2. Criar **OAuth 2.0 Client ID** tipo **iOS**
3. Bundle ID: `com.example.toSemBanda`
4. Copiar o Client ID gerado
5. Atualizar `ios/WeGig/Info.plist` com o novo Client ID

**Veja guia completo em**: `GOOGLE_SIGN_IN_FIX_401.md`

### 4. Testar Funcionalidades

```bash
# Limpar build
flutter clean
cd ios && rm -rf Pods build Podfile.lock && pod install && cd ..

# Executar
flutter run
```

**Testar:**

- ✅ Google Maps carrega (Android e iOS)
- ✅ Google Sign-In funciona (iOS)
- ✅ Firebase Auth funciona
- ✅ Firebase Firestore funciona
- ✅ Firebase Storage funciona
- ✅ Push Notifications funcionam

---

## 🚨 Troubleshooting

### Google Maps não carrega (Android)

**Erro**: Tela cinza no mapa

**Solução**:

1. Verificar API Key no AndroidManifest: `AIzaSyA3Rq-Fmlsrwn-fywriTBp7xZsOo7i5fyQ`
2. Habilitar "Maps SDK for Android" no Google Cloud Console
3. Verificar SHA-1 fingerprint está registrado no Firebase Console

### Google Sign-In erro 401 (iOS)

**Erro**: "The Auth Client was not found"

**Solução**:

1. Criar OAuth Client ID tipo iOS no Google Cloud Console
2. Atualizar `GIDClientID` no Info.plist
3. Ver guia: `GOOGLE_SIGN_IN_FIX_401.md`

### Firebase Auth não funciona

**Verificar**:

1. API Keys corretas nos arquivos de configuração
2. Firebase Authentication habilitado no console
3. Provedores habilitados (Email/Password, Google, Apple)

---

## 📞 Links Úteis

- **Google Cloud Console**: https://console.cloud.google.com/apis/credentials?project=to-sem-banda-83e19
- **Firebase Console**: https://console.firebase.google.com/project/to-sem-banda-83e19
- **Google Cloud APIs Library**: https://console.cloud.google.com/apis/library?project=to-sem-banda-83e19

---

**Última atualização**: 28 de novembro de 2025  
**Status**: ✅ API Keys configuradas e documentadas
