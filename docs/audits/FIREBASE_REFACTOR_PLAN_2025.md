# 🚨 Plano de Ação: Firebase Integration Refactoring (2025)

Baseado na auditoria de 07/12/2025, este plano visa corrigir falhas críticas de arquitetura (acesso direto ao banco na UI), bugs de UX (paginação do chat) e riscos de manutenção.

## 📊 Resumo da Auditoria

| Categoria          | Status        | Principais Problemas                                                                         |
| ------------------ | ------------- | -------------------------------------------------------------------------------------------- |
| **Chat (UX/Perf)** | 🔴 Crítico    | Paginação quebrada (updates em tempo real apagam histórico), parsing manual de JSON na View. |
| **Arquitetura**    | 🟠 Alto Risco | `HomePage` e `AppRouter` acessam `FirebaseFirestore` diretamente.                            |
| **Dados**          | 🟡 Médio      | Queries complexas sem garantia de índices, lógica de negócio (criação de notificação) na UI. |

---

## 🎯 Sprints Recomendadas

### Sprint 16: Chat Feature Rescue (4h - CRÍTICO)

**Objetivo:** Corrigir o bug de paginação e desacoplar a UI do Firestore.

1.  **Arquitetura do Chat (2h)**

    - Criar `ChatRepository` (interface + impl) com métodos: `watchMessages`, `loadMoreMessages`, `sendMessage`, `markAsRead`.
    - Criar `MessageEntity` (se não existir ou estiver incompleta) para substituir `Map<String, dynamic>`.
    - Criar `ChatController` (Riverpod) para gerenciar o estado (lista de mensagens + status de loading).

2.  **Correção da Paginação (2h)**
    - Implementar lógica de merge: `Stream` (novas mensagens) + `Future` (histórico paginado).
    - Garantir que novos snapshots não sobrescrevam mensagens antigas já carregadas.
    - Remover lógica de `setState` e `FirebaseFirestore.instance` da `ChatDetailPage`.

**Resultado Esperado:** Chat fluido, com histórico preservado ao receber novas mensagens e código testável.

---

### Sprint 17: Home & Router Cleanup (3h - ALTA)

**Objetivo:** Remover lógica de banco da Home e do Router.

1.  **Refatorar Interesses na Home (1.5h)**

    - Mover lógica de `_sendInterestNotification` e `_removeInterestOptimistically` para `PostRepository` ou `InterestsRepository`.
    - Centralizar a criação do objeto JSON da notificação no Repository.
    - Garantir índices compostos para a query de remoção de interesse.

2.  **Limpar AppRouter (1.5h)**
    - Criar UseCase `GetProfileByUsername`.
    - Substituir query direta no `AppRouter` pela chamada do UseCase.
    - Tratar erros de forma centralizada.

**Resultado Esperado:** `HomePage` e `AppRouter` limpos, respeitando Clean Architecture.

---

### Sprint 18: Padronização & Segurança (2h - MÉDIA)

**Objetivo:** Garantir consistência e segurança dos dados.

1.  **Padronização de Entidades (1h)**

    - Revisar todas as chamadas manuais de `.data()` e substituir por `.fromFirestore()` das entidades.
    - Garantir que `usernameLowercase` seja gerado apenas no `toFirestore()` da entidade.

2.  **Auditoria de Security Rules (1h)**
    - Verificar se as novas queries dos Repositories estão cobertas pelas regras do Firestore (`firestore.rules`).

**Resultado Esperado:** Código mais seguro e menos propenso a erros de digitação/estrutura.
