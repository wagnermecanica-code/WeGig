#!/usr/bin/env node
/**
 * Deleta todas as conversas 1:1 (e subcoleção messages) entre dois perfis.
 *
 * Uso:
 *   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
 *   node delete_conversations_between_profiles.js \
 *       --project <projectId> \
 *       --user-a <@handle|profileId> \
 *       --user-b <@handle|profileId> \
 *       [--dry-run] [--yes]
 *
 * - Resolve handles (com ou sem '@') consultando users.username ou
 *   profiles.profileId direto.
 * - Encontra conversas por (a) directConversationKey determinístico,
 *   (b) scan em participantProfiles array-contains.
 * - Deleta em batch (500) as mensagens da subcoleção e depois o doc.
 * - Por padrão é dry-run; use --yes para executar.
 */

const { initializeApp, applicationDefault } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

function parseArgs() {
  const args = process.argv.slice(2);
  const get = (flag) => {
    const i = args.indexOf(flag);
    return i >= 0 ? args[i + 1] : null;
  };
  return {
    projectId: get("--project"),
    userA: get("--user-a"),
    userB: get("--user-b"),
    dryRun: !args.includes("--yes"),
    verbose: args.includes("--verbose"),
  };
}

const { projectId, userA, userB, dryRun, verbose } = parseArgs();
if (!projectId || !userA || !userB) {
  console.error(
    "❌ Uso: --project <id> --user-a <@handle|profileId> --user-b <@handle|profileId> [--yes]",
  );
  process.exit(1);
}

initializeApp({ credential: applicationDefault(), projectId });
const db = getFirestore();

function buildDirectKey(pidA, pidB) {
  return [pidA.trim(), pidB.trim()].sort().join("__");
}

async function resolveProfileId(input) {
  const raw = String(input).trim();
  if (!raw) return null;

  // Tenta como profileId direto
  const directDoc = await db.collection("profiles").doc(raw).get();
  if (directDoc.exists) return directDoc.id;

  // Tenta como @handle via users.username → users.profiles (array de profileIds)
  const handle = raw.startsWith("@") ? raw.slice(1) : raw;

  // 1) Busca em profiles.username (se existir)
  const byProfileUsername = await db
    .collection("profiles")
    .where("username", "==", handle)
    .limit(1)
    .get();
  if (!byProfileUsername.empty) return byProfileUsername.docs[0].id;

  // 2) Busca user por username → pega o primeiro profileId atrelado
  const byUser = await db
    .collection("users")
    .where("username", "==", handle)
    .limit(1)
    .get();
  if (!byUser.empty) {
    const data = byUser.docs[0].data() || {};
    const profiles = Array.isArray(data.profiles) ? data.profiles : null;
    if (profiles && profiles.length > 0) {
      console.log(
        `ℹ️  User @${handle} tem ${profiles.length} perfis: ${profiles.join(", ")}`,
      );
      return profiles[0];
    }
  }

  return null;
}

async function deleteSubcollection(ref, subcollectionName) {
  let totalDeleted = 0;
  while (true) {
    const snap = await ref.collection(subcollectionName).limit(500).get();
    if (snap.empty) break;
    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    if (!dryRun) await batch.commit();
    totalDeleted += snap.docs.length;
    if (verbose) {
      console.log(
        `   · ${subcollectionName}: ${snap.docs.length} docs ${dryRun ? "[DRY]" : "apagados"}`,
      );
    }
    if (snap.docs.length < 500) break;
  }
  return totalDeleted;
}

async function findConversations(pidA, pidB) {
  const found = new Map();

  // Query 1: directConversationKey determinístico
  const key = buildDirectKey(pidA, pidB);
  const byKey = await db
    .collection("conversations")
    .where("directConversationKey", "==", key)
    .get();
  byKey.docs.forEach((d) => found.set(d.id, d));

  // Query 2: scan legacy via participantProfiles array-contains (fallback)
  const byProfileA = await db
    .collection("conversations")
    .where("participantProfiles", "array-contains", pidA)
    .get();

  for (const doc of byProfileA.docs) {
    if (found.has(doc.id)) continue;
    const data = doc.data() || {};
    const profiles = Array.isArray(data.participantProfiles)
      ? data.participantProfiles
      : [];
    if (profiles.length !== 2) continue; // só 1:1
    if (profiles.includes(pidB)) found.set(doc.id, doc);
  }

  return Array.from(found.values());
}

async function main() {
  console.log(`🎯 Projeto: ${projectId}`);
  console.log(
    `🎯 Modo: ${dryRun ? "DRY-RUN (use --yes para executar)" : "EXECUÇÃO REAL"}`,
  );
  console.log("");

  const [pidA, pidB] = await Promise.all([
    resolveProfileId(userA),
    resolveProfileId(userB),
  ]);

  if (!pidA) {
    console.error(`❌ Não foi possível resolver perfil: ${userA}`);
    process.exit(2);
  }
  if (!pidB) {
    console.error(`❌ Não foi possível resolver perfil: ${userB}`);
    process.exit(2);
  }
  if (pidA === pidB) {
    console.error(`❌ Os dois perfis são iguais (${pidA}) — abortando`);
    process.exit(2);
  }

  console.log(`👤 ${userA} → ${pidA}`);
  console.log(`👤 ${userB} → ${pidB}`);
  console.log(`🔑 directConversationKey = ${buildDirectKey(pidA, pidB)}`);
  console.log("");

  const convs = await findConversations(pidA, pidB);
  if (convs.length === 0) {
    console.log("✅ Nenhuma conversa encontrada entre esses perfis.");
    return;
  }

  console.log(`📋 ${convs.length} conversa(s) encontrada(s):`);
  for (const doc of convs) {
    const data = doc.data() || {};
    const created = data.createdAt?.toDate?.()?.toISOString?.() ?? "?";
    const lastMsg =
      data.lastMessageTimestamp?.toDate?.()?.toISOString?.() ?? "?";
    console.log(
      `   • ${doc.id}  (created=${created}, lastMsg=${lastMsg}, lastMessage="${(data.lastMessage || "").slice(0, 40)}")`,
    );
  }
  console.log("");

  let totalMessages = 0;
  for (const doc of convs) {
    console.log(`🗑️  Processando ${doc.id}...`);
    const msgCount = await deleteSubcollection(doc.ref, "messages");
    totalMessages += msgCount;
    if (!dryRun) {
      await doc.ref.delete();
      console.log(`   ✅ conversation doc apagado (${msgCount} messages)`);
    } else {
      console.log(
        `   [DRY] conversation + ${msgCount} messages seriam apagados`,
      );
    }
  }

  console.log("");
  console.log(
    `${dryRun ? "🔍 DRY-RUN" : "✅ CONCLUÍDO"}: ${convs.length} conversas, ${totalMessages} mensagens.`,
  );
}

main().catch((err) => {
  console.error("❌ Erro:", err);
  process.exit(99);
});
