# 🚀 Quick Start: Configurar Projetos Firebase Separados

## TL;DR

```bash
# Execute o script interativo
./scripts/setup_firebase_projects.sh
```

O script vai guiar você por todos os passos necessários.

---

## O que o Script Faz?

1. ✅ Verifica se Firebase CLI e FlutterFire CLI estão instalados
2. ✅ Guia criação de projetos DEV e STAGING no Firebase Console
3. ✅ Configura apps automaticamente com `flutterfire configure`
4. ✅ Instrui download de `google-services.json` e `.plist`
5. ✅ Testa builds para validar configuração

---

## Quando Executar?

- ✅ **AGORA**: Se você quer ambientes isolados (recomendado)
- ⏳ **DEPOIS**: Se quiser testar mais com projeto compartilhado

---

## Resultado Final

### Antes (1 projeto compartilhado)

```
to-sem-banda-83e19
├── DEV    } Compartilham
├── STAGING} dados e regras
└── PROD   } - RISCO!
```

### Depois (3 projetos isolados)

```
to-sem-banda-dev      → Dados de teste isolados
to-sem-banda-staging  → Homologação isolada
to-sem-banda-83e19    → Produção segura
```

---

## Guias Completos

- **Guia Passo-a-Passo**: [`docs/guides/FIREBASE_SEPARATE_PROJECTS_GUIDE.md`](docs/guides/FIREBASE_SEPARATE_PROJECTS_GUIDE.md)
- **Flavors Completo**: [`docs/guides/FLAVORS_COMPLETE_GUIDE.md`](docs/guides/FLAVORS_COMPLETE_GUIDE.md)
- **Status Atual**: [`FIREBASE_FLAVORS_STATUS.md`](FIREBASE_FLAVORS_STATUS.md)

---

## Troubleshooting

### Script não executa

```bash
chmod +x scripts/setup_firebase_projects.sh
```

### Firebase CLI não encontrado

```bash
npm install -g firebase-tools
```

### FlutterFire CLI não encontrado

```bash
dart pub global activate flutterfire_cli
```

---

## Comandos Manuais (se preferir)

### 1. Configurar DEV

```bash
cd packages/app
flutterfire configure \
  --project=to-sem-banda-dev \
  --out=lib/firebase_options_dev.dart \
  --platforms=android,ios \
  --ios-bundle-id=com.tosembanda.wegig.dev \
  --android-package-name=com.tosembanda.wegig.dev \
  --yes
```

### 2. Configurar STAGING

```bash
flutterfire configure \
  --project=to-sem-banda-staging \
  --out=lib/firebase_options_staging.dart \
  --platforms=android,ios \
  --ios-bundle-id=com.tosembanda.wegig.staging \
  --android-package-name=com.tosembanda.wegig.staging \
  --yes
```

### 3. Baixar google-services.json

- DEV → `packages/app/android/app/src/dev/google-services.json`
- STAGING → `packages/app/android/app/src/staging/google-services.json`

### 4. Baixar GoogleService-Info.plist

- DEV → `packages/app/ios/Firebase/GoogleService-Info-dev.plist`
- STAGING → `packages/app/ios/Firebase/GoogleService-Info-staging.plist`

### 5. Testar

```bash
flutter build apk --flavor dev -t lib/main_dev.dart --debug
flutter build apk --flavor staging -t lib/main_staging.dart --debug
```

---

## Próximos Passos Depois do Setup

1. ✅ Habilitar Authentication, Firestore, Storage nos novos projetos
2. ✅ Deploy Firestore rules para DEV e STAGING
3. ✅ Configurar iOS Xcode schemes (veja `FLAVORS_COMPLETE_GUIDE.md`)
4. ✅ Popular DEV com dados de teste

---

**Perguntas?** Consulte o guia completo em [`docs/guides/FIREBASE_SEPARATE_PROJECTS_GUIDE.md`](docs/guides/FIREBASE_SEPARATE_PROJECTS_GUIDE.md)
