# Firebase Cloud Functions - WeGig

Cloud Functions para notificações in-app e push notifications.

## 📋 Funções Deployadas

**Total:** 5 funções ativas

| Função                        | Trigger             | Tipo      | Status   |
| ----------------------------- | ------------------- | --------- | -------- |
| `notifyNearbyPosts`           | onCreate(posts)     | Firestore | ✅ Ativa |
| `sendInterestNotification`    | onCreate(interests) | Firestore | ✅ Ativa |
| `sendMessageNotification`     | onCreate(messages)  | Firestore | ✅ Ativa |
| `cleanupExpiredNotifications` | Scheduled (daily)   | Cron      | ✅ Ativa |
| `onProfileDelete`             | onDelete(profiles)  | Firestore | ✅ Ativa |

### 1. notifyNearbyPosts

**Trigger:** `onCreate('posts/{postId}')`  
**Região:** southamerica-east1 (São Paulo)

Notifica perfis quando um novo post é criado próximo a eles.

**Lógica:**

- Busca perfis com `notificationRadiusEnabled = true`
- Calcula distância Haversine
- Se distância ≤ `notificationRadius` (5-100km), cria notificação in-app
- Envia push notification via FCM

**Payload:**

```json
{
  "notification": {
    "title": "Novo post próximo!",
    "body": "João está procurando banda a 5.2 km de você em São Paulo"
  },
  "data": {
    "type": "nearbyPost",
    "postId": "abc123",
    "city": "São Paulo"
  }
}
```

---

### 2. sendInterestNotification

**Trigger:** `onCreate('interests/{interestId}')`  
**Região:** southamerica-east1

Notifica quando alguém demonstra interesse em um post.

**Payload:**

```json
{
  "notification": {
    "title": "Novo interesse!",
    "body": "Maria demonstrou interesse em seu post"
  },
  "data": {
    "type": "interest",
    "postId": "abc123",
    "interestedProfileId": "xyz789"
  }
}
```

---

### 3. sendMessageNotification

**Trigger:** `onCreate('conversations/{conversationId}/messages/{messageId}')`  
**Região:** southamerica-east1

Notifica quando uma nova mensagem é recebida.

**Lógica:**

- Verifica se já existe notificação não lida da conversa
- Se sim, atualiza (agregação) → "João (2 mensagens)"
- Se não, cria nova notificação
- Envia push notification

**Payload:**

```json
{
  "notification": {
    "title": "João Silva",
    "body": "Oi, tudo bem?"
  },
  "data": {
    "type": "newMessage",
    "conversationId": "conv123",
    "senderProfileId": "xyz789"
  }
}
```

---

### 4. cleanupExpiredNotifications

**Trigger:** Scheduled (daily at 3am BRT)  
**Região:** southamerica-east1

Remove notificações expiradas do Firestore.

**Schedule:** `0 3 * * *` (cron)

---

### 5. onProfileDelete

**Trigger:** `onDelete('profiles/{profileId}')`  
**Região:** southamerica-east1

Executa cleanup automático quando um perfil é deletado.

**Ações executadas:**

1. **Posts:** Deleta todos os posts criados pelo perfil (`authorProfileId`)
2. **Storage:** Remove todas as imagens dos posts do Firebase Storage
3. **Notificações:** Remove notificações onde o perfil é destinatário (`recipientProfileId`) ou remetente (`postAuthorProfileId`)
4. **Interesses:** Remove todos os interesses demonstrados pelo perfil
5. **FCM Tokens:** Limpa tokens de notificação push da subcoleção `fcmTokens`

**Segurança:**

- Executa em batches de 500 documentos
- Timeout: 9 minutos (máximo permitido)
- Memória: 512MB
- Fail-safe: não lança exceções (cleanup parcial é melhor que falha completa)

**Logs:**

```
🗑️ Profile deleted: abc123 (João Silva)
🧹 Starting cleanup for profile abc123...
📝 Deleted 15 posts (total: 15)
🖼️ Deleted image: posts/abc123/1234567890.jpg
✅ Posts cleanup complete: 15 posts, 23 images
🔔 Deleted 42 recipient notifications (total: 42)
🔔 Deleted 8 sender notifications (total: 50)
✅ Notifications cleanup complete: 50 notifications
💚 Deleted 12 interests (total: 12)
✅ Interests cleanup complete: 12 interests
✅ Deleted 3 FCM tokens

✅ CLEANUP COMPLETO para perfil abc123:
   📝 Posts deletados: 15
   🖼️ Imagens deletadas: 23
   🔔 Notificações deletadas: 50
   💚 Interesses deletados: 12
   🔔 FCM tokens deletados: 3
```

**Importante:**

- Esta função é **automática** e dispara sempre que um perfil é deletado
- Não requer intervenção manual
- Garante que não há dados órfãos no Firestore/Storage
- Previne acúmulo de storage desnecessário

---

## 🚀 Deploy

### Setup Inicial

```bash
# Instalar dependências
cd functions
npm install

# Verificar configuração
firebase use to-sem-banda-83e19
```

### Deploy Completo

```bash
# Deploy todas as funções
firebase deploy --only functions

# Deploy função específica
firebase deploy --only functions:notifyNearbyPosts
```

### Monitoramento

```bash
# Ver logs de todas as funções
firebase functions:log

# Ver logs de função específica
firebase functions:log --only notifyNearbyPosts

# Ver apenas erros
firebase functions:log --only-errors

# Tempo real (tail)
firebase functions:log --only sendInterestNotification --tail
```

---

## 📦 Dependências

```json
{
  "firebase-functions": "^6.0.1",
  "firebase-admin": "^13.0.3"
}
```

**Node.js Runtime:** v20 (padrão Firebase Functions Gen2)

---

## 🔐 Variáveis de Ambiente

As funções usam configurações do Firebase Admin SDK automaticamente:

- Firestore: `admin.firestore()`
- Messaging: `admin.messaging()`
- Auth: `admin.auth()`

**Nenhuma variável adicional necessária.**

---

## 🧪 Testing Local

**Emulator (opcional):**

```bash
firebase emulators:start --only functions,firestore
```

**Testar via Firestore:**

1. Criar post de teste no Firestore Console
2. Verificar logs do emulator ou Firebase Console
3. Confirmar notificação criada e push enviado

---

## 📊 Monitoramento de Produção

### Firebase Console

1. **Functions Dashboard:**

   - Invocações: [console.firebase.google.com/functions](https://console.firebase.google.com/u/0/project/to-sem-banda-83e19/functions/list)
   - Erros: filtrar por `Error` em logs
   - Latência: gráfico de execução

2. **Cloud Messaging:**
   - Mensagens enviadas: [console.firebase.google.com/cloudmessaging](https://console.firebase.google.com/u/0/project/to-sem-banda-83e19/notification)
   - Taxa de entrega
   - Taxa de abertura

### Métricas Importantes

- **Invocações por dia:** ~100-500 (depende do volume de posts)
- **Latência média:** 1-3 segundos
- **Taxa de erro:** <1%
- **Push delivery rate:** >95%

---

## 🐛 Troubleshooting

### Função não dispara

**Sintomas:** Post criado, mas função não executada

**Soluções:**

1. Verificar logs: `firebase functions:log --only notifyNearbyPosts`
2. Verificar trigger path está correto: `posts/{postId}`
3. Redeploy: `firebase deploy --only functions`
4. Verificar billing habilitado (Gen2 requer Blaze plan)

### Notificações não enviadas

**Sintomas:** Função executa, mas notificações não aparecem

**Soluções:**

1. Verificar FCM tokens existem em `profiles/{id}/fcmTokens`
2. Verificar Firebase Messaging API habilitada
3. Testar token via Firebase Console → Cloud Messaging → Test
4. Verificar logs para erros: `invalid-registration-token`

### Tokens inválidos

**Sintomas:** Logs mostram `failureCount > 0`

**Soluções:**

- Função automaticamente remove tokens inválidos
- Verificar Firestore Rules permitem delete em `fcmTokens`
- Logs mostrarão: `🗑️ Removidos X tokens inválidos`

### Rate Limiting / Quotas

**Sintomas:** Erros `quota-exceeded`

**Soluções:**

1. Verificar Firebase quotas: [console.firebase.google.com/project/\*/usage](https://console.firebase.google.com/u/0/project/to-sem-banda-83e19/usage/details)
2. Implementar batching maior (atualmente 500 tokens/batch)
3. Adicionar delay entre batches se necessário

---

## 🔧 Configuração Avançada

### Aumentar Memória

```javascript
exports.notifyNearbyPosts = functions
  .runWith({
    memory: "512MB", // Padrão: 256MB
    timeoutSeconds: 120, // Padrão: 60s
  })
  .region("southamerica-east1")
  .firestore.document("posts/{postId}")
  .onCreate(async (snap) => {
    // ...
  });
```

### Retry Policy

```javascript
exports.sendPushWithRetry = functions
  .runWith({
    failurePolicy: true, // Auto-retry em caso de falha
    maxRetries: 3,
  })
  .firestore.document("posts/{postId}")
  .onCreate(async (snap) => {
    // ...
  });
```

### Múltiplas Regiões

```javascript
// southamerica-east1 (primary)
exports.notifyNearbyPostsBR = functions
  .region("southamerica-east1")
  .firestore.document("posts/{postId}")
  .onCreate(handler);

// us-central1 (fallback)
exports.notifyNearbyPostsUS = functions
  .region("us-central1")
  .firestore.document("posts/{postId}")
  .onCreate(handler);
```

---

## 📚 Referências

- [Firebase Functions Docs](https://firebase.google.com/docs/functions)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Node.js Admin SDK](https://firebase.google.com/docs/admin/setup)
- [Cron Schedule Format](https://cloud.google.com/scheduler/docs/configuring/cron-job-schedules)

---

## ✅ Checklist de Deploy

Antes de fazer deploy em produção:

- [ ] Testar localmente via emulator
- [ ] Verificar região: `southamerica-east1`
- [ ] Verificar Firebase Messaging API habilitada
- [ ] Verificar billing (Blaze plan) ativo
- [ ] Deploy: `firebase deploy --only functions`
- [ ] Monitorar logs por 1 hora: `firebase functions:log --tail`
- [ ] Testar criando post real
- [ ] Verificar notificações recebidas no app
- [ ] Verificar métricas no Firebase Console

---

**Última atualização:** 25/11/2025  
**Versão:** 1.0.0
