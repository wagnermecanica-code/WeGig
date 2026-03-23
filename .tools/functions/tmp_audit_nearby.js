const admin = require("firebase-admin");
admin.initializeApp({ projectId: "to-sem-banda-83e19" });
const db = admin.firestore();

(async () => {
  const profiles = await db.collection("profiles").get();
  let missingUid = 0;
  let missingLocation = 0;
  let disabledNearby = 0;

  profiles.forEach((doc) => {
    const d = doc.data() || {};
    if (!d.uid) missingUid++;
    if (
      !d.location ||
      (d.location._latitude === undefined && d.location.latitude === undefined)
    ) {
      missingLocation++;
    }
    if (d.notificationRadiusEnabled === false) disabledNearby++;
  });

  console.log(
    "profiles:",
    profiles.size,
    "missingUid:",
    missingUid,
    "missingLocation:",
    missingLocation,
    "nearbyDisabled:",
    disabledNearby,
  );

  const nearbyNotifs = await db
    .collection("notifications")
    .where("type", "==", "nearbyPost")
    .get();
  let missingRecipientUid = 0;
  nearbyNotifs.forEach((doc) => {
    const d = doc.data() || {};
    if (!d.recipientUid) missingRecipientUid++;
  });

  console.log(
    "nearbyPost notifications:",
    nearbyNotifs.size,
    "missingRecipientUid:",
    missingRecipientUid,
  );
  process.exit(0);
})();
