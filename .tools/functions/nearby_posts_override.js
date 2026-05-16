"use strict";

const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Busca tokens FCM válidos para um perfil (copiado do index.js que funciona)
 * - Ordena por updatedAt (mais recente primeiro)
 * - Limita a 20 tokens por perfil
 */
async function getTokensForProfile(profileId, expectedUid) {
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

    // Filtrar tokens válidos e ordenar por updatedAt (mais recente primeiro)
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

    // Ordenar por updatedAt (mais recente primeiro)
    validTokens.sort((a, b) => b.updatedAt - a.updatedAt);

    // Limitar a 20 tokens por perfil
    const MAX_TOKENS_PER_PROFILE = 20;
    const tokensToUse = validTokens
      .slice(0, MAX_TOKENS_PER_PROFILE)
      .map((t) => t.token);

    // Log detalhado para debug
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
 * notifyNearbyPosts (override)
 * Versão enxuta para evitar timeout e garantir criação das notificações.
 */
exports.notifyNearbyPosts = functions
  .runWith({
    memory: "512MB",
    timeoutSeconds: 540,
  })
  .region("southamerica-east1")
  .firestore.document("posts/{postId}")
  .onCreate(async (snap) => {
    console.log("🔧 [nearbyPost] version=2026-02-01-fix6-ios-data");

    const post = snap.data();
    const postId = snap.id;

    if (
      !post.location ||
      (post.location._latitude === undefined &&
        post.location.latitude === undefined)
    ) {
      console.log(`Post ${postId} ignorado: sem localização válida`);
      return null;
    }

    const postLat = post.location.latitude ?? post.location._latitude;
    const postLng = post.location.longitude ?? post.location._longitude;
    const postCity = post.city || "cidade desconhecida";

    const authorName = post.authorName || "Alguém";
    const authorUsername = post.authorUsername || "";
    const authorProfileId = (post.authorProfileId || "").trim();

    if (!authorProfileId) {
      console.log(
        `⚠️ Post ${postId} ignorado: authorProfileId ausente/ inválido`,
      );
      return null;
    }

    const displayAuthor = authorUsername || authorName;

    let authorBlockedSet = new Set();
    try {
      const authorProfileDoc = await db
        .collection("profiles")
        .doc(authorProfileId)
        .get();
      if (authorProfileDoc.exists) {
        const authorData = authorProfileDoc.data() || {};
        const authorBlocked = authorData.blockedProfileIds || [];
        const authorBlockedBy = authorData.blockedByProfileIds || [];
        authorBlockedSet = new Set([...authorBlocked, ...authorBlockedBy]);
      }
    } catch (error) {
      console.log(
        `⚠️ Falha ao carregar bloqueios do autor ${authorProfileId}: ${error}`,
      );
    }

    const profilesSnap = await db.collection("profiles").get();

    const candidates = [];
    for (const doc of profilesSnap.docs) {
      const profile = doc.data();
      const profileId = doc.id;
      const profileUid =
        profile.uid || profile.profileUid || profile.userId || profile.userUid;

      const notifyNearbyPosts =
        profile.notificationRadiusEnabled === undefined
          ? true
          : profile.notificationRadiusEnabled === true;
      if (!notifyNearbyPosts) continue;

      if (
        !profile.location ||
        (profile.location._latitude === undefined &&
          profile.location.latitude === undefined)
      ) {
        continue;
      }

      if (!profileUid) continue;
      if (profileId === authorProfileId) continue;

      if (authorBlockedSet.has(profileId)) continue;
      const candidateBlocked = profile.blockedProfileIds || [];
      const candidateBlockedBy = profile.blockedByProfileIds || [];
      if (
        candidateBlocked.includes(authorProfileId) ||
        candidateBlockedBy.includes(authorProfileId)
      ) {
        continue;
      }

      const userLat = profile.location.latitude ?? profile.location._latitude;
      const userLng = profile.location.longitude ?? profile.location._longitude;
      const rawRadius =
        profile.notificationRadius ?? profile.notificationRadiusKm ?? 20;
      let radius = Number(rawRadius);
      if (!Number.isFinite(radius)) {
        radius = 20;
      }
      // Clamp safety: keep within [5, 100]
      radius = Math.min(100, Math.max(5, radius));

      const R = 6371;
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

      if (distance <= radius) {
        candidates.push({
          profileId,
          profileUid,
          profileName: profile.name || "Perfil",
          distance: distance.toFixed(1),
          radius,
        });
      }
    }

    if (candidates.length === 0) {
      console.log("📭 Nenhum perfil próximo encontrado para notificar");
      return null;
    }

    const MAX_NOTIFICATIONS = 300;
    const limitedCandidates = candidates.slice(0, MAX_NOTIFICATIONS);

    const notifications = [];
    for (const candidate of limitedCandidates) {
      const nearbyBody =
        post.type === "sales"
          ? `@${displayAuthor} • anunciou perto de você`
          : post.type === "hiring"
            ? `@${displayAuthor} • está contratando perto de você`
            : `@${displayAuthor} • postou perto de você`;

      notifications.push({
        recipientProfileId: candidate.profileId,
        recipientUid: candidate.profileUid,
        profileUid: candidate.profileId,
        type: "nearbyPost",
        priority: "medium",
        title: "Novo post próximo!",
        body: nearbyBody,
        actionType: "viewPost",
        actionData: {
          postId: postId,
          distance: candidate.distance,
          city: postCity,
          postType: post.type,
          authorName: authorName,
          authorProfileId: authorProfileId,
        },
        senderName: authorName,
        senderUsername: authorUsername,
        senderPhoto: post.authorPhotoUrl || null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
        expiresAt: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        ),
      });
    }

    const batch = db.batch();
    notifications.forEach((notification) => {
      const notificationRef = db.collection("notifications").doc();
      batch.set(notificationRef, notification);
    });

    await batch.commit();
    console.log(
      `🔔 Enviadas ${notifications.length} notificações in-app de post próximo`,
    );

    // Push notifications (leve, sem badge)
    const processedUids = new Set();
    const MAX_PUSH_UIDS = 200;
    let pushSent = 0;

    for (const notification of notifications) {
      if (processedUids.size >= MAX_PUSH_UIDS) break;

      const profileId = notification.recipientProfileId;
      const recipientUid = notification.recipientUid;

      if (!recipientUid || processedUids.has(recipientUid)) continue;
      processedUids.add(recipientUid);

      const tokens = await getTokensForProfile(profileId, recipientUid);
      if (tokens.length === 0) continue;

      // FCM limit: max 500 tokens per call
      const batchSize = 500;
      const batchedTokens = tokens.slice(0, batchSize);

      // Preparar dados customizados
      const customData = {
        type: "nearbyPost",
        postId: String(postId),
        authorName: String(authorName),
        city: String(postCity),
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      };

      try {
        const response = await admin.messaging().sendEachForMulticast({
          tokens: batchedTokens,
          notification: {
            title: "Novo post próximo!",
            body: notification.body,
          },
          data: customData,
          android: {
            priority: "high",
            notification: {
              channelId: "high_importance_channel",
              clickAction: "FLUTTER_NOTIFICATION_CLICK",
              priority: "high",
              color: "#E47911",
              sound: "default",
            },
          },
          apns: {
            headers: {
              "apns-priority": "10",
            },
            payload: {
              aps: {
                alert: {
                  title: "Novo post próximo!",
                  body: notification.body,
                },
                sound: "default",
                "mutable-content": 1,
                "content-available": 1,
              },
              // iOS: dados customizados devem estar no payload APNS para terminated state
              ...customData,
            },
          },
        });

        console.log(
          `   ✅ ${profileId}: ${response.successCount} ok, ${response.failureCount} falhas`,
        );

        // Log detalhado de falhas
        if (response.failureCount > 0) {
          response.responses.forEach((resp, idx) => {
            if (!resp.success) {
              console.log(
                `   ❌ Token ${idx}: ${resp.error?.code} - ${resp.error?.message}`,
              );
            }
          });
        }
      } catch (err) {
        console.log(`   ❌ Erro push ${profileId}: ${err.message}`);
      }

      pushSent++;
    }

    console.log(
      `📤 Push enviado para ${pushSent} usuário(s) únicos (nearbyPost)`,
    );

    return null;
  });
