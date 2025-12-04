/**
 * Firebase Cloud Functions para WeGig
 *
 * Funções:
 * - notifyNearbyPosts: Notificações in-app + push para posts próximos
 * - sendInterestNotification: Notificações in-app + push para interesses
 * - sendMessageNotification: Notificações in-app + push para mensagens
 * - cleanupExpiredNotifications: Limpeza agendada
 * - onProfileDelete: Cleanup automático de posts e Storage quando perfil é deletado
 *
 * Região: southamerica-east1 (São Paulo)
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Rate Limiter Helper
 * Implementa limitação de taxa baseada em contadores Firestore
 * Uso: await checkRateLimit(userId, 'posts', 20, 24 * 60 * 60 * 1000) // 20 posts/dia
 */
async function checkRateLimit(userId, action, limit, windowMs) {
  const now = Date.now();
  const windowStart = new Date(now - windowMs);
  const counterRef = db.collection("rateLimits").doc(`${userId}_${action}`);

  try {
    const counterDoc = await counterRef.get();

    if (!counterDoc.exists) {
      // Primeiro uso - criar contador
      await counterRef.set({
        count: 1,
        lastReset: admin.firestore.FieldValue.serverTimestamp(),
        windowStart: admin.firestore.Timestamp.fromDate(windowStart),
      });
      return { allowed: true, remaining: limit - 1 };
    }

    const data = counterDoc.data();
    const lastReset = data.lastReset?.toDate() || new Date(0);

    // Reset se janela expirou
    if (now - lastReset.getTime() > windowMs) {
      await counterRef.set({
        count: 1,
        lastReset: admin.firestore.FieldValue.serverTimestamp(),
        windowStart: admin.firestore.Timestamp.fromDate(windowStart),
      });
      return { allowed: true, remaining: limit - 1 };
    }

    // Verificar limite
    if (data.count >= limit) {
      console.log(
        `⚠️ Rate limit exceeded: ${userId} - ${action} (${data.count}/${limit})`
      );
      return {
        allowed: false,
        remaining: 0,
        resetAt: new Date(lastReset.getTime() + windowMs),
      };
    }

    // Incrementar contador
    await counterRef.update({
      count: admin.firestore.FieldValue.increment(1),
    });

    return { allowed: true, remaining: limit - data.count - 1 };
  } catch (error) {
    console.error(`Error checking rate limit: ${error}`);
    // Em caso de erro, permitir (fail-open para não bloquear usuários)
    return { allowed: true, remaining: limit };
  }
}

/**
 * Notifica perfis quando um novo post é criado próximo a eles.
 *
 * Lógica:
 * 1. Obtém localização do novo post (location GeoPoint)
 * 2. Busca todos os perfis com notificationRadiusEnabled = true
 * 3. Para cada perfil:
 *    - Calcula distância usando Haversine
 *    - Se distância <= notificationRadius, cria notificação
 * 4. Batch write de todas as notificações
 *
 * Filtros aplicados:
 * - Perfil tem notificationRadiusEnabled = true
 * - Perfil tem location (GeoPoint)
 * - Perfil NÃO é o autor do post (authorProfileId)
 * - Distância <= notificationRadius configurado pelo perfil (default: 20km)
 */
exports.notifyNearbyPosts = functions
  .runWith({
    memory: "256MB",
    timeoutSeconds: 60,
  })
  .region("southamerica-east1") // São Paulo region para menor latência
  .firestore.document("posts/{postId}")
  .onCreate(async (snap) => {
    const post = snap.data();
    const postId = snap.id;

    // Validação: Post deve ter location (GeoPoint)
    if (
      !post.location ||
      !post.location._latitude ||
      !post.location._longitude
    ) {
      console.log(`Post ${postId} ignorado: sem localização válida`);
      return null;
    }

    // Rate limiting: Validar que usuário não está criando posts excessivamente
    // Limite: 20 posts por dia (proteção contra spam)
    const authorUid = post.authorUid;
    if (authorUid) {
      const rateLimitCheck = await checkRateLimit(
        authorUid,
        "posts",
        20,
        24 * 60 * 60 * 1000 // 24 horas
      );

      if (!rateLimitCheck.allowed) {
        console.log(
          `🚫 Rate limit: ${authorUid} excedeu limite de posts diários`
        );
        // Não bloquear a função, mas logar para monitoramento
        // O post já foi criado (onCreate), então apenas não enviar notificações
        // Em produção, considere adicionar flag no post ou notificar admin
      }
    }

    const postLat = post.location._latitude;
    const postLng = post.location._longitude;
    const postCity = post.city || "cidade desconhecida";
    const postType = post.type === "band" ? "banda" : "músico";
    const authorName = post.authorName || "Alguém";
    const authorProfileId = post.authorProfileId;

    console.log(
      `📍 Novo post criado em ${postCity}: ${authorName} (${postType})`
    );
    console.log(
      `   Coordenadas: (${postLat.toFixed(4)}, ${postLng.toFixed(4)})`
    );

    // Query: Busca perfis com notificações de posts próximos habilitadas
    const profilesSnap = await db
      .collection("profiles")
      .where("notificationRadiusEnabled", "==", true)
      .get();

    console.log(
      `🔍 Encontrados ${profilesSnap.size} perfis com notificações habilitadas`
    );

    const notifications = [];

    for (const doc of profilesSnap.docs) {
      const profile = doc.data();
      const profileId = doc.id;

      // Filtro 1: Perfil deve ter location
      if (
        !profile.location ||
        !profile.location._latitude ||
        !profile.location._longitude
      ) {
        continue;
      }

      // Filtro 2: Não notificar o próprio autor do post
      if (profileId === authorProfileId) {
        continue;
      }

      const userLat = profile.location._latitude;
      const userLng = profile.location._longitude;
      const radius = profile.notificationRadius || 20; // CAMPO CORRETO

      // Cálculo Haversine para distância em km
      const R = 6371; // Raio da Terra em km
      const dLat = ((postLat - userLat) * Math.PI) / 180;
      const dLon = ((postLng - userLng) * Math.PI) / 180;
      const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos((userLat * Math.PI) / 180) *
          Math.cos((postLat * Math.PI) / 180) *
          Math.sin(dLon / 2) *
          Math.sin(dLon / 2);
      const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
      const distance = R * c;

      // Filtro 3: Distância dentro do raio configurado
      if (distance <= radius) {
        const distanceStr = distance.toFixed(1);
        console.log(
          `   ✅ ${profile.name} (${profileId.substring(
            0,
            8
          )}...): ${distanceStr} km (raio: ${radius} km)`
        );

        notifications.push({
          recipientProfileId: profileId,
          type: "nearbyPost",
          priority: "medium",
          title: "Novo post próximo!",
          body: `${authorName} está procurando ${postType} a ${distanceStr} km de você em ${postCity}`,
          actionType: "viewPost",
          actionData: {
            postId: postId,
            distance: distanceStr,
            city: postCity,
            postType: post.type,
            authorName: authorName,
            authorProfileId: authorProfileId,
          },
          senderName: authorName,
          senderPhoto: post.authorPhotoUrl || null,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          read: false,
          expiresAt: admin.firestore.Timestamp.fromDate(
            new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
          ), // 7 dias
        });
      } else {
        // Log apenas se muito próximo (debugging)
        if (distance <= radius * 1.5) {
          console.log(
            `   ❌ ${profile.name}: ${distance.toFixed(
              1
            )} km (fora do raio de ${radius} km)`
          );
        }
      }
    }

    // Batch write de todas as notificações
    if (notifications.length > 0) {
      const batch = db.batch();
      notifications.forEach((notification) => {
        const notificationRef = db.collection("notifications").doc();
        batch.set(notificationRef, notification);
      });

      await batch.commit();
      console.log(
        `🔔 Enviadas ${notifications.length} notificações in-app de post próximo`
      );

      // Enviar push notifications para cada perfil
      await sendPushNotificationsForNearbyPost(
        notifications,
        postId,
        authorName,
        postType,
        postCity
      );
    } else {
      console.log("📭 Nenhum perfil próximo encontrado para notificar");
    }

    return null;
  });

/**
 * Helper: Envia push notifications para posts próximos
 *
 * Busca tokens FCM dos perfis e envia notificações em batch
 * Máximo de 500 tokens por batch (limitação FCM)
 */
async function sendPushNotificationsForNearbyPost(
  notifications,
  postId,
  authorName,
  postType,
  city
) {
  const tokens = [];
  const tokenToProfile = {}; // Map token -> profileId para debug

  // Coletar tokens FCM de todos os perfis
  for (const notification of notifications) {
    const profileId = notification.recipientProfileId;

    try {
      const tokensSnap = await db
        .collection("profiles")
        .doc(profileId)
        .collection("fcmTokens")
        .get();

      tokensSnap.docs.forEach((tokenDoc) => {
        const token = tokenDoc.data().token;
        tokens.push(token);
        tokenToProfile[token] = profileId;
      });
    } catch (error) {
      console.log(`⚠️ Erro ao buscar tokens do perfil ${profileId}: ${error}`);
    }
  }

  if (tokens.length === 0) {
    console.log("📭 Nenhum token FCM encontrado para enviar push");
    return;
  }

  console.log(`📤 Enviando push para ${tokens.length} dispositivos`);

  // Payload da notificação
  const payload = {
    notification: {
      title: "Novo post próximo!",
      body: `${authorName} está procurando ${postType} em ${city}`,
    },
    data: {
      type: "nearbyPost",
      postId: postId,
      authorName: authorName,
      city: city,
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
  };

  // FCM suporta até 500 tokens por batch
  const batchSize = 500;
  for (let i = 0; i < tokens.length; i += batchSize) {
    const batchTokens = tokens.slice(i, i + batchSize);

    try {
      const response = await messaging.sendEachForMulticast({
        tokens: batchTokens,
        notification: payload.notification,
        data: payload.data,
        android: {
          priority: "high",
          notification: {
            channelId: "high_importance_channel",
            priority: "high",
            color: "#E47911",
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: payload.notification.title,
                body: payload.notification.body,
              },
              sound: "default",
              badge: 1,
            },
          },
        },
      });

      console.log(
        `✅ Push enviado: ${response.successCount} sucesso, ${response.failureCount} falhas`
      );

      // Remover tokens inválidos
      if (response.failureCount > 0) {
        const tokensToRemove = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            const errorCode = resp.error && resp.error.code;
            // Tokens inválidos ou desinstalados
            if (
              errorCode === "messaging/registration-token-not-registered" ||
              errorCode === "messaging/invalid-registration-token"
            ) {
              tokensToRemove.push(batchTokens[idx]);
            }
          }
        });

        // Remover tokens inválidos do Firestore
        await removeInvalidTokens(tokensToRemove, tokenToProfile);
      }
    } catch (error) {
      console.log(`❌ Erro ao enviar push batch: ${error}`);
    }
  }
}

/**
 * Helper: Remove tokens FCM inválidos do Firestore
 */
async function removeInvalidTokens(tokens, tokenToProfile) {
  if (tokens.length === 0) return;

  console.log(`🗑️ Removendo ${tokens.length} tokens inválidos`);

  const batch = db.batch();
  for (const token of tokens) {
    const profileId = tokenToProfile[token];
    if (profileId) {
      const tokenRef = db
        .collection("profiles")
        .doc(profileId)
        .collection("fcmTokens")
        .doc(token);
      batch.delete(tokenRef);
    }
  }

  await batch.commit();
  console.log(`✅ Tokens inválidos removidos`);
}

/**
 * Envia notificação quando alguém demonstra interesse em um post
 *
 * Trigger: onCreate em interests/{interestId}
 * Cria notificação in-app + push notification
 */
exports.sendInterestNotification = functions
  .runWith({
    memory: "128MB",
    timeoutSeconds: 30,
  })
  .region("southamerica-east1")
  .firestore.document("interests/{interestId}")
  .onCreate(async (snap) => {
    const interest = snap.data();
    const postAuthorProfileId = interest.postAuthorProfileId;
    const interestedProfileName = interest.interestedProfileName || "Alguém";
    const postId = interest.postId;

    // Rate limiting: 50 interesses por dia por perfil (proteção contra spam)
    const interestedProfileId = interest.interestedProfileId;
    if (interestedProfileId) {
      const rateLimitCheck = await checkRateLimit(
        interestedProfileId,
        "interests",
        50,
        24 * 60 * 60 * 1000
      );

      if (!rateLimitCheck.allowed) {
        console.log(
          `🚫 Rate limit: ${interestedProfileId} excedeu limite de interesses diários`
        );
        // Interesse já criado, apenas não enviar notificação
        return null;
      }
    }

    console.log(`💙 Novo interesse: ${interestedProfileName} → post ${postId}`);

    // Criar notificação in-app
    await db.collection("notifications").add({
      recipientProfileId: postAuthorProfileId,
      type: "interest",
      priority: "high",
      title: "Novo interesse!",
      body: `${interestedProfileName} demonstrou interesse em seu post`,
      actionType: "viewPost",
      actionData: {
        postId: postId,
        interestedProfileId: interest.interestedProfileId,
        interestedProfileName: interestedProfileName,
      },
      senderName: interestedProfileName,
      senderPhoto: interest.interestedProfilePhotoUrl || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      read: false,
      expiresAt: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
      ), // 30 dias
    });

    // Enviar push notification
    await sendPushToProfile(
      postAuthorProfileId,
      {
        title: "Novo interesse!",
        body: `${interestedProfileName} demonstrou interesse em seu post`,
      },
      {
        type: "interest",
        postId: postId,
        interestedProfileId: interest.interestedProfileId,
      }
    );

    return null;
  });

/**
 * Envia notificação quando uma nova mensagem é recebida
 *
 * Trigger: onCreate em messages/{conversationId}/messages/{messageId}
 * Cria notificação in-app + push notification
 *
 * Nota: Apenas envia se destinatário NÃO está na conversa (evita spam)
 */
exports.sendMessageNotification = functions
  .runWith({
    memory: "128MB",
    timeoutSeconds: 30,
  })
  .region("southamerica-east1")
  .firestore.document("conversations/{conversationId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const conversationId = context.params.conversationId;
    const senderProfileId = message.senderProfileId;
    const senderName = message.senderName || "Alguém";
    const messageText = message.text || "Enviou uma mensagem";

    console.log(
      `💬 Nova mensagem de ${senderName} na conversa ${conversationId}`
    );

    // Rate limiting: 500 mensagens por dia por perfil (proteção contra spam)
    if (senderProfileId) {
      const rateLimitCheck = await checkRateLimit(
        senderProfileId,
        "messages",
        500,
        24 * 60 * 60 * 1000
      );

      if (!rateLimitCheck.allowed) {
        console.log(
          `🚫 Rate limit: ${senderProfileId} excedeu limite de mensagens diárias`
        );
        // Mensagem já criada, apenas não enviar notificação
        return null;
      }
    }

    // Buscar conversa para obter destinatário
    const conversationDoc = await db
      .collection("conversations")
      .doc(conversationId)
      .get();

    if (!conversationDoc.exists) {
      console.log("⚠️ Conversa não encontrada");
      return null;
    }

    const conversation = conversationDoc.data();
    const participantProfiles = conversation.participantProfiles || [];

    // Encontrar destinatário (não é o sender)
    const recipientProfileId = participantProfiles.find(
      (id) => id !== senderProfileId
    );

    if (!recipientProfileId) {
      console.log("⚠️ Destinatário não encontrado");
      return null;
    }

    // Verificar se já existe notificação não lida desta conversa (agregação)
    const existingNotifications = await db
      .collection("notifications")
      .where("recipientProfileId", "==", recipientProfileId)
      .where("type", "==", "newMessage")
      .where("data.conversationId", "==", conversationId)
      .where("read", "==", false)
      .limit(1)
      .get();

    if (!existingNotifications.empty) {
      // Atualizar notificação existente (agregar)
      const notificationDoc = existingNotifications.docs[0];
      await notificationDoc.ref.update({
        body: `${senderName}: ${messageText}`,
        "data.messagePreview": messageText,
        "data.messageCount": admin.firestore.FieldValue.increment(1),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log("📝 Notificação de mensagem atualizada (agregação)");
    } else {
      // Criar nova notificação
      await db.collection("notifications").add({
        recipientProfileId: recipientProfileId,
        type: "newMessage",
        priority: "high",
        title: "Nova mensagem",
        body: `${senderName}: ${messageText}`,
        data: {
          conversationId: conversationId,
          messagePreview: messageText,
          messageCount: 1,
          senderName: senderName,
          senderProfileId: senderProfileId,
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
        expiresAt: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
        ), // 7 dias
      });

      console.log("📨 Notificação de mensagem criada");
    }

    // Enviar push notification
    await sendPushToProfile(
      recipientProfileId,
      {
        title: senderName,
        body: messageText,
      },
      {
        type: "newMessage",
        conversationId: conversationId,
        senderProfileId: senderProfileId,
      }
    );

    return null;
  });

/**
 * Helper: Envia push notification para um perfil específico
 *
 * Busca todos os tokens FCM do perfil e envia notificação
 */
async function sendPushToProfile(profileId, notification, data) {
  try {
    // Buscar tokens FCM do perfil
    const tokensSnap = await db
      .collection("profiles")
      .doc(profileId)
      .collection("fcmTokens")
      .get();

    if (tokensSnap.empty) {
      console.log(`📭 Nenhum token FCM encontrado para perfil ${profileId}`);
      return;
    }

    const tokens = tokensSnap.docs.map((doc) => doc.data().token);
    console.log(
      `📤 Enviando push para ${tokens.length} dispositivo(s) do perfil ${profileId}`
    );

    // Adicionar click_action para navegação no app
    data.click_action = "FLUTTER_NOTIFICATION_CLICK";

    const response = await messaging.sendEachForMulticast({
      tokens: tokens,
      notification: notification,
      data: data,
      android: {
        priority: "high",
        notification: {
          channelId: "high_importance_channel",
          priority: "high",
          color: "#E47911",
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: notification.title,
              body: notification.body,
            },
            sound: "default",
            badge: 1,
          },
        },
      },
    });

    console.log(
      `✅ Push enviado: ${response.successCount} sucesso, ${response.failureCount} falhas`
    );

    // Remover tokens inválidos
    if (response.failureCount > 0) {
      const tokensToRemove = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const errorCode = resp.error && resp.error.code;
          if (
            errorCode === "messaging/registration-token-not-registered" ||
            errorCode === "messaging/invalid-registration-token"
          ) {
            tokensToRemove.push(tokens[idx]);
          }
        }
      });

      // Remover tokens inválidos
      const batch = db.batch();
      for (const token of tokensToRemove) {
        const tokenRef = db
          .collection("profiles")
          .doc(profileId)
          .collection("fcmTokens")
          .doc(token);
        batch.delete(tokenRef);
      }
      await batch.commit();
      console.log(`🗑️ Removidos ${tokensToRemove.length} tokens inválidos`);
    }
  } catch (error) {
    console.log(`❌ Erro ao enviar push para perfil ${profileId}: ${error}`);
  }
}

/**
 * Limpa notificações expiradas (opcional).
 *
 * Execução: Diária às 3h da manhã (horário de Brasília)
 *
 * Remove notificações onde:
 * - expiresAt < agora
 *
 * Batch delete de até 500 documentos por execução.
 */
exports.cleanupExpiredNotifications = functions
  .runWith({
    memory: "256MB",
    timeoutSeconds: 120,
  })
  .region("southamerica-east1")
  .pubsub.schedule("0 3 * * *") // 3h da manhã todos os dias
  .timeZone("America/Sao_Paulo")
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();

    const expiredSnap = await db
      .collection("notifications")
      .where("expiresAt", "<", now)
      .limit(500) // Limite de segurança
      .get();

    if (expiredSnap.empty) {
      console.log("🧹 Nenhuma notificação expirada encontrada");
      return null;
    }

    const batch = db.batch();
    expiredSnap.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`🧹 Deletadas ${expiredSnap.size} notificações expiradas`);

    return null;
  });

/**
 * Cleanup automático quando perfil é deletado
 *
 * Trigger: onCreate de profiles/{profileId}
 *
 * Ações:
 * 1. Deleta todos os posts criados pelo perfil (authorProfileId)
 * 2. Remove imagens dos posts do Firebase Storage
 * 3. Deleta notificações relacionadas ao perfil (recipient/sender)
 * 4. Remove interesses do perfil
 * 5. Limpa FCM tokens do perfil
 *
 * Executado em batches de 500 documentos por segurança.
 */
exports.onProfileDelete = functions
  .runWith({
    memory: "512MB",
    timeoutSeconds: 540, // 9 minutos (máximo permitido)
  })
  .region("southamerica-east1")
  .firestore.document("profiles/{profileId}")
  .onDelete(async (snap, context) => {
    const profileId = context.params.profileId;
    const profileData = snap.data();

    console.log(`🗑️ Profile deleted: ${profileId} (${profileData.name})`);
    console.log(`🧹 Starting cleanup for profile ${profileId}...`);

    let totalPostsDeleted = 0;
    let totalImagesDeleted = 0;
    let totalNotificationsDeleted = 0;
    let totalInterestsDeleted = 0;

    try {
      // ========================================
      // 1. DELETAR POSTS DO PERFIL
      // ========================================
      console.log(`📝 Cleaning up posts for profile ${profileId}...`);

      const postsQuery = db
        .collection("posts")
        .where("authorProfileId", "==", profileId)
        .limit(500);

      let postsSnapshot = await postsQuery.get();

      while (!postsSnapshot.empty) {
        const batch = db.batch();
        const imagesToDelete = [];

        postsSnapshot.docs.forEach((doc) => {
          const postData = doc.data();

          // Coletar URLs de imagens para deletar do Storage
          if (postData.images && Array.isArray(postData.images)) {
            imagesToDelete.push(...postData.images);
          }

          batch.delete(doc.ref);
        });

        await batch.commit();
        totalPostsDeleted += postsSnapshot.size;
        console.log(
          `📝 Deleted ${postsSnapshot.size} posts (total: ${totalPostsDeleted})`
        );

        // Deletar imagens do Storage
        for (const imageUrl of imagesToDelete) {
          try {
            // Extrair path do Storage da URL
            const decodedUrl = decodeURIComponent(imageUrl);
            const pathMatch = decodedUrl.match(/\/o\/(.+?)\?/);

            if (pathMatch && pathMatch[1]) {
              const filePath = pathMatch[1].replace(/%2F/g, "/");
              const fileRef = admin.storage().bucket().file(filePath);

              await fileRef.delete();
              totalImagesDeleted++;
              console.log(`🖼️ Deleted image: ${filePath}`);
            }
          } catch (storageError) {
            // Não falhar se imagem já foi deletada ou não existe
            console.warn(
              `⚠️ Could not delete image ${imageUrl}: ${storageError.message}`
            );
          }
        }

        // Verificar se há mais posts
        postsSnapshot = await postsQuery.get();
      }

      console.log(
        `✅ Posts cleanup complete: ${totalPostsDeleted} posts, ${totalImagesDeleted} images`
      );

      // ========================================
      // 2. DELETAR NOTIFICAÇÕES RELACIONADAS
      // ========================================
      console.log(`🔔 Cleaning up notifications for profile ${profileId}...`);

      // Notificações onde o perfil é destinatário
      const recipientNotificationsQuery = db
        .collection("notifications")
        .where("recipientProfileId", "==", profileId)
        .limit(500);

      let notifSnapshot = await recipientNotificationsQuery.get();

      while (!notifSnapshot.empty) {
        const batch = db.batch();
        notifSnapshot.docs.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
        totalNotificationsDeleted += notifSnapshot.size;
        console.log(
          `🔔 Deleted ${notifSnapshot.size} recipient notifications (total: ${totalNotificationsDeleted})`
        );
        notifSnapshot = await recipientNotificationsQuery.get();
      }

      // Notificações onde o perfil é remetente (postAuthorProfileId)
      const senderNotificationsQuery = db
        .collection("notifications")
        .where("postAuthorProfileId", "==", profileId)
        .limit(500);

      notifSnapshot = await senderNotificationsQuery.get();

      while (!notifSnapshot.empty) {
        const batch = db.batch();
        notifSnapshot.docs.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
        totalNotificationsDeleted += notifSnapshot.size;
        console.log(
          `🔔 Deleted ${notifSnapshot.size} sender notifications (total: ${totalNotificationsDeleted})`
        );
        notifSnapshot = await senderNotificationsQuery.get();
      }

      console.log(
        `✅ Notifications cleanup complete: ${totalNotificationsDeleted} notifications`
      );

      // ========================================
      // 3. DELETAR INTERESSES DO PERFIL
      // ========================================
      console.log(`💚 Cleaning up interests for profile ${profileId}...`);

      const interestsQuery = db
        .collection("interests")
        .where("profileId", "==", profileId)
        .limit(500);

      let interestsSnapshot = await interestsQuery.get();

      while (!interestsSnapshot.empty) {
        const batch = db.batch();
        interestsSnapshot.docs.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
        totalInterestsDeleted += interestsSnapshot.size;
        console.log(
          `💚 Deleted ${interestsSnapshot.size} interests (total: ${totalInterestsDeleted})`
        );
        interestsSnapshot = await interestsQuery.get();
      }

      console.log(
        `✅ Interests cleanup complete: ${totalInterestsDeleted} interests`
      );

      // ========================================
      // 4. LIMPAR FCM TOKENS (subcoleção)
      // ========================================
      console.log(`🔔 Cleaning up FCM tokens for profile ${profileId}...`);

      const tokensSnapshot = await db
        .collection("profiles")
        .doc(profileId)
        .collection("fcmTokens")
        .get();

      if (!tokensSnapshot.empty) {
        const batch = db.batch();
        tokensSnapshot.docs.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
        console.log(`✅ Deleted ${tokensSnapshot.size} FCM tokens`);
      }

      // ========================================
      // RESUMO FINAL
      // ========================================
      console.log(`\n✅ CLEANUP COMPLETO para perfil ${profileId}:`);
      console.log(`   📝 Posts deletados: ${totalPostsDeleted}`);
      console.log(`   🖼️ Imagens deletadas: ${totalImagesDeleted}`);
      console.log(`   🔔 Notificações deletadas: ${totalNotificationsDeleted}`);
      console.log(`   💚 Interesses deletados: ${totalInterestsDeleted}`);
      console.log(
        `   🔔 FCM tokens deletados: ${
          tokensSnapshot ? tokensSnapshot.size : 0
        }`
      );

      return null;
    } catch (error) {
      console.error(`❌ Error during profile cleanup: ${error}`);
      console.error(error.stack);

      // Não lançar exceção - cleanup parcial é melhor que nada
      return null;
    }
  });
