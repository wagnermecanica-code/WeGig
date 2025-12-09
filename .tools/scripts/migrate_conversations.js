#!/usr/bin/env node
/**
 * Script de Migração: Conversas
 *
 * Este script garante que todas as conversas tenham o campo `participants`
 * corretamente preenchido com UIDs do Firebase Auth.
 *
 * Estrutura esperada após migração:
 * - participants: [uid1, uid2] - UIDs do Firebase Auth (obrigatório para regras)
 * - profileUid: [uid1, uid2] - Cópia de participants (legado, mantido para compatibilidade)
 * - participantProfiles: [profileId1, profileId2] - IDs dos perfis
 *
 * Uso:
 *   cd .tools/scripts
 *   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
 *   node migrate_conversations.js --project wegig-dev [--dry-run]
 *
 * Ou usar firebase login e depois:
 *   npx firebase-tools firestore:delete --help  (para verificar auth)
 *   node migrate_conversations.js --project wegig-dev [--dry-run]
 *
 * Flags:
 *   --project <id>  : ID do projeto Firebase (obrigatório)
 *   --dry-run       : Apenas simula, não faz alterações
 *   --verbose       : Mostra detalhes de cada documento
 */

const {
  initializeApp,
  cert,
  applicationDefault,
} = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

// Parse arguments
const args = process.argv.slice(2);
const projectIndex = args.indexOf("--project");
const projectId = projectIndex !== -1 ? args[projectIndex + 1] : null;
const dryRun = args.includes("--dry-run");
const verbose = args.includes("--verbose");

if (!projectId) {
  console.error("❌ Erro: --project <id> é obrigatório");
  console.error(
    "Uso: node migrate_conversations.js --project wegig-dev [--dry-run] [--verbose]"
  );
  process.exit(1);
}

console.log(`\n🔧 Migração de Conversas - WeGig`);
console.log(`📦 Projeto: ${projectId}`);
console.log(
  `🧪 Dry Run: ${
    dryRun
      ? "SIM (nenhuma alteração será feita)"
      : "NÃO (alterações serão aplicadas)"
  }`
);
console.log(`📝 Verbose: ${verbose ? "SIM" : "NÃO"}\n`);

// Inicializar Firebase Admin usando ADC ou service account
let app;
try {
  // Tenta usar Application Default Credentials
  app = initializeApp({
    projectId: projectId,
  });
} catch (error) {
  console.error("❌ Erro ao inicializar Firebase:", error.message);
  console.error(
    "   Certifique-se de estar autenticado com: gcloud auth application-default login"
  );
  process.exit(1);
}

const db = getFirestore(app);

async function migrateConversations() {
  console.log("📂 Buscando todas as conversas...\n");

  const conversationsRef = db.collection("conversations");
  const snapshot = await conversationsRef.get();

  if (snapshot.empty) {
    console.log("✅ Nenhuma conversa encontrada. Nada a migrar.");
    return;
  }

  console.log(`📊 Total de conversas: ${snapshot.size}\n`);

  let needsMigration = 0;
  let alreadyOk = 0;
  let errors = 0;
  let migrated = 0;

  const batch = db.batch();
  let batchCount = 0;
  const MAX_BATCH_SIZE = 500;

  // Usar WriteBatch separado para cada lote
  let currentBatch = db.batch();
  let currentBatchCount = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const docId = doc.id;

    // Verificar se já tem participants válido
    const hasParticipants =
      Array.isArray(data.participants) && data.participants.length >= 2;
    const hasProfileUid =
      Array.isArray(data.profileUid) && data.profileUid.length >= 2;
    const hasParticipantProfiles =
      Array.isArray(data.participantProfiles) &&
      data.participantProfiles.length >= 2;

    if (verbose) {
      console.log(`📄 ${docId}:`);
      console.log(
        `   participants: ${
          hasParticipants ? data.participants.join(", ") : "❌ MISSING"
        }`
      );
      console.log(
        `   profileUid: ${
          hasProfileUid ? data.profileUid.join(", ") : "❌ MISSING"
        }`
      );
      console.log(
        `   participantProfiles: ${
          hasParticipantProfiles
            ? data.participantProfiles.join(", ")
            : "❌ MISSING"
        }`
      );
    }

    // Se já tem participants válido, pular
    if (hasParticipants) {
      alreadyOk++;
      if (verbose) console.log(`   ✅ OK\n`);
      continue;
    }

    // Precisa migrar - tentar inferir participants de profileUid ou participantProfiles
    needsMigration++;

    let newParticipants = null;

    // Opção 1: Usar profileUid diretamente (se existir e for UIDs)
    if (hasProfileUid) {
      // profileUid deve conter UIDs do Auth
      newParticipants = data.profileUid;
      if (verbose) console.log(`   🔄 Usando profileUid como participants`);
    }
    // Opção 2: Buscar UIDs dos perfis via participantProfiles
    else if (hasParticipantProfiles) {
      if (verbose)
        console.log(`   🔍 Buscando UIDs via participantProfiles...`);

      try {
        const uids = [];
        for (const profileId of data.participantProfiles) {
          const profileDoc = await db
            .collection("profiles")
            .doc(profileId)
            .get();
          if (profileDoc.exists) {
            const uid = profileDoc.data().uid;
            if (uid) {
              uids.push(uid);
            } else {
              console.warn(`   ⚠️ Perfil ${profileId} não tem UID`);
            }
          } else {
            console.warn(`   ⚠️ Perfil ${profileId} não encontrado`);
          }
        }

        if (uids.length >= 2) {
          newParticipants = uids;
        } else {
          console.error(
            `   ❌ Não foi possível obter UIDs suficientes para ${docId}`
          );
          errors++;
          continue;
        }
      } catch (err) {
        console.error(
          `   ❌ Erro ao buscar perfis para ${docId}: ${err.message}`
        );
        errors++;
        continue;
      }
    } else {
      console.error(`   ❌ ${docId}: Não tem dados suficientes para migrar`);
      errors++;
      continue;
    }

    // Aplicar migração
    if (newParticipants && newParticipants.length >= 2) {
      const updateData = {
        participants: newParticipants,
      };

      // Também garantir que profileUid existe (para compatibilidade)
      if (!hasProfileUid) {
        updateData.profileUid = newParticipants;
      }

      if (verbose) {
        console.log(
          `   📝 Atualizando: participants = [${newParticipants.join(", ")}]`
        );
      }

      if (!dryRun) {
        currentBatch.update(doc.ref, updateData);
        currentBatchCount++;

        // Commit batch se atingir limite
        if (currentBatchCount >= MAX_BATCH_SIZE) {
          await currentBatch.commit();
          console.log(
            `   💾 Batch de ${currentBatchCount} documentos commitado`
          );
          currentBatch = db.batch();
          currentBatchCount = 0;
        }
      }

      migrated++;
      if (verbose) console.log(`   ✅ Migrado\n`);
    }
  }

  // Commit batch final
  if (!dryRun && currentBatchCount > 0) {
    await currentBatch.commit();
    console.log(`💾 Batch final de ${currentBatchCount} documentos commitado`);
  }

  // Resumo
  console.log(`\n${"=".repeat(50)}`);
  console.log(`📊 RESUMO DA MIGRAÇÃO`);
  console.log(`${"=".repeat(50)}`);
  console.log(`📄 Total de conversas: ${snapshot.size}`);
  console.log(`✅ Já estavam OK: ${alreadyOk}`);
  console.log(`🔄 Precisavam migrar: ${needsMigration}`);
  console.log(`✅ Migradas com sucesso: ${migrated}`);
  console.log(`❌ Erros: ${errors}`);

  if (dryRun) {
    console.log(`\n⚠️  DRY RUN - Nenhuma alteração foi feita.`);
    console.log(`   Execute sem --dry-run para aplicar as alterações.`);
  } else if (migrated > 0) {
    console.log(`\n✅ Migração concluída com sucesso!`);
  }
}

// Executar
migrateConversations()
  .then(() => {
    console.log("\n🏁 Script finalizado.\n");
    process.exit(0);
  })
  .catch((error) => {
    console.error("\n❌ Erro fatal:", error);
    process.exit(1);
  });
