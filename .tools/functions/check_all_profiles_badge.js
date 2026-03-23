const admin = require("firebase-admin");
admin.initializeApp({ projectId: "to-sem-banda-83e19" });
const db = admin.firestore();

async function checkAllProfilesForUid() {
  const uid = "6oOYb7UTnWghXNjepljJ16buKuY2";

  // Buscar todos os perfis deste UID
  const profilesSnapshot = await db
    .collection("profiles")
    .where("uid", "==", uid)
    .get();

  console.log("Profiles for UID " + uid + ":");
  console.log("   Total profiles:", profilesSnapshot.docs.length);

  const now = admin.firestore.Timestamp.now();
  let totalUnread = 0;

  for (const profileDoc of profilesSnapshot.docs) {
    const profileId = profileDoc.id;
    const profileData = profileDoc.data();
    console.log("\n   Profile: " + profileId);
    console.log("   Name: " + profileData.displayName);
    console.log("   Type: " + profileData.profileType);

    // Buscar notificacoes nao lidas para este perfil
    const notifQuery = db
      .collection("notifications")
      .where("recipientProfileId", "==", profileId)
      .where("read", "==", false)
      .where("expiresAt", ">", now)
      .orderBy("expiresAt");

    const notifSnapshot = await notifQuery.get();
    console.log("   Unread notifications: " + notifSnapshot.docs.length);
    totalUnread += notifSnapshot.docs.length;

    notifSnapshot.docs.forEach((doc, i) => {
      const data = doc.data();
      console.log("      " + (i + 1) + ". type=" + data.type);
    });
  }

  console.log("\n=================================");
  console.log("TOTAL UNREAD across all profiles: " + totalUnread);
  console.log("This should be the badge count!");

  process.exit(0);
}

checkAllProfilesForUid();
