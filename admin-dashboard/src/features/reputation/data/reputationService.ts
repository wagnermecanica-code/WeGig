import {
  collection,
  doc,
  getDocs,
  limit,
  orderBy,
  query,
  Timestamp,
  updateDoc,
  where,
} from "firebase/firestore";
import { db } from "@core/firebase/client";

export type VerificationStatus =
  | "unverified"
  | "pending"
  | "verified"
  | "rejected";

export interface ReputationProfile {
  id: string;
  name: string;
  city?: string;
  state?: string;
  profileType?: string;
  photoUrl?: string;
  verification: VerificationStatus;
  reputationScore: number;
  reportsAgainst: number;
  postsCount: number;
  lastActiveAt?: Date;
}

function parseDate(value: unknown): Date | undefined {
  if (value instanceof Timestamp) return value.toDate();
  if (value instanceof Date) return value;
  return undefined;
}

function pickVerification(data: Record<string, any>): VerificationStatus {
  const raw = String(
    data.verificationStatus ??
      data.verification ??
      (data.verified === true ? "verified" : "unverified"),
  ).toLowerCase();
  if (raw === "pending" || raw === "in_review") return "pending";
  if (raw === "verified") return "verified";
  if (raw === "rejected" || raw === "denied") return "rejected";
  return "unverified";
}

function clamp(value: number, min: number, max: number) {
  return Math.max(min, Math.min(max, value));
}

function computeReputation(data: Record<string, any>): number {
  const base = Number(data.reputationScore ?? data.score ?? 0);
  if (Number.isFinite(base) && base > 0) {
    return clamp(Math.round(base), 0, 100);
  }
  const reports = Number(data.reportsAgainstCount ?? 0);
  const posts = Number(data.postsCount ?? 0);
  const verified = pickVerification(data) === "verified" ? 1 : 0;

  // Heurística simples: base 60 + posts*2 - reports*8 + 15 se verificado.
  const score = 60 + posts * 2 - reports * 8 + verified * 15;
  return clamp(Math.round(score), 0, 100);
}

export async function listReputationProfiles(params: {
  status?: VerificationStatus | "all";
  search?: string;
  pageSize?: number;
}): Promise<ReputationProfile[]> {
  const pageSize = params.pageSize ?? 80;
  const constraints: any[] = [];

  if (params.status && params.status !== "all") {
    constraints.push(where("verificationStatus", "==", params.status));
  }
  constraints.push(orderBy("createdAt", "desc"));
  constraints.push(limit(pageSize));

  const snap = await getDocs(query(collection(db, "profiles"), ...constraints));
  let items: ReputationProfile[] = snap.docs.map((d) => {
    const data = d.data();
    return {
      id: d.id,
      name: data.name ?? data.displayName ?? "(sem nome)",
      city: data.city,
      state: data.state,
      profileType: data.profileType ?? data.type,
      photoUrl: data.photoUrl ?? data.avatarUrl,
      verification: pickVerification(data),
      reputationScore: computeReputation(data),
      reportsAgainst: Number(data.reportsAgainstCount ?? 0),
      postsCount: Number(data.postsCount ?? 0),
      lastActiveAt: parseDate(data.lastActiveAt),
    };
  });

  const term = params.search?.trim().toLowerCase();
  if (term) {
    items = items.filter(
      (p) =>
        p.name.toLowerCase().includes(term) ||
        (p.city ?? "").toLowerCase().includes(term) ||
        (p.state ?? "").toLowerCase().includes(term) ||
        p.id.toLowerCase().includes(term),
    );
  }

  return items;
}

export async function setVerificationStatus(
  profileId: string,
  status: VerificationStatus,
): Promise<void> {
  await updateDoc(doc(db, "profiles", profileId), {
    verificationStatus: status,
    verified: status === "verified",
    verificationUpdatedAt: Timestamp.now(),
  });
}

export async function adjustReputationScore(
  profileId: string,
  score: number,
): Promise<void> {
  const safeScore = clamp(Math.round(score), 0, 100);
  await updateDoc(doc(db, "profiles", profileId), {
    reputationScore: safeScore,
    reputationUpdatedAt: Timestamp.now(),
  });
}
