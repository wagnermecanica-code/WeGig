"use strict";

const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

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
      return {
        seenAt: null,
        blockedProfileIds: new Set(),
        excludedProfileIds: new Set(),
      };
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
      blockedProfileIds: new Set(
        blockedProfileIds
          .map((value) => String(value || "").trim())
          .filter(Boolean),
      ),
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
    return {
      seenAt: null,
      blockedProfileIds: new Set(),
      excludedProfileIds: new Set(),
    };
  }
}

// ─── Helper Functions (copied from index.js) ───

/**
 * Busca tokens FCM válidos para um perfil
 */
async function getValidTokensForProfile(profileId, expectedUid) {
  try {
    const profileDoc = await db.collection("profiles").doc(profileId).get();
    if (!profileDoc.exists) {
      console.log(`⚠️ Perfil ${profileId} não encontrado`);
      return [];
    }

    const profileData = profileDoc.data() || {};
    const profileUid = (
      profileData.uid ||
      profileData.profileUid ||
      profileData.userId ||
      profileData.userUid ||
      ""
    ).trim();
    const expected = (expectedUid || "").trim();

    if (!profileUid || !expected || profileUid !== expected) {
      console.log(
        `🚨 SECURITY: Perfil ${profileId} não pertence ao usuário ${expectedUid}`,
      );
      return [];
    }

    const tokensSnap = await db
      .collection("profiles")
      .doc(profileId)
      .collection("fcmTokens")
      .get();

    if (tokensSnap.empty) {
      console.log(`📭 Nenhum token FCM encontrado para perfil ${profileId}`);
      return [];
    }

    const validTokens = [];
    let skippedNonMobileTokens = 0;
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

      const updatedAt =
        tokenData.updatedAt &&
        typeof tokenData.updatedAt.toMillis === "function"
          ? tokenData.updatedAt.toMillis()
          : tokenData.createdAt &&
              typeof tokenData.createdAt.toMillis === "function"
            ? tokenData.createdAt.toMillis()
            : 0;

      validTokens.push({ token, updatedAt, platform });
    });

    if (skippedNonMobileTokens > 0) {
      console.log(
        `⏭️ Ignorados ${skippedNonMobileTokens} tokens de plataformas desktop/web`,
      );
    }

    validTokens.sort((a, b) => b.updatedAt - a.updatedAt);

    const MAX_TOKENS_PER_PROFILE = 20;
    const tokensToUse = validTokens
      .slice(0, MAX_TOKENS_PER_PROFILE)
      .map((t) => t.token);

    const platforms = validTokens
      .slice(0, MAX_TOKENS_PER_PROFILE)
      .map((t) => t.platform);
    console.log(
      `✅ ${tokensToUse.length} token(s) para perfil ${profileId} (platforms: ${platforms.join(", ")})`,
    );

    return tokensToUse;
  } catch (error) {
    console.log(`❌ Erro ao buscar tokens do perfil ${profileId}: ${error}`);
    return [];
  }
}

/**
 * Calcula o badge count (notificações não lidas)
 */
function getNotificationCandidateProfileIds(notificationData) {
  const candidateProfileIds = new Set();
  const actionData =
    notificationData.actionData &&
    typeof notificationData.actionData === "object"
      ? notificationData.actionData
      : {};
  const data =
    notificationData.data && typeof notificationData.data === "object"
      ? notificationData.data
      : {};

  const addCandidate = (value) => {
    const normalized = String(value || "").trim();
    if (normalized) {
      candidateProfileIds.add(normalized);
    }
  };

  addCandidate(notificationData.senderProfileId);
  addCandidate(actionData.authorProfileId);
  addCandidate(actionData.interestedProfileId);
  addCandidate(actionData.senderProfileId);
  addCandidate(actionData.commenterProfileId);
  addCandidate(data.actionProfileId);
  addCandidate(data.authorProfileId);
  addCandidate(data.interestedProfileId);
  addCandidate(data.senderProfileId);

  return candidateProfileIds;
}

function isConnectionActivityNotificationData(notificationData) {
  const actionData =
    notificationData.actionData &&
    typeof notificationData.actionData === "object"
      ? notificationData.actionData
      : {};
  const data =
    notificationData.data && typeof notificationData.data === "object"
      ? notificationData.data
      : {};
  const eventType = String(actionData.eventType || data.eventType || "").trim();
  return eventType.startsWith("connection");
}

function shouldIncludeNotificationInBadge(notificationData, blockedProfileIds) {
  const type = String(notificationData.type || "").trim();
  if (type === "newMessage") {
    return false;
  }

  if (isConnectionActivityNotificationData(notificationData)) {
    return false;
  }

  const expiresAt = parseFirestoreDate(notificationData.expiresAt);
  if (expiresAt && expiresAt < new Date()) {
    return false;
  }

  if (blockedProfileIds && blockedProfileIds.size > 0) {
    const candidateProfileIds =
      getNotificationCandidateProfileIds(notificationData);
    for (const profileId of candidateProfileIds) {
      if (blockedProfileIds.has(profileId)) {
        return false;
      }
    }
  }

  return true;
}

async function getUnreadNotificationCount(
  recipientProfileId,
  blockedProfileIds,
) {
  try {
    const unreadSnap = await db
      .collection("notifications")
      .where("recipientProfileId", "==", recipientProfileId)
      .where("read", "==", false)
      .get();

    const total = unreadSnap.docs.filter((doc) =>
      shouldIncludeNotificationInBadge(doc.data() || {}, blockedProfileIds),
    ).length;
    console.log(
      `📱 [BADGE] Perfil ${recipientProfileId.substring(0, 8)}... unread=${total}`,
    );
    return Math.max(0, total);
  } catch (error) {
    console.error(`⚠️ [BADGE] Erro ao contar não lidas: ${error}`);
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
    console.error(`⚠️ [BADGE] Erro ao contar conversas não lidas: ${error}`);
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
    console.error(`⚠️ [BADGE] Erro ao contar Minha Rede: ${error}`);
    return 0;
  }
}

async function getUnifiedBadgeCount(profileId, recipientUid) {
  const { seenAt, blockedProfileIds, excludedProfileIds } =
    await getProfileBadgeContext(profileId);
  const [notifications, messages, myNetwork] = await Promise.all([
    getUnreadNotificationCount(profileId, blockedProfileIds),
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
 * Envia push notification para um perfil
 */
async function sendPushToProfile(profileId, expectedUid, notification, data) {
  const tokens = await getValidTokensForProfile(profileId, expectedUid);

  if (tokens.length === 0) {
    console.log(`📭 Sem tokens FCM válidos para perfil ${profileId}`);
    return;
  }

  const badgeCount = await getUnifiedBadgeCount(profileId, expectedUid);
  const messaging = admin.messaging();

  const message = {
    tokens: tokens,
    notification: {
      title: notification.title,
      body: notification.body,
    },
    data: {
      ...Object.fromEntries(
        Object.entries(data || {}).map(([k, v]) => [k, String(v)]),
      ),
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
    android: {
      priority: "high",
      notification: {
        channelId: "high_importance_channel",
        priority: "high",
        defaultSound: true,
        defaultVibrateTimings: true,
        // Badge count no ícone do launcher (Android 8+).
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
          badge: badgeCount,
          sound: "default",
          "content-available": 1,
        },
      },
    },
  };

  try {
    const response = await messaging.sendEachForMulticast(message);
    console.log(
      `📤 Push enviado para ${profileId}: ${response.successCount} sucesso, ${response.failureCount} falha`,
    );

    // Remover tokens inválidos
    if (response.failureCount > 0) {
      const invalidTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const errorCode = resp.error?.code || "";
          if (
            errorCode === "messaging/invalid-registration-token" ||
            errorCode === "messaging/registration-token-not-registered"
          ) {
            invalidTokens.push(tokens[idx]);
          }
        }
      });

      if (invalidTokens.length > 0) {
        const batch = db.batch();
        for (const token of invalidTokens) {
          const tokenRef = db
            .collection("profiles")
            .doc(profileId)
            .collection("fcmTokens")
            .doc(token);
          batch.delete(tokenRef);
        }
        await batch.commit();
        console.log(`🗑️ ${invalidTokens.length} tokens inválidos removidos`);
      }
    }
  } catch (error) {
    console.error(`❌ Erro ao enviar push para ${profileId}: ${error}`);
  }
}

/**
 * Verifica se um perfil está bloqueado por outro
 */
async function isBlockedByProfile(blockerProfileId, blockedProfileId, context) {
  try {
    const blockDoc = await db
      .collection("blocks")
      .where("blockedByProfileId", "==", blockerProfileId)
      .where("blockedProfileId", "==", blockedProfileId)
      .limit(1)
      .get();

    const isBlocked = !blockDoc.empty;
    if (isBlocked) {
      console.log(
        `🚫 [BLOCK_CHECK][${context}] ${blockerProfileId} bloqueou ${blockedProfileId}`,
      );
    }
    return isBlocked;
  } catch (error) {
    console.error(`❌ [BLOCK_CHECK] Erro: ${error}`);
    return false;
  }
}

/**
 * Rate limiting simples
 */
async function checkRateLimit(profileId, action, limit, windowMs) {
  try {
    const windowStart = new Date(Date.now() - windowMs);
    const countSnap = await db
      .collection("rateLimits")
      .where("profileId", "==", profileId)
      .where("action", "==", action)
      .where("timestamp", ">=", admin.firestore.Timestamp.fromDate(windowStart))
      .get();

    if (countSnap.size >= limit) {
      return { allowed: false, count: countSnap.size };
    }

    // Registrar ação
    await db.collection("rateLimits").add({
      profileId: profileId,
      action: action,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { allowed: true, count: countSnap.size + 1 };
  } catch (error) {
    console.error(`❌ Rate limit check error: ${error}`);
    return { allowed: true, count: 0 }; // Falha segura: permitir
  }
}

// ─── Main Function ───

/**
 * Envia notificação quando um novo comentário é criado
 *
 * Trigger: onCreate em posts/{postId}/comments/{commentId}
 * Cria notificação in-app + push notification para:
 * 1. Se for resposta: notifica quem foi respondido
 * 2. Sempre: notifica o dono do post (se não for o próprio comentarista)
 */
exports.sendCommentNotification = functions
  .runWith({
    memory: "128MB",
    timeoutSeconds: 30,
  })
  .region("southamerica-east1")
  .firestore.document("posts/{postId}/comments/{commentId}")
  .onCreate(async (snap, context) => {
    const comment = snap.data() || {};
    const postId = context.params.postId;
    const commentId = context.params.commentId;

    const commenterProfileId = (comment.authorProfileId || "").trim();
    const commenterUid = (comment.authorUid || "").trim();
    const commenterName = comment.authorName || "WeGig";
    const commentText = comment.text || "Comentou no seu post";
    const commentPreview =
      commentText.length > 120
        ? `${commentText.substring(0, 120)}...`
        : commentText;

    // Campos de resposta (reply)
    const parentCommentId = (comment.parentCommentId || "").trim();
    const replyToProfileId = (comment.replyToProfileId || "").trim();
    const replyToName = comment.replyToName || "";
    const isReply = parentCommentId !== "";

    if (!postId || !commenterProfileId) {
      console.log(
        "⚠️ Comment notification skipped: missing postId or commenterProfileId",
      );
      return null;
    }

    // Buscar post
    const postDoc = await db.collection("posts").doc(postId).get();
    if (!postDoc.exists) {
      console.log(`⚠️ Post ${postId} não encontrado`);
      return null;
    }

    const post = postDoc.data() || {};
    const postAuthorProfileId = (post.authorProfileId || "").trim();
    const postAuthorUid = (post.authorUid || "").trim();

    if (!postAuthorProfileId || !postAuthorUid) {
      console.log(`⚠️ Post ${postId} sem authorProfileId/authorUid`);
      return null;
    }

    // Rate limiting: 500 comentários/dia por perfil
    {
      const rateLimitCheck = await checkRateLimit(
        commenterProfileId,
        "comments",
        500,
        24 * 60 * 60 * 1000,
      );
      if (!rateLimitCheck.allowed) {
        console.log(
          `🚫 Rate limit: ${commenterProfileId} excedeu limite diário de comentários`,
        );
        return null;
      }
    }

    // Foto do comentarista (do doc do comentário)
    const commenterPhoto = comment.authorPhotoUrl || null;

    // Buscar dados do post para contexto
    const postType = post.type || "unknown";
    const postCity = post.city || "";

    // ─── Helper: notificar um perfil (in-app + push) ───
    const notifyProfile = async (
      targetProfileId,
      notificationTitle,
      notificationBody,
    ) => {
      // Não notificar a si mesmo
      if (commenterProfileId === targetProfileId) return;

      // 🔒 BLOCKING: checar bloqueio em ambas direções
      const [commenterBlocksTarget, targetBlocksCommenter] = await Promise.all([
        isBlockedByProfile(
          commenterProfileId,
          targetProfileId,
          `comment:${postId}`,
        ),
        isBlockedByProfile(
          targetProfileId,
          commenterProfileId,
          `comment:${postId}`,
        ),
      ]);

      if (commenterBlocksTarget || targetBlocksCommenter) {
        console.log(
          `🚫 [BLOCK_CHECK][comment:${postId}] Bloqueio detectado (commenter=${commenterProfileId} target=${targetProfileId}), não enviando notificação`,
        );
        return;
      }

      // Buscar perfil do destinatário para UID e preferências
      const targetProfileDoc = await db
        .collection("profiles")
        .doc(targetProfileId)
        .get();

      if (!targetProfileDoc.exists) {
        console.log(`⚠️ Perfil ${targetProfileId} não encontrado`);
        return;
      }

      const targetProfileData = targetProfileDoc.data() || {};
      const targetUid = (targetProfileData.uid || "").trim();

      if (!targetUid) {
        console.log(`⚠️ UID não encontrado para perfil ${targetProfileId}`);
        return;
      }

      // Preferência notifyComments (fallback true)
      const notifyComments = targetProfileData.notifyComments ?? true;
      if (!notifyComments) {
        console.log(
          `🔕 Notificação de comentários desativada para perfil ${targetProfileId}`,
        );
        return;
      }

      // Criar notificação in-app
      await db.collection("notifications").add({
        recipientProfileId: targetProfileId,
        recipientUid: targetUid,
        profileUid: targetProfileId,
        type: "comment",
        priority: "medium",
        title: notificationTitle,
        body: notificationBody,
        actionType: "viewPost",
        actionData: {
          postId: postId,
          commentId: commentId,
          commenterProfileId: commenterProfileId,
          commenterName: commenterName,
          parentCommentId: parentCommentId || null,
          postType: postType,
          city: postCity,
        },
        senderName: commenterName,
        senderPhoto: commenterPhoto,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
        expiresAt: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        ),
      });

      // Enviar push notification
      await sendPushToProfile(
        targetProfileId,
        targetUid,
        {
          title: notificationTitle,
          body: notificationBody,
        },
        {
          type: "comment",
          postId: postId,
          commentId: commentId,
          commenterProfileId: commenterProfileId,
          commenterUid: commenterUid,
          recipientProfileId: targetProfileId,
          postType: postType,
        },
      );

      console.log(
        `📨 Notificação de comentário enviada para ${targetProfileId}`,
      );
    };

    // ─── Notificar destinatários ───
    const notifiedProfiles = new Set();

    if (isReply && replyToProfileId) {
      // 1. Resposta: notificar quem foi respondido
      const replyTitle = `${commenterName} respondeu seu comentário`;
      const replyBody = `Respondeu: ${commentPreview}`;
      await notifyProfile(replyToProfileId, replyTitle, replyBody);
      notifiedProfiles.add(replyToProfileId);

      console.log(
        `💬 Resposta: ${commenterName} → ${replyToName} (${replyToProfileId}) no post ${postId}`,
      );
    }

    // 2. Sempre notificar o dono do post (se não foi já notificado como replyTo)
    if (!notifiedProfiles.has(postAuthorProfileId)) {
      const postOwnerTitle = isReply
        ? `${commenterName} respondeu um comentário no seu post`
        : `${commenterName} comentou no seu post`;
      const postOwnerBody = isReply
        ? `Respondeu: ${commentPreview}`
        : `Comentou: ${commentPreview}`;
      await notifyProfile(postAuthorProfileId, postOwnerTitle, postOwnerBody);

      console.log(`💬 Notificação para dono do post: ${postAuthorProfileId}`);
    }

    return null;
  });
