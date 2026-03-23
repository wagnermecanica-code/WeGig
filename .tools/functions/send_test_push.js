const admin = require("firebase-admin");
admin.initializeApp({ projectId: "to-sem-banda-83e19" });

async function sendTestNotification() {
  const token =
    "eGobrZJXTfiwEDZQGN5HLK:APA91bGL3qFFOiymg-aevBFYK6j4Ls97ZgdLx90ppIh3mWmErcIkSej3pjg2dUgGePF-HNYif4E---uBeQ6Y9D4shhhbYyaCB5g_ofoYcsKH-9dwctbKe_o";

  console.log("📤 Enviando notificação de teste...");
  console.log("   Token:", token.substring(0, 40) + "...");

  try {
    const result = await admin.messaging().send({
      token: token,
      notification: {
        title: "🎸 Teste Push WeGig",
        body:
          "Se você está vendo isso, as notificações funcionam! " +
          new Date().toLocaleTimeString("pt-BR"),
      },
      data: {
        type: "test",
        timestamp: Date.now().toString(),
      },
      android: {
        priority: "high",
        notification: {
          channelId: "high_importance_channel",
          priority: "max",
          defaultSound: true,
          defaultVibrateTimings: true,
        },
      },
    });

    console.log("✅ Notificação enviada com sucesso!");
    console.log("   Message ID:", result);
  } catch (error) {
    console.log("❌ Erro ao enviar:", error.code, error.message);
  }

  process.exit(0);
}

sendTestNotification().catch((e) => {
  console.error(e);
  process.exit(1);
});
