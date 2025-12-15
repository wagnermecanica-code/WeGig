/**
 * Script Node.js para deletar notificações duplicadas type='interest'
 *
 * Execução: node scripts/delete_interest_notifications_simple.js
 */

const admin = require("firebase-admin");

// Inicializar Firebase Admin com credenciais do projeto
admin.initializeApp({
  projectId: "to-sem-banda-83e19",
});

const db = admin.firestore();

async function deleteInterestNotifications() {
  console.log(
    "═══════════════════════════════════════════════════════════════"
  );
  console.log('🧹 DELETANDO NOTIFICAÇÕES DUPLICADAS type="interest"');
  console.log(
    "═══════════════════════════════════════════════════════════════\n"
  );

  try {
    // Buscar todas as notificações com type='interest'
    console.log("📋 Buscando notificações...\n");

    const snapshot = await db
      .collection("notifications")
      .where("type", "==", "interest")
      .get();

    const totalFound = snapshot.size;

    if (totalFound === 0) {
      console.log('✅ Nenhuma notificação type="interest" encontrada!');
      console.log("   O Firestore já está limpo.\n");
      console.log(
        "═══════════════════════════════════════════════════════════════"
      );
      process.exit(0);
    }

    console.log(`📊 Encontradas ${totalFound} notificações type="interest"\n`);
    console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    console.log("LISTAGEM DAS NOTIFICAÇÕES A SEREM DELETADAS:");
    console.log(
      "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    );

    // Listar todas
    snapshot.docs.forEach((doc, index) => {
      const data = doc.data();
      console.log(`${index + 1}. ID: ${doc.id}`);
      console.log(`   Recipient: ${data.recipientProfileId}`);
      console.log(`   Created: ${data.createdAt?.toDate()}`);
      console.log(`   Read: ${data.read}\n`);
    });

    console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    console.log("🔥 INICIANDO DELEÇÃO...\n");

    // Deletar em batches de 500 (limite do Firestore)
    const batchSize = 500;
    let deletedCount = 0;

    for (let i = 0; i < snapshot.docs.length; i += batchSize) {
      const batch = db.batch();
      const end = Math.min(i + batchSize, snapshot.docs.length);

      for (let j = i; j < end; j++) {
        batch.delete(snapshot.docs[j].ref);
      }

      await batch.commit();
      deletedCount += end - i;

      console.log(
        `✅ Batch ${Math.floor(i / batchSize) + 1}: ${
          end - i
        } notificações deletadas`
      );
      console.log(`   Progresso: ${deletedCount}/${totalFound}\n`);
    }

    console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    console.log("✅ LIMPEZA CONCLUÍDA COM SUCESSO!");
    console.log(
      "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    );
    console.log("📊 RESUMO:");
    console.log(
      `   Total deletado: ${deletedCount} notificações type="interest"`
    );
    console.log(
      '   Collection "notifications" agora contém apenas notificações válidas'
    );
    console.log('   Collection "interests" permanece intacta\n');
    console.log("🎯 RESULTADO:");
    console.log(
      "   Badge counter agora contará apenas interests da collection correta"
    );
    console.log("   Sem duplicação!\n");
    console.log(
      "═══════════════════════════════════════════════════════════════"
    );

    process.exit(0);
  } catch (error) {
    console.error("❌ ERRO:", error);
    process.exit(1);
  }
}

// Executar
deleteInterestNotifications();
