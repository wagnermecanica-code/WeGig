#!/usr/bin/env node
/**
 * Audit rápido da saúde da feature "Conexões" em prod.
 *
 * Uso:
 *   GOOGLE_APPLICATION_CREDENTIALS=... node audit_connections_logs.js [--hours=24]
 *
 * Saída: contagem agregada por status em connectionRequests, contagem de
 * connections ativas, pendências antigas e tops de requesterProfileId nas
 * últimas N horas. Foco em sinais simples para Fase 11 do roadmap.
 */

const admin = require("firebase-admin");

const args = Object.fromEntries(
  process.argv.slice(2).map((a) => {
    const [k, v] = a.replace(/^--/, "").split("=");
    return [k, v ?? true];
  }),
);

const HOURS = Number(args.hours || 24);

admin.initializeApp({ projectId: "to-sem-banda-83e19" });
const db = admin.firestore();

function iso(ts) {
  try {
    return ts?.toDate?.()?.toISOString() ?? null;
  } catch (_) {
    return null;
  }
}

async function main() {
  const since = new Date(Date.now() - HOURS * 60 * 60 * 1000);
  console.log(
    `\n📊 Audit connections — últimas ${HOURS}h (desde ${since.toISOString()})\n`,
  );

  // ─── connectionRequests por status (janela completa) ─────────────────
  const reqSnap = await db
    .collection("connectionRequests")
    .where("createdAt", ">=", admin.firestore.Timestamp.fromDate(since))
    .get();

  const byStatus = {};
  const byRequester = {};
  let pendingOld = 0;
  const pendingOldCutoff = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
  reqSnap.forEach((d) => {
    const v = d.data();
    byStatus[v.status] = (byStatus[v.status] || 0) + 1;
    if (v.requesterProfileId) {
      byRequester[v.requesterProfileId] =
        (byRequester[v.requesterProfileId] || 0) + 1;
    }
    if (v.status === "pending" && v.createdAt?.toDate?.() < pendingOldCutoff) {
      pendingOld += 1;
    }
  });

  console.log(`🔸 connectionRequests criados na janela: ${reqSnap.size}`);
  Object.entries(byStatus)
    .sort((a, b) => b[1] - a[1])
    .forEach(([s, n]) => console.log(`   - ${s}: ${n}`));

  // pending antigos (toda a coleção, não só janela)
  const pendingAllSnap = await db
    .collection("connectionRequests")
    .where("status", "==", "pending")
    .get();
  let oldestPendingDate = null;
  pendingAllSnap.forEach((d) => {
    const t = d.data().createdAt?.toDate?.();
    if (!t) return;
    if (!oldestPendingDate || t < oldestPendingDate) oldestPendingDate = t;
  });
  console.log(
    `\n🔸 pending totais: ${pendingAllSnap.size}` +
      (oldestPendingDate
        ? ` (mais antigo: ${oldestPendingDate.toISOString()})`
        : ""),
  );
  console.log(`   pending > 7d na janela: ${pendingOld}`);

  // ─── connections ativas ──────────────────────────────────────────────
  const connSnap = await db.collection("connections").count().get();
  console.log(`\n🔸 connections totais: ${connSnap.data().count}`);

  // ─── top requesters ──────────────────────────────────────────────────
  const top = Object.entries(byRequester)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5);
  if (top.length) {
    console.log(`\n🔸 Top 5 requesterProfileId na janela:`);
    top.forEach(([id, n]) => console.log(`   - ${id}: ${n} requests`));
  }

  // ─── rateLimits (se existir coleção) ─────────────────────────────────
  try {
    const rlSnap = await db
      .collection("rateLimits")
      .where("updatedAt", ">=", admin.firestore.Timestamp.fromDate(since))
      .limit(50)
      .get();
    const blocked = rlSnap.docs.filter((d) => d.data().blocked === true).length;
    console.log(
      `\n🔸 rateLimits docs atualizados na janela: ${rlSnap.size} (blocked=${blocked})`,
    );
  } catch (e) {
    console.log(
      `\n⚠️  rateLimits query falhou (índice faltando?): ${e.code || e.message}`,
    );
  }

  console.log("\n✅ Audit concluído.\n");
}

main().catch((e) => {
  console.error("❌ audit falhou:", e);
  process.exit(1);
});
