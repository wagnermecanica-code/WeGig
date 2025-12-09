# 🚨 Plano de Ação: Notifications Feature Refactoring (2025)

Baseado na auditoria realizada em 07/12/2025, este plano visa corrigir débitos técnicos arquiteturais, problemas de performance e falhas de UX identificadas na feature de notificações.

## 📊 Resumo da Auditoria

| Categoria       | Status        | Principais Problemas                                                        |
| --------------- | ------------- | --------------------------------------------------------------------------- |
| **Arquitetura** | 🔴 Crítico    | Lógica na UI, Acesso direto ao Firestore na View, `setState` durante build. |
| **Performance** | 🟠 Alto Risco | Filtragem client-side (custo $$), leituras redundantes, limite de batch.    |
| **UX**          | 🟡 Médio      | Feedback de erro genérico, strings hardcoded.                               |

---

## 🎯 Sprints Recomendadas

### Sprint 13: Arquitetura & Estabilidade (4h - CRÍTICO) ✅ CONCLUÍDO

**Objetivo:** Remover lógica da UI e garantir estabilidade.

1.  **Refatorar `NotificationsPage` para MVVM/Controller (2h)** ✅

    - Criar `NotificationsController` (Riverpod `AsyncNotifier`).
    - Mover lógica de paginação (`_hasMore`, `_isLoadingMore`, `_notifications`) para o Controller.
    - Mover lógica de refresh e cache local para o Controller.
    - Remover `addPostFrameCallback` (estado reativo resolve).

2.  **Remover Acesso Direto ao Firestore (1h)** ✅

    - Mover query do `_buildAppBar` (contador de não lidas) para `NotificationsRepository`.
    - Consumir via `unreadNotificationCountForProfileProvider` existente.

3.  **Correção de Memory Leaks (1h)** ✅
    - Implementar `dispose` correto dos ScrollControllers (atualmente iterando sobre mapa).
    - Garantir cancelamento de streams ao sair da tela.

**Resultado Esperado:** Código testável, desacoplado e sem erros de "setState during build".

---

### Sprint 14: Performance & Escalabilidade (3h - ALTA) ✅ CONCLUÍDO

**Objetivo:** Reduzir custos do Firestore e evitar crashes em contas grandes.

1.  **Otimizar Query de Notificações (1.5h)** ✅

    - **Solução Ideal:** Criar índice composto `recipientUid` + `recipientProfileId` no Firestore.
    - **Solução Paliativa:** Se índice não for possível, manter filtro client-side mas otimizar o `limit` (evitar `limit * 2` cego).
    - Remover leitura redundante de `startAfterDocument` (usar snapshot anterior). -> **Implementado uso de `startAfter` com valores (expiresAt, createdAt)**.

2.  **Batch Chunking para `markAllAsRead` (1.5h)** ✅
    - Implementar lógica para dividir updates em lotes de 500 documentos.
    - Evitar crash `FirestoreError: batch limit exceeded`. -> **Implementado chunking de 500 docs**.

**Resultado Esperado:** Redução de leituras no Firestore e suporte a "power users".

---

### Sprint 15: UX & Polimento (2h - MÉDIA) ✅ CONCLUÍDO

**Objetivo:** Melhorar a experiência do usuário em casos de borda.

1.  **Melhorar Tratamento de Erros (1h)** ✅

    - Substituir `_buildEmptyState` em caso de erro por um widget `ErrorState` com botão "Tentar Novamente". -> **Implementado `NotificationErrorState`**.
    - Diferenciar erro de conexão vs. lista vazia.

2.  **Feedback Visual de Carregamento (1h)** ✅
    - Adicionar Skeleton Loading (Shimmer) ao carregar a lista inicial (em vez de spinner simples). -> **Implementado `NotificationSkeletonTile`**.
    - Melhorar indicador de "Carregando mais..." no final da lista.

**Resultado Esperado:** UX mais robusta e transparente.

---

## 📝 Notas de Implementação

### Exemplo de Controller (Sugestão)

```dart
@riverpod
class NotificationsController extends _$NotificationsController {
  @override
  FutureOr<List<NotificationEntity>> build(String profileId, NotificationType? type) async {
    // Carregamento inicial
    return _repository.getNotifications(profileId, type: type);
  }

  Future<void> loadMore() async {
    // Lógica de paginação
  }

  Future<void> refresh() async {
    // Lógica de refresh
  }
}
```

### Batch Chunking Helper

```dart
Future<void> safeBatchCommit(WriteBatch batch, int operationCount) async {
  if (operationCount >= 500) {
    await batch.commit();
    return FirebaseFirestore.instance.batch();
  }
  return batch;
}
```
