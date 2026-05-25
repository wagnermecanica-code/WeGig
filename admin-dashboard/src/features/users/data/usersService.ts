import {
  CollectionReference,
  DocumentData,
  Query,
  QueryConstraint,
  QueryDocumentSnapshot,
  collection,
  collectionGroup,
  doc,
  getDoc,
  getDocs,
  limit,
  orderBy,
  query,
  startAfter,
  Timestamp,
  where,
} from "firebase/firestore";
import { db } from "@core/firebase/client";

export interface ProfileSummary {
  id: string;
  name: string;
  city?: string;
  state?: string;
  profileType?: string;
  ownerUid?: string;
  photoUrl?: string;
  createdAt?: Date;
  banned?: boolean;
}

export interface ProfileDetail extends ProfileSummary {
  bio?: string;
  email?: string;
  phone?: string;
  username?: string;
  verified?: boolean;
  moderationStatus?: string;
  allowConnectionSuggestions?: boolean;
  allowConnectionRequests?: boolean;
  blockedProfilesCount?: number;
  blockedByProfilesCount?: number;
  genres?: string[];
  instruments?: string[];
  updatedAt?: Date;
  lastSeenAt?: Date;
  raw: Record<string, any>;
}

function parseDateLike(value: unknown): Date | undefined {
  if (!value) return undefined;
  if (value instanceof Date) return value;
  if (value instanceof Timestamp) return value.toDate();
  if (typeof value === "string") {
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? undefined : parsed;
  }
  if (typeof value === "number" && Number.isFinite(value)) {
    const millis = value > 10_000_000_000 ? value : value * 1000;
    const parsed = new Date(millis);
    return Number.isNaN(parsed.getTime()) ? undefined : parsed;
  }
  if (typeof value === "object" && value !== null) {
    const candidate = value as { toDate?: () => Date };
    if (typeof candidate.toDate === "function") return candidate.toDate();
    const secondsCandidate = value as {
      seconds?: number;
      _seconds?: number;
      nanoseconds?: number;
      _nanoseconds?: number;
    };
    const seconds = secondsCandidate.seconds ?? secondsCandidate._seconds;
    if (typeof seconds === "number" && Number.isFinite(seconds)) {
      const nanos =
        secondsCandidate.nanoseconds ?? secondsCandidate._nanoseconds ?? 0;
      return new Date(seconds * 1000 + Math.floor(nanos / 1_000_000));
    }
  }
  return undefined;
}

function pickDate(data: Record<string, any>, keys: string[]): Date | undefined {
  for (const key of keys) {
    const parsed = parseDateLike(data[key]);
    if (parsed) return parsed;
  }
  return undefined;
}

function mapProfile(id: string, data: Record<string, any>): ProfileSummary {
  return {
    id,
    name: data.name ?? data.displayName ?? "(sem nome)",
    city: data.city,
    state: data.state,
    profileType: data.profileType ?? data.type,
    ownerUid: data.ownerUid ?? data.userId ?? data.uid,
    photoUrl: data.photoUrl ?? data.avatarUrl,
    createdAt: pickDate(data, [
      "createdAt",
      "created_at",
      "created",
      "createdOn",
      "createdDate",
      "timestamp",
      "updatedAt",
    ]),
    banned: data.banned === true || data.moderationStatus === "banned",
  };
}

async function fetchProfilesByPages(params: {
  batchSize: number;
  maxRecords: number;
}): Promise<ProfileSummary[]> {
  const all: ProfileSummary[] = [];
  const seen = new Set<string>();
  let cursor: QueryDocumentSnapshot<DocumentData> | null = null;

  while (all.length < params.maxRecords) {
    const constraints: QueryConstraint[] = [
      orderBy("createdAt", "desc"),
      limit(params.batchSize),
    ];
    if (cursor) constraints.push(startAfter(cursor));

    const snap = await getDocs(
      query(collection(db, "profiles"), ...constraints),
    ).catch(() => null);

    const page =
      snap ??
      (await getDocs(
        query(
          collection(db, "profiles"),
          ...(cursor ? [startAfter(cursor)] : []),
          limit(params.batchSize),
        ),
      ).catch(() => null));

    if (!page || page.empty) break;

    for (const item of page.docs) {
      if (seen.has(item.id)) continue;
      seen.add(item.id);
      all.push(mapProfile(item.id, item.data()));
      if (all.length >= params.maxRecords) break;
    }

    cursor = page.docs[page.docs.length - 1] ?? null;
    if (page.size < params.batchSize) break;
  }

  return all;
}

export async function listProfiles(params: {
  searchTerm?: string;
  profileType?: string;
  pageSize?: number;
  maxRecords?: number;
}): Promise<ProfileSummary[]> {
  const pageSize = Math.max(50, Math.min(params.pageSize ?? 300, 500));
  const maxRecords = Math.max(pageSize, params.maxRecords ?? 5000);
  let items = await fetchProfilesByPages({ batchSize: pageSize, maxRecords });

  if (params.profileType) {
    const requestedType = params.profileType.trim().toLowerCase();
    items = items.filter(
      (p) => (p.profileType ?? "").toLowerCase() === requestedType,
    );
  }

  const term = params.searchTerm?.trim().toLowerCase();
  if (term) {
    items = items.filter(
      (p) =>
        p.name.toLowerCase().includes(term) ||
        (p.city ?? "").toLowerCase().includes(term) ||
        (p.profileType ?? "").toLowerCase().includes(term) ||
        p.id.toLowerCase().includes(term),
    );
  }

  items.sort((a, b) => {
    const at = a.createdAt?.getTime() ?? 0;
    const bt = b.createdAt?.getTime() ?? 0;
    if (at !== bt) return bt - at;
    return a.name.localeCompare(b.name, "pt-BR", { sensitivity: "base" });
  });

  return items;
}

export async function getProfile(id: string): Promise<ProfileDetail | null> {
  const snap = await getDoc(doc(db, "profiles", id));
  if (!snap.exists()) return null;
  const data = snap.data();
  const base = mapProfile(snap.id, data);
  return {
    ...base,
    bio: data.bio,
    email: data.email,
    phone: data.phone ?? data.phoneNumber,
    username: data.username,
    verified: data.verified === true || data.isVerified === true,
    moderationStatus: data.moderationStatus,
    allowConnectionSuggestions:
      typeof data.allowConnectionSuggestions === "boolean"
        ? data.allowConnectionSuggestions
        : undefined,
    allowConnectionRequests:
      typeof data.allowConnectionRequests === "boolean"
        ? data.allowConnectionRequests
        : undefined,
    blockedProfilesCount: Array.isArray(data.blockedProfileIds)
      ? data.blockedProfileIds.length
      : undefined,
    blockedByProfilesCount: Array.isArray(data.blockedByProfileIds)
      ? data.blockedByProfileIds.length
      : undefined,
    genres: Array.isArray(data.genres)
      ? data.genres.filter((x: unknown) => typeof x === "string")
      : undefined,
    instruments: Array.isArray(data.instruments)
      ? data.instruments.filter((x: unknown) => typeof x === "string")
      : undefined,
    updatedAt: parseDateLike(data.updatedAt),
    lastSeenAt: parseDateLike(data.lastSeenAt ?? data.lastActiveAt),
    raw: data,
  };
}

export interface UserActivity {
  postsCount: number;
  conversationsCount: number;
  reportsAgainst: number;
  reportsOpened: number;
  commentsCount: number;
}

async function collectDocumentIdsSafe(
  base: CollectionReference<DocumentData> | Query<DocumentData>,
  constraints: QueryConstraint[],
  maxDocs = 5000,
): Promise<Set<string>> {
  try {
    const snap = await getDocs(query(base, ...constraints, limit(maxDocs)));
    return new Set(snap.docs.map((docSnap) => docSnap.ref.path));
  } catch {
    return new Set<string>();
  }
}

async function collectDocumentLocalIdsSafe(
  base: CollectionReference<DocumentData> | Query<DocumentData>,
  constraints: QueryConstraint[],
  maxDocs = 5000,
): Promise<Set<string>> {
  try {
    const snap = await getDocs(query(base, ...constraints, limit(maxDocs)));
    return new Set(snap.docs.map((docSnap) => docSnap.id));
  } catch {
    return new Set<string>();
  }
}

async function countUniqueDocumentsSafe(
  queries: Array<{
    base: CollectionReference<DocumentData> | Query<DocumentData>;
    constraints: QueryConstraint[];
  }>,
): Promise<number> {
  const ids = new Set<string>();
  const results = await Promise.all(
    queries.map((item) => collectDocumentIdsSafe(item.base, item.constraints)),
  );

  for (const result of results) {
    for (const id of result) ids.add(id);
  }

  return ids.size;
}

function chunk<T>(items: T[], size: number): T[][] {
  const chunks: T[][] = [];
  for (let i = 0; i < items.length; i += size) {
    chunks.push(items.slice(i, i + size));
  }
  return chunks;
}

async function collectOwnedPostIds(
  profileId: string,
  ownerUid?: string,
): Promise<Set<string>> {
  const queries = [
    collectDocumentLocalIdsSafe(collection(db, "posts"), [
      where("authorProfileId", "==", profileId),
    ]),
    collectDocumentLocalIdsSafe(collection(db, "posts"), [
      where("profileId", "==", profileId),
    ]),
    ...(ownerUid
      ? [
          collectDocumentLocalIdsSafe(collection(db, "posts"), [
            where("authorUid", "==", ownerUid),
          ]),
        ]
      : []),
  ];

  const results = await Promise.all(queries);
  const ids = new Set<string>();
  for (const result of results) {
    for (const id of result) ids.add(id);
  }
  return ids;
}

async function countReportsAgainstProfile(
  profileId: string,
  ownerUid?: string,
): Promise<number> {
  const directReportIds = await Promise.all([
    collectDocumentIdsSafe(collection(db, "reports"), [
      where("reportedProfileId", "==", profileId),
    ]),
    collectDocumentIdsSafe(collection(db, "reports"), [
      where("targetProfileId", "==", profileId),
    ]),
    collectDocumentIdsSafe(collection(db, "reports"), [
      where("ownerProfileId", "==", profileId),
    ]),
  ]);

  const ids = new Set<string>();
  for (const result of directReportIds) {
    for (const id of result) ids.add(id);
  }

  const postIds = Array.from(await collectOwnedPostIds(profileId, ownerUid));
  const postReportIds = await Promise.all(
    chunk(postIds, 10).map((idsChunk) =>
      collectDocumentIdsSafe(collection(db, "reports"), [
        where("reportedPostId", "in", idsChunk),
      ]),
    ),
  );

  for (const result of postReportIds) {
    for (const id of result) ids.add(id);
  }

  return ids.size;
}

export async function getUserActivity(
  profileId: string,
  ownerUid?: string,
): Promise<UserActivity> {
  const ownerKey = ownerUid ?? profileId;
  const [
    postsCount,
    conversationsCount,
    reportsAgainst,
    reportsOpened,
    commentsCount,
  ] = await Promise.all([
    countUniqueDocumentsSafe([
      {
        base: collection(db, "posts"),
        constraints: [where("authorProfileId", "==", profileId)],
      },
      {
        base: collection(db, "posts"),
        constraints: [where("profileId", "==", profileId)],
      },
      ...(ownerUid
        ? [
            {
              base: collection(db, "posts"),
              constraints: [where("authorUid", "==", ownerUid)],
            },
          ]
        : []),
    ]),
    countUniqueDocumentsSafe([
      {
        base: collection(db, "conversations"),
        constraints: [
          where("participantProfiles", "array-contains", profileId),
        ],
      },
      {
        base: collection(db, "conversations"),
        constraints: [where("participants", "array-contains", ownerKey)],
      },
      ...(ownerUid && ownerUid !== ownerKey
        ? [
            {
              base: collection(db, "conversations"),
              constraints: [where("participants", "array-contains", ownerUid)],
            },
          ]
        : []),
      {
        base: collection(db, "conversations"),
        constraints: [where("createdBy", "==", profileId)],
      },
    ]),
    countReportsAgainstProfile(profileId, ownerUid),
    countUniqueDocumentsSafe([
      {
        base: collection(db, "reports"),
        constraints: [where("reporterProfileId", "==", profileId)],
      },
      ...(ownerUid
        ? [
            {
              base: collection(db, "reports"),
              constraints: [where("reporterUid", "==", ownerUid)],
            },
            {
              base: collection(db, "reports"),
              constraints: [where("reportedBy", "array-contains", ownerUid)],
            },
          ]
        : []),
    ]),
    countUniqueDocumentsSafe([
      {
        base: collectionGroup(db, "comments"),
        constraints: [where("authorProfileId", "==", profileId)],
      },
      {
        base: collectionGroup(db, "comments"),
        constraints: [where("profileId", "==", profileId)],
      },
      ...(ownerUid
        ? [
            {
              base: collectionGroup(db, "comments"),
              constraints: [where("authorUid", "==", ownerUid)],
            },
          ]
        : []),
    ]),
  ]);

  return {
    postsCount,
    conversationsCount,
    reportsAgainst,
    reportsOpened,
    commentsCount,
  };
}
