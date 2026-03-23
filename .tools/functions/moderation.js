"use strict";

const functions = require("firebase-functions");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const OBJECTIONABLE_WORDS = [
  // Profanity / sexual terms (PT-BR)
  "porra",
  "caralho",
  "cacete",
  "merda",
  "bosta",
  "foder",
  "foda",
  "fodase",
  "foda-se",
  "puta",
  "puto",
  "cu",
  "cuzao",
  "cuzao",
  "pau no cu",
  "pau nocu",
  "vai tomar no cu",
  "vai tomar nocu",
  "vai se foder",
  "vai se foda",
  "vai se fodar",
  "vai se foder",
  "filho da puta",
  "filhodaputa",
  "vai se arrombar",
  "arrombar",
  "buceta",
  "xota",
  "xoxota",
  "bucetinha",
  "xotinha",
  "chupeta",
  "chupeta",
  "chupa",
  "chupando",
  "viado",
  "veado",
  "bicha",
  "bixa",
  "pau",
  "rola",
  "rabo",
  "bundal",
  "bundao",
  "bundão",
  "pepeca",
  "pepecinha",
  "tesão",
  "tesao",
  "gozar",
  "gozada",
  "ejacular",
  "pinto",
  "piranha",
  // Common insults (minimal)
  "vadia",
  "burra",
  "burro",
  "otaria",
  "otario",
  "arrombado",
  "babaca",
  "besta",
  "bobo",
  "cretina",
  "cretino",
  "idiota",
  "imbecil",
  "imbecil",
  "mané",
  "mane",
  "palhaça",
  "palhaca",
  "palhaço",
  "desgraça",
  "desgraca",
  "idiota",
  "imbecil",
];

function escapeRegExp(value) {
  return String(value).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function normalizeText(input) {
  const raw = typeof input === "string" ? input : "";
  if (!raw.trim()) return "";

  // Lowercase + strip diacritics (NFD).
  let s = raw
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "");

  // Basic leetspeak normalization.
  s = s
    .replace(/0/g, "o")
    .replace(/1/g, "i")
    .replace(/3/g, "e")
    .replace(/4/g, "a")
    .replace(/5/g, "s")
    .replace(/7/g, "t");

  // Collapse whitespace.
  s = s.replace(/\s+/g, " ").trim();
  return s;
}

function smashed(input) {
  const s = normalizeText(input);
  if (!s) return "";

  try {
    return s.replace(/[^\p{L}\p{N}]+/gu, "").slice(0, 5000);
  } catch (_) {
    return s.replace(/[^a-z0-9]+/g, "").slice(0, 5000);
  }
}

function findObjectionableMatches(input) {
  const s = normalizeText(input);
  if (!s) return [];

  const matches = [];

  for (const word of OBJECTIONABLE_WORDS) {
    const w = normalizeText(word);
    if (!w) continue;

    let boundary;
    try {
      boundary = new RegExp(
        `(^|[^\\p{L}\\p{N}])${escapeRegExp(w)}($|[^\\p{L}\\p{N}])`,
        "iu"
      );
    } catch (_) {
      boundary = new RegExp(
        `(^|[^a-z0-9])${escapeRegExp(w)}($|[^a-z0-9])`,
        "i"
      );
    }

    if (boundary.test(s)) {
      matches.push(word);
    }
  }

  const sm = smashed(s);
  if (sm) {
    for (const word of OBJECTIONABLE_WORDS) {
      const w = smashed(word);
      if (w.length < 4) continue;

      if (sm.includes(w) && !matches.includes(word)) {
        matches.push(word);
      }
    }
  }

  return matches;
}

exports.moderateObjectionablePosts = functions
  .region("southamerica-east1")
  .firestore.document("posts/{postId}")
  .onWrite(async (change, context) => {
    if (!change.after.exists) return null;

    const after = change.after.data() || {};
    const alreadyFlagged = after?.moderation?.objectionable === true;
    if (alreadyFlagged) return null;

    const title = after.title || "";
    const content = after.content || "";
    const text = `${title}\n${content}`;

    const matches = findObjectionableMatches(text);
    if (matches.length === 0) return null;

    console.log(
      `🧹 [MODERATION] posts/${
        context.params.postId
      } flagged objectionable: ${matches.join(", ")}`
    );

    try {
      await change.after.ref.update({
        "moderation.objectionable": true,
        "moderation.objectionableMatches": matches,
        "moderation.objectionableUpdatedAt":
          admin.firestore.FieldValue.serverTimestamp(),
        // Hide from feeds that require expiresAt > now.
        expiresAt: admin.firestore.Timestamp.fromMillis(0),
      });
    } catch (error) {
      console.error(
        `❌ [MODERATION] posts/${context.params.postId} update failed: ${error}`
      );
    }

    return null;
  });

exports.sanitizeObjectionableProfileBio = functions
  .region("southamerica-east1")
  .firestore.document("profiles/{profileId}")
  .onWrite(async (change, context) => {
    if (!change.after.exists) return null;

    const after = change.after.data() || {};
    const bio = after.bio || "";

    if (!bio || typeof bio !== "string") return null;

    const alreadySanitized = after?.moderation?.objectionableBio === true;
    if (alreadySanitized) return null;

    const matches = findObjectionableMatches(bio);
    if (matches.length === 0) return null;

    console.log(
      `🧹 [MODERATION] profiles/${
        context.params.profileId
      } bio sanitized objectionable: ${matches.join(", ")}`
    );

    try {
      await change.after.ref.update({
        bio: "",
        "moderation.objectionableBio": true,
        "moderation.objectionableBioMatches": matches,
        "moderation.objectionableBioUpdatedAt":
          admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (error) {
      console.error(
        `❌ [MODERATION] profiles/${context.params.profileId} update failed: ${error}`
      );
    }

    return null;
  });
