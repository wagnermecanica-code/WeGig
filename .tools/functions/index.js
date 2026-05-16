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

const functions = require("firebase-functions/v1");
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
        `⚠️ Rate limit exceeded: ${userId} - ${action} (${data.count}/${limit})`,
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
 * Helper: Verifica bloqueio bidirecional entre dois perfis
 *
 * Verifica se existe bloqueio na coleção 'blocks' ou nos arrays blockedProfileIds/blockedByProfileIds.
 * Retorna true se qualquer tipo de bloqueio existir entre os perfis.
 *
 * @param {string} profileId1 - ProfileId do primeiro perfil
 * @param {string} profileId2 - ProfileId do segundo perfil
 * @param {string} context - Contexto para logging (ex: 'nearbyPost:postId')
 * @returns {Promise<boolean>} - true se bloqueado em qualquer direção
 */
async function isBlockedByProfile(profileId1, profileId2, context = "") {
  if (!profileId1 || !profileId2) return false;
  const p1 = profileId1.trim();
  const p2 = profileId2.trim();
  if (p1 === "" || p2 === "") return false;

  const logTag = context ? `[BLOCK_CHECK][${context}]` : "[BLOCK_CHECK]";

  try {
    // Verificar bloqueio em ambas as direções usando IDs de documento (profileId-based)
    const blockId1 = `${p1}_${p2}`; // p1 bloqueou p2
    const blockId2 = `${p2}_${p1}`; // p2 bloqueou p1

    const [block1, block2] = await Promise.all([
      db.collection("blocks").doc(blockId1).get(),
      db.collection("blocks").doc(blockId2).get(),
    ]);

    if (block1.exists || block2.exists) {
      console.log(
        `${logTag} 🚫 Bloqueio detectado entre profiles ${p1} e ${p2} (via blocks collection)`,
      );
      return true;
    }

    // Fallback: verificar blockedProfileIds dos perfis (fonte de verdade canônica)
    const [profile1, profile2] = await Promise.all([
      db.collection("profiles").doc(p1).get(),
      db.collection("profiles").doc(p2).get(),
    ]);

    // Fail-closed if qualquer perfil não existe (evita vazamento)
    if (!profile1.exists || !profile2.exists) {
      console.log(
        `${logTag} 🚫 Bloqueio fail-closed: perfil ausente (p1=${p1} exists=${profile1.exists}, p2=${p2} exists=${profile2.exists})`,
      );
      return true;
    }

    const data1 = profile1.data() || {};
    const data2 = profile2.data() || {};

    const blockedByP1 = data1.blockedProfileIds || [];
    const blockedByP1Reverse = data1.blockedByProfileIds || [];
    const blockedByP2 = data2.blockedProfileIds || [];
    const blockedByP2Reverse = data2.blockedByProfileIds || [];

    // Checar tanto blocked quanto blockedBy (índice reverso) para tolerar dados legados
    if (
      blockedByP1.includes(p2) ||
      blockedByP1Reverse.includes(p2) ||
      blockedByP2.includes(p1) ||
      blockedByP2Reverse.includes(p1)
    ) {
      console.log(`${logTag} 🚫 Bloqueio via arrays entre ${p1} e ${p2}`);
      return true;
    }

    console.log(`${logTag} ✅ Nenhum bloqueio entre ${p1} e ${p2}`);
    return false;
  } catch (error) {
    console.error(`${logTag} ⚠️ Erro ao verificar bloqueio: ${error}`);
    // Fail-closed: em caso de erro, NÃO enviar notificação para evitar vazamento
    return true;
  }
}

function parseFirestoreDate(value) {
  if (!value) return null;
  if (typeof value.toDate === "function") return value.toDate();
  if (value instanceof Date) return value;
  return null;
}

async function getProfileBadgeContext(profileId) {
  try {
    const profileDoc = await db.collection("profiles").doc(profileId).get();
    if (!profileDoc.exists) {
      return { seenAt: null, excludedProfileIds: new Set() };
    }

    const data = profileDoc.data() || {};
    const blockedProfileIds = Array.isArray(data.blockedProfileIds)
      ? data.blockedProfileIds
      : [];
    const blockedByProfileIds = Array.isArray(data.blockedByProfileIds)
      ? data.blockedByProfileIds
      : [];

    return {
      seenAt: parseFirestoreDate(data.myNetworkBadgeSeenAt),
      excludedProfileIds: new Set(
        [...blockedProfileIds, ...blockedByProfileIds]
          .map((value) => String(value || "").trim())
          .filter(Boolean),
      ),
    };
  } catch (error) {
    console.log(
      `⚠️ [BADGE] Erro ao carregar contexto do perfil ${profileId}: ${error}`,
    );
    return { seenAt: null, excludedProfileIds: new Set() };
  }
}

function coerceObject(value) {
  return value && typeof value === "object" && !Array.isArray(value)
    ? value
    : {};
}

function isNotificationTypeExcludedFromBadge(data) {
  const type = String(data.type || "").trim();
  return type === "newMessage";
}

function isConnectionActivityNotification(data) {
  const actionData = coerceObject(data.actionData);
  const payload = coerceObject(data.data);
  const eventType = String(
    actionData.eventType || payload.eventType || "",
  ).trim();
  return eventType.startsWith("connection");
}

function isNotificationExpired(data, now) {
  const expiresAt = parseFirestoreDate(data.expiresAt);
  return expiresAt instanceof Date && expiresAt.getTime() < now.getTime();
}

function notificationMatchesBlockedProfile(data, excludedProfileIds) {
  if (!excludedProfileIds || excludedProfileIds.size === 0) return false;
  const actionData = coerceObject(data.actionData);
  const payload = coerceObject(data.data);
  const candidates = [
    data.senderProfileId,
    data.actorProfileId,
    data.requesterProfileId,
    data.fromProfileId,
    actionData.senderProfileId,
    actionData.actorProfileId,
    actionData.requesterProfileId,
    actionData.fromProfileId,
    actionData.profileId,
    payload.senderProfileId,
    payload.actorProfileId,
    payload.requesterProfileId,
    payload.fromProfileId,
    payload.profileId,
  ];
  for (const candidate of candidates) {
    if (typeof candidate !== "string") continue;
    const normalized = candidate.trim();
    if (normalized && excludedProfileIds.has(normalized)) return true;
  }
  return false;
}

async function getUnreadNotificationBadgeCount(
  profileId,
  recipientUid,
  excludedProfileIds,
) {
  try {
    const unreadSnap = await db
      .collection("notifications")
      .where("recipientProfileId", "==", profileId)
      .where("recipientUid", "==", recipientUid)
      .where("read", "==", false)
      .get();

    const now = new Date();
    let count = 0;
    for (const doc of unreadSnap.docs) {
      const data = doc.data() || {};
      if (isNotificationTypeExcludedFromBadge(data)) continue;
      if (isConnectionActivityNotification(data)) continue;
      if (isNotificationExpired(data, now)) continue;
      if (notificationMatchesBlockedProfile(data, excludedProfileIds)) continue;
      count++;
    }
    return count;
  } catch (error) {
    console.log(`⚠️ [BADGE] Erro ao contar notificações não lidas: ${error}`);
    return 0;
  }
}

async function getUnreadMessageBadgeCount(
  profileId,
  recipientUid,
  excludedProfileIds,
) {
  try {
    const conversationsSnap = await db
      .collection("conversations")
      .where("participants", "array-contains", recipientUid)
      .get();

    let unreadConversations = 0;
    for (const doc of conversationsSnap.docs) {
      const data = doc.data() || {};
      const participantProfiles = Array.isArray(data.participantProfiles)
        ? data.participantProfiles
        : [];
      if (!participantProfiles.includes(profileId)) continue;

      const deletedByProfiles = Array.isArray(data.deletedByProfiles)
        ? data.deletedByProfiles
        : [];
      if (deletedByProfiles.includes(profileId)) continue;

      const archivedByProfiles = Array.isArray(data.archivedByProfiles)
        ? data.archivedByProfiles
        : [];
      if (archivedByProfiles.includes(profileId)) continue;

      const otherProfileId =
        participantProfiles.find((value) => value !== profileId) || "";
      if (otherProfileId && excludedProfileIds.has(otherProfileId)) continue;

      const unreadCount = data.unreadCount || {};
      const countForProfile = Number(unreadCount[profileId] || 0);
      if (countForProfile > 0) {
        unreadConversations++;
      }
    }

    return unreadConversations;
  } catch (error) {
    console.log(`⚠️ [BADGE] Erro ao contar conversas não lidas: ${error}`);
    return 0;
  }
}

async function getMyNetworkBadgeCount(
  profileId,
  recipientUid,
  seenAt,
  excludedProfileIds,
) {
  try {
    const [pendingRequestsSnap, connectionsSnap] = await Promise.all([
      db
        .collection("connectionRequests")
        .where("recipientProfileId", "==", profileId)
        .where("recipientUid", "==", recipientUid)
        .where("status", "==", "pending")
        .get(),
      db
        .collection("connections")
        .where("profileUids", "array-contains", recipientUid)
        .orderBy("createdAt", "desc")
        .get(),
    ]);

    const pendingReceivedCount = pendingRequestsSnap.docs.filter((doc) => {
      const data = doc.data() || {};
      const requesterProfileId = String(data.requesterProfileId || "").trim();
      const requesterUid = String(data.requesterUid || "").trim();
      const requesterName = String(data.requesterName || "").trim();
      const createdAt = parseFirestoreDate(data.createdAt);

      return (
        requesterProfileId &&
        requesterUid &&
        requesterName &&
        (!seenAt || (createdAt && createdAt > seenAt)) &&
        !excludedProfileIds.has(requesterProfileId)
      );
    }).length;

    const newlyAcceptedOutgoingCount = connectionsSnap.docs.filter((doc) => {
      const data = doc.data() || {};
      const profileIds = Array.isArray(data.profileIds) ? data.profileIds : [];
      if (!profileIds.includes(profileId)) return false;

      const initiatedByProfileId = String(
        data.initiatedByProfileId || "",
      ).trim();
      if (initiatedByProfileId !== profileId) return false;

      const createdAt = parseFirestoreDate(data.createdAt);
      if (seenAt && (!createdAt || createdAt <= seenAt)) return false;

      const otherProfileId =
        profileIds.find((candidate) => candidate !== profileId) || "";
      if (!otherProfileId || excludedProfileIds.has(otherProfileId))
        return false;

      const profileUids = Array.isArray(data.profileUids)
        ? data.profileUids
        : [];
      const profileNames = data.profileNames || {};
      const otherIndex = profileIds.indexOf(otherProfileId);
      const otherUid =
        otherIndex >= 0 && otherIndex < profileUids.length
          ? String(profileUids[otherIndex] || "").trim()
          : "";
      const otherName = String(profileNames[otherProfileId] || "").trim();

      return Boolean(otherUid && otherName);
    }).length;

    return pendingReceivedCount + newlyAcceptedOutgoingCount;
  } catch (error) {
    console.log(`⚠️ [BADGE] Erro ao contar Minha Rede: ${error}`);
    return 0;
  }
}

async function getUnifiedBadgeCount(profileId, recipientUid) {
  const { seenAt, excludedProfileIds } =
    await getProfileBadgeContext(profileId);
  const [notifications, messages, myNetwork] = await Promise.all([
    getUnreadNotificationBadgeCount(
      profileId,
      recipientUid,
      excludedProfileIds,
    ),
    getUnreadMessageBadgeCount(profileId, recipientUid, excludedProfileIds),
    getMyNetworkBadgeCount(profileId, recipientUid, seenAt, excludedProfileIds),
  ]);

  const total = notifications + messages + myNetwork;
  console.log(
    `📱 [BADGE] profile=${profileId} notifications=${notifications} messages=${messages} myNetwork=${myNetwork} total=${total}`,
  );
  return total;
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
    // NOTA: Firebase Admin SDK v12+ usa .latitude/.longitude (sem underscore)
    if (
      !post.location ||
      (post.location._latitude === undefined &&
        post.location.latitude === undefined)
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
        24 * 60 * 60 * 1000, // 24 horas
      );

      if (!rateLimitCheck.allowed) {
        console.log(
          `🚫 Rate limit: ${authorUid} excedeu limite de posts diários`,
        );
        // Não bloquear a função, mas logar para monitoramento
        // O post já foi criado (onCreate), então apenas não enviar notificações
        // Em produção, considere adicionar flag no post ou notificar admin
      }
    }

    // Firebase Admin SDK v12+ usa .latitude/.longitude (sem underscore)
    const postLat = post.location.latitude ?? post.location._latitude;
    const postLng = post.location.longitude ?? post.location._longitude;
    const postCity = post.city || "cidade desconhecida";

    // Mapear tipo do post para texto amigável
    const postTypeMap = {
      musician: "banda",
      band: "músico",
      sales: "serviço/produto",
      hiring: "músico/banda", // Para contratações
    };
    const postType = postTypeMap[post.type] || "músico";

    const authorName = post.authorName || "Alguém";
    const authorUsername = post.authorUsername || "";
    const authorProfileId = post.authorProfileId;

    // Usa username se disponível, senão usa nome (para exibição no body)
    const displayAuthor = authorUsername || authorName;

    console.log(
      `📍 Novo post criado em ${postCity}: ${authorName} (${postType})`,
    );
    console.log(
      `   Coordenadas: (${postLat.toFixed(4)}, ${postLng.toFixed(4)})`,
    );

    // Query: Busca perfis com notificações de posts próximos habilitadas
    const profilesSnap = await db
      .collection("profiles")
      .where("notificationRadiusEnabled", "==", true)
      .get();

    console.log(
      `🔍 Encontrados ${profilesSnap.size} perfis com notificações habilitadas`,
    );

    const notifications = [];

    for (const doc of profilesSnap.docs) {
      const profile = doc.data();
      const profileId = doc.id;
      const profileUid = profile.uid; // UID do dono do perfil para push notifications

      // Filtro 1: Perfil deve ter location
      if (
        !profile.location ||
        (profile.location._latitude === undefined &&
          profile.location.latitude === undefined)
      ) {
        continue;
      }

      // Filtro 2: Não notificar o próprio autor do post
      if (profileId === authorProfileId) {
        continue;
      }

      // Filtro 2.1: Verificar bloqueio bidirecional (autor <-> destinatário) por PERFIL
      const [authorBlocksRecipient, recipientBlocksAuthor] = await Promise.all([
        isBlockedByProfile(authorProfileId, profileId, `nearbyPost:${postId}`),
        isBlockedByProfile(profileId, authorProfileId, `nearbyPost:${postId}`),
      ]);
      if (authorBlocksRecipient || recipientBlocksAuthor) {
        console.log(
          `   🚫 ${profile.name}: bloqueio detectado (author=${authorProfileId} recipient=${profileId} post=${postId} authorBlocks=${authorBlocksRecipient} recipientBlocks=${recipientBlocksAuthor})`,
        );
        continue;
      }

      console.log(
        `   🟢 [BLOCK_CHECK][nearbyPost:${postId}] author=${authorProfileId} <-> recipient=${profileId}`,
      );

      // Firebase Admin SDK v12+ usa .latitude/.longitude (sem underscore)
      const userLat = profile.location.latitude ?? profile.location._latitude;
      const userLng = profile.location.longitude ?? profile.location._longitude;
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
            8,
          )}...): ${distanceStr} km (raio: ${radius} km)`,
        );

        // Verificar se já existe notificação não lida para este post próximo
        const existingNearbyNotification = await db
          .collection("notifications")
          .where("recipientProfileId", "==", profileId)
          .where("type", "==", "nearbyPost")
          .where("actionData.postId", "==", postId)
          .where("read", "==", false)
          .limit(1)
          .get();

        if (!existingNearbyNotification.empty) {
          console.log(
            `   📭 ${profile.name} já foi notificado sobre este post próximo, pulando...`,
          );
          continue; // Pular este perfil, já foi notificado
        }

        // Mensagem personalizada baseada no tipo de post
        const nearbyBody =
          post.type === "sales"
            ? `@${displayAuthor} • anunciou perto de você`
            : post.type === "hiring"
              ? `@${displayAuthor} • está contratando perto de você`
              : `@${displayAuthor} • postou perto de você`;

        notifications.push({
          recipientProfileId: profileId,
          recipientUid: profileUid, // 🔒 SECURITY: UID do dono do perfil para push
          profileUid: profileId, // CRITICAL: Isolamento de perfil
          type: "nearbyPost",
          priority: "medium",
          title: "Novo post próximo!",
          body: nearbyBody,
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
          senderUsername: authorUsername, // Username para navegação ao perfil
          senderPhoto: post.authorPhotoUrl || null,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          read: false,
          expiresAt: admin.firestore.Timestamp.fromDate(
            new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
          ), // 7 dias
        });
      } else {
        // Log apenas se muito próximo (debugging)
        if (distance <= radius * 1.5) {
          console.log(
            `   ❌ ${profile.name}: ${distance.toFixed(
              1,
            )} km (fora do raio de ${radius} km)`,
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
        `🔔 Enviadas ${notifications.length} notificações in-app de post próximo`,
      );

      // Enviar push notifications para cada perfil
      await sendPushNotificationsForNearbyPost(
        notifications,
        postId,
        authorName,
        postType,
        postCity,
        post.type, // tipo original do post
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
  city,
  originalPostType, // tipo original do post ('musician', 'band', 'sales')
) {
  const tokens = [];
  const tokenToProfile = {}; // Map token -> profileId para debug
  const processedUids = new Set(); // 🔧 FIX: Evitar duplicação por UID

  // 🔒 SECURITY FIX: Coletar apenas tokens válidos com ownership verificado
  // 🔧 DEDUP FIX: Processar apenas um perfil por UID para evitar duplicação
  for (const notification of notifications) {
    const profileId = notification.recipientProfileId;
    const recipientUid = notification.recipientUid;

    // Pular se já processamos este UID (usuário pode ter múltiplos perfis)
    if (processedUids.has(recipientUid)) {
      console.log(
        `   ⏭️ UID ${recipientUid} já processado, pulando perfil ${profileId}...`,
      );
      continue;
    }
    processedUids.add(recipientUid);

    const profileTokens = await getValidTokensForProfile(
      profileId,
      recipientUid,
    );

    profileTokens.forEach((token) => {
      // Verificar se token já foi adicionado (mesmo token em múltiplos perfis)
      if (!tokens.includes(token)) {
        tokens.push(token);
        tokenToProfile[token] = profileId;
      }
    });
  }

  if (tokens.length === 0) {
    console.log("📭 Nenhum token FCM encontrado para enviar push");
    return;
  }

  console.log(`📤 Enviando push para ${tokens.length} dispositivos`);

  // Texto personalizado baseado no tipo de post
  const notificationBody =
    originalPostType === "sales"
      ? `${authorName} está oferecendo ${postType} em ${city}`
      : originalPostType === "hiring"
        ? `${authorName} está contratando ${postType} em ${city}`
        : `${authorName} está procurando ${postType} em ${city}`;

  // Payload da notificação
  const payload = {
    notification: {
      title: "Novo post próximo!",
      body: notificationBody,
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
            },
          },
        },
      });

      console.log(
        `✅ Push enviado: ${response.successCount} sucesso, ${response.failureCount} falhas`,
      );

      // Remover tokens inválidos
      if (response.failureCount > 0) {
        const tokensToRemove = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            const errorCode = resp.error && resp.error.code;
            const errorMsg = resp.error && resp.error.message;

            // ✅ LOG DETALHADO: Mostrar erro específico para debugging
            console.log(
              `❌ Push falhou para token ${idx}: ${errorCode} - ${errorMsg}`,
            );

            // Tokens inválidos ou desinstalados
            if (
              errorCode === "messaging/registration-token-not-registered" ||
              errorCode === "messaging/invalid-registration-token" ||
              errorCode === "messaging/invalid-argument"
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
 * 🔒 SECURITY HELPER: Valida ownership e busca tokens FCM válidos para um perfil
 *
 * @param {string} profileId - ID do perfil
 * @param {string} expectedUid - UID esperado do dono do perfil (validação de ownership)
 * @return {Promise<string[]>} Array de tokens FCM válidos (não expirados)
 */
async function getValidTokensForProfile(profileId, expectedUid) {
  try {
    // Validar que o profileId pertence ao expectedUid
    const profileDoc = await db.collection("profiles").doc(profileId).get();
    if (!profileDoc.exists) {
      console.log(`⚠️ Perfil ${profileId} não encontrado`);
      return [];
    }

    const profileData = profileDoc.data();
    if (profileData.uid !== expectedUid) {
      console.log(
        `🚨 SECURITY: Perfil ${profileId} não pertence ao usuário ${expectedUid}`,
      );
      return [];
    }

    // Buscar tokens FCM
    const tokensSnap = await db
      .collection("profiles")
      .doc(profileId)
      .collection("fcmTokens")
      .get();

    if (tokensSnap.empty) {
      console.log(`📭 Nenhum token FCM encontrado para perfil ${profileId}`);
      return [];
    }

    // Filtrar tokens válidos e ordenar por updatedAt (mais recente primeiro)
    // NOTA: NÃO expiramos tokens por idade - FCM reporta tokens inválidos no envio
    const validTokens = [];
    let skippedNonMobileTokens = 0;
    let skippedUnknownPlatformTokens = 0;

    tokensSnap.docs.forEach((tokenDoc) => {
      const tokenData = tokenDoc.data();
      const token =
        typeof tokenData.token === "string" ? tokenData.token.trim() : "";
      if (!token) return;

      // 🚫 Ignorar tokens de plataformas não-mobile (causam third-party-auth-error)
      const platform = (tokenData.platform || "").toLowerCase();
      if (
        platform === "web" ||
        platform === "linux" ||
        platform === "windows" ||
        platform === "macos"
      ) {
        skippedNonMobileTokens++;
        return;
      }

      // Manter apenas plataformas mobile conhecidas para evitar tokens
      // legados inconsistentes (geram invalid-argument no FCM).
      if (platform !== "ios" && platform !== "android") {
        skippedUnknownPlatformTokens++;
        return;
      }

      const updatedAt =
        tokenData.updatedAt?.toMillis() || tokenData.createdAt?.toMillis() || 0;

      validTokens.push({ token, updatedAt, platform });
    });

    // Ordenar por updatedAt (mais recente primeiro) e pegar apenas o mais recente
    // para evitar notificações duplicadas em múltiplos dispositivos
    if (skippedNonMobileTokens > 0) {
      console.log(
        `⏭️ Ignorados ${skippedNonMobileTokens} tokens de plataformas desktop/web`,
      );
    }

    if (skippedUnknownPlatformTokens > 0) {
      console.log(
        `⏭️ Ignorados ${skippedUnknownPlatformTokens} tokens com platform ausente/inesperada`,
      );
    }

    validTokens.sort((a, b) => b.updatedAt - a.updatedAt);

    // Estratégia balanceada:
    // 1) prioriza 1 token mais recente de Android e iOS
    // 2) completa com os próximos mais recentes até 5 tokens no total
    // Isso preserva entrega em multi-dispositivo sem exagerar fan-out.
    const selectedTokens = [];
    const selectedTokenSet = new Set();

    const latestAndroid = validTokens.find((t) => t.platform === "android");
    if (latestAndroid) {
      selectedTokens.push(latestAndroid);
      selectedTokenSet.add(latestAndroid.token);
    }

    const latestIos = validTokens.find((t) => t.platform === "ios");
    if (latestIos && !selectedTokenSet.has(latestIos.token)) {
      selectedTokens.push(latestIos);
      selectedTokenSet.add(latestIos.token);
    }

    for (const tokenData of validTokens) {
      if (selectedTokens.length >= 5) break;
      if (selectedTokenSet.has(tokenData.token)) continue;
      selectedTokens.push(tokenData);
      selectedTokenSet.add(tokenData.token);
    }

    const tokensToUse = selectedTokens.map((t) => t.token);

    console.log(
      `✅ ${tokensToUse.length} token(s) válido(s) para perfil ` +
        `${profileId} (${validTokens.length} tokens válidos)`,
    );
    // Debug: log platforms for troubleshooting
    const platformSummary = selectedTokens
      .map((t) => t.platform || "NO_PLATFORM")
      .join(", ");
    console.log(`📱 Platforms selecionadas para envio: ${platformSummary}`);
    // Debug: log platforms for troubleshooting
    return tokensToUse;
  } catch (error) {
    console.log(`❌ Erro ao buscar tokens do perfil ${profileId}: ${error}`);
    return [];
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
    const interestedProfileUsername = interest.interestedProfileUsername || "";
    const postId = interest.postId;

    // Buscar dados do post para personalizar mensagem
    let postType = "unknown";
    let postCity = "";
    try {
      const postDoc = await db.collection("posts").doc(postId).get();
      if (postDoc.exists) {
        const postData = postDoc.data();
        postType = postData.type || "unknown";
        postCity = postData.city || "";
      }
    } catch (err) {
      console.log(`⚠️ Erro ao buscar post ${postId}:`, err.message);
    }

    // Usa username se disponível, senão usa nome
    const displayName = interestedProfileUsername || interestedProfileName;

    // Mensagem personalizada baseada no tipo de post
    const interestBody =
      postType === "sales"
        ? `@${displayName} • salvou seu anúncio`
        : `@${displayName} • demonstrou interesse no seu post`;

    // Rate limiting: 50 interesses por dia por perfil (proteção contra spam)
    const interestedProfileId = interest.interestedProfileId;
    if (interestedProfileId) {
      const rateLimitCheck = await checkRateLimit(
        interestedProfileId,
        "interests",
        50,
        24 * 60 * 60 * 1000,
      );

      if (!rateLimitCheck.allowed) {
        console.log(
          `🚫 Rate limit: ${interestedProfileId} excedeu limite de interesses diários`,
        );
        // Interesse já criado, apenas não enviar notificação
        return null;
      }
    }

    console.log(`💙 Novo interesse: ${interestedProfileName} → post ${postId}`);

    // 🔒 SECURITY: Buscar UID do perfil autor para validação
    const postAuthorProfile = await db
      .collection("profiles")
      .doc(postAuthorProfileId)
      .get();
    if (!postAuthorProfile.exists) {
      console.log(`⚠️ Perfil autor ${postAuthorProfileId} não encontrado`);
      return null;
    }
    const postAuthorProfileData = postAuthorProfile.data();
    const recipientUid = postAuthorProfileData.uid;

    // 🔒 BLOCKING: Checar bloqueio em ambas as direções (interessado <-> autor)
    if (interestedProfileId && postAuthorProfileId) {
      const [interestedBlocksAuthor, authorBlocksInterested] =
        await Promise.all([
          isBlockedByProfile(
            interestedProfileId,
            postAuthorProfileId,
            `interest:${postId}`,
          ),
          isBlockedByProfile(
            postAuthorProfileId,
            interestedProfileId,
            `interest:${postId}`,
          ),
        ]);

      if (interestedBlocksAuthor || authorBlocksInterested) {
        console.log(
          `🚫 [BLOCK_CHECK][interest:${postId}] Bloqueio detectado (interested=${interestedProfileId} author=${postAuthorProfileId} interestedBlocks=${interestedBlocksAuthor} authorBlocks=${authorBlocksInterested}), não enviando notificação`,
        );
        return null;
      }

      console.log(
        `🟢 [BLOCK_CHECK][interest:${postId}] autorizado: ${interestedProfileId} <-> ${postAuthorProfileId}`,
      );
    }

    // ✅ Verificar configuração notifyInterests do usuário destinatário
    const notifyInterests = postAuthorProfileData.notifyInterests ?? true;
    if (!notifyInterests) {
      console.log(
        `🔕 Notificação de interesse desativada para perfil ${postAuthorProfileId}`,
      );
      return null;
    }

    // Criar notificação in-app
    await db.collection("notifications").add({
      recipientProfileId: postAuthorProfileId,
      recipientUid: recipientUid, // 🔒 SECURITY: UID do dono do perfil
      profileUid: postAuthorProfileId, // LEGACY: manter para compatibilidade
      type: "interest",
      priority: "high",
      title: "Novo interesse!",
      body: interestBody,
      actionType: "viewPost",
      actionData: {
        postId: postId,
        interestedProfileId: interest.interestedProfileId,
        interestedProfileName: interestedProfileName,
        postType: postType,
        city: postCity,
      },
      senderName: interestedProfileName,
      senderUsername: interestedProfileUsername, // Username para navegação ao perfil
      senderPhoto: interest.interestedProfilePhotoUrl || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      read: false,
      expiresAt: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      ), // 30 dias
    });

    // Enviar push notification
    await sendPushToProfile(
      postAuthorProfileId,
      recipientUid, // 🔒 SECURITY: passar UID para validação
      {
        title: "Novo interesse!",
        body: interestBody,
      },
      {
        type: "interest",
        postId: postId,
        interestedProfileId: interest.interestedProfileId,
        postType: postType,
      },
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

    // Metadados do remetente (úteis para deep link do app)
    const senderUid = message.senderId || message.senderUid || "";
    const senderPhotoUrl = message.senderPhotoUrl || "";

    console.log(
      `💬 Nova mensagem de ${senderName} na conversa ${conversationId}`,
    );

    // Rate limiting: 500 mensagens por dia por perfil (proteção contra spam)
    if (senderProfileId) {
      const rateLimitCheck = await checkRateLimit(
        senderProfileId,
        "messages",
        500,
        24 * 60 * 60 * 1000,
      );

      if (!rateLimitCheck.allowed) {
        console.log(
          `🚫 Rate limit: ${senderProfileId} excedeu limite de mensagens diárias`,
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
    const groupNameRaw = (conversation.groupName || "").toString().trim();
    const isGroupConversation =
      conversation.isGroup === true ||
      participantProfiles.length > 2 ||
      groupNameRaw.length > 0;
    const groupName = groupNameRaw || "Grupo";
    const groupPhotoUrl = conversation.groupPhotoUrl || "";

    const inAppTitle = isGroupConversation
      ? `Nova mensagem em ${groupName}`
      : "Nova mensagem";
    const inAppBody = isGroupConversation
      ? `${senderName} no grupo ${groupName}: ${messageText}`
      : `${senderName}: ${messageText}`;

    const pushTitle = isGroupConversation ? groupName : senderName;
    const pushBody = isGroupConversation
      ? `${senderName} no grupo ${groupName}: ${messageText}`
      : messageText;

    // Encontrar destinatário (não é o sender)
    const recipientProfileId = participantProfiles.find(
      (id) => id !== senderProfileId,
    );

    if (!recipientProfileId) {
      console.log("⚠️ Destinatário não encontrado");
      return null;
    }

    // ✅ FIX: Buscar UID do destinatário para permissões (Security Rules)
    const recipientProfileDoc = await db
      .collection("profiles")
      .doc(recipientProfileId)
      .get();

    if (!recipientProfileDoc.exists) {
      console.log(`⚠️ Perfil ${recipientProfileId} não encontrado`);
      return null;
    }

    const recipientProfileData = recipientProfileDoc.data();
    const recipientUid = recipientProfileData.uid;

    if (!recipientUid) {
      console.log(`⚠️ UID não encontrado para perfil ${recipientProfileId}`);
      return null;
    }

    // 🔒 BLOCKING: Checar bloqueio em ambas as direções (sender <-> recipient)
    if (senderProfileId && recipientProfileId) {
      const [senderBlocksRecipient, recipientBlocksSender] = await Promise.all([
        isBlockedByProfile(
          senderProfileId,
          recipientProfileId,
          `message:${conversationId}`,
        ),
        isBlockedByProfile(
          recipientProfileId,
          senderProfileId,
          `message:${conversationId}`,
        ),
      ]);

      if (senderBlocksRecipient || recipientBlocksSender) {
        console.log(
          `🚫 [BLOCK_CHECK][message:${conversationId}] Bloqueio detectado (sender=${senderProfileId} recipient=${recipientProfileId} senderBlocks=${senderBlocksRecipient} recipientBlocks=${recipientBlocksSender}), não enviando notificação de mensagem`,
        );
        return null;
      }

      console.log(
        `🟢 [BLOCK_CHECK][message:${conversationId}] autorizado: ${senderProfileId} <-> ${recipientProfileId}`,
      );
    }

    // ✅ Verificar configuração notifyMessages do usuário destinatário
    const notifyMessages = recipientProfileData.notifyMessages ?? true;
    if (!notifyMessages) {
      console.log(
        `🔕 Notificação de mensagem desativada para perfil ${recipientProfileId}`,
      );
      return null;
    }

    // NOTA: unreadCount é incrementado no app Flutter (sendMessage)
    // Não incrementar aqui para evitar contagem duplicada

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
        title: inAppTitle,
        body: inAppBody,
        "data.messagePreview": messageText,
        "data.messageCount": admin.firestore.FieldValue.increment(1),
        "data.isGroup": isGroupConversation,
        "data.groupName": isGroupConversation ? groupName : "",
        "data.groupPhotoUrl": isGroupConversation ? groupPhotoUrl : "",
        "data.otherProfileId": senderProfileId,
        "data.otherUid": senderUid,
        "data.otherName": senderName,
        "data.otherPhotoUrl": senderPhotoUrl,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log("📝 Notificação de mensagem atualizada (agregação)");
    } else {
      // Criar nova notificação
      await db.collection("notifications").add({
        recipientProfileId: recipientProfileId,
        recipientUid: recipientUid, // ✅ FIX: Auth UID para Security Rules
        type: "newMessage",
        priority: "high",
        title: inAppTitle,
        body: inAppBody,
        data: {
          conversationId: conversationId,
          messagePreview: messageText,
          messageCount: 1,
          isGroup: isGroupConversation,
          groupName: isGroupConversation ? groupName : "",
          groupPhotoUrl: isGroupConversation ? groupPhotoUrl : "",
          senderName: senderName,
          senderProfileId: senderProfileId,
          // Padronizar payload para navegação no app (chat)
          otherProfileId: senderProfileId,
          otherUid: senderUid,
          otherName: senderName,
          otherPhotoUrl: senderPhotoUrl,
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
        expiresAt: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        ), // 7 dias
      });

      console.log("📨 Notificação de mensagem criada");
    }

    // ✅ Sempre enviar push notification para cada mensagem recebida
    await sendPushToProfile(
      recipientProfileId,
      recipientUid, // 🔒 SECURITY: passar UID para validação
      {
        title: pushTitle,
        body: pushBody,
      },
      {
        type: "newMessage",
        conversationId: conversationId,
        isGroup: isGroupConversation ? "true" : "false",
        groupName: isGroupConversation ? groupName : "",
        groupPhotoUrl: isGroupConversation ? groupPhotoUrl : "",
        // Compat: manter senderProfileId (já usado em algumas telas)
        senderProfileId: senderProfileId,
        // Novo: padronizado para navegação direta sem reads adicionais
        otherProfileId: senderProfileId,
        otherUid: senderUid,
        otherName: senderName,
        otherPhotoUrl: senderPhotoUrl,
      },
    );

    return null;
  });

/**
 * Envia notificacao quando alguem curte um comentario
 *
 * Trigger: onUpdate em posts/{postId}/comments/{commentId}
 * Detecta novas curtidas comparando likedBy antes/depois.
 * Cria notificacao in-app + push notification para o autor do comentario.
 */
exports.sendCommentLikeNotification = functions
  .runWith({
    memory: "128MB",
    timeoutSeconds: 30,
  })
  .region("southamerica-east1")
  .firestore.document("posts/{postId}/comments/{commentId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};
    const postId = context.params.postId;
    const commentId = context.params.commentId;

    const beforeLikedBy = before.likedBy || [];
    const afterLikedBy = after.likedBy || [];

    const beforeSet = new Set(beforeLikedBy);
    const newLikers = afterLikedBy.filter((id) => !beforeSet.has(id));

    if (newLikers.length === 0) {
      return null;
    }

    const commentAuthorProfileId = (after.authorProfileId || "").trim();
    const commentAuthorUid = (after.authorUid || "").trim();

    if (!commentAuthorProfileId || !commentAuthorUid) {
      console.log(
        "Comment like notification skipped: missing authorProfileId or authorUid",
      );
      return null;
    }

    for (const likerProfileId of newLikers) {
      if (likerProfileId === commentAuthorProfileId) {
        continue;
      }

      const rateLimitCheck = await checkRateLimit(
        likerProfileId,
        "commentLikes",
        200,
        24 * 60 * 60 * 1000,
      );
      if (!rateLimitCheck.allowed) {
        console.log(
          "Rate limit: " + likerProfileId + " excedeu limite de curtidas",
        );
        continue;
      }

      const [likerBlocksAuthor, authorBlocksLiker] = await Promise.all([
        isBlockedByProfile(
          likerProfileId,
          commentAuthorProfileId,
          "commentLike:" + commentId,
        ),
        isBlockedByProfile(
          commentAuthorProfileId,
          likerProfileId,
          "commentLike:" + commentId,
        ),
      ]);

      if (likerBlocksAuthor || authorBlocksLiker) {
        continue;
      }

      const authorProfileDoc = await db
        .collection("profiles")
        .doc(commentAuthorProfileId)
        .get();
      if (!authorProfileDoc.exists) continue;

      const authorProfileData = authorProfileDoc.data() || {};
      const authorUid = (authorProfileData.uid || "").trim();
      if (!authorUid) continue;

      const notifyComments = authorProfileData.notifyComments ?? true;
      if (!notifyComments) continue;

      const likerProfileDoc = await db
        .collection("profiles")
        .doc(likerProfileId)
        .get();
      const likerName = likerProfileDoc.exists
        ? likerProfileDoc.data().name || "Alguem"
        : "Alguem";
      const likerPhoto = likerProfileDoc.exists
        ? likerProfileDoc.data().photoUrl || null
        : null;

      const commentText = after.text || "";
      const commentPreview =
        commentText.length > 80
          ? commentText.substring(0, 80) + "..."
          : commentText;

      const notificationTitle = likerName + " curtiu seu comentário";
      const notificationBody = "Curtiu seu comentário: " + commentPreview;

      await db.collection("notifications").add({
        recipientProfileId: commentAuthorProfileId,
        recipientUid: authorUid,
        profileUid: commentAuthorProfileId,
        type: "comment_like",
        priority: "low",
        title: notificationTitle,
        body: notificationBody,
        actionType: "viewPost",
        actionData: {
          postId: postId,
          commentId: commentId,
          likerProfileId: likerProfileId,
          likerName: likerName,
        },
        senderName: likerName,
        senderPhoto: likerPhoto,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
        expiresAt: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        ),
      });

      await sendPushToProfile(
        commentAuthorProfileId,
        authorUid,
        { title: notificationTitle, body: notificationBody },
        {
          type: "comment_like",
          postId: postId,
          commentId: commentId,
          likerProfileId: likerProfileId,
          recipientProfileId: commentAuthorProfileId,
        },
      );

      console.log(
        "Notificacao de curtida enviada: " +
          likerName +
          " -> " +
          commentAuthorProfileId,
      );
    }

    return null;
  });

/**
 * Helper: Envia push notification para um perfil específico
 *
 * Busca todos os tokens FCM do perfil e envia notificação
 */
async function sendPushToProfile(profileId, recipientUid, notification, data) {
  try {
    // 🔒 SECURITY: Buscar apenas tokens válidos com ownership verificado
    const tokens = await getValidTokensForProfile(profileId, recipientUid);

    if (tokens.length === 0) {
      console.log(
        `📭 Nenhum token FCM válido encontrado para perfil ${profileId}`,
      );
      return;
    }

    console.log(
      `📤 Enviando push para ${tokens.length} dispositivo(s) do perfil ${profileId}`,
    );

    // Adicionar click_action para navegação no app
    data.click_action = "FLUTTER_NOTIFICATION_CLICK";
    const badgeCount = await getUnifiedBadgeCount(profileId, recipientUid);

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
          // Badge count no ícone do launcher (Android 8+).
          // Renderizado via NotificationCompat.setNumber(count) — quando o
          // launcher suporta badges numéricos (Samsung One UI, Pixel, etc.),
          // exibe o total de itens não lidos no ícone do app.
          notificationCount: badgeCount,
        },
      },
      apns: {
        headers: {
          "apns-priority": "10",
        },
        payload: {
          aps: {
            alert: {
              title: notification.title,
              body: notification.body,
            },
            sound: "default",
            badge: badgeCount,
            "content-available": 1,
          },
        },
      },
    });

    console.log(
      `✅ Push enviado: ${response.successCount} sucesso, ${response.failureCount} falhas`,
    );

    // Remover tokens inválidos (podem ter expirado entre busca e envio)
    if (response.failureCount > 0) {
      const tokensToRemove = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const errorCode = resp.error && resp.error.code;
          const errorMsg = resp.error && resp.error.message;

          // ✅ LOG DETALHADO: Mostrar erro específico para debugging
          console.log(
            `❌ Push falhou para token ${idx}: ${errorCode} - ${errorMsg}`,
          );

          if (
            errorCode === "messaging/registration-token-not-registered" ||
            errorCode === "messaging/invalid-registration-token" ||
            errorCode === "messaging/invalid-argument"
          ) {
            tokensToRemove.push(tokens[idx]);
          }
        }
      });

      // Usar helper para remover tokens (mantém consistência)
      const tokenToProfile = {};
      tokensToRemove.forEach((token) => (tokenToProfile[token] = profileId));
      await removeInvalidTokens(tokensToRemove, tokenToProfile);
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
 * Notifica autores quando seus posts estão prestes a expirar
 *
 * Execução: Diária às 10h da manhã (horário de Brasília)
 *
 * Lógica:
 * 1. Busca posts com expiresAt entre agora e +24h
 * 2. Para cada post, cria notificação para o autor
 * 3. Envia push notification
 *
 * Nota: Não notifica posts que já foram notificados (dedup via notificationId fixo)
 */
exports.notifyPostExpiring = functions
  .runWith({
    memory: "256MB",
    timeoutSeconds: 120,
  })
  .region("southamerica-east1")
  .pubsub.schedule("0 10 * * *") // 10h da manhã todos os dias
  .timeZone("America/Sao_Paulo")
  .onRun(async () => {
    const now = admin.firestore.Timestamp.now();
    const in24Hours = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 24 * 60 * 60 * 1000),
    );

    console.log(
      `⏰ [POST_EXPIRING] Buscando posts que expiram nas próximas 24h...`,
    );

    // Buscar posts que expiram entre agora e +24h
    const expiringPostsSnap = await db
      .collection("posts")
      .where("expiresAt", ">", now)
      .where("expiresAt", "<=", in24Hours)
      .orderBy("expiresAt")
      .limit(200) // Limite de segurança
      .get();

    if (expiringPostsSnap.empty) {
      console.log("⏰ [POST_EXPIRING] Nenhum post expirando nas próximas 24h");
      return null;
    }

    console.log(
      `⏰ [POST_EXPIRING] Encontrados ${expiringPostsSnap.size} posts expirando`,
    );

    let notificationsCreated = 0;
    let notificationsSkipped = 0;

    for (const postDoc of expiringPostsSnap.docs) {
      const post = postDoc.data();
      const postId = postDoc.id;
      const authorProfileId = (post.authorProfileId || "").trim();
      const authorUid = (post.authorUid || "").trim();

      if (!authorProfileId || !authorUid) {
        console.log(
          `⚠️ Post ${postId} sem authorProfileId/authorUid, pulando...`,
        );
        continue;
      }

      // Verificar se já notificamos este post (dedup)
      // Usamos um ID fixo baseado no postId para evitar múltiplas notificações
      const notificationId = `postExpiring_${postId}`;
      const existingNotification = await db
        .collection("notifications")
        .doc(notificationId)
        .get();

      if (existingNotification.exists) {
        notificationsSkipped++;
        continue;
      }

      // Calcular horas restantes
      const expiresAt = post.expiresAt?.toDate?.() || new Date();
      const hoursRemaining = Math.max(
        0,
        Math.round((expiresAt.getTime() - Date.now()) / (1000 * 60 * 60)),
      );

      const postCity = post.city || "sua cidade";
      const postType = post.type || "post";

      // Mensagem personalizada
      const expiringBody =
        postType === "sales"
          ? `Seu anúncio em ${postCity} expira em ${hoursRemaining}h. Deseja renovar?`
          : postType === "hiring"
            ? `Sua vaga em ${postCity} expira em ${hoursRemaining}h. Deseja renovar?`
            : `Seu post em ${postCity} expira em ${hoursRemaining}h. Deseja renovar?`;

      // Criar notificação com ID fixo (dedup)
      await db
        .collection("notifications")
        .doc(notificationId)
        .set({
          recipientProfileId: authorProfileId,
          recipientUid: authorUid,
          profileUid: authorProfileId, // Legacy
          type: "postExpiring",
          priority: "high",
          title: "Post expirando!",
          body: expiringBody,
          actionType: "renewPost",
          actionData: {
            postId: postId,
            postType: postType,
            city: postCity,
            hoursRemaining: hoursRemaining,
          },
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          read: false,
          expiresAt: admin.firestore.Timestamp.fromDate(
            new Date(Date.now() + 3 * 24 * 60 * 60 * 1000), // Notificação expira em 3 dias
          ),
        });

      // Enviar push notification
      await sendPushToProfile(
        authorProfileId,
        authorUid,
        {
          title: "⏰ Post expirando!",
          body: expiringBody,
        },
        {
          type: "postExpiring",
          postId: postId,
          postType: postType,
        },
      );

      notificationsCreated++;
      console.log(
        `⏰ [POST_EXPIRING] Notificado: post ${postId} (${hoursRemaining}h restantes)`,
      );
    }

    console.log(
      `⏰ [POST_EXPIRING] Concluído: ${notificationsCreated} notificações criadas, ${notificationsSkipped} puladas (já notificadas)`,
    );

    return null;
  });

/**
 * Notifica interessados quando um post é atualizado
 *
 * Trigger: onUpdate em posts/{postId}
 *
 * Lógica:
 * 1. Verifica se o post foi realmente atualizado (não apenas metadata)
 * 2. Busca todos os interessados (interests) no post
 * 3. Cria notificação para cada interessado
 * 4. Envia push notifications
 *
 * Campos monitorados: content, title, images, location, city, type
 */
exports.notifyPostUpdated = functions
  .runWith({
    memory: "256MB",
    timeoutSeconds: 60,
  })
  .region("southamerica-east1")
  .firestore.document("posts/{postId}")
  .onUpdate(async (change, context) => {
    const postId = context.params.postId;
    const before = change.before.data();
    const after = change.after.data();

    // Verificar se houve mudança significativa no conteúdo
    const significantFields = [
      "content",
      "title",
      "images",
      "location",
      "city",
      "type",
    ];
    const hasSignificantChange = significantFields.some((field) => {
      const beforeVal = JSON.stringify(before[field] || "");
      const afterVal = JSON.stringify(after[field] || "");
      return beforeVal !== afterVal;
    });

    if (!hasSignificantChange) {
      console.log(
        `📝 [POST_UPDATED] Post ${postId} atualizado sem mudanças significativas, ignorando`,
      );
      return null;
    }

    const authorProfileId = (after.authorProfileId || "").trim();
    const authorName = after.authorName || "O autor";
    const authorUsername = after.authorUsername || "";
    const postCity = after.city || "";
    const postType = after.type || "post";

    if (!authorProfileId) {
      console.log(`⚠️ Post ${postId} sem authorProfileId, pulando...`);
      return null;
    }

    console.log(
      `📝 [POST_UPDATED] Post ${postId} atualizado, notificando interessados...`,
    );

    // Buscar todos os interessados no post
    const interestsSnap = await db
      .collection("interests")
      .where("postId", "==", postId)
      .get();

    if (interestsSnap.empty) {
      console.log(`📝 [POST_UPDATED] Nenhum interessado no post ${postId}`);
      return null;
    }

    console.log(
      `📝 [POST_UPDATED] Encontrados ${interestsSnap.size} interessados no post`,
    );

    const displayAuthor = authorUsername || authorName;
    const updateBody =
      postType === "sales"
        ? `@${displayAuthor} • atualizou o anúncio que você salvou`
        : `@${displayAuthor} • atualizou o post que você curtiu`;

    let notificationsCreated = 0;
    let notificationsSkipped = 0;

    for (const interestDoc of interestsSnap.docs) {
      const interest = interestDoc.data();
      const interestedProfileId = (interest.interestedProfileId || "").trim();

      if (!interestedProfileId) continue;

      // Buscar UID do interessado
      const interestedProfile = await db
        .collection("profiles")
        .doc(interestedProfileId)
        .get();

      if (!interestedProfile.exists) {
        notificationsSkipped++;
        continue;
      }

      const interestedProfileData = interestedProfile.data();
      const recipientUid = interestedProfileData.uid;

      if (!recipientUid) {
        notificationsSkipped++;
        continue;
      }

      // Verificar bloqueio entre autor e interessado
      const isBlocked = await isBlockedByProfile(
        authorProfileId,
        interestedProfileId,
        `postUpdated:${postId}`,
      );

      if (isBlocked) {
        console.log(
          `🚫 [POST_UPDATED] Bloqueio detectado, não notificando ${interestedProfileId}`,
        );
        notificationsSkipped++;
        continue;
      }

      // Verificar se já existe notificação recente de update para este post/interessado
      const recentNotification = await db
        .collection("notifications")
        .where("recipientProfileId", "==", interestedProfileId)
        .where("type", "==", "postUpdated")
        .where("actionData.postId", "==", postId)
        .where("read", "==", false)
        .limit(1)
        .get();

      if (!recentNotification.empty) {
        // Atualizar notificação existente ao invés de criar nova
        await recentNotification.docs[0].ref.update({
          body: updateBody,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(
          `📝 [POST_UPDATED] Notificação atualizada para ${interestedProfileId}`,
        );
        notificationsCreated++;
        continue;
      }

      // Criar nova notificação
      await db.collection("notifications").add({
        recipientProfileId: interestedProfileId,
        recipientUid: recipientUid,
        profileUid: interestedProfileId, // Legacy
        type: "postUpdated",
        priority: "medium",
        title: "Post atualizado!",
        body: updateBody,
        actionType: "viewPost",
        actionData: {
          postId: postId,
          postType: postType,
          city: postCity,
          authorProfileId: authorProfileId,
          authorName: authorName,
        },
        senderName: authorName,
        senderUsername: authorUsername,
        senderPhoto: after.authorPhotoUrl || null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
        expiresAt: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 dias
        ),
      });

      // Enviar push notification
      await sendPushToProfile(
        interestedProfileId,
        recipientUid,
        {
          title: "Post atualizado!",
          body: updateBody,
        },
        {
          type: "postUpdated",
          postId: postId,
          authorProfileId: authorProfileId,
        },
      );

      notificationsCreated++;
    }

    console.log(
      `📝 [POST_UPDATED] Concluído: ${notificationsCreated} notificações, ${notificationsSkipped} puladas`,
    );

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
    let totalConnectionRequestsDeleted = 0;
    let totalConnectionsDeleted = 0;
    let totalConnectionSuggestionDocsDeleted = 0;
    let totalConnectionStatsDocsDeleted = 0;

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
          `📝 Deleted ${postsSnapshot.size} posts (total: ${totalPostsDeleted})`,
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
              `⚠️ Could not delete image ${imageUrl}: ${storageError.message}`,
            );
          }
        }

        // Verificar se há mais posts
        postsSnapshot = await postsQuery.get();
      }

      console.log(
        `✅ Posts cleanup complete: ${totalPostsDeleted} posts, ${totalImagesDeleted} images`,
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
          `🔔 Deleted ${notifSnapshot.size} recipient notifications (total: ${totalNotificationsDeleted})`,
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
          `🔔 Deleted ${notifSnapshot.size} sender notifications (total: ${totalNotificationsDeleted})`,
        );
        notifSnapshot = await senderNotificationsQuery.get();
      }

      console.log(
        `✅ Notifications cleanup complete: ${totalNotificationsDeleted} notifications`,
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
          `💚 Deleted ${interestsSnapshot.size} interests (total: ${totalInterestsDeleted})`,
        );
        interestsSnapshot = await interestsQuery.get();
      }

      console.log(
        `✅ Interests cleanup complete: ${totalInterestsDeleted} interests`,
      );

      // ========================================
      // 4. LIMPAR GRAFO SOCIAL DE CONEXOES
      // ========================================
      console.log(
        `🤝 Cleaning up connections graph for profile ${profileId}...`,
      );

      const connectionCleanup =
        await cleanupConnectionArtifactsForDeletedProfile(
          profileId,
          `profileDelete:${profileId}`,
        );
      totalConnectionRequestsDeleted = connectionCleanup.deletedRequests;
      totalConnectionsDeleted = connectionCleanup.deletedConnections;
      totalConnectionSuggestionDocsDeleted =
        connectionCleanup.deletedSuggestionDocs;
      totalConnectionStatsDocsDeleted = connectionCleanup.deletedStatsDocs;

      console.log(
        `✅ Connections cleanup complete: ${totalConnectionRequestsDeleted} requests, ${totalConnectionsDeleted} connections`,
      );

      // ========================================
      // 5. LIMPAR FCM TOKENS (subcoleção)
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
        `   🤝 Convites deletados: ${totalConnectionRequestsDeleted}`,
      );
      console.log(`   🤝 Conexões deletadas: ${totalConnectionsDeleted}`);
      console.log(
        `   💡 Docs de sugestões deletados: ${totalConnectionSuggestionDocsDeleted}`,
      );
      console.log(
        `   📊 Docs de stats deletados: ${totalConnectionStatsDocsDeleted}`,
      );
      console.log(
        `   🔔 FCM tokens deletados: ${
          tokensSnapshot ? tokensSnapshot.size : 0
        }`,
      );

      return null;
    } catch (error) {
      console.error(`❌ Error during profile cleanup: ${error}`);
      console.error(error.stack);

      // Não lançar exceção - cleanup parcial é melhor que nada
      return null;
    }
  });

/**
 * Notifica administradores quando um novo report é criado.
 *
 * Lógica:
 * 1. Obtém dados do report (reason, targetId, etc.)
 * 2. Busca dados adicionais do conteúdo reportado (post ou perfil)
 * 3. Cria notificação no Firestore para admins
 * 4. Envia email via SendGrid (se configurado) ou log para monitoramento
 *
 * Campos do report esperados:
 * - reportedPostId ou reportedProfileId (string)
 * - reporterUid (string)
 * - reason (string)
 * - description (string, opcional)
 * - timestamp (Timestamp)
 * - status (string: "pending")
 * - reportedBy (array de UIDs)
 */
exports.onReportCreated = functions
  .runWith({
    memory: "256MB",
    timeoutSeconds: 30,
  })
  .region("southamerica-east1")
  .firestore.document("reports/{reportId}")
  .onCreate(async (snap, context) => {
    const report = snap.data();
    const reportId = context.params.reportId;

    console.log(`📢 Novo report recebido: ${reportId}`);
    console.log(`   Motivo: ${report.reason}`);
    console.log(`   Reporter: ${report.reporterUid}`);

    try {
      // Determinar tipo de conteúdo reportado
      const isPostReport = !!report.reportedPostId;
      const targetId = report.reportedPostId || report.reportedProfileId;
      const targetType = isPostReport ? "post" : "perfil";

      // Buscar informações adicionais sobre o conteúdo reportado
      let targetInfo = {};
      if (isPostReport) {
        const postDoc = await db.collection("posts").doc(targetId).get();
        if (postDoc.exists) {
          const postData = postDoc.data();
          targetInfo = {
            authorName: postData.authorName || "Desconhecido",
            authorProfileId: postData.authorProfileId,
            content: postData.content?.substring(0, 100) || "",
            city: postData.city || "",
          };
        }
      } else {
        const profileDoc = await db.collection("profiles").doc(targetId).get();
        if (profileDoc.exists) {
          const profileData = profileDoc.data();
          targetInfo = {
            name: profileData.name || "Desconhecido",
            username: profileData.username || "",
            city: profileData.city || "",
          };
        }
      }

      // Contar reports anteriores para este conteúdo (para priorização)
      const reportCountField = isPostReport
        ? "reportedPostId"
        : "reportedProfileId";
      const previousReports = await db
        .collection("reports")
        .where(reportCountField, "==", targetId)
        .where("status", "==", "pending")
        .count()
        .get();

      const totalReports = previousReports.data().count || 1;

      // Criar notificação para dashboard admin
      await db.collection("adminNotifications").add({
        type: "new_report",
        reportId: reportId,
        targetType: targetType,
        targetId: targetId,
        targetInfo: targetInfo,
        reason: report.reason,
        description: report.description || null,
        totalReports: totalReports,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
        priority: totalReports >= 3 ? "high" : "normal", // Prioridade alta se 3+ reports
      });

      console.log(`✅ Admin notification criada para report ${reportId}`);
      console.log(`   Tipo: ${targetType}`);
      console.log(`   Target: ${targetId}`);
      console.log(`   Total reports para este ${targetType}: ${totalReports}`);

      // ✅ ENVIAR EMAIL PARA TODA DENÚNCIA
      // Enviar email via SendGrid para contato@wegig.com.br
      try {
        const sgMail = require("@sendgrid/mail");
        const sendgridKey = process.env.SENDGRID_API_KEY;

        if (sendgridKey) {
          sgMail.setApiKey(sendgridKey);

          // Determinar prioridade e assunto baseado no número de denúncias
          let priority = "normal";
          let subjectPrefix = "📢 Nova Denúncia";
          if (totalReports >= 5) {
            priority = "urgente";
            subjectPrefix = "🚨 URGENTE - Múltiplas Denúncias";
          } else if (totalReports >= 3) {
            priority = "alta";
            subjectPrefix = "⚠️ ALERTA - Denúncias Recorrentes";
          }

          // Buscar informações do denunciante
          let reporterInfo = { name: "Desconhecido", email: "" };
          try {
            const reporterProfiles = await db
              .collection("profiles")
              .where("uid", "==", report.reporterUid)
              .limit(1)
              .get();
            if (!reporterProfiles.empty) {
              const reporterData = reporterProfiles.docs[0].data();
              reporterInfo = {
                name: reporterData.name || "Desconhecido",
                username: reporterData.username || "",
                profileId: reporterProfiles.docs[0].id,
              };
            }
          } catch (e) {
            console.warn("Não foi possível buscar dados do denunciante:", e);
          }

          const emailData = {
            to: "contato@wegig.com.br",
            from: {
              email: "noreply@wegig.com.br",
              name: "WeGig - Sistema de Denúncias",
            },
            subject: `${subjectPrefix} - ${
              targetType === "post" ? "Post" : "Perfil"
            } #${targetId.substring(0, 8)}`,
            html: `
              <!DOCTYPE html>
              <html>
              <head>
                <meta charset="utf-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
              </head>
              <body style="font-family: 'Segoe UI', Arial, sans-serif; max-width: 650px; margin: 0 auto; background: #f5f5f5; padding: 20px;">
                <div style="background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
                  <!-- Header -->
                  <div style="background: linear-gradient(135deg, #E47911 0%, #c96a0f 100%); padding: 25px; text-align: center;">
                    <h1 style="color: white; margin: 0; font-size: 24px;">
                      ${
                        priority === "urgente"
                          ? "🚨"
                          : priority === "alta"
                            ? "⚠️"
                            : "📢"
                      } 
                      Nova Denúncia Recebida
                    </h1>
                    <p style="color: rgba(255,255,255,0.9); margin: 10px 0 0;">
                      ${new Date().toLocaleString("pt-BR", {
                        timeZone: "America/Sao_Paulo",
                      })}
                    </p>
                  </div>
                  
                  <!-- Prioridade Badge -->
                  ${
                    totalReports > 1
                      ? `
                  <div style="background: ${
                    priority === "urgente"
                      ? "#dc3545"
                      : priority === "alta"
                        ? "#fd7e14"
                        : "#17a2b8"
                  }; 
                       color: white; text-align: center; padding: 10px; font-weight: bold;">
                    ${totalReports} DENÚNCIA(S) PENDENTE(S) PARA ESTE ${targetType.toUpperCase()}
                  </div>
                  `
                      : ""
                  }
                  
                  <!-- Conteúdo -->
                  <div style="padding: 25px;">
                    <!-- Info do Report -->
                    <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 20px; border-left: 4px solid #E47911;">
                      <h3 style="margin: 0 0 15px; color: #333;">📋 Detalhes da Denúncia</h3>
                      <table style="width: 100%; border-collapse: collapse;">
                        <tr>
                          <td style="padding: 8px 0; color: #666; width: 140px;"><strong>ID do Report:</strong></td>
                          <td style="padding: 8px 0; color: #333;">${reportId}</td>
                        </tr>
                        <tr>
                          <td style="padding: 8px 0; color: #666;"><strong>Tipo:</strong></td>
                          <td style="padding: 8px 0; color: #333;">${
                            targetType === "post" ? "📝 Post" : "👤 Perfil"
                          }</td>
                        </tr>
                        <tr>
                          <td style="padding: 8px 0; color: #666;"><strong>ID do ${targetType}:</strong></td>
                          <td style="padding: 8px 0; color: #333; font-family: monospace; background: #eee; padding: 4px 8px; border-radius: 4px;">${targetId}</td>
                        </tr>
                        <tr>
                          <td style="padding: 8px 0; color: #666;"><strong>Motivo:</strong></td>
                          <td style="padding: 8px 0; color: #333; font-weight: bold;">${
                            report.reason
                          }</td>
                        </tr>
                        ${
                          report.description
                            ? `
                        <tr>
                          <td style="padding: 8px 0; color: #666; vertical-align: top;"><strong>Descrição:</strong></td>
                          <td style="padding: 8px 0; color: #333;">${report.description}</td>
                        </tr>
                        `
                            : ""
                        }
                      </table>
                    </div>
                    
                    <!-- Info do Conteúdo Denunciado -->
                    <div style="background: #fff3e6; padding: 20px; border-radius: 8px; margin-bottom: 20px; border-left: 4px solid #fd7e14;">
                      <h3 style="margin: 0 0 15px; color: #333;">
                        ${
                          targetType === "post"
                            ? "📝 Informações do Post"
                            : "👤 Informações do Perfil"
                        }
                      </h3>
                      <table style="width: 100%; border-collapse: collapse;">
                        ${
                          targetType === "post"
                            ? `
                        <tr>
                          <td style="padding: 8px 0; color: #666; width: 140px;"><strong>Autor:</strong></td>
                          <td style="padding: 8px 0; color: #333;">${
                            targetInfo.authorName || "N/A"
                          }</td>
                        </tr>
                        <tr>
                          <td style="padding: 8px 0; color: #666;"><strong>ID do Perfil:</strong></td>
                          <td style="padding: 8px 0; color: #333; font-family: monospace;">${
                            targetInfo.authorProfileId || "N/A"
                          }</td>
                        </tr>
                        <tr>
                          <td style="padding: 8px 0; color: #666;"><strong>Cidade:</strong></td>
                          <td style="padding: 8px 0; color: #333;">${
                            targetInfo.city || "N/A"
                          }</td>
                        </tr>
                        ${
                          targetInfo.content
                            ? `
                        <tr>
                          <td style="padding: 8px 0; color: #666; vertical-align: top;"><strong>Conteúdo:</strong></td>
                          <td style="padding: 8px 0; color: #333;">"${
                            targetInfo.content
                          }${
                            targetInfo.content.length >= 100 ? "..." : ""
                          }"</td>
                        </tr>
                        `
                            : ""
                        }
                        `
                            : `
                        <tr>
                          <td style="padding: 8px 0; color: #666; width: 140px;"><strong>Nome:</strong></td>
                          <td style="padding: 8px 0; color: #333;">${
                            targetInfo.name || "N/A"
                          }</td>
                        </tr>
                        <tr>
                          <td style="padding: 8px 0; color: #666;"><strong>Username:</strong></td>
                          <td style="padding: 8px 0; color: #333;">@${
                            targetInfo.username || "N/A"
                          }</td>
                        </tr>
                        <tr>
                          <td style="padding: 8px 0; color: #666;"><strong>Cidade:</strong></td>
                          <td style="padding: 8px 0; color: #333;">${
                            targetInfo.city || "N/A"
                          }</td>
                        </tr>
                        `
                        }
                      </table>
                    </div>
                    
                    <!-- Info do Denunciante -->
                    <div style="background: #e8f4fd; padding: 20px; border-radius: 8px; margin-bottom: 20px; border-left: 4px solid #007EB9;">
                      <h3 style="margin: 0 0 15px; color: #333;">🔍 Quem Denunciou</h3>
                      <table style="width: 100%; border-collapse: collapse;">
                        <tr>
                          <td style="padding: 8px 0; color: #666; width: 140px;"><strong>Nome:</strong></td>
                          <td style="padding: 8px 0; color: #333;">${
                            reporterInfo.name
                          }</td>
                        </tr>
                        ${
                          reporterInfo.username
                            ? `
                        <tr>
                          <td style="padding: 8px 0; color: #666;"><strong>Username:</strong></td>
                          <td style="padding: 8px 0; color: #333;">@${reporterInfo.username}</td>
                        </tr>
                        `
                            : ""
                        }
                        <tr>
                          <td style="padding: 8px 0; color: #666;"><strong>UID Firebase:</strong></td>
                          <td style="padding: 8px 0; color: #333; font-family: monospace; font-size: 12px;">${
                            report.reporterUid
                          }</td>
                        </tr>
                        ${
                          reporterInfo.profileId
                            ? `
                        <tr>
                          <td style="padding: 8px 0; color: #666;"><strong>Profile ID:</strong></td>
                          <td style="padding: 8px 0; color: #333; font-family: monospace; font-size: 12px;">${reporterInfo.profileId}</td>
                        </tr>
                        `
                            : ""
                        }
                      </table>
                    </div>
                    
                    <!-- Ações -->
                    <div style="background: #d4edda; border: 1px solid #c3e6cb; padding: 20px; border-radius: 8px; text-align: center;">
                      <p style="margin: 0 0 15px; color: #155724; font-weight: bold;">
                        📌 Ação Necessária
                      </p>
                      <p style="margin: 0; color: #155724;">
                        Acesse o painel administrativo para revisar esta denúncia e tomar as medidas apropriadas.
                      </p>
                    </div>
                  </div>
                  
                  <!-- Footer -->
                  <div style="background: #37475A; padding: 20px; text-align: center;">
                    <p style="color: rgba(255,255,255,0.7); margin: 0; font-size: 12px;">
                      Esta é uma notificação automática do sistema WeGig.<br>
                      Não responda a este email.
                    </p>
                  </div>
                </div>
              </body>
              </html>
            `,
          };

          await sgMail.send(emailData);
          console.log(
            `📧 Email de denúncia enviado para contato@wegig.com.br - Report: ${reportId}`,
          );
        } else {
          console.warn(
            "⚠️ SendGrid key não configurada - pulando envio de email",
          );
          console.log(
            "   Para configurar: defina SENDGRID_API_KEY no .env das functions",
          );
        }
      } catch (emailError) {
        console.error("❌ Erro ao enviar email via SendGrid:", emailError);
        // Não falhar a função por erro de email
      }

      // Log adicional para monitoramento de denúncias recorrentes
      if (totalReports >= 3) {
        console.log(
          `⚠️ ATENÇÃO: ${targetType} ${targetId} tem ${totalReports} denúncias pendentes!`,
        );
      }

      return null;
    } catch (error) {
      console.error(`❌ Erro ao processar report: ${error}`);
      console.error(error.stack);
      return null;
    }
  });

/**
 * ============================================
 * ON USER DELETE - Cleanup após exclusão de conta
 * ============================================
 *
 * Trigger: Quando um usuário é deletado do Firebase Authentication
 *
 * Esta função é acionada automaticamente quando user.delete() é chamado
 * no app Flutter. Ela limpa todos os dados associados ao usuário:
 * - Documento users/{uid}
 * - Todos os perfis do usuário (que por sua vez acionam onProfileDelete)
 * - Conversas órfãs
 * - Interesses órfãos
 * - Rate limits
 */
exports.onUserDelete = functions
  .runWith({
    memory: "512MB",
    timeoutSeconds: 540,
  })
  .region("southamerica-east1")
  .auth.user()
  .onDelete(async (user) => {
    const uid = user.uid;
    const email = user.email || "unknown";

    console.log(`🗑️ User deleted from Firebase Auth: ${uid} (${email})`);
    console.log(`🧹 Starting cleanup for user ${uid}...`);

    let totalProfilesDeleted = 0;
    let totalConversationsDeleted = 0;
    let totalInterestsDeleted = 0;

    try {
      // 1. DELETAR DOCUMENTO users/{uid}
      console.log(`📄 Deleting user document for ${uid}...`);
      try {
        await db.collection("users").doc(uid).delete();
        console.log(`✅ User document deleted`);
      } catch (userDocError) {
        console.warn(
          `⚠️ Could not delete user document: ${userDocError.message}`,
        );
      }

      // 2. DELETAR TODOS OS PERFIS DO USUÁRIO
      console.log(`👤 Finding and deleting profiles for user ${uid}...`);

      const profilesQuery = db
        .collection("profiles")
        .where("uid", "==", uid)
        .limit(100);
      let profilesSnapshot = await profilesQuery.get();

      while (!profilesSnapshot.empty) {
        const batch = db.batch();
        profilesSnapshot.docs.forEach((doc) => {
          batch.delete(doc.ref);
        });
        await batch.commit();
        totalProfilesDeleted += profilesSnapshot.size;
        console.log(
          `👤 Deleted ${profilesSnapshot.size} profiles (total: ${totalProfilesDeleted})`,
        );
        profilesSnapshot = await profilesQuery.get();
      }

      console.log(
        `✅ Profile cleanup complete: ${totalProfilesDeleted} profiles deleted`,
      );

      // 3. LIMPAR CONVERSAS ÓRFÃS
      console.log(`💬 Cleaning up conversations for user ${uid}...`);

      const conversationsQuery = db
        .collection("conversations")
        .where("participants", "array-contains", uid)
        .limit(500);
      let conversationsSnapshot = await conversationsQuery.get();

      while (!conversationsSnapshot.empty) {
        const batch = db.batch();
        for (const doc of conversationsSnapshot.docs) {
          const messagesSnapshot = await doc.ref
            .collection("messages")
            .limit(500)
            .get();
          messagesSnapshot.docs.forEach((msgDoc) => {
            batch.delete(msgDoc.ref);
          });
          batch.delete(doc.ref);
        }
        await batch.commit();
        totalConversationsDeleted += conversationsSnapshot.size;
        console.log(
          `💬 Deleted ${conversationsSnapshot.size} conversations (total: ${totalConversationsDeleted})`,
        );
        conversationsSnapshot = await conversationsQuery.get();
      }

      console.log(
        `✅ Conversation cleanup complete: ${totalConversationsDeleted} conversations deleted`,
      );

      // 4. LIMPAR INTERESSES CRIADOS PELO USUÁRIO
      console.log(`❤️ Cleaning up interests created by user ${uid}...`);

      const interestsQuery = db
        .collection("interests")
        .where("interestedUid", "==", uid)
        .limit(500);
      let interestsSnapshot = await interestsQuery.get();

      while (!interestsSnapshot.empty) {
        const batch = db.batch();
        interestsSnapshot.docs.forEach((doc) => {
          batch.delete(doc.ref);
        });
        await batch.commit();
        totalInterestsDeleted += interestsSnapshot.size;
        console.log(
          `❤️ Deleted ${interestsSnapshot.size} interests (total: ${totalInterestsDeleted})`,
        );
        interestsSnapshot = await interestsQuery.get();
      }

      console.log(
        `✅ Interest cleanup complete: ${totalInterestsDeleted} interests deleted`,
      );

      // 5. LIMPAR RATE LIMITS
      console.log(`⏱️ Cleaning up rate limits for user ${uid}...`);

      const rateLimitsQuery = db
        .collection("rateLimits")
        .where(admin.firestore.FieldPath.documentId(), ">=", `${uid}_`)
        .where(admin.firestore.FieldPath.documentId(), "<", `${uid}_~`)
        .limit(100);

      const rateLimitsSnapshot = await rateLimitsQuery.get();
      if (!rateLimitsSnapshot.empty) {
        const batch = db.batch();
        rateLimitsSnapshot.docs.forEach((doc) => {
          batch.delete(doc.ref);
        });
        await batch.commit();
        console.log(`⏱️ Deleted ${rateLimitsSnapshot.size} rate limit records`);
      }

      console.log(`✅ Rate limit cleanup complete`);

      // RESUMO FINAL
      console.log(`\n🎉 User cleanup complete for ${uid}:`);
      console.log(`   - Profiles deleted: ${totalProfilesDeleted}`);
      console.log(`   - Conversations deleted: ${totalConversationsDeleted}`);
      console.log(`   - Interests deleted: ${totalInterestsDeleted}`);
      console.log(
        `   - Note: Posts and storage were cleaned by onProfileDelete triggers`,
      );

      return null;
    } catch (error) {
      console.error(`❌ Error cleaning up user ${uid}: ${error}`);
      console.error(error.stack);
      return null;
    }
  });

function normalizeProfileId(value) {
  return typeof value === "string" ? value.trim() : "";
}

function uniqueProfileIds(values) {
  return [...new Set(values.map(normalizeProfileId).filter(Boolean))];
}

function buildConnectionId(firstProfileId, secondProfileId) {
  return uniqueProfileIds([firstProfileId, secondProfileId]).sort().join("__");
}

const CONNECTION_REQUEST_DAILY_LIMIT = 50;
const CONNECTION_REQUEST_COOLDOWN_MS = 3 * 24 * 60 * 60 * 1000;

async function rebuildConnectionStatsForProfile(profileId) {
  const normalizedProfileId = normalizeProfileId(profileId);
  if (!normalizedProfileId) {
    return;
  }

  const [connectionsSnapshot, pendingReceivedSnapshot, pendingSentSnapshot] =
    await Promise.all([
      db
        .collection("connections")
        .where("profileIds", "array-contains", normalizedProfileId)
        .get(),
      db
        .collection("connectionRequests")
        .where("recipientProfileId", "==", normalizedProfileId)
        .where("status", "==", "pending")
        .get(),
      db
        .collection("connectionRequests")
        .where("requesterProfileId", "==", normalizedProfileId)
        .where("status", "==", "pending")
        .get(),
    ]);

  await db.collection("connectionStats").doc(normalizedProfileId).set(
    {
      profileId: normalizedProfileId,
      totalConnections: connectionsSnapshot.size,
      pendingReceived: pendingReceivedSnapshot.size,
      pendingSent: pendingSentSnapshot.size,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

async function rebuildConnectionStatsForProfiles(profileIds) {
  const normalizedProfileIds = uniqueProfileIds(profileIds);
  await Promise.all(
    normalizedProfileIds.map((profileId) =>
      rebuildConnectionStatsForProfile(profileId),
    ),
  );
}

async function removeProfileFromSuggestionsCache(
  ownerProfileId,
  removedProfileId,
) {
  const normalizedOwnerProfileId = normalizeProfileId(ownerProfileId);
  const normalizedRemovedProfileId = normalizeProfileId(removedProfileId);
  if (!normalizedOwnerProfileId || !normalizedRemovedProfileId) {
    return;
  }

  const suggestionRef = db
    .collection("connectionSuggestions")
    .doc(normalizedOwnerProfileId);
  const suggestionSnapshot = await suggestionRef.get();
  if (!suggestionSnapshot.exists) {
    return;
  }

  const data = suggestionSnapshot.data() || {};
  const suggestions = Array.isArray(data.suggestions) ? data.suggestions : [];
  const filteredSuggestions = suggestions.filter((entry) => {
    if (!entry || typeof entry !== "object") {
      return false;
    }

    return (
      normalizeProfileId(entry.candidateProfileId) !==
      normalizedRemovedProfileId
    );
  });

  if (filteredSuggestions.length === suggestions.length) {
    return;
  }

  await suggestionRef.set(
    {
      suggestions: filteredSuggestions,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

async function removeConnectionArtifactsBetweenProfiles(
  firstProfileId,
  secondProfileId,
  context = "",
) {
  const profileId1 = normalizeProfileId(firstProfileId);
  const profileId2 = normalizeProfileId(secondProfileId);
  if (!profileId1 || !profileId2 || profileId1 === profileId2) {
    return;
  }

  const logTag = context
    ? `[CONNECTION_GUARD][${context}]`
    : "[CONNECTION_GUARD]";
  const batch = db.batch();

  batch.delete(
    db.collection("connectionRequests").doc(`${profileId1}_${profileId2}`),
  );
  batch.delete(
    db.collection("connectionRequests").doc(`${profileId2}_${profileId1}`),
  );
  batch.delete(
    db.collection("connections").doc(buildConnectionId(profileId1, profileId2)),
  );

  await batch.commit();

  await Promise.all([
    removeProfileFromSuggestionsCache(profileId1, profileId2),
    removeProfileFromSuggestionsCache(profileId2, profileId1),
    rebuildConnectionStatsForProfiles([profileId1, profileId2]),
  ]);

  console.log(
    `${logTag} 🧹 artefatos de conexão reconciliados para ${profileId1} <-> ${profileId2}`,
  );
}

async function cleanupConnectionArtifactsForDeletedProfile(
  profileId,
  context = "",
) {
  const normalizedProfileId = normalizeProfileId(profileId);
  if (!normalizedProfileId) {
    return {
      deletedRequests: 0,
      deletedConnections: 0,
      deletedSuggestionDocs: 0,
      deletedStatsDocs: 0,
      affectedProfileIds: [],
    };
  }

  const logTag = context
    ? `[PROFILE_CONNECTION_CLEANUP][${context}]`
    : "[PROFILE_CONNECTION_CLEANUP]";
  const affectedProfileIds = new Set();
  let deletedRequests = 0;
  let deletedConnections = 0;

  const requesterQuery = db
    .collection("connectionRequests")
    .where("requesterProfileId", "==", normalizedProfileId)
    .limit(500);
  let requesterSnapshot = await requesterQuery.get();
  while (!requesterSnapshot.empty) {
    const batch = db.batch();
    requesterSnapshot.docs.forEach((doc) => {
      const data = doc.data() || {};
      const otherProfileId = normalizeProfileId(data.recipientProfileId);
      if (otherProfileId) {
        affectedProfileIds.add(otherProfileId);
      }
      batch.delete(doc.ref);
    });
    await batch.commit();
    deletedRequests += requesterSnapshot.size;
    requesterSnapshot = await requesterQuery.get();
  }

  const recipientQuery = db
    .collection("connectionRequests")
    .where("recipientProfileId", "==", normalizedProfileId)
    .limit(500);
  let recipientSnapshot = await recipientQuery.get();
  while (!recipientSnapshot.empty) {
    const batch = db.batch();
    recipientSnapshot.docs.forEach((doc) => {
      const data = doc.data() || {};
      const otherProfileId = normalizeProfileId(data.requesterProfileId);
      if (otherProfileId) {
        affectedProfileIds.add(otherProfileId);
      }
      batch.delete(doc.ref);
    });
    await batch.commit();
    deletedRequests += recipientSnapshot.size;
    recipientSnapshot = await recipientQuery.get();
  }

  const connectionsQuery = db
    .collection("connections")
    .where("profileIds", "array-contains", normalizedProfileId)
    .limit(500);
  let connectionsSnapshot = await connectionsQuery.get();
  while (!connectionsSnapshot.empty) {
    const batch = db.batch();
    connectionsSnapshot.docs.forEach((doc) => {
      const data = doc.data() || {};
      const profileIds = Array.isArray(data.profileIds) ? data.profileIds : [];
      profileIds.forEach((candidateProfileId) => {
        const normalizedCandidateProfileId =
          normalizeProfileId(candidateProfileId);
        if (
          normalizedCandidateProfileId &&
          normalizedCandidateProfileId !== normalizedProfileId
        ) {
          affectedProfileIds.add(normalizedCandidateProfileId);
        }
      });
      batch.delete(doc.ref);
    });
    await batch.commit();
    deletedConnections += connectionsSnapshot.size;
    connectionsSnapshot = await connectionsQuery.get();
  }

  const suggestionsRef = db
    .collection("connectionSuggestions")
    .doc(normalizedProfileId);
  const statsRef = db.collection("connectionStats").doc(normalizedProfileId);
  const [suggestionsSnapshot, statsSnapshot] = await Promise.all([
    suggestionsRef.get(),
    statsRef.get(),
  ]);

  await Promise.all([
    suggestionsSnapshot.exists ? suggestionsRef.delete() : Promise.resolve(),
    statsSnapshot.exists ? statsRef.delete() : Promise.resolve(),
    ...Array.from(affectedProfileIds).map((otherProfileId) =>
      removeProfileFromSuggestionsCache(otherProfileId, normalizedProfileId),
    ),
  ]);

  if (affectedProfileIds.size > 0) {
    await rebuildConnectionStatsForProfiles(Array.from(affectedProfileIds));
  }

  console.log(
    `${logTag} 🧹 cleanup de conexões concluído para ${normalizedProfileId}: requests=${deletedRequests}, connections=${deletedConnections}, affectedProfiles=${affectedProfileIds.size}`,
  );

  return {
    deletedRequests,
    deletedConnections,
    deletedSuggestionDocs: suggestionsSnapshot.exists ? 1 : 0,
    deletedStatsDocs: statsSnapshot.exists ? 1 : 0,
    affectedProfileIds: Array.from(affectedProfileIds),
  };
}

async function ensureConnectionDocumentFromRequest(requestId, requestData) {
  const requesterProfileId = normalizeProfileId(requestData.requesterProfileId);
  const recipientProfileId = normalizeProfileId(requestData.recipientProfileId);
  if (!requesterProfileId || !recipientProfileId) {
    return;
  }

  const connectionId = buildConnectionId(
    requesterProfileId,
    recipientProfileId,
  );
  const connectionRef = db.collection("connections").doc(connectionId);
  const connectionSnapshot = await connectionRef.get();
  if (connectionSnapshot.exists) {
    return;
  }

  await connectionRef.set({
    profileIds: [requesterProfileId, recipientProfileId].sort(),
    profileUids: [
      requestData.requesterUid || "",
      requestData.recipientUid || "",
    ],
    profileNames: {
      [requesterProfileId]: requestData.requesterName || "",
      [recipientProfileId]: requestData.recipientName || "",
    },
    profilePhotoUrls: {
      [requesterProfileId]: requestData.requesterPhotoUrl || "",
      [recipientProfileId]: requestData.recipientPhotoUrl || "",
    },
    initiatedByProfileId: requesterProfileId,
    requestId,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

function extractConnectionRequestActionDate(requestData) {
  const rawValue =
    requestData.respondedAt || requestData.updatedAt || requestData.createdAt;
  if (!rawValue) return null;
  if (typeof rawValue.toDate === "function") return rawValue.toDate();
  if (rawValue instanceof Date) return rawValue;
  return null;
}

async function hasRecentConnectionCooldown(requestData) {
  const status = (requestData.status || "").trim();
  if (!status || status === "pending") {
    return false;
  }

  const actionDate = extractConnectionRequestActionDate(requestData);
  if (!actionDate) {
    return false;
  }

  return Date.now() - actionDate.getTime() < CONNECTION_REQUEST_COOLDOWN_MS;
}

function buildConnectionNotificationBody(senderName, eventType) {
  if (eventType === "connectionAccepted") {
    return `${senderName} aceitou seu convite de conexão`;
  }

  return `${senderName} quer se conectar com você`;
}

async function createConnectionNotification({
  recipientProfileId,
  recipientUid,
  senderProfileId,
  senderUid,
  senderName,
  senderUsername,
  senderPhoto,
  eventType,
  title,
  requestId,
}) {
  const normalizedRecipientProfileId = normalizeProfileId(recipientProfileId);
  const normalizedRecipientUid =
    typeof recipientUid === "string" ? recipientUid.trim() : "";
  const normalizedSenderProfileId = normalizeProfileId(senderProfileId);
  const normalizedSenderUid =
    typeof senderUid === "string" ? senderUid.trim() : "";
  const normalizedEventType =
    typeof eventType === "string" ? eventType.trim() : "";
  const normalizedTitle = typeof title === "string" ? title.trim() : "";
  const normalizedSenderName =
    typeof senderName === "string" && senderName.trim()
      ? senderName.trim()
      : "Alguém";

  if (
    !normalizedRecipientProfileId ||
    !normalizedRecipientUid ||
    !normalizedSenderProfileId ||
    !normalizedEventType ||
    !normalizedTitle
  ) {
    console.log(
      "⚠️ createConnectionNotification: parâmetros obrigatórios ausentes",
    );
    return;
  }

  const body = buildConnectionNotificationBody(
    normalizedSenderName,
    normalizedEventType,
  );

  const notificationPayload = {
    recipientProfileId: normalizedRecipientProfileId,
    recipientUid: normalizedRecipientUid,
    profileUid: normalizedRecipientUid,
    type: "profileMatch",
    priority: "high",
    title: normalizedTitle,
    body,
    message: body,
    actionType: "navigate",
    actionData: {
      route: "/home?index=1",
      eventType: normalizedEventType,
      connectionProfileId: normalizedSenderProfileId,
      profileId: normalizedSenderProfileId,
      targetId: normalizedSenderProfileId,
      requestId: requestId || "",
    },
    data: {
      eventType: normalizedEventType,
      connectionProfileId: normalizedSenderProfileId,
      targetProfileId: normalizedSenderProfileId,
      targetId: normalizedSenderProfileId,
      requestId: requestId || "",
      route: "/home?index=1",
    },
    senderUid: normalizedSenderUid || null,
    senderProfileId: normalizedSenderProfileId,
    senderName: normalizedSenderName,
    senderUsername:
      typeof senderUsername === "string" && senderUsername.trim()
        ? senderUsername.trim()
        : null,
    senderPhoto:
      typeof senderPhoto === "string" && senderPhoto.trim()
        ? senderPhoto.trim()
        : null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    read: false,
    expiresAt: admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
    ),
  };

  await db.collection("notifications").add(notificationPayload);

  await sendPushToProfile(
    normalizedRecipientProfileId,
    normalizedRecipientUid,
    {
      title: normalizedTitle,
      body,
    },
    {
      type: normalizedEventType,
      eventType: normalizedEventType,
      connectionProfileId: normalizedSenderProfileId,
      targetProfileId: normalizedSenderProfileId,
      targetId: normalizedSenderProfileId,
      senderProfileId: normalizedSenderProfileId,
      senderUid: normalizedSenderUid,
      senderName: normalizedSenderName,
      senderUsername:
        typeof senderUsername === "string" ? senderUsername.trim() : "",
      senderPhoto: typeof senderPhoto === "string" ? senderPhoto.trim() : "",
      requestId: requestId || "",
      route: "/home?index=1",
    },
  );
}

exports.onConnectionRequestCreated = functions
  .runWith({
    memory: "256MB",
    timeoutSeconds: 60,
  })
  .region("southamerica-east1")
  .firestore.document("connectionRequests/{requestId}")
  .onCreate(async (snap, context) => {
    const requestData = snap.data() || {};
    const requesterProfileId = normalizeProfileId(
      requestData.requesterProfileId,
    );
    const recipientProfileId = normalizeProfileId(
      requestData.recipientProfileId,
    );

    if (!requesterProfileId || !recipientProfileId) {
      console.log(
        `⚠️ onConnectionRequestCreated: request ${context.params.requestId} sem perfis válidos`,
      );
      return null;
    }

    const rateLimitCheck = await checkRateLimit(
      requesterProfileId,
      "connection_requests",
      CONNECTION_REQUEST_DAILY_LIMIT,
      24 * 60 * 60 * 1000,
    );

    if (!rateLimitCheck.allowed) {
      console.log(
        `🚫 onConnectionRequestCreated: rate limit excedido para ${requesterProfileId}`,
      );
      await snap.ref.delete();
      await rebuildConnectionStatsForProfiles([
        requesterProfileId,
        recipientProfileId,
      ]);
      return null;
    }

    const inverseRequestSnapshot = await db
      .collection("connectionRequests")
      .doc(`${recipientProfileId}_${requesterProfileId}`)
      .get();
    if (
      await hasRecentConnectionCooldown(inverseRequestSnapshot.data() || {})
    ) {
      console.log(
        `🚫 onConnectionRequestCreated: cooldown ativo para ${requesterProfileId} -> ${recipientProfileId}`,
      );
      await snap.ref.delete();
      await rebuildConnectionStatsForProfiles([
        requesterProfileId,
        recipientProfileId,
      ]);
      return null;
    }

    const blocked = await isBlockedByProfile(
      requesterProfileId,
      recipientProfileId,
      `connectionRequestCreated:${context.params.requestId}`,
    );

    if (blocked) {
      console.log(
        `🚫 onConnectionRequestCreated: removendo convite bloqueado ${context.params.requestId}`,
      );
      await snap.ref.delete();
      await rebuildConnectionStatsForProfiles([
        requesterProfileId,
        recipientProfileId,
      ]);
      return null;
    }

    await createConnectionNotification({
      recipientProfileId,
      recipientUid: requestData.recipientUid,
      senderProfileId: requesterProfileId,
      senderUid: requestData.requesterUid,
      senderName: requestData.requesterName,
      senderUsername: requestData.requesterUsername,
      senderPhoto: requestData.requesterPhotoUrl,
      eventType: "connectionRequest",
      title: "Novo convite de conexão",
      requestId: context.params.requestId,
    });

    await rebuildConnectionStatsForProfiles([
      requesterProfileId,
      recipientProfileId,
    ]);
    return null;
  });

exports.onConnectionRequestAccepted = functions
  .runWith({
    memory: "256MB",
    timeoutSeconds: 60,
  })
  .region("southamerica-east1")
  .firestore.document("connectionRequests/{requestId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};
    if (before.status === after.status || after.status !== "accepted") {
      return null;
    }

    const requesterProfileId = normalizeProfileId(after.requesterProfileId);
    const recipientProfileId = normalizeProfileId(after.recipientProfileId);
    if (!requesterProfileId || !recipientProfileId) {
      return null;
    }

    const blocked = await isBlockedByProfile(
      requesterProfileId,
      recipientProfileId,
      `connectionRequestAccepted:${context.params.requestId}`,
    );

    if (blocked) {
      const connectionId = buildConnectionId(
        requesterProfileId,
        recipientProfileId,
      );
      await Promise.all([
        db
          .collection("connections")
          .doc(connectionId)
          .delete()
          .catch(() => null),
        change.after.ref.update({
          status: "cancelled",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }),
      ]);
      await rebuildConnectionStatsForProfiles([
        requesterProfileId,
        recipientProfileId,
      ]);
      return null;
    }

    await ensureConnectionDocumentFromRequest(context.params.requestId, after);
    await createConnectionNotification({
      recipientProfileId: requesterProfileId,
      recipientUid: after.requesterUid,
      senderProfileId: recipientProfileId,
      senderUid: after.recipientUid,
      senderName: after.recipientName,
      senderUsername: after.recipientUsername,
      senderPhoto: after.recipientPhotoUrl,
      eventType: "connectionAccepted",
      title: "Convite aceito",
      requestId: context.params.requestId,
    });
    await rebuildConnectionStatsForProfiles([
      requesterProfileId,
      recipientProfileId,
    ]);
    return null;
  });

exports.onConnectionRequestDeclined = functions
  .runWith({
    memory: "256MB",
    timeoutSeconds: 60,
  })
  .region("southamerica-east1")
  .firestore.document("connectionRequests/{requestId}")
  .onUpdate(async (change) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};
    if (before.status === after.status || after.status !== "declined") {
      return null;
    }

    await rebuildConnectionStatsForProfiles([
      after.requesterProfileId,
      after.recipientProfileId,
    ]);
    return null;
  });

exports.onConnectionRequestCancelled = functions
  .runWith({
    memory: "256MB",
    timeoutSeconds: 60,
  })
  .region("southamerica-east1")
  .firestore.document("connectionRequests/{requestId}")
  .onUpdate(async (change) => {
    const before = change.before.data() || {};
    const after = change.after.data() || {};
    if (before.status === after.status || after.status !== "cancelled") {
      return null;
    }

    await rebuildConnectionStatsForProfiles([
      after.requesterProfileId,
      after.recipientProfileId,
    ]);
    return null;
  });

exports.onConnectionRemoved = functions
  .runWith({
    memory: "256MB",
    timeoutSeconds: 60,
  })
  .region("southamerica-east1")
  .firestore.document("connections/{connectionId}")
  .onDelete(async (snap) => {
    const data = snap.data() || {};
    await rebuildConnectionStatsForProfiles(data.profileIds || []);
    return null;
  });

exports.onBlockCreated = functions
  .runWith({
    memory: "256MB",
    timeoutSeconds: 60,
  })
  .region("southamerica-east1")
  .firestore.document("blocks/{blockId}")
  .onCreate(async (snap, context) => {
    const data = snap.data() || {};
    const blockedByProfileId = normalizeProfileId(data.blockedByProfileId);
    const blockedProfileId = normalizeProfileId(data.blockedProfileId);

    if (!blockedByProfileId || !blockedProfileId) {
      console.log(
        `⚠️ onBlockCreated: block ${context.params.blockId} sem perfis válidos`,
      );
      return null;
    }

    await removeConnectionArtifactsBetweenProfiles(
      blockedByProfileId,
      blockedProfileId,
      `blockCreated:${context.params.blockId}`,
    );
    return null;
  });

exports.rebuildConnectionStats = functions
  .runWith({
    memory: "256MB",
    timeoutSeconds: 120,
  })
  .region("southamerica-east1")
  .https.onCall(async (data, context) => {
    if (!context.auth?.uid) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Autenticação obrigatória.",
      );
    }

    const requestedProfileId = normalizeProfileId(data?.profileId);
    let profileIds = [];

    if (requestedProfileId) {
      const profileSnapshot = await db
        .collection("profiles")
        .doc(requestedProfileId)
        .get();

      if (!profileSnapshot.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "Perfil não encontrado.",
        );
      }

      if ((profileSnapshot.data()?.uid || "") !== context.auth.uid) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "Você só pode reconstruir estatísticas dos seus perfis.",
        );
      }

      profileIds = [requestedProfileId];
    } else {
      const profilesSnapshot = await db
        .collection("profiles")
        .where("uid", "==", context.auth.uid)
        .get();

      profileIds = profilesSnapshot.docs.map((doc) => doc.id);
    }

    await rebuildConnectionStatsForProfiles(profileIds);

    return {
      ok: true,
      rebuiltProfiles: uniqueProfileIds(profileIds),
    };
  });
