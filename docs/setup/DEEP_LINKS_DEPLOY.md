# 🔗 Deploy dos Arquivos de Deep Linking

## Resumo

Para que os links de compartilhamento (`https://wegig.com.br/profile/...`, `https://wegig.com.br/post/...`) funcionem e abram diretamente no app:

1. Os arquivos em `docs/.well-known/` precisam estar acessíveis em `https://wegig.com.br/.well-known/`
2. O domínio `wegig.com.br` já está registrado e hospedado via GitHub Pages

---

## Arquivos Criados

### 1. `docs/.well-known/assetlinks.json` (Android)

- Configura App Links para Android
- Package names: `com.wegig.wegig`, `com.wegig.wegig.dev`, `com.wegig.wegig.staging`
- SHA-256 fingerprint do keystore de debug incluído (atualizar para release)

### 2. `docs/.well-known/apple-app-site-association` (iOS)

- Configura Universal Links para iOS
- Team ID: `6PP9UL45V7`
- Bundle IDs: `com.wegig.wegig`, `com.wegig.wegig.dev`, `com.wegig.wegig.staging`
- Paths: `/profile/*`, `/post/*`, `/conversation/*`, `/chat/*`

---

## Passos para Deploy

### Opção A: GitHub Pages (Recomendado)

O domínio `wegig.com.br` já está configurado no arquivo `docs/CNAME`, então basta:

1. **Commit e push** dos arquivos `.well-known`:

```bash
git add docs/.well-known/
git commit -m "feat: add deep linking verification files"
git push
```

2. **Verificar se está acessível**:

```bash
curl -I https://wegig.com.br/.well-known/assetlinks.json
curl -I https://wegig.com.br/.well-known/apple-app-site-association
```

⚠️ **Importante**: GitHub Pages pode ter problemas com arquivos sem extensão. Se não funcionar, use a Opção B.

### Opção B: Firebase Hosting

1. **Crie um `firebase.json`** na raiz com:

```json
{
  "hosting": {
    "public": "docs",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "headers": [
      {
        "source": "/.well-known/apple-app-site-association",
        "headers": [{ "key": "Content-Type", "value": "application/json" }]
      }
    ]
  }
}
```

2. **Deploy**:

```bash
firebase deploy --only hosting
```

---

## Para Produção (Release)

### Atualizar SHA-256 Fingerprint Android

1. **Obter fingerprint do keystore de release**:

```bash
keytool -list -v -keystore /path/to/release.keystore -alias your-key-alias
```

2. **Copiar o SHA256** e atualizar em `docs/.well-known/assetlinks.json`

### Verificar Entitlements iOS

Os arquivos de entitlements já foram atualizados:

- `packages/app/ios/Runner/Runner.entitlements`
- `packages/app/ios/Runner/RunnerDebug.entitlements`
- `packages/app/ios/Runner/RunnerRelease.entitlements`

Contêm:

```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:wegig.com.br</string>
    <string>webcredentials:wegig.com.br</string>
</array>
```

---

## Testando Deep Links

### Android

```bash
# App scheme
adb shell am start -W -a android.intent.action.VIEW \
  -d "wegig://app/profile/PROFILE_ID" com.wegig.wegig

# Universal Link
adb shell am start -W -a android.intent.action.VIEW \
  -d "https://wegig.com.br/profile/PROFILE_ID" com.wegig.wegig
```

### iOS

```bash
# App scheme
xcrun simctl openurl booted "wegig://app/profile/PROFILE_ID"

# Universal Link
xcrun simctl openurl booted "https://wegig.com.br/profile/PROFILE_ID"
```

---

## Checklist

- [x] Arquivos `.well-known/` criados
- [x] Entitlements iOS atualizados com Associated Domains
- [x] AndroidManifest.xml já configurado
- [ ] Deploy dos arquivos para `https://wegig.com.br/.well-known/`
- [ ] Atualizar SHA-256 com keystore de release
- [ ] Testar links em dispositivos reais

---

## Links Gerados pelo App

Quando um usuário compartilha um perfil ou post, o app gera:

- **Perfil**: `https://wegig.com.br/profile/{userId}/{profileId}`
- **Post**: `https://wegig.com.br/post/{postId}`

Esses links:

1. Se o app está instalado → Abre diretamente no app
2. Se o app não está instalado → Abre no navegador (pode redirecionar para app store)
