/**
 * Funções administrativas para o painel WeGig Admin.
 *
 * - aggregateDailyMetrics: scheduled (3AM BRT). Agrega métricas em `analytics_daily/{YYYY-MM-DD}`.
 * - setUserModeration: callable (ban/unban um perfil). Apenas admins.
 *
 * Região: southamerica-east1.
 */

const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");

const REGION = "southamerica-east1";

/**
 * Conta documentos de uma coleção (ou query) usando agregação count() do Firestore.
 * Retorna 0 em caso de erro (coleção inexistente etc.).
 */
async function safeCount(query) {
  try {
    const snap = await query.count().get();
    return snap.data().count || 0;
  } catch (err) {
    console.warn("[aggregateDailyMetrics] count failed:", err.message);
    return 0;
  }
}

/**
 * aggregateDailyMetrics
 * Roda diariamente às 03:00 BRT e grava um snapshot em `analytics_daily/{date}`.
 */
exports.aggregateDailyMetrics = functions
  .region(REGION)
  .pubsub.schedule("0 3 * * *")
  .timeZone("America/Sao_Paulo")
  .onRun(async () => {
    const db = admin.firestore();
    const now = new Date();
    const yesterday = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    const dateId = yesterday.toISOString().slice(0, 10); // YYYY-MM-DD
    const startOfDay = new Date(`${dateId}T00:00:00-03:00`);
    const endOfDay = new Date(`${dateId}T23:59:59-03:00`);
    const startTs = admin.firestore.Timestamp.fromDate(startOfDay);
    const endTs = admin.firestore.Timestamp.fromDate(endOfDay);

    const [
      totalUsers,
      totalPosts,
      activePosts,
      totalConversations,
      newUsers,
      newPosts,
      newConversations,
      newMessages,
    ] = await Promise.all([
      safeCount(db.collection("profiles")),
      safeCount(db.collection("posts")),
      safeCount(
        db
          .collection("posts")
          .where("expiresAt", ">", admin.firestore.Timestamp.now()),
      ),
      safeCount(db.collection("conversations")),
      safeCount(
        db
          .collection("profiles")
          .where("createdAt", ">=", startTs)
          .where("createdAt", "<=", endTs),
      ),
      safeCount(
        db
          .collection("posts")
          .where("createdAt", ">=", startTs)
          .where("createdAt", "<=", endTs),
      ),
      safeCount(
        db
          .collection("conversations")
          .where("createdAt", ">=", startTs)
          .where("createdAt", "<=", endTs),
      ),
      safeCount(
        db
          .collectionGroup("messages")
          .where("createdAt", ">=", startTs)
          .where("createdAt", "<=", endTs),
      ),
    ]);

    const payload = {
      date: dateId,
      totalUsers,
      totalPosts,
      activePosts,
      totalConversations,
      newUsers,
      newPosts,
      newConversations,
      messagesSent: newMessages,
      dau: newMessages > 0 ? newUsers + Math.round(newMessages / 5) : newUsers,
      generatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db
      .collection("analytics_daily")
      .doc(dateId)
      .set(payload, { merge: true });
    console.log(`[aggregateDailyMetrics] saved ${dateId}`, payload);
    return null;
  });

/**
 * setUserModeration
 * Callable: ban/unban de um perfil. Requer admin.
 *
 * data: { profileId: string, banned: boolean, reason?: string }
 */
exports.setUserModeration = functions
  .region(REGION)
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Login obrigatório.",
      );
    }
    const db = admin.firestore();
    const adminSnap = await db.collection("admins").doc(context.auth.uid).get();
    if (!adminSnap.exists) {
      throw new functions.https.HttpsError("permission-denied", "Não é admin.");
    }
    const adminData = adminSnap.data() || {};
    const role = adminData.role || "admin";
    const allowedRoles = ["superadmin", "admin", "moderator"];
    if (!allowedRoles.includes(role)) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Role sem permissão.",
      );
    }

    const { profileId, banned, reason } = data || {};
    if (!profileId || typeof banned !== "boolean") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "profileId e banned são obrigatórios.",
      );
    }

    const profileRef = db.collection("profiles").doc(profileId);
    const profile = await profileRef.get();
    if (!profile.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        "Perfil não encontrado.",
      );
    }

    await profileRef.update({
      banned,
      moderationStatus: banned ? "banned" : "active",
      moderationReason: reason || null,
      moderatedAt: admin.firestore.FieldValue.serverTimestamp(),
      moderatedBy: context.auth.uid,
    });

    await db.collection("audit_logs").add({
      actorUid: context.auth.uid,
      actorEmail: adminData.email || null,
      actorRole: role,
      action: banned ? "user.ban" : "user.unban",
      targetType: "user",
      targetId: profileId,
      metadata: { reason: reason || null, source: "callable" },
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { ok: true, profileId, banned };
  });
