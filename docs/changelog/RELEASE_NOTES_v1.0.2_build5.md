# Release Notes - WeGig v1.0.2 (Build 5)

**Data:** 22 de Dezembro de 2025  
**Versão:** 1.0.2  
**Build:** 5  
**Bundle ID:** com.wegig.wegig

---

## 📱 TestFlight (iOS) - What to Test

### Notas de Teste (Copiar para TestFlight)

```
O que há de novo na versão 1.0.2:

🔧 CORREÇÕES
• Markers do mapa agora têm tamanho consistente entre iOS e Android
• Card de vídeo do YouTube não fica mais colado na borda inferior
• Campo de link do YouTube agora quebra texto de aviso em duas linhas
• Fluxo de reautenticação para exclusão de conta melhorado

📍 MELHORIAS NO MAPA
• Tamanho dos pins normalizado em todas as plataformas
• Clusters de marcadores com renderização otimizada

🎨 INTERFACE
• Espaçamento corrigido na página de detalhes do post
• Melhor legibilidade dos avisos de validação

Por favor, teste:
1. Abrir o mapa e verificar tamanho dos markers
2. Visualizar posts com vídeo do YouTube
3. Criar/editar posts com link do YouTube
4. Fluxo de exclusão de conta (Configurações > Excluir Conta)
```

---

## 🤖 Google Play Console (Android) - Release Notes

### Português (Brasil) - pt-BR

```
O que há de novo:

🔧 Correções
• Tamanho dos marcadores no mapa agora igual ao iOS
• Espaçamento corrigido em páginas de detalhes
• Campo de link do YouTube com texto ajustável

🎨 Melhorias visuais
• Interface mais consistente entre plataformas
• Melhor legibilidade de avisos e validações

🛡️ Segurança
• Fluxo de exclusão de conta aprimorado
```

### English - en-US

```
What's new:

🔧 Bug Fixes
• Map marker sizes now consistent with iOS
• Fixed spacing on post detail pages
• YouTube link field with adjustable hint text

🎨 Visual Improvements
• More consistent interface across platforms
• Better readability for warnings and validations

🛡️ Security
• Improved account deletion flow
```

---

## 📋 Changelog Técnico

### Alterações de Código

| Arquivo                             | Mudança                                                                       |
| ----------------------------------- | ----------------------------------------------------------------------------- |
| `wegig_pin_descriptor_builder.dart` | Tamanho de markers específico por plataforma (Android: 32x43, iOS: 46.9x62.7) |
| `wegig_cluster_renderer.dart`       | Clusters específicos por plataforma (Android: 66x66, iOS: 96x96)              |
| `post_detail_page.dart`             | Adicionado SizedBox(height: 24) após card do YouTube                          |
| `post_page.dart`                    | helperMaxLines: 2 no campo de YouTube                                         |
| `edit_profile_page.dart`            | helperMaxLines: 2 no campo de YouTube                                         |
| `account_settings_page.dart`        | Melhorado fluxo de reautenticação                                             |

### Arquivos Modificados

```
packages/app/lib/features/home/presentation/widgets/map/
├── wegig_pin_descriptor_builder.dart  ✅ Platform-specific sizing
└── wegig_cluster_renderer.dart        ✅ Platform-specific clusters

packages/app/lib/features/post/presentation/pages/
├── post_detail_page.dart              ✅ Bottom padding fix
└── post_page.dart                     ✅ YouTube helperMaxLines

packages/app/lib/features/profile/presentation/pages/
├── edit_profile_page.dart             ✅ YouTube helperMaxLines
└── account_settings_page.dart         ✅ Reauth flow improved
```

---

## 🚀 Deploy Checklist

### iOS (TestFlight)

- [ ] Abrir Xcode Organizer (`Cmd + Shift + O`)
- [ ] Selecionar `WeGig.xcarchive` mais recente
- [ ] Clicar em "Distribute App"
- [ ] Selecionar "App Store Connect"
- [ ] Upload e aguardar processamento (5-15 min)
- [ ] Adicionar testers no TestFlight

### Android (Google Play Console)

- [ ] Rodar `flutter build appbundle --flavor prod -t lib/main_prod.dart`
- [ ] Acessar Google Play Console > Production/Internal Testing
- [ ] Upload do arquivo `.aab`
- [ ] Preencher release notes (acima)
- [ ] Submeter para revisão

---

## 📊 Métricas de Qualidade

| Métrica                | Status       |
| ---------------------- | ------------ |
| Erros de compilação    | ✅ 0         |
| Warnings Dart Analyzer | ⚠️ Verificar |
| Testes unitários       | ⚠️ Executar  |
| Build iOS              | ✅ Sucesso   |
| Build Android          | ⚠️ Pendente  |

---

## 🔗 Links Úteis

- **TestFlight:** https://appstoreconnect.apple.com
- **Google Play Console:** https://play.google.com/console
- **Firebase Console:** https://console.firebase.google.com/project/to-sem-banda-83e19
