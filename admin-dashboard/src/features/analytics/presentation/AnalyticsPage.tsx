import { useEffect, useMemo, useState } from "react";
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Legend,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import {
  Activity,
  CalendarRange,
  Download,
  TrendingDown,
  Users,
  UserCheck,
  Timer,
  Sparkles,
} from "lucide-react";
import { StatCard } from "@shared/components/ui/StatCard";
import { Button } from "@shared/components/ui/Button";
import {
  Card,
  CardBody,
  CardHeader,
  CardTitle,
} from "@shared/components/ui/Card";
import { Skeleton } from "@shared/components/ui/Skeleton";
import { exportSheetsToXlsx, exportRowsToXlsx } from "@shared/utils/exportXlsx";
import {
  fetchActivationFunnel,
  fetchActivityMetrics,
  fetchChurnRate,
  fetchCohortBuckets,
  fetchGeoDistribution,
  type ActivityMetrics,
  type CohortBucket,
  type FunnelStep,
  type GeoBucket,
} from "../data/analyticsService";

function formatNumber(value: number) {
  return new Intl.NumberFormat("pt-BR").format(value);
}

function formatPercent(value: number) {
  return `${(value * 100).toFixed(1)}%`;
}

function formatDuration(seconds: number) {
  if (seconds <= 0) return "—";
  if (seconds < 60) return `${seconds}s`;
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${m}min ${s}s`;
}

const PIE_COLORS = [
  "#37475A",
  "#E47911",
  "#1F8FFF",
  "#22C55E",
  "#A855F7",
  "#EAB308",
  "#EF4444",
  "#0EA5E9",
];

export function AnalyticsPage() {
  const [activity, setActivity] = useState<ActivityMetrics | null>(null);
  const [funnel, setFunnel] = useState<FunnelStep[]>([]);
  const [cohorts, setCohorts] = useState<CohortBucket[]>([]);
  const [churn, setChurn] = useState<number>(0);
  const [geo, setGeo] = useState<GeoBucket[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    (async () => {
      try {
        const [a, f, c, ch, g] = await Promise.all([
          fetchActivityMetrics(),
          fetchActivationFunnel(),
          fetchCohortBuckets(6),
          fetchChurnRate(),
          fetchGeoDistribution(1500),
        ]);
        if (!active) return;
        setActivity(a);
        setFunnel(f);
        setCohorts(c);
        setChurn(ch);
        setGeo(g);
      } catch (err) {
        if (!active) return;
        setError(
          err instanceof Error ? err.message : "Erro ao carregar analytics",
        );
      } finally {
        if (active) setLoading(false);
      }
    })();
    return () => {
      active = false;
    };
  }, []);

  const geoStateBuckets = useMemo(() => {
    const map = new Map<string, number>();
    for (const row of geo) {
      const k = row.state || "—";
      map.set(k, (map.get(k) ?? 0) + row.profiles + row.posts);
    }
    return Array.from(map.entries())
      .map(([state, value]) => ({ state, value }))
      .sort((a, b) => b.value - a.value)
      .slice(0, 8);
  }, [geo]);

  function handleExportAll() {
    if (!activity) return;
    exportSheetsToXlsx("wegig-analytics", [
      {
        name: "Atividade",
        rows: [
          { metrica: "DAU", valor: activity.dau },
          { metrica: "WAU", valor: activity.wau },
          { metrica: "MAU", valor: activity.mau },
          {
            metrica: "Retenção D1",
            valor: formatPercent(activity.d1Retention),
          },
          {
            metrica: "Retenção D7",
            valor: formatPercent(activity.d7Retention),
          },
          {
            metrica: "Engajamento médio",
            valor: formatDuration(activity.avgEngagementSeconds),
          },
          { metrica: "Conteúdo total", valor: activity.totalContent },
          { metrica: "Churn 30d", valor: formatPercent(churn) },
        ],
      },
      {
        name: "Funil",
        rows: funnel.map((s) => ({ etapa: s.label, total: s.count })),
      },
      { name: "Coortes", rows: cohorts },
      { name: "Geografia", rows: geo },
    ]);
  }

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-3">
        <div>
          <h2 className="text-xl font-semibold tracking-tight dark:text-white">
            Analytics avançado
          </h2>
          <p className="text-sm text-gray-500 dark:text-slate-400">
            Cohorts, funis, churn, retenção e distribuição geográfica.
          </p>
        </div>
        <Button onClick={handleExportAll} disabled={!activity || loading}>
          <Download className="h-4 w-4" /> Exportar .xlsx
        </Button>
      </div>

      {error ? (
        <div className="rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-700 dark:bg-red-900/30 dark:border-red-900 dark:text-red-300">
          {error}
        </div>
      ) : null}

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {loading || !activity ? (
          Array.from({ length: 8 }).map((_, i) => (
            <Skeleton key={i} className="h-28" />
          ))
        ) : (
          <>
            <StatCard
              label="DAU"
              value={formatNumber(activity.dau)}
              icon={<Activity className="h-5 w-5" />}
              hint="Ativos hoje ou proxy legado"
            />
            <StatCard
              label="WAU"
              value={formatNumber(activity.wau)}
              icon={<Users className="h-5 w-5" />}
              hint="Últimos 7 dias ou proxy legado"
            />
            <StatCard
              label="MAU"
              value={formatNumber(activity.mau)}
              icon={<CalendarRange className="h-5 w-5" />}
              hint="Últimos 30 dias ou proxy legado"
            />
            <StatCard
              label="Conteúdo total"
              value={formatNumber(activity.totalContent)}
              icon={<Sparkles className="h-5 w-5" />}
              hint="Posts publicados"
            />
            <StatCard
              label="Retenção D1"
              value={formatPercent(activity.d1Retention)}
              icon={<UserCheck className="h-5 w-5" />}
              hint="Retorno D1 com dados legados"
            />
            <StatCard
              label="Retenção D7"
              value={formatPercent(activity.d7Retention)}
              icon={<UserCheck className="h-5 w-5" />}
              hint="Retorno D7 com dados legados"
            />
            <StatCard
              label="Engajamento médio"
              value={formatDuration(activity.avgEngagementSeconds)}
              icon={<Timer className="h-5 w-5" />}
              hint="Estimado por eventos legados"
            />
            <StatCard
              label="Churn 30d"
              value={formatPercent(churn)}
              icon={<TrendingDown className="h-5 w-5" />}
              hint="Inatividade 30d + proxy legado"
            />
          </>
        )}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <Card>
          <CardHeader>
            <CardTitle>Funil de ativação</CardTitle>
          </CardHeader>
          <CardBody>
            <div className="h-72 w-full">
              <ResponsiveContainer>
                <BarChart
                  data={funnel}
                  layout="vertical"
                  margin={{ top: 8, right: 16, left: 24, bottom: 0 }}
                >
                  <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                  <XAxis type="number" tick={{ fontSize: 11 }} />
                  <YAxis
                    dataKey="label"
                    type="category"
                    width={140}
                    tick={{ fontSize: 11 }}
                  />
                  <Tooltip />
                  <Bar dataKey="count" fill="#37475A" radius={[0, 4, 4, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </CardBody>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Distribuição por estado (top 8)</CardTitle>
          </CardHeader>
          <CardBody>
            <div className="h-72 w-full">
              <ResponsiveContainer>
                <PieChart>
                  <Pie
                    data={geoStateBuckets}
                    dataKey="value"
                    nameKey="state"
                    cx="50%"
                    cy="50%"
                    outerRadius={90}
                    label
                  >
                    {geoStateBuckets.map((_, i) => (
                      <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />
                    ))}
                  </Pie>
                  <Legend />
                  <Tooltip />
                </PieChart>
              </ResponsiveContainer>
            </div>
          </CardBody>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <div className="flex items-center justify-between gap-3">
            <CardTitle>Coortes (últimos 6 meses)</CardTitle>
            <Button
              variant="secondary"
              size="sm"
              onClick={() =>
                exportRowsToXlsx("wegig-coortes", "Coortes", cohorts)
              }
              disabled={cohorts.length === 0}
            >
              <Download className="h-3.5 w-3.5" /> Exportar
            </Button>
          </div>
        </CardHeader>
        <CardBody>
          {cohorts.length === 0 ? (
            <p className="text-sm text-gray-500 dark:text-slate-400">
              Sem dados de coorte disponíveis.
            </p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="text-left text-xs uppercase text-gray-500 dark:text-slate-400">
                    <th className="px-3 py-2">Coorte</th>
                    <th className="px-3 py-2">Novos</th>
                    <th className="px-3 py-2">D1</th>
                    <th className="px-3 py-2">D7</th>
                    <th className="px-3 py-2">D30</th>
                  </tr>
                </thead>
                <tbody>
                  {cohorts.map((c) => (
                    <tr
                      key={c.cohort}
                      className="border-t border-gray-100 dark:border-slate-800"
                    >
                      <td className="px-3 py-2 font-medium">{c.cohort}</td>
                      <td className="px-3 py-2">{formatNumber(c.newUsers)}</td>
                      <td className="px-3 py-2">
                        {c.newUsers > 0
                          ? `${formatNumber(c.d1)} (${((c.d1 / c.newUsers) * 100).toFixed(0)}%)`
                          : "—"}
                      </td>
                      <td className="px-3 py-2">
                        {c.newUsers > 0
                          ? `${formatNumber(c.d7)} (${((c.d7 / c.newUsers) * 100).toFixed(0)}%)`
                          : "—"}
                      </td>
                      <td className="px-3 py-2">
                        {c.newUsers > 0
                          ? `${formatNumber(c.d30)} (${((c.d30 / c.newUsers) * 100).toFixed(0)}%)`
                          : "—"}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardBody>
      </Card>
    </div>
  );
}
