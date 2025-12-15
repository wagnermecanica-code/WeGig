# Relatório de Correções - Sessão de Bug Fixes

**Data:** 06 de dezembro de 2025  
**Branch:** `feat/ci-pipeline-test`  
**Autor:** Wagner Oliveira via GitHub Copilot

---

## 📋 Resumo Executivo

Sessão focada em correções de bugs gerais identificados durante testes manuais. Foram corrigidos **14 problemas** em 10 arquivos diferentes, abrangendo Home, Profile, Auth, Settings, Post e UI geral.

### Estatísticas

| Categoria | Bugs Corrigidos |
| --------- | --------------- |
| Home      | 1               |
| Profile   | 3               |
| Auth      | 2               |
| Settings  | 2               |
| Post      | 2               |
| UI Geral  | 4               |
| **Total** | **14**          |

---

## 🐛 Bugs Corrigidos

### 1. Home: Markers Pretos no Mapa ✅

**Arquivo:** `packages/app/lib/features/home/presentation/widgets/map/wegig_pin_descriptor_builder.dart`

**Problema:** Marcadores no mapa aparecendo na cor preta em vez da cor correta (teal para músicos, laranja para bandas).

**Causa Raiz:** Flutter 3.x mudou a API de `Color` - os getters `.r`, `.g`, `.b` agora retornam `double` entre 0-1, não mais `int` entre 0-255.

**Solução:**

```dart
// ANTES (Flutter 2.x)
color.r.toInt()

// DEPOIS (Flutter 3.x)
(color.r * 255).round()
```

---

### 2. Profile: Erro array-contains Duplicado ✅

**Arquivo:** `packages/app/lib/features/profile/presentation/pages/view_profile_page.dart`

**Problema:** Exception ao abrir conversa de perfil: "A maximum of 1 'array-contains' filter is allowed."

**Causa Raiz:** Firestore permite apenas UM filtro `array-contains` por query, mas o código tinha dois.

**Solução:** Remover segundo `array-contains` e filtrar client-side:

```dart
// ANTES
.where('participants', arrayContains: myId)
.where('participants', arrayContains: otherId)

// DEPOIS
.where('participants', arrayContains: myId)
// ... depois filtra no client
.where((doc) => participants.contains(otherId))
```

---

### 3. Profile: Redirecionamento Errado ao Trocar Perfil ✅

**Arquivo:** `packages/app/lib/navigation/bottom_nav_scaffold.dart`

**Problema:** Ao trocar de perfil via long press no avatar ou ProfileSwitcher, o app não permanecia na ViewProfilePage com os dados do novo perfil.

**Causa Raiz:** O callback `onProfileSelected` no `_showProfileSwitcher` fazia `ref.invalidate(profileProvider)` o que **desfazia** a troca de perfil já realizada pelo `ProfileSwitcherBottomSheet.switchProfile()`.

**Evidência:** Conforme WIREFRAME.md seção 6: "ViewProfile deve exibir os dados do perfil ativo e recarregar automaticamente ao trocar".

**Solução:** Remover `ref.invalidate(profileProvider)` do callback e confiar no fluxo interno do ProfileSwitcherBottomSheet que já faz a troca corretamente:

```dart
// ANTES (ERRADO - desfazia a troca)
onProfileSelected: (String profileId) {
  ref.invalidate(profileProvider); // ❌ Problema!
  ref.invalidate(postNotifierProvider);
  _currentIndexNotifier.value = 4;
  Navigator.pop(context); // ❌ Modal já fechado!
},

// DEPOIS (CORRETO)
onProfileSelected: (String profileId) {
  // NÃO invalidar profileProvider - switchProfile já foi chamado
  ref.invalidate(postNotifierProvider); // Apenas posts
  if (_currentIndexNotifier.value != 4) {
    _currentIndexNotifier.value = 4;
  }
  // NÃO chamar Navigator.pop - modal já fechado pelo ProfileSwitcherBottomSheet
},
```

**Fluxo Correto Após Fix:**

1. `ProfileSwitcherBottomSheet` fecha o modal
2. Mostra overlay de transição animado
3. Chama `switchProfile()` que atualiza o Riverpod
4. ViewProfilePage detecta mudança via `ref.listen(profileProvider)`
5. ViewProfilePage recarrega automaticamente (`_loadProfileFromFirestore`)

---

### 4. Profile: Lista de Posts Vazia em Outros Perfis ✅

**Arquivo:** `packages/app/lib/features/profile/presentation/pages/view_profile_page.dart`

**Problema:** Ao visualizar perfil de outro usuário, a lista de posts aparecia vazia mesmo que existissem posts.

**Causa Raiz:** Query usava `.orderBy('expiresAt', descending: true)` mas o índice do Firestore estava configurado para ordem ascendente.

**Solução:** Usar ordem ascendente para `expiresAt` para coincidir com o índice.

---

### 5. Auth: Erro de Widget Desativado no Logout ✅

**Arquivo:** `packages/app/lib/features/settings/presentation/pages/settings_page.dart`

**Problema:** "setState() called after dispose()" ao fazer logout.

**Causa Raiz:** Operações assíncronas executavam após o widget ser desmontado.

**Solução:** Navegar ANTES de invalidar providers:

```dart
// ANTES
await FirebaseAuth.instance.signOut();
ref.invalidate(profileProvider);
context.goToAuth(); // Widget já desmontado!

// DEPOIS
context.goToAuth(); // Navega primeiro
await Future.delayed(Duration(milliseconds: 100));
await FirebaseAuth.instance.signOut();
ref.invalidate(profileProvider); // Agora pode
```

---

### 6. Auth: Redirecionamento Incorreto após Login ✅

**Arquivo:** `packages/app/lib/app/router/app_router.dart`

**Problema:** Após login, usuário era redirecionado para local errado (às vezes para profile creation mesmo tendo perfil).

**Causa Raiz:** Profile provider ainda estava loading quando o router verificava o estado.

**Solução:** Adicionar verificação explícita de estado de loading:

```dart
final profileIsLoading = profileValue.isLoading;
if (profileIsLoading && !isOnSplash) {
  return '/splash'; // Aguarda carregar
}
```

---

### 7. Settings: Cores dos Toggles Pouco Visíveis ✅

**Arquivos:**

- `packages/app/lib/features/settings/presentation/pages/settings_page.dart`
- `packages/app/lib/features/settings/presentation/widgets/settings_tile.dart`

**Problema:** Toggles (switches) não tinham distinção visual clara entre ligado/desligado.

**Solução:** Usar cor accent (laranja) quando ativo:

```dart
thumbColor: WidgetStateProperty.resolveWith<Color?>(
  (states) => states.contains(WidgetState.selected)
    ? AppColors.accent  // Laranja quando ON
    : AppColors.border, // Cinza quando OFF
),
trackColor: WidgetStateProperty.resolveWith<Color?>(
  (states) => states.contains(WidgetState.selected)
    ? AppColors.accent.withValues(alpha: 0.3) // Laranja translúcido
    : AppColors.surfaceVariant,
),
```

---

### 8. Settings: Latência ao Abrir Campos ✅

**Arquivos:**

- `packages/app/lib/features/settings/presentation/pages/settings_page.dart`
- `packages/app/lib/features/settings/presentation/providers/settings_providers.dart`

**Problema:** Settings demoravam para aparecer ao abrir a página.

**Solução:**

1. Remover `addPostFrameCallback` e carregar imediatamente no `initState`
2. Adicionar cache no provider para evitar recarregar do Firestore se já tem dados:

```dart
Future<void> loadSettings(String profileId, {bool forceReload = false}) async {
  if (!forceReload && _loadedProfileId == profileId && state.hasValue) {
    return; // Já tem dados, pula
  }
  // ... carrega do Firestore
}
```

---

### 9. Post: Debug Logging Adicionado ✅

**Arquivo:** `packages/app/lib/features/post/presentation/providers/post_providers.dart`

**Problema:** Dificuldade em diagnosticar problemas de salvamento de posts.

**Solução:** Adicionados logs detalhados em todo o fluxo de `savePost()`:

```dart
debugPrint('📝 PostNotifier.savePost: Iniciando - type=${input.type}');
debugPrint('✅ PostNotifier.savePost: Perfil encontrado - ${profile.profileId}');
debugPrint('📷 PostNotifier.savePost: Fazendo upload de imagem...');
debugPrint('📝 PostNotifier.savePost: Validando entidade...');
debugPrint('✅ PostNotifier.savePost: Post criado');
debugPrint('📦 PostNotifier.savePost: Invalidando cache...');
```

---

### 10. Post: Alinhamento de Textos à Esquerda ✅

**Arquivo:** `packages/app/lib/features/post/presentation/pages/post_detail_page.dart`

**Problema:** Textos centralizados na página de detalhes do post (deviam estar à esquerda).

**Solução:** Adicionar `crossAxisAlignment: CrossAxisAlignment.start` nas Columns relevantes e `Align(alignment: Alignment.centerLeft)` em títulos.

---

### 11. UI: Alinhamento de Cards à Esquerda ✅

**Arquivos:**

- `packages/app/lib/features/home/presentation/pages/home_page.dart` (PostCard)
- `packages/app/lib/features/home/presentation/widgets/feed_post_card.dart`
- `packages/app/lib/features/profile/presentation/pages/view_profile_page.dart` (post cards)

**Problema:** Conteúdo dos cards de post centralizado em vez de alinhado à esquerda.

**Solução:** Adicionar `crossAxisAlignment: CrossAxisAlignment.start` nas Columns do conteúdo dos cards.

---

### 12-13. UI: Padronização e Fix do Crop de Imagens ✅

**Arquivos:**

- `packages/app/lib/features/profile/presentation/pages/view_profile_page.dart` (2 lugares)
- `packages/app/lib/features/profile/presentation/pages/edit_profile_page.dart`

**Problema:** Ferramenta de crop com opções saindo da tela e configurações inconsistentes entre diferentes fluxos de upload.

**Solução:** Padronizar todas as chamadas de `ImageCropper().cropImage()` com:

```dart
AndroidUiSettings(
  statusBarColor: AppColors.primary,      // ✅ Previne overflow
  hideBottomControls: false,              // ✅ Garante botões visíveis
  cropFrameColor: AppColors.primary,
  cropGridColor: Colors.white24,
  dimmedLayerColor: Colors.black.withValues(alpha: 0.8),
),
IOSUiSettings(
  rotateButtonsHidden: false,             // ✅ Botões sempre visíveis
  resetButtonHidden: false,
),
```

---

## 📁 Arquivos Modificados

| Arquivo                             | Modificações                                                                      |
| ----------------------------------- | --------------------------------------------------------------------------------- |
| `wegig_pin_descriptor_builder.dart` | Corrigido Color API para Flutter 3.x                                              |
| `view_profile_page.dart`            | 4 correções: array-contains, query ordering, card alignment, crop standardization |
| `bottom_nav_scaffold.dart`          | Corrigido redirecionamento ao trocar perfil                                       |
| `settings_page.dart`                | Corrigido logout, melhorado toggle colors, removido latência                      |
| `settings_tile.dart`                | Melhorado toggle colors com accent                                                |
| `settings_providers.dart`           | Adicionado cache para evitar recargas                                             |
| `app_router.dart`                   | Corrigido login redirect timing                                                   |
| `post_providers.dart`               | Adicionado debug logging detalhado                                                |
| `post_detail_page.dart`             | Corrigido alinhamento de textos                                                   |
| `home_page.dart`                    | Corrigido alinhamento de PostCard                                                 |
| `feed_post_card.dart`               | Corrigido alinhamento                                                             |
| `edit_profile_page.dart`            | Padronizado crop settings                                                         |

---

## 🧪 Validação

- ✅ Nenhum erro de análise estática (dart analyze)
- ✅ Nenhum warning nos arquivos modificados
- ⏳ Testes manuais pendentes no simulador iPhone 17 Pro

---

## 📝 Próximos Passos

1. **Testar no iPhone 17 Pro Simulator:**

   - Verificar marcadores coloridos no mapa
   - Testar troca de perfil
   - Validar logout sem erros
   - Confirmar login redirect correto
   - Testar salvamento de posts
   - Verificar alinhamento de textos

2. **Monitorar em Produção:**
   - Logs de `PostNotifier.savePost` para diagnosticar problemas reportados
   - Verificar se cache de Settings está funcionando

---

## 🔧 Lições Aprendidas

1. **Flutter 3.x Breaking Change:** `Color.r/g/b` retornam `double` (0-1) em vez de `int` (0-255)

2. **Firestore Limitation:** Apenas UM `array-contains` por query - filtrar extras no client

3. **Widget Lifecycle:** Sempre navegar ANTES de operações assíncronas que invalidam providers

4. **GoRouter + Riverpod:** Verificar estado de loading antes de decisões de redirect

5. **ImageCropper iOS:** `statusBarColor` e `hideBottomControls: false` previnem overflow em telas pequenas
