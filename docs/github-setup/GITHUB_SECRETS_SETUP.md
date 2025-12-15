# 🔐 Guia Rápido: Configurar GitHub Secrets

## 📋 Secrets Necessários

Acesse: `https://github.com/wagnermecanica-code/ToSemBandaRepo/settings/secrets/actions`

### 1️⃣ APPLE_DEVELOPER_TEAM_ID

```
Valor: 6PP9UL45V7
```

**Onde encontrar:**

- [Apple Developer Account](https://developer.apple.com/account) → Membership → Team ID

---

### 2️⃣ APPLE_CERTIFICATE

**Como gerar:**

```bash
# 1. Exportar certificado do Keychain Access
# Keychain Access → Meus Certificados → "Apple Development" ou "Apple Distribution"
# Botão direito → Exportar → Salvar como: certificate.p12
# Definir senha (ex: MySecurePassword123)

# 2. Converter para base64
base64 -i certificate.p12 | pbcopy

# 3. Colar o conteúdo copiado no GitHub Secret
```

**Tipos de certificado necessários:**

- **Apple Development**: Para builds dev/staging
- **Apple Distribution**: Para builds prod/App Store

---

### 3️⃣ APPLE_CERTIFICATE_PASSWORD

```
Valor: A senha que você definiu ao exportar o .p12
Exemplo: MySecurePassword123
```

---

### 4️⃣ APPLE_PROVISIONING_PROFILE

**Como gerar:**

```bash
# 1. Baixar o Provisioning Profile
# https://developer.apple.com/account/resources/profiles/list
# Selecione: WeGig Development ou WeGig Production
# Download → WeGig_Dev.mobileprovision

# 2. Converter para base64
base64 -i WeGig_Dev.mobileprovision | pbcopy

# 3. Colar o conteúdo copiado no GitHub Secret
```

**Profiles necessários:**

- **Dev**: `com.wegig.app.dev` → WeGig Development
- **Staging**: `com.wegig.app.staging` → WeGig Staging
- **Prod**: `com.wegig.app` → WeGig Production (App Store)

---

### 5️⃣ KEYCHAIN_PASSWORD (Opcional)

```
Valor: Qualquer senha segura
Exemplo: TempKeychainPass2025!
```

Usado apenas no CI/CD para criar keychain temporário.

---

## 🎬 Secrets Opcionais (TestFlight)

### 6️⃣ APPLE_ID

```
Valor: seu.email@example.com
```

Email da conta Apple Developer para upload no TestFlight.

### 7️⃣ APPLE_APP_SPECIFIC_PASSWORD

**Como gerar:**

1. [Apple ID Account](https://appleid.apple.com/account/manage) → Sign In
2. Security → App-Specific Passwords
3. Generate password → "GitHub Actions WeGig"
4. Copiar a senha gerada (ex: `xxxx-xxxx-xxxx-xxxx`)

---

## ✅ Verificação Rápida

Depois de configurar todos os secrets, teste:

```bash
# Local
cd /Users/wagneroliveira/to_sem_banda
./scripts/verify_codesigning.sh

# GitHub Actions
# Push para branch develop ou main
git push origin develop
```

---

## 📱 Criar Provisioning Profiles

### No Apple Developer Portal:

1. **Acesse:** https://developer.apple.com/account/resources/profiles/add

2. **Development Profile (Dev/Staging):**

   - Type: **iOS App Development**
   - App ID: `com.wegig.app.dev` (ou `.staging`)
   - Select Certificates: Seu certificado de desenvolvimento
   - Select Devices: Adicione devices de teste
   - Name: `WeGig Development`
   - Generate & Download

3. **Distribution Profile (Prod):**

   - Type: **App Store**
   - App ID: `com.wegig.app`
   - Select Certificates: Seu certificado de distribuição
   - Name: `WeGig Production`
   - Generate & Download

4. **Instalar localmente:**
   ```bash
   # Arrastar e soltar o .mobileprovision no Xcode
   # Ou copiar para:
   cp WeGig_Development.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/
   ```

---

## 🔄 Fluxo Completo

```bash
# 1. Gerar certificados no Keychain
# 2. Exportar como .p12 com senha
# 3. Converter certificado para base64
base64 -i certificate.p12 | pbcopy

# 4. Baixar Provisioning Profiles do portal
# 5. Converter profiles para base64
base64 -i WeGig_Dev.mobileprovision | pbcopy

# 6. Adicionar no GitHub:
#    Settings → Secrets → Actions → New repository secret
#    - APPLE_CERTIFICATE (colar base64 do certificado)
#    - APPLE_CERTIFICATE_PASSWORD (senha do .p12)
#    - APPLE_PROVISIONING_PROFILE (colar base64 do profile)
#    - APPLE_DEVELOPER_TEAM_ID (6PP9UL45V7)

# 7. Commit e push
git add .github/workflows/ios-build.yml
git commit -m "Add iOS build workflow with code signing"
git push

# 8. Verificar Actions no GitHub
# https://github.com/wagnermecanica-code/ToSemBandaRepo/actions
```

---

## 🚨 Troubleshooting

### Erro: "No signing certificate found"

```bash
# Verificar certificados locais
security find-identity -v -p codesigning
```

### Erro: "Provisioning profile doesn't include signing certificate"

- Certifique-se que o certificado usado no CI está incluído no provisioning profile
- Regenere o profile incluindo o certificado correto

### Erro: "No such file: exportOptions.plist"

```bash
# Verificar se o arquivo existe
ls packages/app/ios/exportOptions.plist
```

---

## 📞 Links Úteis

- [Apple Developer Portal](https://developer.apple.com/account)
- [Certificates](https://developer.apple.com/account/resources/certificates/list)
- [Identifiers](https://developer.apple.com/account/resources/identifiers/list)
- [Profiles](https://developer.apple.com/account/resources/profiles/list)
- [Devices](https://developer.apple.com/account/resources/devices/list)

---

**Team ID atual:** `6PP9UL45V7`  
**Bundle IDs:**

- Dev: `com.wegig.app.dev`
- Staging: `com.wegig.app.staging`
- Prod: `com.wegig.app`
