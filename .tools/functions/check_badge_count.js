const admin = require("firebase-admin");
admin.initializeApp({ projectId: "to-sem-banda-83e19" });
const db = admin.firestore();

async function checkNotifications() {
  const profileId = "45HHAPu2xOf2rfiCKlzY";

  // Primeiro, buscar o UID associado a este perfil
  const profileDoc = await db.collection("profiles").doc(profileId).get();
  const uid = profileDoc.data().uid;
  console.log("Profile:", profileId);
  console.log("UID:", uid);

  if (!uid) {
    console.log("UID nao encontrado");
    process.exit(1);
  }

  // ========================================
  // QUERY 1: Como o Cloud Function faz (getUnreadBadgeCount)
  // ========================================
  const now = admin.firestore.Timestamp.now();

  const cfQuery = db
    .collection("notifications")
    .where("recipientProfileId", "==", profileId)
    .where("read", "==", false)
    .where("expiresAt", ">", now)
    .orderBy("expiresAt");

  const cfSnapshot = await cfQuery.get();
  console.log("\n[Cloud Function query - by recipientProfileId]:");
  console.log("   Count:", cfSnapshot.docs.length);

  cfSnapshot.docs.forEach((doc, i) => {
    const data = doc.data();
    console.log(
      "   " +
        (i + 1) +
        ". type=" +
        data.type +
        " expiresAt=" +
        data.expiresAt.toDate()
    );
  });

  // ========================================
  // QUERY 2: Como o Flutter faz (updateAppBadge)
  // ========================================
  const flutterQuery = db
    .collection("notifications")
    .where("recipientUid", "==", uid)
    .where("read", "==", false);

  const flutterSnapshot = await flutterQuery.get();
  console.log("\n[Flutter query - by recipientUid]:");
  console.log("   Count:", flutterSnapshot.docs.length);

  let validForProfile = 0;
  flutterSnapshot.docs.forEach((doc, i) => {
    const data = doc.data();
    const expiresAt = data.expiresAt;
    const isExpired = expiresAt && expiresAt.toMillis() < now.toMillis();
    const matchesProfile = data.recipientProfileId === profileId;

    if (matchesProfile && !isExpired) validForProfile++;

    console.log(
      "   " + (i + 1) + ". recipientProfileId=" + data.recipientProfileId
    );
    console.log(
      "      matches=" +
        matchesProfile +
        " expired=" +
        isExpired +
        " type=" +
        data.type
    );
  });

  console.log("   Valid for this profile (after filter):", validForProfile);

  // ========================================
  // QUERY 3: TODAS notificacoes nao lidas (sem filtro de perfil)
  // ========================================
  const allUnreadQuery = db
    .collection("notifications")
    .where("read", "==", false)
    .limit(20);

  const allUnreadSnapshot = await allUnreadQuery.get();
  console.log("\n[All unread notifications - first 20]:");
  console.log("   Count:", allUnreadSnapshot.docs.length);

  allUnreadSnapshot.docs.forEach((doc, i) => {
    const data = doc.data();
    console.log(
      "   " +
        (i + 1) +
        ". recipientProfileId=" +
        data.recipientProfileId +
        " type=" +
        data.type
    );
  });

  process.exit(0);
}

checkNotifications();
