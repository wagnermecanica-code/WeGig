import {
  collection,
  doc,
  getDoc,
  getDocs,
  limit,
  orderBy,
  query,
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
  raw: Record<string, any>;
}

function mapProfile(id: string, data: Record<string, any>): ProfileSummary {
  const createdAtRaw = data.createdAt;
  return {
    id,
    name: data.name ?? data.displayName ?? "(sem nome)",
    city: data.city,
    state: data.state,
    profileType: data.profileType ?? data.type,
    ownerUid: data.ownerUid ?? data.userId ?? data.uid,
    photoUrl: data.photoUrl ?? data.avatarUrl,
    createdAt:
      createdAtRaw instanceof Timestamp ? createdAtRaw.toDate() : undefined,
    banned: data.banned === true || data.moderationStatus === "banned",
  };
}

export async function listProfiles(params: {
  searchTerm?: string;
  profileType?: string;
  pageSize?: number;
}): Promise<ProfileSummary[]> {
  const pageSize = params.pageSize ?? 50;
  const constraints: any[] = [];
  if (params.profileType) {
    constraints.push(where("profileType", "==", params.profileType));
  }
  constraints.push(orderBy("createdAt", "desc"));
  constraints.push(limit(pageSize));

  const snap = await getDocs(query(collection(db, "profiles"), ...constraints));
  let items = snap.docs.map((d) => mapProfile(d.id, d.data()));

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
    raw: data,
  };
}

export interface UserActivity {
  postsCount: number;
  conversationsCount: number;
  reportsAgainst: number;
}

export async function getUserActivity(
  profileId: string,
  ownerUid?: string,
): Promise<UserActivity> {
  const ownerKey = ownerUid ?? profileId;
  const [postsSnap, convsSnap, reportsSnap] = await Promise.all([
    getDocs(
      query(
        collection(db, "posts"),
        where("profileId", "==", profileId),
        limit(50),
      ),
    ).catch(() => ({ size: 0 }) as any),
    getDocs(
      query(
        collection(db, "conversations"),
        where("participants", "array-contains", ownerKey),
        limit(50),
      ),
    ).catch(() => ({ size: 0 }) as any),
    getDocs(
      query(
        collection(db, "reports"),
        where("targetProfileId", "==", profileId),
        limit(50),
      ),
    ).catch(() => ({ size: 0 }) as any),
  ]);
  return {
    postsCount: postsSnap.size ?? 0,
    conversationsCount: convsSnap.size ?? 0,
    reportsAgainst: reportsSnap.size ?? 0,
  };
}
