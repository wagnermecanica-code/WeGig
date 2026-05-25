import {
  CollectionReference,
  DocumentData,
  QueryConstraint,
  QueryDocumentSnapshot,
  collection,
  doc,
  getCountFromServer,
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
  if (typeof value === "object" && value !== null) {
    const candidate = value as { toDate?: () => Date };
    if (typeof candidate.toDate === "function") return candidate.toDate();
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
    createdAt: parseDateLike(data.createdAt),
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

async function countQuerySafe(
  base: CollectionReference<DocumentData>,
  constraints: QueryConstraint[],
): Promise<number> {
  const q = query(base, ...constraints);
  try {
    const agg = await getCountFromServer(q);
    return agg.data().count ?? 0;
  } catch {
    const snap = await getDocs(query(base, ...constraints, limit(2000))).catch(
      () => null,
    );
    return snap?.size ?? 0;
  }
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
    countQuerySafe(collection(db, "posts"), [
      where("profileId", "==", profileId),
    ]),
    countQuerySafe(collection(db, "conversations"), [
      where("participants", "array-contains", ownerKey),
    ]),
    countQuerySafe(collection(db, "reports"), [
      where("targetProfileId", "==", profileId),
    ]),
    countQuerySafe(collection(db, "reports"), [
      where("reporterProfileId", "==", profileId),
    ]).catch(() => 0),
    countQuerySafe(collection(db, "comments"), [
      where("profileId", "==", profileId),
    ]).catch(() => 0),
  ]);

  return {
    postsCount,
    conversationsCount,
    reportsAgainst,
    reportsOpened,
    commentsCount,
  };
}
