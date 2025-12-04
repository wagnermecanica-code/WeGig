# 🔐 Configuração de Code Signing - WeGig

**Data:** 4 de dezembro de 2025  
**Status:** Guia de Configuração

---

## 📋 Pré-requisitos

1. **Apple Developer Account** com acesso ao Team ID
2. **Certificado de Desenvolvedor Apple** (.p12)
3. **Provisioning Profile** para o app
4. **Bundle Identifier configurado**: `com.wegig.app`

---

## 🔑 Secrets Necessários no GitHub

Configure os seguintes secrets no repositório GitHub:
**Settings → Secrets and variables → Actions → New repository secret**

### 1. APPLE_DEVELOPER_TEAM_ID

- **Descrição**: ID do time de desenvolvimento Apple
- **Valor atual detectado**: `6PP9UL45V7`
- **Como obter**:
  1. Acesse [Apple Developer Portal](https://developer.apple.com/account)
  2. Vá em **Membership**
  3. Copie o **Team ID**

### 2. APPLE_CERTIFICATE

- **Descrição**: Certificado de desenvolvimento/distribuição em formato base64
- **Como criar**:

```bash
# 1. Exportar certificado do Keychain Access (exportar como .p12)
# Keychain Access → Meus Certificados → Apple Development/Distribution
# Botão direito → Exportar → Salvar como certificado.p12

# 2. Converter para base64
base64 -i certificado.p12 | pbcopy

# 3. Colar o conteúdo no GitHub Secret
```

**Tipos de certificado**:

- **Development**: Para builds de desenvolvimento e testes em devices
- **Distribution**: Para builds de produção (App Store/TestFlight)

### 3. APPLE_CERTIFICATE_PASSWORD

- **Descrição**: Senha do arquivo .p12 do certificado
- **Recomendação**: Use uma senha forte (mínimo 12 caracteres)

### 4. APPLE_PROVISIONING_PROFILE

- **Descrição**: Provisioning Profile em formato base64
- **Como criar**:

```bash
# 1. Baixar o Provisioning Profile do Apple Developer Portal
# https://developer.apple.com/account/resources/profiles/list

# 2. Converter para base64
base64 -i WeGig_Development.mobileprovision | pbcopy

# 3. Colar o conteúdo no GitHub Secret
```

**Tipos de Provisioning Profile**:

- **Development**: Para testes em devices físicos
- **Ad Hoc**: Para distribuição limitada
- **App Store**: Para submissão à App Store

### 5. KEYCHAIN_PASSWORD (opcional)

- **Descrição**: Senha temporária para o keychain no CI
- **Recomendação**: Use `${{ secrets.KEYCHAIN_PASSWORD }}` ou gere aleatoriamente

---

## 📱 Provisioning Profiles Necessários

Para o projeto WeGig com 3 flavors, você precisa de **3 provisioning profiles**:

### Dev Flavor

- **Bundle ID**: `com.wegig.app.dev`
- **Nome**: WeGig DEV
- **Tipo**: Development ou Ad Hoc
- **Devices**: Adicione devices de teste

### Staging Flavor

- **Bundle ID**: `com.wegig.app.staging`
- **Nome**: WeGig STAGING
- **Tipo**: Development ou Ad Hoc
- **Devices**: Adicione devices de QA

### Prod Flavor

- **Bundle ID**: `com.wegig.app`
- **Nome**: WeGig
- **Tipo**: App Store
- **Devices**: N/A (App Store não requer devices)

---

## 🛠️ Configuração Local

### 1. Verificar Team ID Atual

```bash
cd packages/app/ios
xcodebuild -project Runner.xcodeproj -showBuildSettings -configuration Release | grep DEVELOPMENT_TEAM
```

**Output esperado**: `DEVELOPMENT_TEAM = 6PP9UL45V7`

### 2. Atualizar Team ID (se necessário)

Edite manualmente ou use o script:

```bash
# Atualizar para seu Team ID
cd packages/app/ios
sed -i '' 's/DEVELOPMENT_TEAM = .*/DEVELOPMENT_TEAM = SEU_TEAM_ID;/g' Runner.xcodeproj/project.pbxproj
```

### 3. Configurar no Xcode

1. Abra `packages/app/ios/Runner.xcodeproj` no Xcode
2. Selecione o target **Runner**
3. Aba **Signing & Capabilities**
4. Marque **Automatically manage signing**
5. Selecione seu **Team**
6. Verifique se o Bundle Identifier está correto: `com.wegig.app`

---

## 🔄 Workflow GitHub Actions

Crie/atualize `.github/workflows/ios-build.yml`:

```yaml
name: iOS Build & Deploy

on:
  push:
    branches: [main, develop]
    tags:
      - "v*"
  pull_request:
    branches: [main]

jobs:
  build-ios:
    runs-on: macos-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.27.1"
          channel: "stable"
          cache: true

      - name: Install dependencies
        run: |
          cd packages/app
          flutter pub get

      - name: Setup Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: "15.0"

      - name: Install Apple Certificate
        env:
          APPLE_CERTIFICATE: ${{ secrets.APPLE_CERTIFICATE }}
          APPLE_CERTIFICATE_PASSWORD: ${{ secrets.APPLE_CERTIFICATE_PASSWORD }}
          KEYCHAIN_PASSWORD: ${{ secrets.KEYCHAIN_PASSWORD }}
        run: |
          # Criar keychain temporário
          KEYCHAIN_PATH=$RUNNER_TEMP/app-signing.keychain-db
          security create-keychain -p "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH
          security set-keychain-settings -lut 21600 $KEYCHAIN_PATH
          security unlock-keychain -p "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH

          # Importar certificado
          echo -n "$APPLE_CERTIFICATE" | base64 --decode --output certificate.p12
          security import certificate.p12 \
            -P "$APPLE_CERTIFICATE_PASSWORD" \
            -A \
            -t cert \
            -f pkcs12 \
            -k $KEYCHAIN_PATH
          security list-keychain -d user -s $KEYCHAIN_PATH

      - name: Install Provisioning Profile
        env:
          APPLE_PROVISIONING_PROFILE: ${{ secrets.APPLE_PROVISIONING_PROFILE }}
        run: |
          # Instalar provisioning profile
          PP_PATH=$RUNNER_TEMP/build_pp.mobileprovision
          echo -n "$APPLE_PROVISIONING_PROFILE" | base64 --decode --output $PP_PATH
          mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
          cp $PP_PATH ~/Library/MobileDevice/Provisioning\ Profiles/

      - name: Build iOS (Dev)
        run: |
          cd packages/app
          flutter build ios \
            --release \
            --flavor dev \
            -t lib/main_dev.dart \
            --no-codesign

      - name: Build iOS IPA
        run: |
          cd packages/app/ios
          xcodebuild \
            -workspace Runner.xcworkspace \
            -scheme dev \
            -configuration Release-dev \
            -archivePath $RUNNER_TEMP/Runner.xcarchive \
            archive

          xcodebuild \
            -exportArchive \
            -archivePath $RUNNER_TEMP/Runner.xcarchive \
            -exportPath $RUNNER_TEMP/Runner \
            -exportOptionsPlist exportOptions.plist

      - name: Upload IPA
        uses: actions/upload-artifact@v3
        with:
          name: wegig-dev.ipa
          path: ${{ runner.temp }}/Runner/*.ipa
          retention-days: 30

      - name: Cleanup
        if: always()
        run: |
          security delete-keychain $RUNNER_TEMP/app-signing.keychain-db || true
          rm -f certificate.p12
          rm -f $RUNNER_TEMP/build_pp.mobileprovision
```

---

## 📄 exportOptions.plist

Crie `packages/app/ios/exportOptions.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <!-- Opções: development, ad-hoc, app-store, enterprise -->

    <key>teamID</key>
    <string>6PP9UL45V7</string>

    <key>signingStyle</key>
    <string>manual</string>

    <key>provisioningProfiles</key>
    <dict>
        <key>com.wegig.app.dev</key>
        <string>WeGig Development</string>

        <key>com.wegig.app.staging</key>
        <string>WeGig Staging</string>

        <key>com.wegig.app</key>
        <string>WeGig App Store</string>
    </dict>

    <key>compileBitcode</key>
    <false/>

    <key>uploadBitcode</key>
    <false/>

    <key>uploadSymbols</key>
    <true/>

    <key>signingCertificate</key>
    <string>iPhone Distribution</string>
    <!-- Para development use: iPhone Developer -->
</dict>
</plist>
```

---

## 🧪 Teste Local de Code Signing

```bash
# 1. Verificar certificados instalados
security find-identity -v -p codesigning

# 2. Verificar provisioning profiles
ls ~/Library/MobileDevice/Provisioning\ Profiles/

# 3. Build com codesign
cd packages/app
flutter build ios --release --flavor dev -t lib/main_dev.dart

# 4. Verificar assinatura
codesign -dv --verbose=4 build/ios/iphoneos/Runner.app
```

---

## 📋 Checklist de Configuração

### Pré-deploy

- [ ] Team ID configurado no Xcode
- [ ] Bundle Identifier atualizado: `com.wegig.app`
- [ ] Certificados válidos no Keychain
- [ ] Provisioning Profiles instalados
- [ ] exportOptions.plist criado

### GitHub Secrets

- [ ] `APPLE_DEVELOPER_TEAM_ID` = `6PP9UL45V7`
- [ ] `APPLE_CERTIFICATE` (base64)
- [ ] `APPLE_CERTIFICATE_PASSWORD`
- [ ] `APPLE_PROVISIONING_PROFILE` (base64)
- [ ] `KEYCHAIN_PASSWORD` (opcional)

### Workflow

- [ ] `.github/workflows/ios-build.yml` criado
- [ ] Teste local de build funcionando
- [ ] Push para GitHub e verificar Actions

---

## 🚨 Troubleshooting

### Erro: "No signing certificate found"

**Solução**: Verifique se o certificado foi importado corretamente:

```bash
security find-identity -v -p codesigning
```

### Erro: "No provisioning profile found"

**Solução**: Verifique se o profile foi instalado:

```bash
ls ~/Library/MobileDevice/Provisioning\ Profiles/
```

### Erro: "Team ID mismatch"

**Solução**: Garanta que o Team ID no `exportOptions.plist` corresponde ao do certificado.

### Erro: "Bundle identifier mismatch"

**Solução**: Verifique se o Bundle ID no provisioning profile corresponde ao configurado no projeto.

---

## 📚 Recursos Adicionais

- [Apple Developer Portal](https://developer.apple.com/account)
- [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/certificates/list)
- [GitHub Actions for Flutter](https://docs.github.com/en/actions)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)

---

## 🔄 Renovação de Certificados

**Certificados expiram após 1 ano**. Para renovar:

1. Acesse Apple Developer Portal
2. Revoke o certificado antigo (opcional)
3. Crie novo certificado
4. Baixe e converta para base64
5. Atualize o secret `APPLE_CERTIFICATE` no GitHub

**Provisioning Profiles também expiram**. Renove anualmente.

---

**Última atualização:** 4 de dezembro de 2025  
**Team ID atual:** 6PP9UL45V7  
**Bundle ID:** com.wegig.app
