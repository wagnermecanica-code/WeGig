const admin = require("firebase-admin");

// Usar Application Default Credentials
admin.initializeApp({
  projectId: "to-sem-banda-83e19",
});

const db = admin.firestore();

async function findNewestAndroidToken() {
  try {
    const profileId = "45HHAPu2xOf2rfiCKlzY";
    // Buscar todos tokens e filtrar manualmente (evita necessidade de índice)
    const snapshot = await db
      .collection("profiles")
      .doc(profileId)
      .collection("fcmTokens")
      .get();

    // Filtrar Android e ordenar por updatedAt
    const androidTokens = snapshot.docs
      .filter((doc) => doc.data().platform === "android")
      .map((doc) => ({
        id: doc.id,
        updatedAt: doc.data().updatedAt?.toDate() || new Date(0),
      }))
      .sort((a, b) => b.updatedAt - a.updatedAt)
      .slice(0, 5);

    console.log("📱 5 tokens Android mais recentes:\n");
    let i = 0;
    for (const token of androidTokens) {
      i++;
      console.log(`  ${i}. ${token.id}`);
      console.log(`     Updated: ${token.updatedAt}\n`);
    }

    if (androidTokens.length > 0) {
      const newest = androidTokens[0];
      console.log("\n🔥 TOKEN MAIS RECENTE PARA TESTAR:");
      console.log(newest.id);
    }
  } catch (error) {
    console.error("Erro:", error.message);
    if (
      error.message.includes("application-default") ||
      error.message.includes("Could not load the default credentials")
    ) {
      console.log("\n💡 Execute: gcloud auth application-default login");
    }
  }

  process.exit(0);
}

findNewestAndroidToken();
