# iOS Push Notifications - Configuração Manual

## ⚠️ IMPORTANTE: Configuração via Xcode

As capabilities de Push Notifications no iOS devem ser configuradas via Xcode. Siga os passos abaixo:

## 📋 Passo a Passo

### 1. Abrir projeto no Xcode

```bash
cd ios
open WeGig.xcworkspace
```

### 2. Habilitar Push Notifications

1. Selecione o target **WeGig** no Project Navigator
2. Vá para aba **Signing & Capabilities**
3. Clique no botão **+ Capability**
4. Adicione **Push Notifications**
5. Adicione **Background Modes** e marque:
   - **Remote notifications**
   - **Background fetch** (opcional)

### 3. Configurar Apple Developer Portal

1. Acesse [developer.apple.com](https://developer.apple.com)
2. Vá para **Certificates, Identifiers & Profiles**
3. Selecione seu App ID (Bundle Identifier)
4. Habilite **Push Notifications**
5. Configure APNs Authentication Key:
   - Vá para **Keys** → **Create a new key**
   - Marque **Apple Push Notifications service (APNs)**
   - Baixe o arquivo `.p8` (guarde em local seguro!)
   - Anote o **Key ID** e **Team ID**

### 4. Configurar Firebase Console

1. Acesse [console.firebase.google.com](https://console.firebase.google.com)
2. Selecione seu projeto
3. Vá para **Project Settings** → **Cloud Messaging**
4. Na seção **Apple app configuration**, clique em **Upload**
5. Faça upload do arquivo `.p8` e insira:
   - **Key ID**: do passo anterior
   - **Team ID**: do passo anterior

### 5. Testar Notificações (opcional)

Após configurar, você pode testar via Firebase Console:

1. Vá para **Cloud Messaging** → **Send your first message**
2. Insira título e corpo da mensagem
3. Selecione **Send test message**
4. Adicione o FCM token do dispositivo (pode obter via logs do app)
5. Clique em **Test**

## 📱 Entitlements Criados

Após seguir os passos acima, o Xcode criará automaticamente:

```xml
<!-- ios/WeGig/WeGig.entitlements -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>aps-environment</key>
    <string>development</string> <!-- 'production' para release -->

    <key>com.apple.developer.associated-domains</key>
    <array>
        <string>applinks:tosembanda.com</string>
    </array>
</dict>
</plist>
```

## 🔐 Info.plist (já configurado)

O arquivo `ios/WeGig/Info.plist` já deve conter:

```xml
<!-- Permissões de notificação -->
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

## ✅ Verificação

Para verificar se está tudo configurado:

1. Execute o app no simulador/dispositivo
2. Verifique os logs para:
   ```
   ✅ PushNotificationService: Permission granted
   🔑 FCM Token: [seu token aqui]
   ```
3. Se não aparecer erro, a configuração está correta!

## 🚨 Troubleshooting

### Token não é gerado

- Verifique se Push Notifications está habilitado no Xcode
- Confirme que APNs Key está configurado no Firebase
- Teste em dispositivo físico (simulador tem limitações)

### Notificações não aparecem

- Verifique se app tem permissão (Settings → App → Notifications)
- Confirme que APNs environment está correto (development/production)
- Teste enviando notificação via Firebase Console

### Erro "no valid 'aps-environment' entitlement"

- Rebuild completo: `flutter clean && flutter pub get`
- Verifique Bundle Identifier no Xcode
- Confirme que certificado de desenvolvimento está válido

## 📚 Documentação Adicional

- [Firebase Cloud Messaging iOS Setup](https://firebase.google.com/docs/cloud-messaging/ios/client)
- [Apple Push Notifications Guide](https://developer.apple.com/documentation/usernotifications)
- [flutter_local_notifications iOS Setup](https://pub.dev/packages/flutter_local_notifications#ios-integration)
