import {
  collection,
  collectionGroup,
  getCountFromServer,
  getDocs,
  limit,
  orderBy,
  query,
  Timestamp,
} from "firebase/firestore";
import { db } from "@core/firebase/client";

export interface CrashEvent {
  id: string;
  issue: string;
  severity: "fatal" | "non_fatal";
  appVersion: string;
  platform: string;
  eventCount: number;
  createdAt: Date | null;
  userId?: string;
  sessionId?: string;
}

export interface CrashSummary {
  totalEvents: number;
  fatalEvents: number;
  nonFatalEvents: number;
  events7d: number;
  affectedVersions: number;
  affectedPlatforms: number;
  fatalRate: number;
  crashFreeUsersRate: number | null;
  crashFreeSessionsRate: number | null;
  totalUsers: number | null;
  totalSessions: number | null;
  affectedUsersEstimate: number;
  affectedSessionsEstimate: number;
}

export interface CrashDailyPoint {
  date: string;
  fatal: number;
  nonFatal: number;
  total: number;
}

export interface CrashIssuePoint {
  issue: string;
  total: number;
  fatal: number;
}

export interface CrashBreakdownPoint {
  label: string;
  total: number;
  fatal: number;
  nonFatal: number;
}

export interface CrashlyticsSignals {
  events: CrashEvent[];
  summary: CrashSummary;
  daily: CrashDailyPoint[];
  topIssues: CrashIssuePoint[];
  platforms: CrashBreakdownPoint[];
  versions: CrashBreakdownPoint[];
  source: string;
}

const CANDIDATE_COLLECTIONS = [
  "crashlytics_issues",
  "crashlyticsIssues",
  "crashlytics_events",
  "crashlyticsEvents",
  "crash_reports",
  "crashReports",
  "app_crashes",
  "appCrashes",
];

const SESSION_COLLECTIONS = [
  "sessions",
  "app_sessions",
  "appSessions",
  "analytics_sessions",
  "analyticsSessions",
  "user_sessions",
  "userSessions",
];

function parseTimestampLike(value: unknown): Date | null {
  if (!value) return null;
  if (value instanceof Date) return value;
  if (value instanceof Timestamp) return value.toDate();
  if (typeof value === "object" && value !== null) {
    const maybe = value as { toDate?: () => Date };
    if (typeof maybe.toDate === "function") return maybe.toDate();
  }
  return null;
}

function parseExternalDate(value: unknown): Date | null {
  if (typeof value !== "string") return parseTimestampLike(value);
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function pickString(
  data: Record<string, any>,
  keys: string[],
  fallback: string,
) {
  for (const key of keys) {
    const value = data[key];
    if (typeof value === "string" && value.trim()) return value.trim();
  }
  return fallback;
}

function pickNumber(data: Record<string, any>, keys: string[], fallback = 1) {
  for (const key of keys) {
    const value = data[key];
    if (typeof value === "number" && Number.isFinite(value)) {
      return Math.max(1, Math.round(value));
    }
    if (typeof value === "string") {
      const n = Number(value);
      if (Number.isFinite(n)) return Math.max(1, Math.round(n));
    }
  }
  return fallback;
}

function parseSeverity(data: Record<string, any>): "fatal" | "non_fatal" {
  const raw = String(
    data.severity ?? data.type ?? data.eventType ?? data.level ?? "",
  ).toLowerCase();
  if (
    raw.includes("non_fatal") ||
    raw.includes("non-fatal") ||
    raw.includes("warning") ||
    raw.includes("handled")
  ) {
    return "non_fatal";
  }
  if (raw.includes("fatal") || raw.includes("critical") || raw === "crash") {
    return "fatal";
  }
  const boolFatal = data.isFatal;
  if (boolFatal === true) return "fatal";
  return "non_fatal";
}

async function tryReadCollection(
  name: string,
  take = 500,
): Promise<CrashEvent[]> {
  const col = collection(db, name);

  // Prioriza ordenação temporal para tendência; em ausência de índice, faz fallback.
  const ordered = await getDocs(
    query(col, orderBy("createdAt", "desc"), limit(take)),
  ).catch(() => null);

  const snap =
    ordered ?? (await getDocs(query(col, limit(take))).catch(() => null));

  if (!snap || snap.empty) return [];

  return snap.docs.map((doc) => {
    const data = doc.data();
    return {
      id: doc.id,
      issue: pickString(
        data,
        ["issue", "title", "error", "message", "exception"],
        "(sem título)",
      ),
      severity: parseSeverity(data),
      appVersion: pickString(
        data,
        ["appVersion", "version", "buildVersion"],
        "desconhecida",
      ),
      platform: pickString(
        data,
        ["platform", "os", "devicePlatform"],
        "desconhecido",
      ),
      eventCount: pickNumber(data, ["count", "occurrences", "eventCount"], 1),
      createdAt: parseTimestampLike(
        data.createdAt ?? data.timestamp ?? data.updatedAt,
      ),
      userId: pickString(data, ["userId", "uid", "ownerUid"], ""),
      sessionId: pickString(data, ["sessionId", "session"], ""),
    };
  });
}

async function fetchLocalCrashEvents(): Promise<{
  events: CrashEvent[];
  source: string;
}> {
  const response = await fetch("/admin/crashlytics-local-events.json", {
    cache: "no-store",
  }).catch(() => null);

  if (!response?.ok) return { events: [], source: "sem dados" };

  const payload = await response.json().catch(() => null);
  if (!payload || !Array.isArray(payload.events)) {
    return { events: [], source: "sem dados" };
  }

  return {
    source: payload.source ?? "fallback local",
    events: payload.events.map((event: Record<string, any>) => ({
      id: String(
        event.id ?? `${event.issue ?? "issue"}-${event.createdAt ?? "unknown"}`,
      ),
      issue: pickString(event, ["issue", "title", "message"], "(sem título)"),
      severity: parseSeverity(event),
      appVersion: pickString(
        event,
        ["appVersion", "version", "buildVersion"],
        "desconhecida",
      ),
      platform: pickString(event, ["platform", "os"], "desconhecido"),
      eventCount: pickNumber(event, ["eventCount", "count", "occurrences"], 1),
      createdAt: parseExternalDate(event.createdAt ?? event.timestamp),
      userId: pickString(event, ["userId", "uid", "ownerUid"], ""),
      sessionId: pickString(event, ["sessionId", "session"], ""),
    })),
  };
}

export async function fetchCrashEvents(): Promise<{
  events: CrashEvent[];
  source: string;
}> {
  for (const collectionName of CANDIDATE_COLLECTIONS) {
    try {
      const events = await tryReadCollection(collectionName);
      if (events.length > 0) {
        return { events, source: `Firestore: ${collectionName}` };
      }
    } catch (err) {
      console.warn(`[crashlyticsService] failed ${collectionName}:`, err);
    }
  }
  return fetchLocalCrashEvents();
}

async function countProfilesSafe(): Promise<number | null> {
  try {
    const snap = await getCountFromServer(collection(db, "profiles"));
    return snap.data().count ?? null;
  } catch {
    return null;
  }
}

async function countCollectionSafe(name: string): Promise<number> {
  try {
    const snap = await getCountFromServer(collection(db, name));
    return snap.data().count ?? 0;
  } catch {
    return 0;
  }
}

async function countActivityProxySafe(): Promise<number> {
  const [posts, interests, messages] = await Promise.all([
    countCollectionSafe("posts"),
    countCollectionSafe("interests"),
    getCountFromServer(collectionGroup(db, "messages"))
      .then((snap) => snap.data().count ?? 0)
      .catch(() => 0),
  ]);
  return posts + interests + messages;
}

async function countSessionsSafe(
  affectedSessionsEstimate: number,
  totalUsers: number | null,
  totalEvents: number,
): Promise<number | null> {
  for (const collectionName of SESSION_COLLECTIONS) {
    const count = await countCollectionSafe(collectionName);
    if (count > 0) return Math.max(count, affectedSessionsEstimate);
  }

  const activityProxy = await countActivityProxySafe();
  const fallback = Math.max(
    activityProxy,
    totalUsers ?? 0,
    totalEvents,
    affectedSessionsEstimate,
  );

  return fallback > 0 ? fallback : null;
}

function computeCrashFreeRate(total: number | null, affected: number) {
  if (!total || total <= 0) return null;
  return Math.max(0, Math.min(1, (total - affected) / total));
}

export async function buildCrashSummary(
  events: CrashEvent[],
): Promise<CrashSummary> {
  const totalEvents = events.reduce((sum, e) => sum + e.eventCount, 0);
  const fatalEvents = events
    .filter((e) => e.severity === "fatal")
    .reduce((sum, e) => sum + e.eventCount, 0);
  const nonFatalEvents = totalEvents - fatalEvents;

  const threshold7d = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
  const events7d = events
    .filter((e) => e.createdAt && e.createdAt >= threshold7d)
    .reduce((sum, e) => sum + e.eventCount, 0);

  const affectedVersions = new Set(events.map((e) => e.appVersion)).size;
  const affectedPlatforms = new Set(events.map((e) => e.platform)).size;
  const explicitUsers = new Set(events.map((e) => e.userId).filter(Boolean));
  const explicitSessions = new Set(
    events.map((e) => e.sessionId).filter(Boolean),
  );
  const affectedUsersEstimate =
    explicitUsers.size || Math.min(events.length, totalEvents);
  const affectedSessionsEstimate =
    explicitSessions.size || Math.min(events.length, totalEvents);
  const totalUsers = await countProfilesSafe();
  const totalSessions = await countSessionsSafe(
    affectedSessionsEstimate,
    totalUsers,
    totalEvents,
  );

  return {
    totalEvents,
    fatalEvents,
    nonFatalEvents,
    events7d,
    affectedVersions,
    affectedPlatforms,
    fatalRate: totalEvents > 0 ? fatalEvents / totalEvents : 0,
    crashFreeUsersRate: computeCrashFreeRate(totalUsers, affectedUsersEstimate),
    crashFreeSessionsRate: computeCrashFreeRate(
      totalSessions,
      affectedSessionsEstimate,
    ),
    totalUsers,
    totalSessions,
    affectedUsersEstimate,
    affectedSessionsEstimate,
  };
}

export function buildCrashBreakdown(
  events: CrashEvent[],
  key: "platform" | "appVersion",
): CrashBreakdownPoint[] {
  const buckets = new Map<string, CrashBreakdownPoint>();

  for (const event of events) {
    const label = event[key] || "desconhecido";
    const row = buckets.get(label) ?? {
      label,
      total: 0,
      fatal: 0,
      nonFatal: 0,
    };
    row.total += event.eventCount;
    if (event.severity === "fatal") row.fatal += event.eventCount;
    else row.nonFatal += event.eventCount;
    buckets.set(label, row);
  }

  return Array.from(buckets.values()).sort((a, b) => b.total - a.total);
}

export function buildCrashDailySeries(
  events: CrashEvent[],
  days = 14,
): CrashDailyPoint[] {
  const now = new Date();
  const seed = new Map<string, CrashDailyPoint>();

  for (let i = days - 1; i >= 0; i -= 1) {
    const d = new Date(now);
    d.setDate(now.getDate() - i);
    const key = d.toISOString().slice(0, 10);
    seed.set(key, { date: key, fatal: 0, nonFatal: 0, total: 0 });
  }

  for (const event of events) {
    if (!event.createdAt) continue;
    const key = event.createdAt.toISOString().slice(0, 10);
    const row = seed.get(key);
    if (!row) continue;

    if (event.severity === "fatal") {
      row.fatal += event.eventCount;
    } else {
      row.nonFatal += event.eventCount;
    }
    row.total += event.eventCount;
  }

  return Array.from(seed.values());
}

export function buildTopIssues(
  events: CrashEvent[],
  top = 8,
): CrashIssuePoint[] {
  const agg = new Map<string, CrashIssuePoint>();

  for (const event of events) {
    const key = event.issue;
    const row = agg.get(key) ?? { issue: key, total: 0, fatal: 0 };
    row.total += event.eventCount;
    if (event.severity === "fatal") row.fatal += event.eventCount;
    agg.set(key, row);
  }

  return Array.from(agg.values())
    .sort((a, b) => b.total - a.total)
    .slice(0, top);
}

export async function fetchCrashlyticsSignals(): Promise<CrashlyticsSignals> {
  const { events, source } = await fetchCrashEvents();
  return {
    events,
    summary: await buildCrashSummary(events),
    daily: buildCrashDailySeries(events),
    topIssues: buildTopIssues(events),
    platforms: buildCrashBreakdown(events, "platform"),
    versions: buildCrashBreakdown(events, "appVersion"),
    source,
  };
}
