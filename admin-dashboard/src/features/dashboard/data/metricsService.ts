import {
  collection,
  collectionGroup,
  doc,
  documentId,
  getCountFromServer,
  getDoc,
  getDocs,
  limit,
  orderBy,
  query,
  where,
  Timestamp,
} from "firebase/firestore";
import { db } from "@core/firebase/client";

export interface OverviewMetrics {
  totalUsers: number;
  totalPosts: number;
  activePosts: number;
  totalConversations: number;
  totalGroupConversations: number;
  totalComments: number;
  totalInterests: number;
  pendingReports: number;
  pendingFeedbacks: number;
}

export interface DailySnapshot {
  date: string; // YYYY-MM-DD
  dau?: number;
  newUsers?: number;
  newPosts?: number;
  messagesSent?: number;
}

function mapDailySnapshot(
  data: Record<string, unknown>,
  fallbackDate: string,
): DailySnapshot {
  return {
    date: (typeof data.date === "string" && data.date) || fallbackDate,
    dau: Number(data.dau ?? 0),
    newUsers: Number(data.newUsers ?? 0),
    newPosts: Number(data.newPosts ?? 0),
    messagesSent: Number(data.messagesSent ?? 0),
  };
}

function formatDateKey(date: Date): string {
  return date.toISOString().slice(0, 10);
}

function parseTimestampLike(value: unknown): Date | null {
  if (!value) return null;
  if (value instanceof Date) return value;
  if (typeof value === "object" && value !== null) {
    const maybe = value as { toDate?: () => Date };
    if (typeof maybe.toDate === "function") {
      return maybe.toDate();
    }
  }
  return null;
}

export async function fetchDerivedDailySnapshots(
  days = 14,
): Promise<DailySnapshot[]> {
  const now = new Date();
  const start = new Date(now);
  start.setDate(now.getDate() - (days - 1));
  start.setHours(0, 0, 0, 0);
  const startTs = Timestamp.fromDate(start);

  const initial = new Map<string, DailySnapshot>();
  for (let i = 0; i < days; i += 1) {
    const d = new Date(start);
    d.setDate(start.getDate() + i);
    const key = formatDateKey(d);
    initial.set(key, {
      date: key,
      dau: 0,
      newUsers: 0,
      newPosts: 0,
      messagesSent: 0,
    });
  }

  try {
    const [postsSnap, usersSnap] = await Promise.all([
      getDocs(
        query(collection(db, "posts"), where("createdAt", ">=", startTs)),
      ),
      getDocs(
        query(collection(db, "profiles"), where("createdAt", ">=", startTs)),
      ),
    ]);

    for (const docSnap of postsSnap.docs) {
      const createdAt = parseTimestampLike(docSnap.data().createdAt);
      if (!createdAt) continue;
      const key = formatDateKey(createdAt);
      const row = initial.get(key);
      if (!row) continue;
      row.newPosts = (row.newPosts ?? 0) + 1;
    }

    for (const docSnap of usersSnap.docs) {
      const createdAt = parseTimestampLike(docSnap.data().createdAt);
      if (!createdAt) continue;
      const key = formatDateKey(createdAt);
      const row = initial.get(key);
      if (!row) continue;
      row.newUsers = (row.newUsers ?? 0) + 1;
    }

    const result = Array.from(initial.values());
    for (const row of result) {
      const newUsers = row.newUsers ?? 0;
      const newPosts = row.newPosts ?? 0;
      row.dau = newUsers + Math.round(newPosts / 2);
    }

    return result;
  } catch (err) {
    console.warn("[metricsService] derived daily snapshots failed:", err);
    return [];
  }
}

export async function fetchDerivedDailySnapshotsFromHistory(
  days = 14,
  sampleLimit = 800,
): Promise<DailySnapshot[]> {
  try {
    const [postsSnap, usersSnap] = await Promise.all([
      getDocs(
        query(
          collection(db, "posts"),
          orderBy("createdAt", "desc"),
          limit(sampleLimit),
        ),
      ),
      getDocs(
        query(
          collection(db, "profiles"),
          orderBy("createdAt", "desc"),
          limit(sampleLimit),
        ),
      ),
    ]);

    const buckets = new Map<string, DailySnapshot>();

    for (const docSnap of postsSnap.docs) {
      const createdAt = parseTimestampLike(docSnap.data().createdAt);
      if (!createdAt) continue;
      const key = formatDateKey(createdAt);
      const row = buckets.get(key) ?? {
        date: key,
        dau: 0,
        newUsers: 0,
        newPosts: 0,
        messagesSent: 0,
      };
      row.newPosts = (row.newPosts ?? 0) + 1;
      buckets.set(key, row);
    }

    for (const docSnap of usersSnap.docs) {
      const createdAt = parseTimestampLike(docSnap.data().createdAt);
      if (!createdAt) continue;
      const key = formatDateKey(createdAt);
      const row = buckets.get(key) ?? {
        date: key,
        dau: 0,
        newUsers: 0,
        newPosts: 0,
        messagesSent: 0,
      };
      row.newUsers = (row.newUsers ?? 0) + 1;
      buckets.set(key, row);
    }

    const selectedKeys = Array.from(buckets.keys())
      .sort()
      .reverse()
      .slice(0, days);
    const result = selectedKeys.sort().map((key) => {
      const row = buckets.get(key)!;
      const newUsers = row.newUsers ?? 0;
      const newPosts = row.newPosts ?? 0;
      row.dau = newUsers + Math.round(newPosts / 2);
      return row;
    });

    return result;
  } catch (err) {
    console.warn("[metricsService] historical derived snapshots failed:", err);
    return [];
  }
}

/**
 * Conta documentos com Firestore aggregation, retornando 0 em caso de
 * falha (permissão negada, coleção inexistente, índice ausente).
 * Cada métrica falha de forma independente — o dashboard nunca quebra inteiro.
 */
async function safeCount(
  q: Parameters<typeof getCountFromServer>[0],
): Promise<number> {
  try {
    const snap = await getCountFromServer(q);
    return snap.data().count ?? 0;
  } catch (err) {
    console.warn("[metricsService] count failed:", err);
    return 0;
  }
}

/** Lê contagens diretamente do Firestore via getCountFromServer (rápido e barato). */
export async function fetchOverviewMetrics(): Promise<OverviewMetrics> {
  const now = Timestamp.now();
  const [
    totalUsers,
    totalPosts,
    activePosts,
    totalConversations,
    totalGroupConversations,
    totalComments,
    totalInterests,
    pendingReports,
    pendingFeedbacks,
  ] = await Promise.all([
    safeCount(collection(db, "profiles")),
    safeCount(collection(db, "posts")),
    safeCount(query(collection(db, "posts"), where("expiresAt", ">", now))),
    safeCount(collection(db, "conversations")),
    safeCount(
      query(collection(db, "conversations"), where("isGroup", "==", true)),
    ),
    safeCount(collectionGroup(db, "comments")),
    safeCount(collection(db, "interests")),
    safeCount(
      query(collection(db, "reports"), where("status", "==", "pending")),
    ),
    safeCount(collection(db, "feedbacks")),
  ]);

  return {
    totalUsers,
    totalPosts,
    activePosts,
    totalConversations,
    totalGroupConversations,
    totalComments,
    totalInterests,
    pendingReports,
    pendingFeedbacks,
  };
}

/**
 * Lê snapshots diários da coleção `analytics_daily`.
 * Retorna [] se a coleção ainda não existir (Cloud Function não rodou).
 */
export async function fetchDailySnapshots(days = 14): Promise<DailySnapshot[]> {
  const col = collection(db, "analytics_daily");

  try {
    const q = query(col, orderBy("date", "desc"), limit(days));
    const snap = await getDocs(q);
    const items = snap.docs.map((d) =>
      mapDailySnapshot(d.data() as Record<string, unknown>, d.id),
    );

    if (items.length > 0) {
      return items.reverse();
    }
  } catch (err) {
    console.warn("[metricsService] analytics_daily by date failed:", err);
  }

  // Fallback para dados legados sem campo `date`: ordena pelo ID do doc (YYYY-MM-DD).
  try {
    const qById = query(col, orderBy(documentId(), "desc"), limit(days));
    const snapById = await getDocs(qById);
    const itemsById = snapById.docs.map((d) =>
      mapDailySnapshot(d.data() as Record<string, unknown>, d.id),
    );
    return itemsById.reverse();
  } catch (err) {
    console.warn("[metricsService] analytics_daily by documentId failed:", err);
    return [];
  }
}

/** Tenta ler o doc agregado de hoje. */
export async function fetchTodaySnapshot(): Promise<DailySnapshot | null> {
  const today = new Date().toISOString().slice(0, 10);
  try {
    const snap = await getDoc(doc(db, "analytics_daily", today));
    if (!snap.exists()) return null;
    const data = snap.data();
    return {
      date: data.date ?? today,
      dau: data.dau,
      newUsers: data.newUsers,
      newPosts: data.newPosts,
      messagesSent: data.messagesSent,
    };
  } catch {
    return null;
  }
}
