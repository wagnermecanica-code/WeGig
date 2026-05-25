import { useEffect, useMemo, useState } from "react";
import {
  Bar,
  BarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { Download, Music2, MapPin } from "lucide-react";
import {
  Card,
  CardBody,
  CardHeader,
  CardTitle,
} from "@shared/components/ui/Card";
import { Button } from "@shared/components/ui/Button";
import { Skeleton } from "@shared/components/ui/Skeleton";
import {
  exportSheetsToXlsx,
} from "@shared/utils/exportXlsx";
import {
  fetchMusicalHeatmap,
  summarizeGenres,
  type HeatmapBucket,
  type GenreSummary,
} from "../data/heatmapService";

function formatNumber(value: number) {
  return new Intl.NumberFormat("pt-BR").format(value);
}

function topEntries(map: Record<string, number>, max = 3): string {
  return Object.entries(map)
    .sort((a, b) => b[1] - a[1])
    .slice(0, max)
    .map(([k, v]) => `${k} (${v})`)
    .join(", ");
}

export function HeatmapPage() {
  const [buckets, setBuckets] = useState<HeatmapBucket[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    (async () => {
      try {
        const data = await fetchMusicalHeatmap(1500);
        if (!active) return;
        setBuckets(data);
      } catch (err) {
        if (!active) return;
        setError(err instanceof Error ? err.message : "Erro ao carregar heatmap");
      } finally {
        if (active) setLoading(false);
      }
    })();
    return () => {
      active = false;
    };
  }, []);

  const genreChartData: GenreSummary[] = useMemo(
    () => summarizeGenres(buckets).slice(0, 10),
    [buckets],
  );

  const topCities = useMemo(() => buckets.slice(0, 25), [buckets]);
  const maxPosts = useMemo(
    () => topCities.reduce((acc, b) => Math.max(acc, b.posts), 0),
    [topCities],
  );

  function handleExport() {
    exportSheetsToXlsx("wegig-heatmap", [
      {
        name: "Cidades",
        rows: buckets.map((b) => ({
          estado: b.state,
          cidade: b.city,
          posts: b.posts,
          generos: topEntries(b.genres, 5),
          instrumentos: topEntries(b.instruments, 5),
          lat: b.lat ?? "",
          lng: b.lng ?? "",
        })),
      },
      {
        name: "Generos",
        rows: summarizeGenres(buckets),
      },
    ]);
  }

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-3">
        <div>
          <h2 className="text-xl font-semibold tracking-tight dark:text-white">
            Heatmap musical
          </h2>
          <p className="text-sm text-gray-500 dark:text-slate-400">
            Concentração geográfica e estilos musicais predominantes na base.
          </p>
        </div>
        <Button onClick={handleExport} disabled={loading || buckets.length === 0}>
          <Download className="h-4 w-4" /> Exportar .xlsx
        </Button>
      </div>

      {error ? (
        <div className="rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-700 dark:bg-red-900/30 dark:border-red-900 dark:text-red-300">
          {error}
        </div>
      ) : null}

      <Card>
        <CardHeader>
          <CardTitle>Top gêneros musicais</CardTitle>
        </CardHeader>
        <CardBody>
          {loading ? (
            <Skeleton className="h-72" />
          ) : (
            <div className="h-72 w-full">
              <ResponsiveContainer>
                <BarChart
                  data={genreChartData}
                  margin={{ top: 8, right: 16, left: 0, bottom: 0 }}
                >
                  <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                  <XAxis dataKey="genre" tick={{ fontSize: 11 }} />
                  <YAxis tick={{ fontSize: 11 }} />
                  <Tooltip />
                  <Bar dataKey="posts" fill="#E47911" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          )}
        </CardBody>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Top cidades (musical heatmap)</CardTitle>
        </CardHeader>
        <CardBody className="space-y-2">
          {loading ? (
            <>
              <Skeleton className="h-10" />
              <Skeleton className="h-10" />
              <Skeleton className="h-10" />
            </>
          ) : topCities.length === 0 ? (
            <p className="text-sm text-gray-500 dark:text-slate-400">
              Sem dados geográficos suficientes.
            </p>
          ) : (
            <div className="space-y-2">
              {topCities.map((bucket) => {
                const percent =
                  maxPosts > 0 ? Math.round((bucket.posts / maxPosts) * 100) : 0;
                return (
                  <div
                    key={`${bucket.state}-${bucket.city}`}
                    className="rounded-lg border border-gray-100 dark:border-slate-800 p-3"
                  >
                    <div className="flex items-center justify-between text-sm">
                      <span className="flex items-center gap-2 font-medium">
                        <MapPin className="h-4 w-4 text-gray-400" />
                        {bucket.city}, {bucket.state}
                      </span>
                      <span className="text-xs text-gray-500 dark:text-slate-400">
                        {formatNumber(bucket.posts)} posts
                      </span>
                    </div>
                    <div className="mt-2 h-2 w-full rounded-full bg-gray-100 dark:bg-slate-800 overflow-hidden">
                      <div
                        className="h-full bg-primary"
                        style={{ width: `${percent}%` }}
                      />
                    </div>
                    <div className="mt-2 grid grid-cols-1 sm:grid-cols-2 gap-2 text-xs text-gray-500 dark:text-slate-400">
                      <div className="flex items-center gap-1">
                        <Music2 className="h-3.5 w-3.5" />
                        Gêneros: {topEntries(bucket.genres) || "—"}
                      </div>
                      <div>Instrumentos: {topEntries(bucket.instruments) || "—"}</div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </CardBody>
      </Card>
    </div>
  );
}
