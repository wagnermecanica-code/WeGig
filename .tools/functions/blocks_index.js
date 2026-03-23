"use strict";

const functions = require("firebase-functions");
const admin = require("firebase-admin");

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Reverse Block Index (Profile Doc)
 *
 * Mantém um índice "quem me bloqueou" dentro do doc do perfil bloqueado:
 * - profiles/{blockedProfileId}.blockedByProfileIds: [blockedByProfileId, ...]
 *
 * Motivo:
 * - Queries/listeners na coleção `blocks` podem falhar por rules/permissão ou por docs legados.
 * - Leitura de `profiles` é pública no app, então o perfil bloqueado sempre consegue filtrar
 *   conteúdo/visibilidade com base nesse campo.
 */
exports.syncBlockedByProfileIndex = functions
  .region("southamerica-east1")
  .firestore.document("blocks/{blockId}")
  .onWrite(async (change, context) => {
    const before = change.before.exists ? change.before.data() : null;
    const after = change.after.exists ? change.after.data() : null;

    const normalize = (v) => (typeof v === "string" ? v.trim() : "");

    const beforeBlockedProfileId = normalize(before?.blockedProfileId);
    const beforeBlockedByProfileId = normalize(before?.blockedByProfileId);
    const afterBlockedProfileId = normalize(after?.blockedProfileId);
    const afterBlockedByProfileId = normalize(after?.blockedByProfileId);

    if (!before && !after) return null;

    const addIndex = async (blockedProfileId, blockedByProfileId) => {
      if (!blockedProfileId || !blockedByProfileId) return;

      const profileRef = db.collection("profiles").doc(blockedProfileId);
      const profileSnap = await profileRef.get();
      if (!profileSnap.exists) {
        console.log(
          `⚠️ [BLOCKS_INDEX] profiles/${blockedProfileId} não existe. Ignorando add blockedByProfileId=${blockedByProfileId}`
        );
        return;
      }

      console.log(
        `🧩 [BLOCKS_INDEX] ADD profiles/${blockedProfileId}.blockedByProfileIds += ${blockedByProfileId} (blockId=${context.params.blockId})`
      );

      await profileRef.set(
        {
          blockedByProfileIds:
            admin.firestore.FieldValue.arrayUnion(blockedByProfileId),
          blockedByUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    };

    const removeIndex = async (blockedProfileId, blockedByProfileId) => {
      if (!blockedProfileId || !blockedByProfileId) return;

      const profileRef = db.collection("profiles").doc(blockedProfileId);
      const profileSnap = await profileRef.get();
      if (!profileSnap.exists) {
        console.log(
          `⚠️ [BLOCKS_INDEX] profiles/${blockedProfileId} não existe. Ignorando remove blockedByProfileId=${blockedByProfileId}`
        );
        return;
      }

      console.log(
        `🧩 [BLOCKS_INDEX] REMOVE profiles/${blockedProfileId}.blockedByProfileIds -= ${blockedByProfileId} (blockId=${context.params.blockId})`
      );

      await profileRef.set(
        {
          blockedByProfileIds:
            admin.firestore.FieldValue.arrayRemove(blockedByProfileId),
          blockedByUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    };

    try {
      // Create
      if (!before && after) {
        await addIndex(afterBlockedProfileId, afterBlockedByProfileId);
        return null;
      }

      // Delete
      if (before && !after) {
        await removeIndex(beforeBlockedProfileId, beforeBlockedByProfileId);
        return null;
      }

      // Update
      if (before && after) {
        if (
          beforeBlockedProfileId !== afterBlockedProfileId ||
          beforeBlockedByProfileId !== afterBlockedByProfileId
        ) {
          await removeIndex(beforeBlockedProfileId, beforeBlockedByProfileId);
          await addIndex(afterBlockedProfileId, afterBlockedByProfileId);
        }
        return null;
      }

      return null;
    } catch (error) {
      console.error(`❌ [BLOCKS_INDEX] onWrite failed: ${error}`);
      return null;
    }
  });

/**
 * Backfill (Scheduled)
 *
 * Popula `profiles/{blockedProfileId}.blockedByProfileIds` para bloqueios antigos,
 * criados antes do deploy do trigger `syncBlockedByProfileIndex`.
 *
 * Estratégia:
 * - Processa a coleção `blocks` em páginas (por documentId) e faz arrayUnion.
 * - Persiste cursor em `maintenance/blocksIndexBackfill`.
 * - É propositalmente "fail-closed": se houver valores a mais, é melhor do que leak.
 */
exports.backfillBlockedByProfileIndex = functions
  .region("southamerica-east1")
  .pubsub.schedule("every 5 minutes")
  .timeZone("America/Sao_Paulo")
  .onRun(async () => {
    const stateRef = db.collection("maintenance").doc("blocksIndexBackfill");
    const stateSnap = await stateRef.get();
    const state = stateSnap.exists ? stateSnap.data() : {};
    const lastDocId =
      typeof state?.lastDocId === "string" ? state.lastDocId : null;

    let query = db
      .collection("blocks")
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(500);

    if (lastDocId && lastDocId.trim() !== "") {
      query = query.startAfter(lastDocId);
    }

    const snap = await query.get();
    if (snap.empty) {
      console.log("🧩 [BLOCKS_INDEX] Backfill complete (no more blocks)");
      await stateRef.set(
        {
          lastDocId: null,
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      return null;
    }

    const byBlockedProfileId = new Map();

    for (const doc of snap.docs) {
      const data = doc.data() || {};

      let blockedProfileId =
        typeof data.blockedProfileId === "string"
          ? data.blockedProfileId.trim()
          : "";
      let blockedByProfileId =
        typeof data.blockedByProfileId === "string"
          ? data.blockedByProfileId.trim()
          : "";

      // Fallback: tentar inferir a partir do docId "blockedBy_blocked".
      if (
        (!blockedProfileId || !blockedByProfileId) &&
        typeof doc.id === "string"
      ) {
        const parts = doc.id.split("_");
        if (parts.length >= 2) {
          blockedByProfileId = blockedByProfileId || (parts[0] || "").trim();
          blockedProfileId =
            blockedProfileId || (parts.slice(1).join("_") || "").trim();
        }
      }

      if (!blockedProfileId || !blockedByProfileId) continue;

      if (!byBlockedProfileId.has(blockedProfileId)) {
        byBlockedProfileId.set(blockedProfileId, new Set());
      }
      byBlockedProfileId.get(blockedProfileId).add(blockedByProfileId);
    }

    const batch = db.batch();
    let writes = 0;
    for (const [blockedProfileId, set] of byBlockedProfileId.entries()) {
      const values = Array.from(set);
      if (values.length === 0) continue;

      const profileRef = db.collection("profiles").doc(blockedProfileId);
      batch.set(
        profileRef,
        {
          blockedByProfileIds: admin.firestore.FieldValue.arrayUnion(...values),
          blockedByUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
      writes++;
    }

    if (writes > 0) {
      await batch.commit();
    }

    const newLastDocId = snap.docs[snap.docs.length - 1].id;
    console.log(
      `🧩 [BLOCKS_INDEX] Backfill page: blocks=${snap.size} profilesUpdated=${writes} lastDocId=${newLastDocId}`
    );

    await stateRef.set(
      {
        lastDocId: newLastDocId,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        processedBlocks: admin.firestore.FieldValue.increment(snap.size),
        processedPages: admin.firestore.FieldValue.increment(1),
      },
      { merge: true }
    );

    return null;
  });
