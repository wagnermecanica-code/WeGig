# 🎯 Plano de Rebranding: Tô Sem Banda → WeGig

**Status:** 📋 PLANEJAMENTO  
**Data:** 30 de Novembro de 2025  
**Impacto:** MÉDIO (sem quebra de funcionalidades)

---

## 📊 Análise Atual

### ✅ O que JÁ está correto (WeGig):

1. **Package ID (Android/iOS):** `com.tosembanda.wegig` ✅
2. **App Name (usuário vê):** "WeGig" ✅
3. **pubspec.yaml root:** `name: wegig` ✅
4. **Firebase Project ID:** `to-sem-banda-83e19` ✅ (não precisa mudar)
5. **Domínio registrado:** `tosembanda.com` ✅ (pode manter)
6. **Android namespace:** `com.tosembanda.wegig` ✅

### ⚠️ O que precisa ATUALIZAR:

1. **Nome da pasta raiz:** `/Users/wagneroliveira/to_sem_banda/` → `/Users/wagneroliveira/wegig/`
2. **Documentação:** Referências a "Tô Sem Banda" em 50+ arquivos
3. **Comentários no código:** Strings hardcoded com nome antigo
4. **Windows binários:** Ainda usam `to_sem_banda.exe`
5. **iOS Display Name:** `to_sem_banda` → `WeGig`
6. **Repository Name:** `ToSemBandaRepo` → `WeGigRepo` (GitHub)

---

## 🚀 Estratégia de Migração

### Abordagem Recomendada: **INCREMENTAL** (sem quebrar nada)

**Por quê?**

- Mudar nome da pasta pode quebrar paths absolutos
- Git history e branches existentes
- Links de documentação e referências
- Menos risco de bugs

**Etapas:**

1. ✅ Atualizar documentação e comentários (texto)
2. ✅ Atualizar display names (iOS/Windows)
3. ⚠️ **OPCIONAL:** Renomear pasta raiz (requer cuidado)
4. ⚠️ **OPCIONAL:** Renomear repositório no GitHub

---

## 📝 Checklist de Mudanças

### 🎯 Fase 1: Documentação (SEGURO - 0 risco)

#### Arquivos de Documentação

- [ ] `.github/copilot-instructions.md` - Linha 1 e 109

  - `# WeGig (Tô Sem Banda)` → `# WeGig`
  - `- **Repo:** Tô Sem Banda / ToSemBandaRepo` → `- **Repo:** WeGig / WeGigRepo`

- [ ] `README.md` - Atualizar título e descrição
- [ ] `.env.example` - Linha 1

  - `# Tô Sem Banda / WeGig` → `# WeGig`

- [ ] `PROJECT_STRUCTURE_COMPLETE_2025-11-29.md`

  - Linha 3: `**Projeto:** WeGig (Tô Sem Banda)` → `**Projeto:** WeGig`

- [ ] `packages/app/pubspec.yaml` - Linha 2

  - `description: App principal Tô Sem Banda` → `description: WeGig - Conectando músicos e bandas`

- [ ] `FIREBASE_FLAVORS_STATUS.md` - Atualizar referências se houver

#### Arquivos de Configuração (comentários)

- [ ] `windows/CMakeLists.txt` - Comentários (se houver)
- [ ] `windows/runner/main.cpp` - Comentário do projeto
- [ ] `windows/runner/Runner.rc` - Descrição do produto

---

### 🎨 Fase 2: Display Names (MÉDIO - 5% risco)

#### iOS

- [ ] `packages/app/ios/Runner/Info.plist`
  - Linha 18: `<string>to_sem_banda</string>` → `<string>WeGig</string>`
  - ⚠️ **Impacto:** Nome do app na home screen do iOS

#### Windows

- [ ] `windows/runner/main.cpp`
  - Linha 30: `L"to_sem_banda"` → `L"WeGig"`
- [ ] `windows/runner/Runner.rc`

  - Linha 93: `"to_sem_banda"` → `"WeGig"`
  - Linha 95: `"to_sem_banda"` → `"wegig"`
  - Linha 97: `"to_sem_banda.exe"` → `"wegig.exe"`
  - Linha 98: `"to_sem_banda"` → `"WeGig"`

- [ ] `windows/CMakeLists.txt`
  - Linha 3: `project(to_sem_banda LANGUAGES CXX)` → `project(wegig LANGUAGES CXX)`
  - Linha 7: `set(BINARY_NAME "to_sem_banda")` → `set(BINARY_NAME "wegig")`

---

### ⚠️ Fase 3: Pasta Raiz (ALTO RISCO - NÃO RECOMENDADO inicialmente)

**Mudança:** `/Users/wagneroliveira/to_sem_banda/` → `/Users/wagneroliveira/wegig/`

**Impactos:**

- ❌ Quebra todos os paths absolutos em documentação
- ❌ Git remotes precisam ser atualizados
- ❌ IDEs (VS Code, Android Studio, Xcode) perdem configurações
- ❌ Histórico de terminal/comandos quebra
- ❌ Links simbólicos quebram

**Se decidir fazer:**

1. Commit de todas as mudanças pendentes
2. Push para remoto (backup)
3. Fechar TODOS os editores e terminais
4. Renomear pasta: `mv ~/to_sem_banda ~/wegig`
5. Atualizar Git remote (se necessário)
6. Reabrir projeto em IDE
7. Testar builds: `flutter run`, `flutter build apk`

**Alternativa (recomendada):**

- **Manter pasta atual** e apenas atualizar documentação
- Razão: `com.tosembanda.wegig` já é o bundle ID correto
- Usuário final nunca vê o nome da pasta

---

### 🔄 Fase 4: Repositório GitHub (OPCIONAL)

**Mudança:** `ToSemBandaRepo` → `WeGigRepo`

**Como fazer:**

1. GitHub → Settings → Repository name
2. Renomear para `WeGigRepo`
3. Atualizar remote local:
   ```bash
   git remote set-url origin https://github.com/wagnermecanica-code/WeGigRepo.git
   ```

**Impacto:**

- ✅ GitHub redireciona automaticamente (backward compatible)
- ✅ Links antigos continuam funcionando (301 redirect)
- ⚠️ Atualizar links em documentação

---

## 🎯 Recomendação Final

### Estratégia MINIMALISTA (recomendada):

**O que fazer AGORA:**

1. ✅ **Fase 1:** Atualizar documentação e comentários (15 min)
2. ✅ **Fase 2:** Atualizar display names iOS/Windows (10 min)

**O que NÃO fazer:** 3. ❌ **Fase 3:** Renomear pasta raiz (alto risco, baixo benefício)

**Por quê?**

- Bundle ID `com.tosembanda.wegig` já está correto
- App name "WeGig" já está correto
- Package name `wegig` já está correto
- Usuário final nunca vê o nome da pasta
- Zero risco de quebrar algo

### Estratégia COMPLETA (se quiser tudo perfeitamente alinhado):

**Ordem:**

1. ✅ Fase 1 (documentação)
2. ✅ Fase 2 (display names)
3. ⚠️ Fase 3 (pasta raiz) - **BACKUP OBRIGATÓRIO antes**
4. ⚠️ Fase 4 (GitHub rename)

---

## 🛠️ Scripts Auxiliares

### Script para atualizar documentação (Fase 1)

```bash
#!/bin/bash
# renomear_docs.sh

# Substitui "Tô Sem Banda" por "WeGig" em arquivos de documentação
find . -type f \( -name "*.md" -o -name "*.yaml" -o -name ".env.example" \) \
  -not -path "*/node_modules/*" \
  -not -path "*/.git/*" \
  -not -path "*/build/*" \
  -exec sed -i '' 's/Tô Sem Banda/WeGig/g' {} +

# Substitui "ToSemBandaRepo" por "WeGigRepo"
find . -type f -name "*.md" \
  -not -path "*/node_modules/*" \
  -not -path "*/.git/*" \
  -exec sed -i '' 's/ToSemBandaRepo/WeGigRepo/g' {} +

echo "✅ Documentação atualizada!"
```

### Validação pós-migração

```bash
#!/bin/bash
# validar_migração.sh

echo "🔍 Buscando referências antigas..."

# Busca "Tô Sem Banda" (exceto em arquivos de histórico)
echo "📝 Tô Sem Banda:"
grep -r "Tô Sem Banda" . \
  --exclude-dir={node_modules,.git,build,ios/Pods} \
  --exclude="*.{iml,lock,log}" \
  | wc -l

# Busca "to_sem_banda" (nome de variável/pasta)
echo "📝 to_sem_banda:"
grep -r "to_sem_banda" . \
  --exclude-dir={node_modules,.git,build,ios/Pods} \
  --exclude="*.{iml,lock,log}" \
  | wc -l

echo "✅ Validação concluída!"
```

---

## ⚠️ Testes Obrigatórios Após Mudanças

### Após Fase 1 (documentação):

- [ ] `git status` - Verificar arquivos modificados
- [ ] `git diff` - Revisar mudanças
- [ ] Nenhum teste técnico necessário (apenas texto)

### Após Fase 2 (display names):

- [ ] **iOS:** `flutter run --flavor dev -t lib/main_dev.dart`
  - Verificar nome "WeGig" na home screen
- [ ] **Android:** `flutter run --flavor dev -t lib/main_dev.dart`
  - Verificar nome "WeGig DEV" no launcher
- [ ] **Windows:** `flutter run -d windows`
  - Verificar título da janela "WeGig"

### Após Fase 3 (pasta raiz - SE FIZER):

- [ ] `flutter clean`
- [ ] `melos bootstrap`
- [ ] `flutter run --flavor dev -t lib/main_dev.dart`
- [ ] `flutter build apk --flavor dev -t lib/main_dev.dart`
- [ ] `flutter build ios --flavor dev -t lib/main_dev.dart`
- [ ] Verificar git remote: `git remote -v`

---

## 📋 Histórico

- **30/11/2025 12:00:** Plano criado
- **30/11/2025 12:30:** ✅ **Fase 1 CONCLUÍDA** - Documentação atualizada (13 arquivos modificados)

  - .github/copilot-instructions.md
  - .env.example
  - PROJECT_STRUCTURE_COMPLETE_2025-11-29.md
  - packages/app/pubspec.yaml
  - functions/package.json + index.js
  - packages/app/lib/features/home/presentation/pages/home_page.dart
  - ProGuard rules (2 arquivos)
  - packages/core_ui/lib/utils/deep_link_generator.dart
  - CONTRIBUTING.md
  - BOAS_PRATICAS_ANALISE_2025-11-30.md
  - design_system_integration.dart
  - docs/reports/ (4 arquivos)
  - **Resultado:** 0 referências a "Tô Sem Banda" em código/docs relevantes

- **30/11/2025 12:35:** ✅ **Fase 2 CONCLUÍDA** - Display names atualizados (5 arquivos modificados)

  - **iOS:** packages/app/ios/Runner/Info.plist
    - CFBundleName: "to_sem_banda" → "WeGig"
    - **Impacto:** Nome visível na home screen do iPhone/iPad
  - **Windows:** windows/runner/main.cpp
    - Título da janela: "to_sem_banda" → "WeGig"
  - **Windows:** windows/runner/Runner.rc
    - FileDescription: "WeGig"
    - InternalName: "wegig"
    - OriginalFilename: "wegig.exe"
    - ProductName: "WeGig"
  - **Windows:** windows/CMakeLists.txt
    - project(wegig)
    - BINARY_NAME: "wegig"
  - **Resultado:** 0 referências a "to_sem_banda" em código executável

- **Pendente:** Execução das Fases 3-4 (OPCIONAIS)

---

## 🔗 Referências

- **Bundle ID atual:** `com.tosembanda.wegig` (correto)
- **Firebase Project:** `to-sem-banda-83e19` (mantém)
- **Domínio:** `tosembanda.com` (mantém)
- **GitHub:** `ToSemBandaRepo` → `WeGigRepo` (opcional)

---

**Próximo passo sugerido:**  
Executar **Fase 1** (documentação) - zero risco, 100% benefício.
