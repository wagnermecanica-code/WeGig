import {
  collection,
  collectionGroup,
  getCountFromServer,
  getDocs,
  limit,
  orderBy,
  query,
  Timestamp,
  where,
} from "firebase/firestore";
import { db } from "@core/firebase/client";

export interface ActivityMetrics {
  dau: number;
  wau: number;
  mau: number;
  d1Retention: number; // 0-1
  d7Retention: number; // 0-1
  avgEngagementSeconds: number;
  totalContent: number;
}

export interface CohortBucket {
  cohort: string; // YYYY-MM
  newUsers: number;
  d1: number;
  d7: number;
  d30: number;
}

export interface FunnelStep {
  label: string;
  count: number;
}

export interface GeoBucket {
  state: string;
  city: string;
  profiles: number;
  posts: number;
}

interface LegacyProfileActivity {
  id: string;
  createdAt: Date;
  lastActivityAt: Date;
  activeDayOffsets: Set<number>;
}

interface LegacyActivityInsights {
  d1Retention: number;
  d7Retention: number;
  churnRate: number;
  cohorts: CohortBucket[];
}

let legacyActivityInsightsPromise: Promise<LegacyActivityInsights> | null = null;

function parseTimestampLike(value: unknown): Date | null {
  if (!value) return null;
  if (value instanceof Date) return value;
  if (typeof value === "object" && value !== null) {
    const maybe = value as { toDate?: () => Date };
    if (typeof maybe.toDate === "function") return maybe.toDate();
  }
  return null;
}

async function safeCount(
  q: Parameters<typeof getCountFromServer>[0],
): Promise<number> {
  try {
    const snap = await getCountFromServer(q);
    return snap.data().count ?? 0;
  } catch (err) {
    console.warn("[analyticsService] safeCount failed:", err);
    return 0;
  }
}

function startOfDayMinus(days: number): Date {
  const d = new Date();
  d.setHours(0, 0, 0, 0);
  d.setDate(d.getDate() - days);
  return d;
}

function pickString(data: Record<string, any>, keys: string[]): string | null {
  for (const key of keys) {
    const value = data[key];
    if (typeof value === "string" && value.trim()) return value.trim();
  }
  return null;
}

function daysBetween(start: Date, end: Date): number {
  const startDay = new Date(start);
  const endDay = new Date(end);
  startDay.setHours(0, 0, 0, 0);
  endDay.setHours(0, 0, 0, 0);
  return Math.floor(
    (endDay.getTime() - startDay.getTime()) / (1000 * 60 * 60 * 24),
  );
}

async function safeDocs(
  q: Parameters<typeof getDocs>[0],
): Promise<Awaited<ReturnType<typeof getDocs>> | null> {
  try {
    return await getDocs(q);
  } catch (err) {
    console.warn("[analyticsService] legacy docs failed:", err);
    return null;
  }
}

function addProfileActivity(
  profiles: Map<string, LegacyProfileActivity>,
  profileId: string | null,
  activityAt: Date | null,
) {
  if (!profileId || !activityAt) return;
  const profile = profiles.get(profileId);
  if (!profile) return;

  if (activityAt > profile.lastActivityAt) {
    profile.lastActivityAt = activityAt;
  }

  const offset = daysBetween(profile.createdAt, activityAt);
  if (offset >= 0) profile.activeDayOffsets.add(offset);
}

function buildInsightsFromProfiles(
  profiles: LegacyProfileActivity[],
): LegacyActivityInsights {
  const today = new Date();
  const d30 = startOfDayMinus(30);
  let d1Eligible = 0;
  let d1Retained = 0;
  let d7Eligible = 0;
  let d7Retained = 0;
  let churned = 0;
  const cohorts = new Map<string, CohortBucket>();

  for (const profile of profiles) {
    const ageDays = daysBetween(profile.createdAt, today);
    const cohortKey = `${profile.createdAt.getFullYear()}-${String(
      profile.createdAt.getMonth() + 1,
    ).padStart(2, "0")}`;
    const cohort = cohorts.get(cohortKey) ?? {
      cohort: cohortKey,
      newUsers: 0,
      d1: 0,
      d7: 0,
      d30: 0,
    };

    cohort.newUsers += 1;
    if (profile.activeDayOffsets.has(1) || profile.activeDayOffsets.has(2)) {
      cohort.d1 += 1;
    }
    if (Array.from(profile.activeDayOffsets).some((offset) => offset >= 7)) {
      cohort.d7 += 1;
    }
    if (Array.from(profile.activeDayOffsets).some((offset) => offset >= 30)) {
      cohort.d30 += 1;
    }
    cohorts.set(cohortKey, cohort);

    if (ageDays >= 1) {
      d1Eligible += 1;
      if (profile.activeDayOffsets.has(1) || profile.activeDayOffsets.has(2)) {
        d1Retained += 1;
      }
    }
    if (ageDays >= 7) {
      d7Eligible += 1;
      if (Array.from(profile.activeDayOffsets).some((offset) => offset >= 7)) {
        d7Retained += 1;
      }
    }
    if (profile.lastActivityAt < d30) {
      churned += 1;
    }
  }

  return {
    d1Retention: d1Eligible > 0 ? d1Retained / d1Eligible : 0,
    d7Retention: d7Eligible > 0 ? d7Retained / d7Eligible : 0,
    churnRate: profiles.length > 0 ? churned / profiles.length : 0,
    cohorts: Array.from(cohorts.values()).sort((a, b) =>
      a.cohort.localeCompare(b.cohort),
    ),
  };
}

async function fetchLegacyActivityInsights(
  sampleLimit = 5000,
): Promise<LegacyActivityInsights> {
  if (legacyActivityInsightsPromise) return legacyActivityInsightsPromise;

  legacyActivityInsightsPromise = fetchLegacyActivityInsightsUncached(sampleLimit);
  return legacyActivityInsightsPromise;
}

async function fetchLegacyActivityInsightsUncached(
  sampleLimit: number,
): Promise<LegacyActivityInsights> {
  const [profilesSnap, postsSnap, interestsSnap, messagesSnap] =
    await Promise.all([
      safeDocs(
        query(
          collection(db, "profiles"),
          orderBy("createdAt", "desc"),
          limit(sampleLimit),
        ),
      ),
      safeDocs(
        query(
          collection(db, "posts"),
          orderBy("createdAt", "desc"),
          limit(sampleLimit),
        ),
      ),
      safeDocs(
        query(
          collection(db, "interests"),
          orderBy("createdAt", "desc"),
          limit(sampleLimit),
        ),
      ),
      safeDocs(
        query(
          collectionGroup(db, "messages"),
          orderBy("createdAt", "desc"),
          limit(sampleLimit),
        ),
      ),
    ]);

  const profiles = new Map<string, LegacyProfileActivity>();

  for (const profileDoc of profilesSnap?.docs ?? []) {
    const data = profileDoc.data();
    const createdAt = parseTimestampLike(data.createdAt);
    if (!createdAt) continue;

    const lastActivityAt =
      parseTimestampLike(data.lastActiveAt) ??
      parseTimestampLike(data.lastSeenAt) ??
      parseTimestampLike(data.updatedAt) ??
      createdAt;

    const activeDayOffsets = new Set<number>();
    activeDayOffsets.add(0);
    const initialOffset = daysBetween(createdAt, lastActivityAt);
    if (initialOffset >= 0) activeDayOffsets.add(initialOffset);

    profiles.set(profileDoc.id, {
      id: profileDoc.id,
      createdAt,
      lastActivityAt,
      activeDayOffsets,
    });
  }

  for (const postDoc of postsSnap?.docs ?? []) {
    const data = postDoc.data();
    addProfileActivity(
      profiles,
      pickString(data, [
        "profileId",
        "authorProfileId",
        "ownerProfileId",
        "creatorProfileId",
      ]),
      parseTimestampLike(data.createdAt),
    );
  }

  for (const interestDoc of interestsSnap?.docs ?? []) {
    const data = interestDoc.data();
    addProfileActivity(
      profiles,
      pickString(data, [
        "interestedProfileId",
        "senderProfileId",
        "profileId",
        "fromProfileId",
      ]),
      parseTimestampLike(data.createdAt),
    );
  }

  for (const messageDoc of messagesSnap?.docs ?? []) {
    const data = messageDoc.data();
    addProfileActivity(
      profiles,
      pickString(data, ["senderProfileId", "profileId", "fromProfileId"]),
      parseTimestampLike(data.createdAt),
    );
  }

  return buildInsightsFromProfiles(Array.from(profiles.values()));
}

/**
 * Calcula DAU/WAU/MAU + retenção D1/D7 + tempo médio de engajamento + total de conteúdo.
 * Heurística baseada em mensagens e posts criados (proxy de sessões),
 * já que não há events session log explícito.
 */
export async function fetchActivityMetrics(): Promise<ActivityMetrics> {
  const d1 = Timestamp.fromDate(startOfDayMinus(1));
  const d7 = Timestamp.fromDate(startOfDayMinus(7));
  const d30 = Timestamp.fromDate(startOfDayMinus(30));

  const messages = collectionGroup(db, "messages");
  const posts = collection(db, "posts");
  const profiles = collection(db, "profiles");

  const [
    dauMessages,
    wauMessages,
    mauMessages,
    totalPosts,
    dauPosts,
    wauPosts,
    mauPosts,
    profilesCreatedD7,
    profilesActiveD1AfterD7,
    profilesCreatedD30,
    profilesActiveD7AfterD30,
  ] = await Promise.all([
    safeCount(query(messages, where("createdAt", ">=", d1))),
    safeCount(query(messages, where("createdAt", ">=", d7))),
    safeCount(query(messages, where("createdAt", ">=", d30))),
    safeCount(posts),
    safeCount(query(posts, where("createdAt", ">=", d1))),
    safeCount(query(posts, where("createdAt", ">=", d7))),
    safeCount(query(posts, where("createdAt", ">=", d30))),
    safeCount(query(profiles, where("createdAt", ">=", d7))),
    safeCount(query(profiles, where("lastActiveAt", ">=", d1))),
    safeCount(query(profiles, where("createdAt", ">=", d30))),
    safeCount(query(profiles, where("lastActiveAt", ">=", d7))),
  ]);

  const legacyInsights = await fetchLegacyActivityInsights();

  const dau = Math.max(dauMessages, dauPosts);
  const wau = Math.max(wauMessages, wauPosts);
  const mau = Math.max(mauMessages, mauPosts);

  const d1Retention =
    profilesCreatedD7 > 0
      ? Math.max(
          legacyInsights.d1Retention,
          Math.min(1, profilesActiveD1AfterD7 / profilesCreatedD7),
        )
      : legacyInsights.d1Retention;
  const d7Retention =
    profilesCreatedD30 > 0
      ? Math.max(
          legacyInsights.d7Retention,
          Math.min(1, profilesActiveD7AfterD30 / profilesCreatedD30),
        )
      : legacyInsights.d7Retention;

  // Estimativa: mensagens × 12s + posts × 45s, dividido por usuários ativos diários.
  const engagementSeconds =
    dau > 0
      ? Math.round((dauMessages * 12 + dauPosts * 45) / Math.max(dau, 1))
      : 0;

  return {
    dau,
    wau,
    mau,
    d1Retention,
    d7Retention,
    avgEngagementSeconds: engagementSeconds,
    totalContent: totalPosts,
  };
}

/**
 * Constrói buckets de coorte mensal e calcula taxas de retenção D1/D7/D30
 * baseado em `lastActiveAt` e nos eventos legados de posts/interesses/mensagens.
 */
export async function fetchCohortBuckets(months = 6): Promise<CohortBucket[]> {
  const start = new Date();
  start.setMonth(start.getMonth() - (months - 1));
  start.setDate(1);
  start.setHours(0, 0, 0, 0);
  const startTs = Timestamp.fromDate(start);

  try {
    const snap = await getDocs(
      query(
        collection(db, "profiles"),
        where("createdAt", ">=", startTs),
        orderBy("createdAt", "asc"),
        limit(5000),
      ),
    );

    const buckets = new Map<string, CohortBucket>();

    for (const doc of snap.docs) {
      const data = doc.data();
      const createdAt = parseTimestampLike(data.createdAt);
      const lastActive = parseTimestampLike(data.lastActiveAt);
      if (!createdAt) continue;

      const cohortKey = `${createdAt.getFullYear()}-${String(createdAt.getMonth() + 1).padStart(2, "0")}`;
      const row = buckets.get(cohortKey) ?? {
        cohort: cohortKey,
        newUsers: 0,
        d1: 0,
        d7: 0,
        d30: 0,
      };

      row.newUsers += 1;

      if (lastActive) {
        const diffDays =
          (lastActive.getTime() - createdAt.getTime()) / (1000 * 60 * 60 * 24);
        if (diffDays >= 1) row.d1 += 1;
        if (diffDays >= 7) row.d7 += 1;
        if (diffDays >= 30) row.d30 += 1;
      }

      buckets.set(cohortKey, row);
    }

    const legacy = await fetchLegacyActivityInsights();
    const legacyByCohort = new Map(
      legacy.cohorts.map((row) => [row.cohort, row]),
    );

    return Array.from(buckets.values())
      .map((row) => {
        const fallback = legacyByCohort.get(row.cohort);
        if (!fallback) return row;
        return {
          ...row,
          d1: Math.max(row.d1, fallback.d1),
          d7: Math.max(row.d7, fallback.d7),
          d30: Math.max(row.d30, fallback.d30),
        };
      })
      .sort((a, b) => a.cohort.localeCompare(b.cohort));
  } catch (err) {
    console.warn("[analyticsService] cohorts failed:", err);
    return [];
  }
}

/**
 * Funnel: cadastros → perfis criados → posts criados → conversas → mensagens.
 */
export async function fetchActivationFunnel(): Promise<FunnelStep[]> {
  const [users, profiles, posts, conversations, messages] = await Promise.all([
    safeCount(collection(db, "users")),
    safeCount(collection(db, "profiles")),
    safeCount(collection(db, "posts")),
    safeCount(collection(db, "conversations")),
    safeCount(collectionGroup(db, "messages")),
  ]);

  return [
    { label: "Cadastros (users)", count: users },
    { label: "Perfis criados", count: profiles },
    { label: "Posts publicados", count: posts },
    { label: "Conversas iniciadas", count: conversations },
    { label: "Mensagens enviadas", count: messages },
  ];
}

/**
 * Calcula churn aproximado: % de perfis cuja `lastActiveAt` é >30 dias atrás
 * em relação ao total de perfis.
 */
export async function fetchChurnRate(): Promise<number> {
  const d30 = Timestamp.fromDate(startOfDayMinus(30));
  const [total, inactive, legacy] = await Promise.all([
    safeCount(collection(db, "profiles")),
    safeCount(
      query(collection(db, "profiles"), where("lastActiveAt", "<", d30)),
    ),
    fetchLegacyActivityInsights(),
  ]);
  const direct = total > 0 ? inactive / total : 0;
  return Math.max(direct, legacy.churnRate);
}

/**
 * Distribuição geográfica agregada de perfis e posts por (estado, cidade).
 */
export async function fetchGeoDistribution(
  sampleLimit = 1500,
): Promise<GeoBucket[]> {
  try {
    const [profilesSnap, postsSnap] = await Promise.all([
      getDocs(
        query(
          collection(db, "profiles"),
          orderBy("createdAt", "desc"),
          limit(sampleLimit),
        ),
      ),
      getDocs(
        query(
          collection(db, "posts"),
          orderBy("createdAt", "desc"),
          limit(sampleLimit),
        ),
      ),
    ]);

    const buckets = new Map<string, GeoBucket>();
    const keyOf = (state: string, city: string) =>
      `${state || "—"}|${city || "—"}`;

    for (const doc of profilesSnap.docs) {
      const data = doc.data();
      const state = String(data.state ?? "").trim();
      const city = String(data.city ?? "").trim();
      if (!state && !city) continue;
      const k = keyOf(state, city);
      const row = buckets.get(k) ?? {
        state: state || "—",
        city: city || "—",
        profiles: 0,
        posts: 0,
      };
      row.profiles += 1;
      buckets.set(k, row);
    }

    for (const doc of postsSnap.docs) {
      const data = doc.data();
      const state = String(data.state ?? data.locationState ?? "").trim();
      const city = String(data.city ?? data.locationCity ?? "").trim();
      if (!state && !city) continue;
      const k = keyOf(state, city);
      const row = buckets.get(k) ?? {
        state: state || "—",
        city: city || "—",
        profiles: 0,
        posts: 0,
      };
      row.posts += 1;
      buckets.set(k, row);
    }

    return Array.from(buckets.values()).sort(
      (a, b) => b.profiles + b.posts - (a.profiles + a.posts),
    );
  } catch (err) {
    console.warn("[analyticsService] geo distribution failed:", err);
    return [];
  }
}
