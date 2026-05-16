// Diagnose a specific connection request + both profiles + auth uid match.
// Usage:
//   cd .tools/scripts
//   node diagnose_connection_request.js
// Requires: gcloud auth application-default login && project = to-sem-banda-83e19

const admin = require("firebase-admin");

admin.initializeApp({ projectId: "to-sem-banda-83e19" });
const db = admin.firestore();
const auth = admin.auth();

const REQUEST_ID = "mmF1dAKequGIinIG1ycY_Co4uGwnY18rCbQhTKqoe";
const REQUESTER_PROFILE_ID = "mmF1dAKequGIinIG1ycY";
const RECIPIENT_PROFILE_ID = "Co4uGwnY18rCbQhTKqoe";

async function main() {
  console.log("==========================================================");
  console.log("CONNECTION REQUEST DIAGNOSIS");
  console.log("==========================================================\n");

  // 1. The request doc
  console.log(`📄 connectionRequests/${REQUEST_ID}`);
  const reqSnap = await db
    .collection("connectionRequests")
    .doc(REQUEST_ID)
    .get();
  if (!reqSnap.exists) {
    console.log("   ❌ NOT FOUND");
  } else {
    const d = reqSnap.data();
    console.log("   requesterProfileId:", d.requesterProfileId);
    console.log("   requesterUid      :", d.requesterUid);
    console.log("   recipientProfileId:", d.recipientProfileId);
    console.log("   recipientUid      :", d.recipientUid);
    console.log("   recipientName     :", d.recipientName);
    console.log("   status            :", d.status);
    console.log(
      "   createdAt         :",
      d.createdAt?.toDate?.().toISOString(),
    );
  }

  // 2. Requester profile
  console.log(`\n👤 profiles/${REQUESTER_PROFILE_ID} (requester — @teste1)`);
  const a = await db.collection("profiles").doc(REQUESTER_PROFILE_ID).get();
  if (!a.exists) console.log("   ❌ NOT FOUND");
  else {
    const d = a.data();
    console.log("   uid     :", d.uid);
    console.log("   name    :", d.name);
    console.log("   username:", d.username);
    console.log("   allowConnectionRequests:", d.allowConnectionRequests);
  }

  // 3. Recipient profile — THE KEY ONE
  console.log(`\n👤 profiles/${RECIPIENT_PROFILE_ID} (recipient — @wagner)`);
  const b = await db.collection("profiles").doc(RECIPIENT_PROFILE_ID).get();
  let recipientUidFromProfile = null;
  if (!b.exists) console.log("   ❌ NOT FOUND");
  else {
    const d = b.data();
    recipientUidFromProfile = d.uid;
    console.log("   uid     :", d.uid);
    console.log("   name    :", d.name);
    console.log("   username:", d.username);
    console.log("   allowConnectionRequests:", d.allowConnectionRequests);
  }

  // 4. users/{uid} cross-check — resolves the uid actually used by @wagner
  if (recipientUidFromProfile) {
    console.log(`\n🔐 users/${recipientUidFromProfile}`);
    const u = await db.collection("users").doc(recipientUidFromProfile).get();
    if (!u.exists)
      console.log(
        "   ❌ users doc NOT FOUND for uid in profile → uid is likely stale",
      );
    else console.log("   exists, email:", u.data().email || "(no email field)");

    try {
      const authUser = await auth.getUser(recipientUidFromProfile);
      console.log(
        "   Auth record OK. email:",
        authUser.email,
        "| providers:",
        authUser.providerData.map((p) => p.providerId).join(","),
      );
    } catch (e) {
      console.log(
        "   ❌ Auth.getUser FAILED — uid does not exist in Firebase Auth:",
        e.code,
      );
    }
  }

  // 5. All profiles that claim to be @wagner (or owned by any uid that has that email)
  console.log(
    `\n🔎 All profiles owned by uid in profile (${recipientUidFromProfile}):`,
  );
  if (recipientUidFromProfile) {
    const owned = await db
      .collection("profiles")
      .where("uid", "==", recipientUidFromProfile)
      .get();
    owned.forEach((doc) => {
      console.log(
        `   - ${doc.id}: name="${doc.data().name}" username="${doc.data().username}"`,
      );
    });
  }

  // 6. Any connectionRequests whose recipientProfileId == recipient — what does @wagner see?
  console.log(
    `\n📥 Pending requests where recipientProfileId=${RECIPIENT_PROFILE_ID}:`,
  );
  const pend = await db
    .collection("connectionRequests")
    .where("recipientProfileId", "==", RECIPIENT_PROFILE_ID)
    .where("status", "==", "pending")
    .get();
  console.log(`   ${pend.size} doc(s) found`);
  pend.forEach((doc) => {
    const d = doc.data();
    console.log(
      `   - ${doc.id}: recipientUid=${d.recipientUid} requesterProfileId=${d.requesterProfileId}`,
    );
  });

  console.log("\n==========================================================");
  console.log("VERDICT");
  console.log("==========================================================");

  const req = reqSnap.exists ? reqSnap.data() : null;
  const profile = b.exists ? b.data() : null;
  if (req && profile) {
    if (req.recipientUid === profile.uid) {
      console.log("✅ recipientUid in request MATCHES profile.uid");
      console.log(
        "   → If @wagner still does not see it, check which uid his device is logged in as.",
      );
    } else {
      console.log("❌ MISMATCH:");
      console.log(`   request.recipientUid  = ${req.recipientUid}`);
      console.log(`   profile.uid           = ${profile.uid}`);
      console.log(
        "   → @wagner's query filters by his current authUid and will not find the doc.",
      );
    }
  }

  process.exit(0);
}

main().catch((e) => {
  console.error("FATAL:", e);
  process.exit(1);
});
