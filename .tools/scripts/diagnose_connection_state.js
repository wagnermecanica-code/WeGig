const admin = require("firebase-admin");
admin.initializeApp({ projectId: "to-sem-banda-83e19" });
const db = admin.firestore();

const REQUESTER = "mmF1dAKequGIinIG1ycY";
const RECIPIENT = "Co4uGwnY18rCbQhTKqoe";

async function main() {
  console.log("🔎 All requests where requesterProfileId=", REQUESTER);
  const a = await db
    .collection("connectionRequests")
    .where("requesterProfileId", "==", REQUESTER)
    .get();
  console.log(`   ${a.size} doc(s)`);
  a.forEach((d) =>
    console.log(
      "   -",
      d.id,
      "→",
      d.data().recipientProfileId,
      "status=",
      d.data().status,
      "createdAt=",
      d.data().createdAt?.toDate?.().toISOString(),
    ),
  );

  console.log("\n🔎 All requests involving RECIPIENT", RECIPIENT);
  const b = await db
    .collection("connectionRequests")
    .where("recipientProfileId", "==", RECIPIENT)
    .get();
  const c = await db
    .collection("connectionRequests")
    .where("requesterProfileId", "==", RECIPIENT)
    .get();
  console.log(`   as recipient: ${b.size}, as requester: ${c.size}`);

  console.log("\n🔎 connectionStats for requester:");
  const s1 = await db.collection("connectionStats").doc(REQUESTER).get();
  console.log("   exists=", s1.exists, "data=", s1.data());

  console.log("\n🔎 connectionStats for recipient:");
  const s2 = await db.collection("connectionStats").doc(RECIPIENT).get();
  console.log("   exists=", s2.exists, "data=", s2.data());

  console.log("\n🔎 connections involving either:");
  const conns = await db
    .collection("connections")
    .where("profileIds", "array-contains", REQUESTER)
    .get();
  console.log(`   requester in ${conns.size} connection(s)`);
  conns.forEach((d) =>
    console.log("   -", d.id, "profileIds=", d.data().profileIds),
  );

  console.log("\n🔎 blocks involving either:");
  const blocks = await db
    .collection("blocks")
    .where("profileIds", "array-contains", REQUESTER)
    .get();
  console.log(`   ${blocks.size} block(s) involving requester`);
  blocks.forEach((d) =>
    console.log("   -", d.id, "profileIds=", d.data().profileIds),
  );

  // Check App Check enforcement for Firestore
  console.log("\n📋 Latest 10 connectionRequests (any):");
  const latest = await db
    .collection("connectionRequests")
    .orderBy("createdAt", "desc")
    .limit(10)
    .get();
  console.log(`   ${latest.size} doc(s)`);
  latest.forEach((d) => {
    const x = d.data();
    console.log(
      `   - ${d.id} [${x.status}] ${x.requesterProfileId}→${x.recipientProfileId} @ ${x.createdAt?.toDate?.().toISOString()}`,
    );
  });

  process.exit(0);
}
main().catch((e) => {
  console.error(e);
  process.exit(1);
});
