import {
  collection,
  collectionGroup,
  doc,
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
    totalComments,
    totalInterests,
    pendingReports,
    pendingFeedbacks,
  ] = await Promise.all([
    safeCount(collection(db, "profiles")),
    safeCount(collection(db, "posts")),
    safeCount(query(collection(db, "posts"), where("expiresAt", ">", now))),
    safeCount(collection(db, "conversations")),
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
  try {
    const q = query(
      collection(db, "analytics_daily"),
      orderBy("date", "desc"),
      limit(days),
    );
    const snap = await getDocs(q);
    const items: DailySnapshot[] = snap.docs.map((d) => {
      const data = d.data() as Record<string, any>;
      return {
        date: data.date ?? d.id,
        dau: data.dau,
        newUsers: data.newUsers,
        newPosts: data.newPosts,
        messagesSent: data.messagesSent,
      };
    });
    return items.reverse();
  } catch {
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
