# 🔍 Guia de Ativação do Monitoramento (Firebase Crashlytics + Analytics)

**Status:** ✅ **CÓDIGO TOTALMENTE IMPLEMENTADO** - Apenas verificação necessária

**Última Atualização:** 27 de novembro de 2025

---

## 📊 O que já está implementado

### ✅ Firebase Crashlytics (Captura de Erros)

**Código implementado em `lib/main.dart`:**

```dart
// 1. Captura de erros do framework Flutter
FlutterError.onError = (details) {
  FirebaseCrashlytics.instance.recordFlutterFatalError(details);
};

// 2. Captura de erros assíncronos (async/await)
PlatformDispatcher.instance.onError = (error, stack) {
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};

// 3. Tratamento especial: Silencia erros não-fatais do Google Maps iOS
if (errorStr.contains('google_maps_flutter_ios') &&
    errorStr.contains('channel-error')) {
  return true; // Ignora (erro conhecido, não afeta usuário)
}
```

**Onde é usado:**

- `lib/main.dart` - Captura global de erros
- `lib/services/analytics_service.dart` - Método `logError()` para erros específicos
- `lib/services/profile_service.dart` - 6 blocos `try-catch` com `FirebaseCrashlytics.instance.recordError()`

**Dependência:** `firebase_crashlytics: ">=5.0.5 <6.0.0"` em `pubspec.yaml` ✅

---

### ✅ Firebase Analytics (Rastreamento de Eventos)

**Código implementado em `lib/services/analytics_service.dart`:**

```dart
class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Eventos rastreados:
  - logLoginSuccess()        → Firebase Analytics: login
  - logLoginFailure()        → Firebase Analytics: login_failure
  - logSignUpSuccess()       → Firebase Analytics: sign_up
  - logLogout()              → Firebase Analytics: logout
  - logPasswordReset()       → Firebase Analytics: password_reset
  - logEmailVerificationSent() → Firebase Analytics: email_verification_sent
  - logEvent()               → Eventos customizados genéricos
}
```

**Onde é usado:**

- `lib/services/profile_service.dart` - Eventos de perfil:
  - `profile_created`
  - `profile_switched`
  - `profile_updated`
  - `profile_deleted`

**Dependência:** `firebase_analytics: ">=12.0.3 <13.0.0"` em `pubspec.yaml` ✅

**Configuração Android:** `com.google.gms.google-services` plugin em `android/app/build.gradle.kts` ✅

---

## 🚀 Passo a Passo: Verificar se está ativo

### Passo 1: Verificar Firebase Console

#### 1.1. Crashlytics

1. Acesse [Firebase Console](https://console.firebase.google.com/)
2. Selecione o projeto **`to-sem-banda-83e19`**
3. No menu lateral, clique em **Crashlytics**
4. Você deverá ver uma das seguintes telas:

**✅ Se já está ativo:**

- Dashboard com gráficos de estabilidade
- Lista de crashes (pode estar vazia se nenhum erro ocorreu)
- Abas: "Crashes", "Velocities", "Configurações"

**⚠️ Se precisa ativar:**

- Mensagem: "Configure o Crashlytics para começar"
- Botão: "Ativar Crashlytics"
- Clique no botão e aguarde 1-2 minutos

#### 1.2. Analytics

1. No mesmo projeto `to-sem-banda-83e19`
2. No menu lateral, clique em **Analytics** → **Dashboard**
3. Você deverá ver:

**✅ Se já está ativo:**

- Gráfico de "Usuários ativos" (pode estar em 0 se ninguém usou ainda)
- Cards: "Usuários em tempo real", "Eventos", "Conversões"
- Seção "Principais eventos" com lista

**⚠️ Se não há dados:**

- Normal se o app ainda não foi usado por usuários reais
- Continue para testar com DebugView (próximo passo)

---

### Passo 2: Testar Crashlytics (Forçar crash de teste)

**IMPORTANTE:** Teste em **dispositivo físico** (iOS ou Android), não no simulador!

#### 2.1. Adicionar botão de teste (temporário)

Adicione este código em qualquer página (ex: `lib/pages/home_page.dart`):

```dart
// No corpo do Scaffold, adicione:
floatingActionButton: FloatingActionButton(
  onPressed: () {
    throw Exception('🧪 TESTE CRASHLYTICS - Este erro é proposital!');
  },
  child: Icon(Icons.bug_report),
  backgroundColor: Colors.red,
),
```

#### 2.2. Executar teste

```bash
# 1. Conecte um dispositivo físico via USB (iOS ou Android)
flutter run --release

# 2. No app, toque no botão vermelho com ícone de bug
# 3. O app irá crashar e fechar imediatamente (esperado!)
# 4. Reabra o app
```

#### 2.3. Verificar resultado no Firebase Console

```bash
# Aguarde 1-5 minutos para o relatório ser enviado
# No Firebase Console → Crashlytics → Crashes
# Você deverá ver:
# - 1 novo crash com mensagem "TESTE CRASHLYTICS"
# - Stack trace completo
# - Dispositivo, SO, versão do app
```

**✅ SUCESSO:** Se o crash aparecer, Crashlytics está funcionando!

**❌ NÃO APARECEU:** Verifique:

1. `google-services.json` está em `android/app/`? ✅ (já verificado)
2. Executou em `--release` mode? (Debug mode não envia relatórios)
3. Aguardou 5 minutos? (Pode haver atraso)

#### 2.4. Remover botão de teste

```bash
# Após confirmar que funciona, remova o floatingActionButton
git checkout lib/pages/home_page.dart  # Reverte mudanças
```

---

### Passo 3: Testar Analytics (DebugView)

**IMPORTANTE:** DebugView só funciona em **dispositivos físicos** conectados via USB!

#### 3.1. Habilitar DebugView

**Android:**

```bash
# 1. Conecte dispositivo Android via USB
adb shell setprop debug.firebase.analytics.app com.example.to_sem_banda
adb shell setprop log.tag.FA VERBOSE
adb shell setprop log.tag.FA-SVC VERBOSE

# 2. Execute o app
flutter run
```

**iOS:**

```bash
# 1. Adicione argumento de linha de comando no Xcode:
# Product → Scheme → Edit Scheme → Run → Arguments → Arguments Passed On Launch
# Adicione: -FIRAnalyticsDebugEnabled

# 2. Ou via Flutter:
flutter run --dart-define=ANALYTICS_DEBUG=true
```

#### 3.2. Abrir DebugView no Firebase Console

1. Firebase Console → **Analytics** → **DebugView**
2. Você deverá ver:
   - Dispositivo conectado aparece na lista
   - Eventos em tempo real conforme você usa o app

#### 3.3. Testar eventos

**No app, execute estas ações:**

| Ação no App                          | Evento Esperado no DebugView    |
| ------------------------------------ | ------------------------------- |
| Login com email/senha                | `login` (loginMethod: password) |
| Criar novo perfil                    | `profile_created`               |
| Trocar perfil ativo                  | `profile_switched`              |
| Editar perfil                        | `profile_updated`               |
| Deletar perfil                       | `profile_deleted`               |
| Abrir página de recuperação de senha | `password_reset`                |
| Enviar email de verificação          | `email_verification_sent`       |

**✅ SUCESSO:** Se os eventos aparecerem em tempo real, Analytics está funcionando!

#### 3.4. Desabilitar DebugView (após teste)

**Android:**

```bash
adb shell setprop debug.firebase.analytics.app .none.
```

**iOS:**

```bash
# Remova o argumento -FIRAnalyticsDebugEnabled do Xcode
```

---

### Passo 4: Verificar símbolos de depuração (Crashlytics)

**Para builds ofuscados (release)**, é necessário enviar símbolos de depuração ao Firebase:

#### 4.1. Android (ProGuard symbols)

```bash
# Após build release, execute:
cd android
./gradlew app:assembleLRelease
./gradlew app:crashlyticsUploadMappingRelease

# Ou use o script automatizado:
cd /Users/wagneroliveira/to_sem_banda
./scripts/build_release.sh
```

**Configuração existente em `android/app/build.gradle.kts`:**

```kotlin
buildTypes {
  release {
    isMinifyEnabled = true          // ✅ Ofuscação ativada
    isShrinkResources = true
    proguardFiles(...)
  }
}
```

#### 4.2. iOS (dSYM symbols)

```bash
# Build com símbolos separados
flutter build ios --release --obfuscate --split-debug-info=build/symbols/ios

# Upload automático via Firebase (se configurado) ou manual:
# 1. Abra Xcode
# 2. Archive → Distribute App → Upload Symbols to Crash Reporting
```

---

## 📋 Checklist de Verificação Final

Antes de lançar para beta testers, confirme:

### Crashlytics

- [ ] ✅ Crashlytics ativado no Firebase Console
- [ ] ✅ Teste de crash forçado executado com sucesso
- [ ] ✅ Crash apareceu no dashboard do Firebase (1-5 min de atraso)
- [ ] ✅ Stack trace legível e completo
- [ ] ✅ Símbolos de depuração enviados para builds release

### Analytics

- [ ] ✅ Analytics ativado no Firebase Console
- [ ] ✅ DebugView testado com dispositivo físico
- [ ] ✅ Eventos de login aparecem no DebugView
- [ ] ✅ Eventos de perfil (`profile_created`, etc.) aparecem
- [ ] ✅ User properties configuradas (visto em Analytics → User Properties)

### Configuração

- [ ] ✅ `google-services.json` presente em `android/app/`
- [ ] ✅ `GoogleService-Info.plist` presente em `ios/WeGig/`
- [ ] ✅ Plugin `com.google.gms.google-services` em `android/app/build.gradle.kts`
- [ ] ✅ Firebase inicializado em `main.dart` (antes de runApp)
- [ ] ✅ Error handlers configurados em `main.dart`

---

## 🐛 Solução de Problemas

### Problema: Crashlytics não recebe relatórios

**Causas comuns:**

1. **Testando em debug mode:**

   - ❌ `flutter run` (debug) → Não envia relatórios
   - ✅ `flutter run --release` → Envia relatórios

2. **Testando em simulador:**

   - ❌ iOS Simulator / Android Emulator → Pode não enviar
   - ✅ Dispositivo físico → Sempre envia

3. **Crashlytics não ativado:**

   - Verifique Firebase Console → Crashlytics → "Ativar Crashlytics"

4. **Aguardando pouco tempo:**
   - Normal: 1-5 minutos de atraso
   - Anormal: 15+ minutos → Verifique logs

**Verificação de logs:**

```bash
# Android
flutter run --release
adb logcat | grep -i firebase

# iOS
flutter run --release
# No Xcode: Window → Devices and Simulators → Open Console
# Filtrar por: "firebase"
```

---

### Problema: Analytics não mostra eventos

**Causas comuns:**

1. **DebugView não habilitado:**

   - Execute `adb shell setprop debug.firebase.analytics.app com.example.to_sem_banda` (Android)
   - Adicione `-FIRAnalyticsDebugEnabled` no Xcode (iOS)

2. **Dispositivo não aparece no DebugView:**

   - Confirme que está conectado via USB (não Wi-Fi)
   - Aguarde 1-2 minutos após abrir o app

3. **Eventos não aparecem:**

   - Verifique se `AnalyticsService().logEvent()` está sendo chamado no código
   - Use `debugPrint()` para confirmar execução:
     ```dart
     debugPrint('📊 Logando evento: profile_created');
     await _analyticsService.logEvent(name: 'profile_created');
     ```

4. **Dashboard está vazio (não DebugView):**
   - Normal! Dashboard só mostra dados após 24-48 horas
   - Use DebugView para verificação imediata

---

### Problema: Build release falha com ProGuard

**Erro comum:**

```
> Task :app:minifyReleaseWithR8 FAILED
```

**Solução:**

```bash
# 1. Limpe cache
flutter clean
cd android && ./gradlew clean
cd ..

# 2. Verifique proguard-rules.pro
# Arquivo: android/app/proguard-rules.pro
# Deve conter regras para Firebase:

-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# 3. Rebuild
flutter build apk --release
```

---

## 📊 Dashboards de Monitoramento

### Crashlytics Dashboard

**URL:** https://console.firebase.google.com/u/0/project/to-sem-banda-83e19/crashlytics

**Principais métricas:**

- **Crash-free users:** % de usuários sem crashes (meta: >99%)
- **Crash-free sessions:** % de sessões sem crashes (meta: >99.5%)
- **Crashes:** Número total de crashes por versão
- **Impacted users:** Usuários únicos afetados
- **Stack trace:** Linha exata do código que causou o erro

**Alertas recomendados:**

1. Crash-free users < 99% → Email imediato
2. Novo crash com 10+ ocorrências → Slack/Discord
3. Crash em função crítica (login, pagamento) → SMS

---

### Analytics Dashboard

**URL:** https://console.firebase.google.com/u/0/project/to-sem-banda-83e19/analytics

**Principais métricas:**

- **Usuários ativos:** Diário, semanal, mensal
- **Eventos principais:** Login, profile_created, profile_switched
- **Retenção:** % de usuários que retornam após 1, 7, 30 dias
- **Engajamento:** Tempo médio de sessão, sessões por usuário

**Eventos customizados (já implementados):**

| Evento                    | Parâmetros                    | Quando é disparado                  |
| ------------------------- | ----------------------------- | ----------------------------------- |
| `login`                   | `loginMethod: password`       | Login bem-sucedido                  |
| `sign_up`                 | `signUpMethod: email`         | Cadastro bem-sucedido               |
| `logout`                  | -                             | Usuário faz logout                  |
| `profile_created`         | `profile_type: musician/band` | Novo perfil criado                  |
| `profile_switched`        | `profile_id`                  | Troca de perfil ativo               |
| `profile_updated`         | `profile_id`                  | Edição de perfil                    |
| `profile_deleted`         | `profile_id`                  | Perfil deletado                     |
| `password_reset`          | `email`                       | Solicitação de recuperação de senha |
| `email_verification_sent` | -                             | Email de verificação enviado        |
| `login_failure`           | `method, error_code`          | Falha no login (senha errada, etc.) |

---

## 🔐 Privacidade e LGPD

**IMPORTANTE:** Analytics e Crashlytics coletam dados dos usuários. Certifique-se de que:

1. ✅ **Política de Privacidade atualizada:**

   - Arquivo: `PRIVACY_POLICY.md` (seção 5: "Ferramentas de Monitoramento")
   - URL: https://wegig.com.br/privacidade.html

2. ✅ **Dados coletados pelo Analytics:**

   - User ID (Firebase Auth UID)
   - Device model, OS version
   - App version
   - Timestamps de eventos
   - **NÃO coleta:** Localização precisa, fotos, mensagens (apenas eventos)

3. ✅ **Dados coletados pelo Crashlytics:**

   - Stack traces de erros
   - Device state (memória, bateria, conectividade)
   - User ID (apenas se configurado via `setUserIdentifier()`)

4. ✅ **Consentimento:**

   - Usuários consentem ao aceitar Termos de Uso (tela de login)
   - Checkbox explícita: "Aceito os Termos de Uso e Política de Privacidade"

5. ✅ **Direitos LGPD implementados:**
   - Usuários podem deletar conta (deleta todos os dados)
   - Dados de Analytics anonimizados após 14 meses (padrão Firebase)
   - Crashlytics retém dados por 90 dias (configurável)

---

## 📞 Suporte

**Se precisar de ajuda:**

1. **Documentação oficial:**

   - [Firebase Crashlytics](https://firebase.google.com/docs/crashlytics)
   - [Firebase Analytics](https://firebase.google.com/docs/analytics)

2. **Logs do Flutter:**

   ```bash
   flutter run --verbose 2>&1 | tee flutter_logs.txt
   ```

3. **Status do Firebase:**

   - [Firebase Status Dashboard](https://status.firebase.google.com/)

4. **Repositório:**
   - [ToSemBandaRepo Issues](https://github.com/wagnermecanica-code/ToSemBandaRepo/issues)

---

## ✅ Próximos Passos

Após confirmar que Crashlytics e Analytics estão ativos:

1. **Beta Testing:**

   - Distribua app via Firebase App Distribution ou TestFlight
   - Monitore dashboard diariamente nos primeiros 7 dias
   - Configure alertas para crashes críticos

2. **Melhorias futuras:**

   - Adicionar eventos customizados para fluxos críticos (criar post, enviar interesse, chat)
   - Configurar Conversion Events (login → criar perfil → criar post)
   - Integrar Remote Config para testes A/B
   - Adicionar Performance Monitoring (tempo de carregamento de telas)

3. **Documentação:**
   - Atualizar `MVP_CHECKLIST.md` com status "✅ Monitoramento ativo"
   - Adicionar dashboard URLs ao `README.md`
   - Documentar processo de triagem de crashes para equipe

---

**Última atualização:** 27 de novembro de 2025  
**Versão do app:** Flutter 3.9.2+, Dart 3.9.2+  
**Firebase Project:** to-sem-banda-83e19  
**Autor:** GitHub Copilot (Claude Sonnet 4.5)
