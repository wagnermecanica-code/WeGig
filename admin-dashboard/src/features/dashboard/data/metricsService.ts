import {
  collection,
  doc,
  getCountFromServer,
  getDoc,
  getDocs,
  limit,
  orderBy,
  query,
  where,
  Timestamp,
} from 'firebase/firestore';
import { db } from '@core/firebase/client';

export interface OverviewMetrics {
  totalUsers: number;
  totalPosts: number;
  activePosts: number;
  totalConversations: number;
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

/** Lê contagens diretamente do Firestore via getCountFromServer (rápido e barato). */
export async function fetchOverviewMetrics(): Promise<OverviewMetrics> {
  const now = Timestamp.now();
  const [
    usersSnap,
    postsSnap,
    activePostsSnap,
    conversationsSnap,
    reportsSnap,
    feedbacksSnap,
  ] = await Promise.all([
    getCountFromServer(collection(db, 'profiles')),
    getCountFromServer(collection(db, 'posts')),
    getCountFromServer(
      query(collection(db, 'posts'), where('expiresAt', '>', now)),
    ),
    getCountFromServer(collection(db, 'conversations')),
    getCountFromServer(
      query(collection(db, 'reports'), where('status', '==', 'pending')),
    ).catch(() => ({ data: () => ({ count: 0 }) }) as any),
    getCountFromServer(collection(db, 'feedbacks')).catch(
      () => ({ data: () => ({ count: 0 }) }) as any,
    ),
  ]);

  return {
    totalUsers: usersSnap.data().count,
    totalPosts: postsSnap.data().count,
    activePosts: activePostsSnap.data().count,
    totalConversations: conversationsSnap.data().count,
    pendingReports: reportsSnap.data().count,
    pendingFeedbacks: feedbacksSnap.data().count,
  };
}

/**
 * Lê snapshots diários da coleção `analytics_daily`.
 * Retorna [] se a coleção ainda não existir (Cloud Function não rodou).
 */
export async function fetchDailySnapshots(days = 14): Promise<DailySnapshot[]> {
  try {
    const q = query(
      collection(db, 'analytics_daily'),
      orderBy('date', 'desc'),
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
    const snap = await getDoc(doc(db, 'analytics_daily', today));
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
