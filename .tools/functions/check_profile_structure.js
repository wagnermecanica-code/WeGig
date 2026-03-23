const admin = require("firebase-admin");
admin.initializeApp({ projectId: "to-sem-banda-83e19" });
const db = admin.firestore();

async function checkProfileStructure() {
  const profileId = "45HHAPu2xOf2rfiCKlzY";

  console.log("=== Verificando estrutura do perfil ===\n");

  // 1. Buscar o documento do perfil
  const profileDoc = await db.collection("profiles").doc(profileId).get();

  if (!profileDoc.exists) {
    console.log("ERRO: Perfil nao existe!");
    process.exit(1);
  }

  const profileData = profileDoc.data();
  console.log("Profile ID:", profileId);
  console.log("Campos do perfil:");
  console.log("  uid:", profileData.uid || "AUSENTE");
  console.log("  displayName:", profileData.displayName || "AUSENTE");
  console.log("  name:", profileData.name || "AUSENTE");
  console.log("  profileType:", profileData.profileType || "AUSENTE");
  console.log("  email:", profileData.email || "AUSENTE");
  console.log(
    "  createdAt:",
    profileData.createdAt ? String(profileData.createdAt) : "AUSENTE"
  );

  // 2. Verificar se existe documento em users/{uid}
  const uid = profileData.uid;
  if (uid) {
    const userDoc = await db.collection("users").doc(uid).get();
    if (userDoc.exists) {
      const userData = userDoc.data();
      console.log("\n=== Documento users/" + uid + " ===");
      console.log("  activeProfileId:", userData.activeProfileId || "AUSENTE");
      console.log("  email:", userData.email || "AUSENTE");
    } else {
      console.log("\n!!! ATENCAO: Documento users/" + uid + " NAO EXISTE !!!");
      console.log("Isso pode causar problemas no login.");
    }
  }

  // 3. Buscar todos os perfis com esse UID via query
  console.log("\n=== Query profiles.uid == " + uid + " ===");
  const querySnapshot = await db
    .collection("profiles")
    .where("uid", "==", uid)
    .get();
  console.log("Perfis encontrados:", querySnapshot.docs.length);
  querySnapshot.docs.forEach((doc, i) => {
    const data = doc.data();
    console.log(
      "  " +
        (i + 1) +
        ". " +
        doc.id +
        " - " +
        (data.displayName || data.name || "sem nome")
    );
  });

  // 4. Verificar se ha perfil legado em profiles/{uid}
  console.log("\n=== Verificando perfil legado profiles/" + uid + " ===");
  const legacyDoc = await db.collection("profiles").doc(uid).get();
  if (legacyDoc.exists) {
    console.log("Perfil legado EXISTE - pode causar conflito");
    const legacyData = legacyDoc.data();
    console.log("  uid no doc legado:", legacyData.uid || "AUSENTE");
  } else {
    console.log("Perfil legado NAO existe (OK)");
  }

  process.exit(0);
}

checkProfileStructure();
