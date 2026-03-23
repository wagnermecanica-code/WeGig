const admin = require("firebase-admin");
admin.initializeApp({ projectId: "to-sem-banda-83e19" });
const db = admin.firestore();

async function findRecentToken() {
  const profileId = "45HHAPu2xOf2rfiCKlzY";

  // O token do seu app começa com eGobrZJXTfiwEDZQGN5HLK
  const yourTokenPrefix = "eGobrZJXTfiwEDZQGN5HLK";

  const tokensSnap = await db
    .collection("profiles")
    .doc(profileId)
    .collection("fcmTokens")
    .get();

  console.log("📱 Buscando seu token (começa com eGobrZJXTfiwEDZQGN5HLK):\n");

  let found = null;
  tokensSnap.docs.forEach((doc) => {
    if (doc.id.startsWith(yourTokenPrefix)) {
      found = {
        token: doc.id,
        data: doc.data(),
      };
    }
  });

  if (found) {
    console.log("✅ Encontrado!");
    console.log("   Token COMPLETO:", found.token);
    console.log("   Platform:", found.data.platform);
    console.log("   Updated:", found.data.updatedAt?.toDate?.());

    // Verificar se este token é válido
    console.log("\n🔍 Verificando se o token é válido no FCM...");
    try {
      const result = await admin.messaging().send(
        {
          token: found.token,
          data: { test: "ping" },
          android: {
            priority: "high",
          },
        },
        true
      ); // dry_run = true (não envia de fato)
      console.log("✅ Token VÁLIDO! DryRun result:", result);
    } catch (error) {
      console.log("❌ Token INVÁLIDO:", error.code, error.message);
    }
  } else {
    console.log("❌ Token não encontrado!");
  }

  process.exit(0);
}

findRecentToken().catch((e) => {
  console.error(e);
  process.exit(1);
});
