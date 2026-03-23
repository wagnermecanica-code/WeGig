const admin = require("firebase-admin");
admin.initializeApp({ projectId: "to-sem-banda-83e19" });
const db = admin.firestore();

async function checkTokens() {
  const profileId = "45HHAPu2xOf2rfiCKlzY";

  // Verificar fcmTokens (camelCase)
  const tokensSnap = await db
    .collection("profiles")
    .doc(profileId)
    .collection("fcmTokens")
    .get();
  console.log("📱 fcmTokens (camelCase):", tokensSnap.size, "tokens");

  if (tokensSnap.size > 0) {
    tokensSnap.docs.forEach((doc, i) => {
      const data = doc.data();
      console.log(`   Token ${i + 1}: ${doc.id.substring(0, 40)}...`);
      console.log(`      Platform: ${data.platform || "N/A"}`);
      console.log(`      Updated: ${data.updatedAt?.toDate?.() || "N/A"}`);
    });
  }

  // Verificar fcm_tokens (snake_case)
  const tokensSnap2 = await db
    .collection("profiles")
    .doc(profileId)
    .collection("fcm_tokens")
    .get();
  console.log("\n📱 fcm_tokens (snake_case):", tokensSnap2.size, "tokens");

  // Listar todas as subcoleções do perfil
  const profileRef = db.collection("profiles").doc(profileId);
  const collections = await profileRef.listCollections();
  console.log("\n📁 Subcoleções do perfil:");
  for (const col of collections) {
    const snap = await col.get();
    console.log("   -", col.id + ":", snap.size, "docs");
  }

  process.exit(0);
}

checkTokens().catch((e) => {
  console.error(e);
  process.exit(1);
});
