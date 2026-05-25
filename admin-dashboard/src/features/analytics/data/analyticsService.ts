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

/**
 * Calcula DAU/WAU/MAU + retenção D1/D7 + tempo médio de engajamento + total de conteúdo.
 * Heurística baseada em mensagens e posts criados (proxy de sessões),
 * já que não há events session log explícito.
 */
export async function fetchActivityMetrics(): Promise<ActivityMetrics> {
  const now = Timestamp.now();
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

  const dau = Math.max(dauMessages, dauPosts);
  const wau = Math.max(wauMessages, wauPosts);
  const mau = Math.max(mauMessages, mauPosts);

  const d1Retention =
    profilesCreatedD7 > 0
      ? Math.min(1, profilesActiveD1AfterD7 / profilesCreatedD7)
      : 0;
  const d7Retention =
    profilesCreatedD30 > 0
      ? Math.min(1, profilesActiveD7AfterD30 / profilesCreatedD30)
      : 0;

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
 * baseado em `lastActiveAt` dos perfis criados no mês.
 */
export async function fetchCohortBuckets(
  months = 6,
): Promise<CohortBucket[]> {
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

    return Array.from(buckets.values()).sort((a, b) =>
      a.cohort.localeCompare(b.cohort),
    );
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
  const [total, inactive] = await Promise.all([
    safeCount(collection(db, "profiles")),
    safeCount(
      query(collection(db, "profiles"), where("lastActiveAt", "<", d30)),
    ),
  ]);
  return total > 0 ? inactive / total : 0;
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
