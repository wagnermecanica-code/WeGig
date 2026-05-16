// Cleans up orphan connectionRequests in prod:
//  - requests with status=accepted whose connections/{id} doc does NOT exist
//  - requests with status in {cancelled, declined} older than 30d (optional safety)
// Also normalizes profiles missing `allowConnectionRequests` -> true.
//
// Usage: cd .tools/scripts && node cleanup_connection_orphans.js --apply
// Without --apply it only prints the diff.

const admin = require("firebase-admin");
admin.initializeApp({ projectId: "to-sem-banda-83e19" });
const db = admin.firestore();

const APPLY = process.argv.includes("--apply");

function connectionIdFor(a, b) {
  return [a, b].sort().join("__");
}

async function main() {
  console.log(
    APPLY
      ? "🧹 APPLY mode (will write)"
      : "🔍 DRY-RUN mode (no writes). Use --apply to commit.",
  );

  // 1) Orphan accepted requests: accepted but no connections/ doc.
  const accepted = await db
    .collection("connectionRequests")
    .where("status", "==", "accepted")
    .get();
  console.log(`\nAccepted connectionRequests: ${accepted.size}`);
  const orphans = [];
  for (const doc of accepted.docs) {
    const d = doc.data();
    const cid = connectionIdFor(d.requesterProfileId, d.recipientProfileId);
    const cSnap = await db.collection("connections").doc(cid).get();
    if (!cSnap.exists) {
      orphans.push({ id: doc.id, ref: doc.ref, connectionId: cid, data: d });
    }
  }
  console.log(`Orphans (accepted w/o connections): ${orphans.length}`);
  orphans.forEach((o) =>
    console.log(`  - ${o.id} (expected connections/${o.connectionId})`),
  );

  if (APPLY && orphans.length > 0) {
    const batch = db.batch();
    orphans.forEach((o) => batch.delete(o.ref));
    await batch.commit();
    console.log(`✅ Deleted ${orphans.length} orphan requests.`);
  }

  // 2) Profiles missing allowConnectionRequests -> default to true.
  const profiles = await db.collection("profiles").get();
  const missing = [];
  profiles.forEach((doc) => {
    const d = doc.data();
    if (typeof d.allowConnectionRequests !== "boolean") {
      missing.push({ id: doc.id, ref: doc.ref, name: d.name });
    }
  });
  console.log(`\nProfiles missing allowConnectionRequests: ${missing.length}`);
  missing.forEach((m) => console.log(`  - ${m.id} (${m.name})`));

  if (APPLY && missing.length > 0) {
    const batch = db.batch();
    missing.forEach((m) =>
      batch.update(m.ref, {
        allowConnectionRequests: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }),
    );
    await batch.commit();
    console.log(`✅ Normalized ${missing.length} profiles.`);
  }

  // 3) Recompute stats for touched profiles (simple: pendingSent/Received/total).
  if (APPLY) {
    const touchedProfileIds = new Set();
    orphans.forEach((o) => {
      touchedProfileIds.add(o.data.requesterProfileId);
      touchedProfileIds.add(o.data.recipientProfileId);
    });
    for (const pid of touchedProfileIds) {
      const pendingSent = (
        await db
          .collection("connectionRequests")
          .where("requesterProfileId", "==", pid)
          .where("status", "==", "pending")
          .get()
      ).size;
      const pendingReceived = (
        await db
          .collection("connectionRequests")
          .where("recipientProfileId", "==", pid)
          .where("status", "==", "pending")
          .get()
      ).size;
      const total = (
        await db
          .collection("connections")
          .where("profileIds", "array-contains", pid)
          .get()
      ).size;
      await db.collection("connectionStats").doc(pid).set(
        {
          profileId: pid,
          pendingSent,
          pendingReceived,
          totalConnections: total,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      console.log(
        `🔧 Rebuilt stats for ${pid}: sent=${pendingSent} received=${pendingReceived} total=${total}`,
      );
    }
  }

  console.log(APPLY ? "\n✅ Done." : "\nℹ️  Re-run with --apply to commit.");
  process.exit(0);
}

main().catch((e) => {
  console.error("FATAL:", e);
  process.exit(1);
});
