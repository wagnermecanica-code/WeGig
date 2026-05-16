# 🚀 Guia Rápido - Sistema de Múltiplos Perfis

## ✨ Funcionalidades Novas

### 1️⃣ Editar Perfil

1. Abra o menu de perfis (ícone no AppBar)
2. Clique nos **3 pontos (⋮)** ao lado do perfil
3. Selecione **"Editar"**
4. Faça as alterações
5. Clique em **"Salvar"**

### 2️⃣ Excluir Perfil

1. Abra o menu de perfis
2. Clique nos **3 pontos (⋮)** ao lado do perfil
3. Selecione **"Excluir"**
4. Confirme a exclusão

⚠️ **Restrições:**

- Não é possível excluir o perfil principal
- Você precisa ter pelo menos 1 perfil

### 3️⃣ Trocar de Perfil

1. Abra o menu de perfis
2. Clique no perfil desejado
3. Aguarde a animação de transição
4. ✅ Perfil trocado automaticamente!

---

## 💻 Para Desenvolvedores

### Troca de perfil na arquitetura atual

```dart
import 'package:wegig_app/features/profile/presentation/providers/profile_switcher_provider.dart';

// Exemplo em um ConsumerWidget / ConsumerState
await ref.read(profileSwitcherNotifierProvider.notifier)
    .switchToProfile(profileId);
```

### Overlay de transição

```dart
import 'package:wegig_app/features/profile/presentation/widgets/profile_transition_overlay.dart';

ProfileTransitionOverlay.show(
  context,
  profileName: 'João Silva',
  profileType: 'musician',
  photoUrl: 'https://...',
  onComplete: () {
    // Código executado após animação
  },
);
```

---

## 📁 Arquivos Criados/Modificados

### Referências atuais:

- `packages/app/lib/features/profile/presentation/providers/profile_switcher_provider.dart`
- `packages/app/lib/features/profile/presentation/providers/profile_providers.dart`
- `packages/app/lib/features/profile/presentation/widgets/profile_switcher_bottom_sheet.dart`
- `packages/app/lib/features/profile/presentation/widgets/profile_transition_overlay.dart`
- `packages/app/lib/features/profile/presentation/pages/edit_profile_page.dart`
- `docs/features/MULTIPLE_PROFILES_IMPLEMENTATION.md`

---

## 🎯 Próximos Passos

1. **Testar as novas funcionalidades**

   ```bash
   flutter run
   ```

2. **Revisar a fonte canônica da feature**

- Ver `docs/features/MULTIPLE_PROFILES_IMPLEMENTATION.md`
- Confirmar regras de exclusão, troca e invalidação de cache

3. **Adicionar testes**
   ```dart
   // packages/app/test/features/profile/...
   test('switches active profile safely', () async {
    // validar troca de perfil e invalidação de contexto
   });
   ```

---

## 🐛 Troubleshooting

### Erro ao excluir perfil

- ✅ Verifique se não é o perfil principal
- ✅ Verifique se tem mais de 1 perfil

### Perfil não atualiza após editar

- ✅ Verifique se `EditProfilePage` dispara a troca do perfil correto quando necessário
- ✅ Verifique callback e fluxo em `profile_switcher_bottom_sheet.dart`

### Animação não aparece

- ✅ Verifique import de `features/profile/presentation/widgets/profile_transition_overlay.dart`
- ✅ Verifique se context está montado

---

## 📚 Documentação Completa

Ver `docs/features/MULTIPLE_PROFILES_IMPLEMENTATION.md` para a referência canônica resumida.
