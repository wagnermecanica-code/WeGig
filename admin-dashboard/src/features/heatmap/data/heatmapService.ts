import { collection, getDocs, limit, orderBy, query } from "firebase/firestore";
import { db } from "@core/firebase/client";

export interface HeatmapBucket {
  state: string;
  city: string;
  posts: number;
  genres: Record<string, number>;
  instruments: Record<string, number>;
  lat?: number;
  lng?: number;
}

export interface GenreSummary {
  genre: string;
  posts: number;
}

function asStringArray(value: unknown): string[] {
  if (Array.isArray(value)) {
    return value
      .map((item) => (typeof item === "string" ? item.trim() : ""))
      .filter(Boolean);
  }
  if (typeof value === "string" && value.trim()) {
    return [value.trim()];
  }
  return [];
}

function pickNumber(value: unknown): number | undefined {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const n = Number(value);
    return Number.isFinite(n) ? n : undefined;
  }
  return undefined;
}

/**
 * Agrega buckets de posts por (estado, cidade), com contagem de gêneros/instrumentos
 * e centro geográfico médio quando há lat/lng disponíveis.
 */
export async function fetchMusicalHeatmap(
  sampleLimit = 1500,
): Promise<HeatmapBucket[]> {
  try {
    const snap = await getDocs(
      query(
        collection(db, "posts"),
        orderBy("createdAt", "desc"),
        limit(sampleLimit),
      ),
    );

    const buckets = new Map<
      string,
      HeatmapBucket & { latSum: number; lngSum: number; latCount: number }
    >();

    for (const doc of snap.docs) {
      const data = doc.data();
      const state = String(data.state ?? data.locationState ?? "").trim();
      const city = String(data.city ?? data.locationCity ?? "").trim();
      if (!state && !city) continue;

      const key = `${state || "—"}|${city || "—"}`;
      const bucket = buckets.get(key) ?? {
        state: state || "—",
        city: city || "—",
        posts: 0,
        genres: {} as Record<string, number>,
        instruments: {} as Record<string, number>,
        latSum: 0,
        lngSum: 0,
        latCount: 0,
      };

      bucket.posts += 1;

      for (const g of asStringArray(data.genres ?? data.genre)) {
        bucket.genres[g] = (bucket.genres[g] ?? 0) + 1;
      }
      for (const ins of asStringArray(data.instruments ?? data.instrument)) {
        bucket.instruments[ins] = (bucket.instruments[ins] ?? 0) + 1;
      }

      const lat =
        pickNumber(data.lat) ??
        pickNumber(data.latitude) ??
        pickNumber(data.location?.latitude);
      const lng =
        pickNumber(data.lng) ??
        pickNumber(data.longitude) ??
        pickNumber(data.location?.longitude);
      if (lat !== undefined && lng !== undefined) {
        bucket.latSum += lat;
        bucket.lngSum += lng;
        bucket.latCount += 1;
      }

      buckets.set(key, bucket);
    }

    return Array.from(buckets.values())
      .map((b) => ({
        state: b.state,
        city: b.city,
        posts: b.posts,
        genres: b.genres,
        instruments: b.instruments,
        lat: b.latCount > 0 ? b.latSum / b.latCount : undefined,
        lng: b.latCount > 0 ? b.lngSum / b.latCount : undefined,
      }))
      .sort((a, b) => b.posts - a.posts);
  } catch (err) {
    console.warn("[heatmapService] failed:", err);
    return [];
  }
}

export function summarizeGenres(buckets: HeatmapBucket[]): GenreSummary[] {
  const map = new Map<string, number>();
  for (const b of buckets) {
    for (const [genre, count] of Object.entries(b.genres)) {
      map.set(genre, (map.get(genre) ?? 0) + count);
    }
  }
  return Array.from(map.entries())
    .map(([genre, posts]) => ({ genre, posts }))
    .sort((a, b) => b.posts - a.posts);
}
