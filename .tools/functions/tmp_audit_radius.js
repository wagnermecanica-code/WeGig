const admin = require("firebase-admin");
admin.initializeApp({ projectId: "to-sem-banda-83e19" });
const db = admin.firestore();

(async () => {
  const profiles = await db.collection("profiles").get();
  let total = 0;
  let missingRadius = 0;
  let invalidRadius = 0;
  let disabled = 0;
  let sample = 0;

  profiles.forEach((doc) => {
    total++;
    const d = doc.data() || {};
    const radius = d.notificationRadius;
    if (d.notificationRadiusEnabled === false) disabled++;
    if (radius === undefined || radius === null) {
      missingRadius++;
      return;
    }
    const r = Number(radius);
    if (Number.isNaN(r) || r <= 0) {
      invalidRadius++;
    }
  });

  console.log("profiles:", total);
  console.log("missingRadius:", missingRadius);
  console.log("invalidRadius:", invalidRadius);
  console.log("nearbyDisabled:", disabled);

  const sampleSnap = await db.collection("profiles").limit(5).get();
  sampleSnap.forEach((doc) => {
    if (sample >= 5) return;
    const d = doc.data() || {};
    console.log(
      "sample",
      doc.id,
      "radius=",
      d.notificationRadius,
      "enabled=",
      d.notificationRadiusEnabled,
    );
    sample++;
  });

  process.exit(0);
})();
