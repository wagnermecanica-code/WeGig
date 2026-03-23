const admin = require("firebase-admin");
admin.initializeApp({ projectId: "to-sem-banda-83e19" });

async function sendAggressiveTestNotification() {
  const token =
    "eGobrZJXTfiwEDZQGN5HLK:APA91bGL3qFFOiymg-aevBFYK6j4Ls97ZgdLx90ppIh3mWmErcIkSej3pjg2dUgGePF-HNYif4E---uBeQ6Y9D4shhhbYyaCB5g_ofoYcsKH-9dwctbKe_o";

  console.log("📤 Enviando notificação AGRESSIVA de teste...");
  console.log("   Token:", token.substring(0, 40) + "...");
  console.log("   Timestamp:", new Date().toISOString());

  try {
    // Método 1: Notification message (mostra automaticamente)
    const result1 = await admin.messaging().send({
      token: token,
      // NOTIFICATION payload - FCM mostra automaticamente
      notification: {
        title: "🔔 TESTE PUSH #1",
        body:
          "Notification payload - " + new Date().toLocaleTimeString("pt-BR"),
      },
      // Android-specific
      android: {
        priority: "high",
        ttl: 0, // Entrega imediata, não armazena
        notification: {
          channelId: "high_importance_channel",
          priority: "max",
          visibility: "public",
          sound: "default",
          defaultVibrateTimings: true,
          notificationCount: 1,
          // Força a exibição mesmo com app em foreground
          // clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
    });
    console.log("✅ Método 1 (notification): Message ID:", result1);

    // Aguardar 2 segundos
    await new Promise((r) => setTimeout(r, 2000));

    // Método 2: Data-only message (processado pelo app)
    const result2 = await admin.messaging().send({
      token: token,
      // DATA-ONLY payload - app processa
      data: {
        type: "test",
        title: "🔔 TESTE PUSH #2",
        body: "Data-only payload - " + new Date().toLocaleTimeString("pt-BR"),
        timestamp: Date.now().toString(),
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
        ttl: 0,
      },
    });
    console.log("✅ Método 2 (data-only): Message ID:", result2);

    // Aguardar 2 segundos
    await new Promise((r) => setTimeout(r, 2000));

    // Método 3: Combined (notification + data)
    const result3 = await admin.messaging().send({
      token: token,
      notification: {
        title: "🔔 TESTE PUSH #3",
        body: "Combined payload - " + new Date().toLocaleTimeString("pt-BR"),
      },
      data: {
        type: "test",
        timestamp: Date.now().toString(),
      },
      android: {
        priority: "high",
        ttl: 0,
        notification: {
          channelId: "high_importance_channel",
          priority: "max",
          sound: "default",
        },
      },
    });
    console.log("✅ Método 3 (combined): Message ID:", result3);

    console.log("\n📱 3 notificações enviadas!");
    console.log("   Se NENHUMA aparecer, o problema é no dispositivo Samsung.");
    console.log("   Verifique: Configurações > Apps > WeGig > Notificações");
    console.log(
      "   E também: Configurações > Bateria > Otimização de bateria > WeGig (Não otimizar)"
    );
  } catch (error) {
    console.log("❌ Erro ao enviar:", error.code, error.message);
    console.log("   Full error:", error);
  }

  process.exit(0);
}

sendAggressiveTestNotification().catch((e) => {
  console.error(e);
  process.exit(1);
});
