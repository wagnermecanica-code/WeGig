import {
  collection,
  getDocs,
  limit,
  orderBy,
  query,
  where,
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
}

export interface CrashSummary {
  totalEvents: number;
  fatalEvents: number;
  nonFatalEvents: number;
  events24h: number;
  affectedVersions: number;
  affectedPlatforms: number;
  fatalRate: number;
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

function pickString(data: Record<string, any>, keys: string[], fallback: string) {
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
  if (raw.includes("fatal") || raw.includes("critical") || raw === "crash") {
    return "fatal";
  }
  const boolFatal = data.isFatal;
  if (boolFatal === true) return "fatal";
  return "non_fatal";
}

async function tryReadCollection(name: string, take = 500): Promise<CrashEvent[]> {
  const col = collection(db, name);

  // Prioriza ordenação temporal para tendência; em ausência de índice, faz fallback.
  const ordered = await getDocs(
    query(col, orderBy("createdAt", "desc"), limit(take)),
  ).catch(() => null);

  const snap =
    ordered ??
    (await getDocs(query(col, limit(take))).catch(() => null));

  if (!snap || snap.empty) return [];

  return snap.docs.map((doc) => {
    const data = doc.data();
    return {
      id: doc.id,
      issue: pickString(data, ["issue", "title", "error", "message", "exception"], "(sem título)"),
      severity: parseSeverity(data),
      appVersion: pickString(data, ["appVersion", "version", "buildVersion"], "desconhecida"),
      platform: pickString(data, ["platform", "os", "devicePlatform"], "desconhecido"),
      eventCount: pickNumber(data, ["count", "occurrences", "eventCount"], 1),
      createdAt: parseTimestampLike(data.createdAt ?? data.timestamp ?? data.updatedAt),
    };
  });
}

export async function fetchCrashEvents(): Promise<CrashEvent[]> {
  for (const collectionName of CANDIDATE_COLLECTIONS) {
    try {
      const events = await tryReadCollection(collectionName);
      if (events.length > 0) return events;
    } catch (err) {
      console.warn(`[crashlyticsService] failed ${collectionName}:`, err);
    }
  }
  return [];
}

export function buildCrashSummary(events: CrashEvent[]): CrashSummary {
  const totalEvents = events.reduce((sum, e) => sum + e.eventCount, 0);
  const fatalEvents = events
    .filter((e) => e.severity === "fatal")
    .reduce((sum, e) => sum + e.eventCount, 0);
  const nonFatalEvents = totalEvents - fatalEvents;

  const threshold = new Date(Date.now() - 24 * 60 * 60 * 1000);
  const events24h = events
    .filter((e) => e.createdAt && e.createdAt >= threshold)
    .reduce((sum, e) => sum + e.eventCount, 0);

  const affectedVersions = new Set(events.map((e) => e.appVersion)).size;
  const affectedPlatforms = new Set(events.map((e) => e.platform)).size;

  return {
    totalEvents,
    fatalEvents,
    nonFatalEvents,
    events24h,
    affectedVersions,
    affectedPlatforms,
    fatalRate: totalEvents > 0 ? fatalEvents / totalEvents : 0,
  };
}

export function buildCrashDailySeries(events: CrashEvent[], days = 14): CrashDailyPoint[] {
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

export function buildTopIssues(events: CrashEvent[], top = 8): CrashIssuePoint[] {
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

export async function fetchCrashlyticsSignals(): Promise<{
  events: CrashEvent[];
  summary: CrashSummary;
  daily: CrashDailyPoint[];
  topIssues: CrashIssuePoint[];
}> {
  const events = await fetchCrashEvents();
  return {
    events,
    summary: buildCrashSummary(events),
    daily: buildCrashDailySeries(events),
    topIssues: buildTopIssues(events),
  };
}
