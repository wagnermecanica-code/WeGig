import { useEffect, useState } from "react";
import {
  Area,
  AreaChart,
  Bar,
  BarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import {
  AlertTriangle,
  Bug,
  Download,
  Gauge,
  Layers,
  RefreshCw,
  Smartphone,
} from "lucide-react";
import {
  Card,
  CardBody,
  CardHeader,
  CardTitle,
} from "@shared/components/ui/Card";
import { StatCard } from "@shared/components/ui/StatCard";
import { Button } from "@shared/components/ui/Button";
import { Skeleton } from "@shared/components/ui/Skeleton";
import {
  fetchCrashlyticsSignals,
  type CrashBreakdownPoint,
  type CrashEvent,
  type CrashDailyPoint,
  type CrashIssuePoint,
  type CrashSummary,
} from "../data/crashlyticsService";

function formatNumber(value: number) {
  return new Intl.NumberFormat("pt-BR").format(value);
}

function formatPercent(value: number) {
  return `${(value * 100).toFixed(1)}%`;
}

const EMPTY_SUMMARY: CrashSummary = {
  totalEvents: 0,
  fatalEvents: 0,
  nonFatalEvents: 0,
  events7d: 0,
  affectedVersions: 0,
  affectedPlatforms: 0,
  fatalRate: 0,
  crashFreeUsersRate: null,
  crashFreeSessionsRate: null,
  totalUsers: null,
  totalSessions: null,
  affectedUsersEstimate: 0,
  affectedSessionsEstimate: 0,
};

function csvCell(value: unknown) {
  const raw = String(value ?? "");
  return `"${raw.replace(/"/g, '""')}"`;
}

export function CrashlyticsPage() {
  const [summary, setSummary] = useState<CrashSummary>(EMPTY_SUMMARY);
  const [events, setEvents] = useState<CrashEvent[]>([]);
  const [daily, setDaily] = useState<CrashDailyPoint[]>([]);
  const [topIssues, setTopIssues] = useState<CrashIssuePoint[]>([]);
  const [platforms, setPlatforms] = useState<CrashBreakdownPoint[]>([]);
  const [versions, setVersions] = useState<CrashBreakdownPoint[]>([]);
  const [source, setSource] = useState("sem dados");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  async function loadData() {
    setLoading(true);
    setError(null);
    try {
      const result = await fetchCrashlyticsSignals();
      setEvents(result.events);
      setSummary(result.summary);
      setDaily(result.daily);
      setTopIssues(result.topIssues);
      setPlatforms(result.platforms);
      setVersions(result.versions);
      setSource(result.source);
    } catch (err) {
      setError(
        err instanceof Error
          ? err.message
          : "Erro ao carregar indicadores de Crashlytics",
      );
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void loadData();
  }, []);

  function exportReport() {
    const header = [
      "id",
      "issue",
      "severity",
      "appVersion",
      "platform",
      "eventCount",
      "createdAt",
      "source",
    ];
    const rows = events.map((event) => [
      event.id,
      event.issue,
      event.severity,
      event.appVersion,
      event.platform,
      event.eventCount,
      event.createdAt?.toISOString() ?? "",
      source,
    ]);
    const summaryRows = [
      [],
      ["metric", "value"],
      ["totalEvents", summary.totalEvents],
      ["fatalEvents", summary.fatalEvents],
      ["nonFatalEvents", summary.nonFatalEvents],
      ["events7d", summary.events7d],
      ["affectedVersions", summary.affectedVersions],
      ["affectedPlatforms", summary.affectedPlatforms],
      ["crashFreeUsersRate", summary.crashFreeUsersRate ?? "unavailable"],
      ["crashFreeSessionsRate", summary.crashFreeSessionsRate ?? "unavailable"],
    ];
    const csv = [header, ...rows, ...summaryRows]
      .map((row) => row.map(csvCell).join(","))
      .join("\n");
    const blob = new Blob([csv], { type: "text/csv;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = `wegig-crashlytics-${new Date().toISOString().slice(0, 10)}.csv`;
    anchor.click();
    URL.revokeObjectURL(url);
  }

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-3">
        <div>
          <h2 className="text-xl font-semibold tracking-tight dark:text-white">
            Crashlytics
          </h2>
          <p className="text-sm text-gray-500 dark:text-slate-400">
            Indicadores de estabilidade, severidade e tendência de erros.
          </p>
          {!loading ? (
            <p className="mt-1 text-xs text-gray-400 dark:text-slate-500">
              Fonte: {source}
            </p>
          ) : null}
        </div>
        <div className="flex flex-wrap gap-2">
          <Button variant="secondary" onClick={() => void loadData()}>
            <RefreshCw className="h-4 w-4" /> Atualizar
          </Button>
          <Button variant="primary" onClick={exportReport} disabled={loading}>
            <Download className="h-4 w-4" /> Extrair relatório
          </Button>
        </div>
      </div>

      {error ? (
        <div className="rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-700 dark:bg-red-900/30 dark:border-red-900 dark:text-red-300">
          {error}
        </div>
      ) : null}

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {loading ? (
          Array.from({ length: 8 }).map((_, i) => (
            <Skeleton key={i} className="h-28" />
          ))
        ) : (
          <>
            <StatCard
              label="Erros totais"
              value={formatNumber(summary.totalEvents)}
              icon={<Bug className="h-5 w-5" />}
              hint="Volume consolidado"
            />
            <StatCard
              label="Falhas fatais"
              value={formatNumber(summary.fatalEvents)}
              icon={<AlertTriangle className="h-5 w-5" />}
              hint="Crashes críticos"
            />
            <StatCard
              label="Não fatais"
              value={formatNumber(summary.nonFatalEvents)}
              icon={<Layers className="h-5 w-5" />}
              hint="Warnings e exceptions"
            />
            <StatCard
              label="Últimos 7 dias"
              value={formatNumber(summary.events7d)}
              icon={<Gauge className="h-5 w-5" />}
              hint="Incidentes recentes"
            />
            <StatCard
              label="Taxa fatal"
              value={formatPercent(summary.fatalRate)}
              icon={<AlertTriangle className="h-5 w-5" />}
              hint="Fatal / total"
            />
            <StatCard
              label="Versões afetadas"
              value={formatNumber(summary.affectedVersions)}
              icon={<Layers className="h-5 w-5" />}
            />
            <StatCard
              label="Plataformas afetadas"
              value={formatNumber(summary.affectedPlatforms)}
              icon={<Smartphone className="h-5 w-5" />}
            />
            <StatCard
              label="Saúde geral"
              value={
                summary.totalEvents === 0
                  ? "Sem eventos"
                  : summary.fatalRate < 0.05
                    ? "Estável"
                    : summary.fatalRate < 0.15
                      ? "Atenção"
                      : "Crítico"
              }
              icon={<Gauge className="h-5 w-5" />}
              hint="Classificação heurística"
            />
            <StatCard
              label="Usuários sem falhas"
              value={
                summary.crashFreeUsersRate === null
                  ? "—"
                  : formatPercent(summary.crashFreeUsersRate)
              }
              icon={<Gauge className="h-5 w-5" />}
              hint={
                summary.totalUsers
                  ? `${summary.affectedUsersEstimate} afetados de ${summary.totalUsers}`
                  : "Sem denominador de usuários"
              }
            />
            <StatCard
              label="Sessões sem falhas"
              value={
                summary.crashFreeSessionsRate === null
                  ? "—"
                  : formatPercent(summary.crashFreeSessionsRate)
              }
              icon={<Gauge className="h-5 w-5" />}
              hint={
                summary.totalSessions
                  ? `${summary.affectedSessionsEstimate} afetadas de ${summary.totalSessions}`
                  : "Sem total de sessões exportado"
              }
            />
          </>
        )}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <Card>
          <CardHeader>
            <CardTitle>Plataformas afetadas</CardTitle>
          </CardHeader>
          <CardBody>
            {loading ? (
              <Skeleton className="h-32" />
            ) : platforms.length === 0 ? (
              <p className="text-sm text-gray-500 dark:text-slate-400">Sem plataformas.</p>
            ) : (
              <div className="space-y-2 text-sm">
                {platforms.map((item) => (
                  <div key={item.label} className="flex items-center justify-between gap-3 rounded border border-gray-100 px-3 py-2 dark:border-slate-800">
                    <span className="font-medium text-gray-700 dark:text-slate-200">{item.label}</span>
                    <span className="text-xs text-gray-500 dark:text-slate-400">{item.total} total · {item.fatal} fatal · {item.nonFatal} não fatal</span>
                  </div>
                ))}
              </div>
            )}
          </CardBody>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Versões afetadas</CardTitle>
          </CardHeader>
          <CardBody>
            {loading ? (
              <Skeleton className="h-32" />
            ) : versions.length === 0 ? (
              <p className="text-sm text-gray-500 dark:text-slate-400">Sem versões.</p>
            ) : (
              <div className="space-y-2 text-sm">
                {versions.map((item) => (
                  <div key={item.label} className="flex items-center justify-between gap-3 rounded border border-gray-100 px-3 py-2 dark:border-slate-800">
                    <span className="font-medium text-gray-700 dark:text-slate-200">{item.label}</span>
                    <span className="text-xs text-gray-500 dark:text-slate-400">{item.total} total · {item.fatal} fatal · {item.nonFatal} não fatal</span>
                  </div>
                ))}
              </div>
            )}
          </CardBody>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <Card>
          <CardHeader>
            <CardTitle>Tendência diária (14 dias)</CardTitle>
          </CardHeader>
          <CardBody>
            {loading ? (
              <Skeleton className="h-72" />
            ) : (
              <div className="h-72 w-full">
                <ResponsiveContainer>
                  <AreaChart
                    data={daily}
                    margin={{ top: 8, right: 16, left: 0, bottom: 0 }}
                  >
                    <defs>
                      <linearGradient id="fatal" x1="0" y1="0" x2="0" y2="1">
                        <stop
                          offset="0%"
                          stopColor="#dc2626"
                          stopOpacity={0.35}
                        />
                        <stop
                          offset="100%"
                          stopColor="#dc2626"
                          stopOpacity={0}
                        />
                      </linearGradient>
                      <linearGradient id="nonFatal" x1="0" y1="0" x2="0" y2="1">
                        <stop
                          offset="0%"
                          stopColor="#2563eb"
                          stopOpacity={0.3}
                        />
                        <stop
                          offset="100%"
                          stopColor="#2563eb"
                          stopOpacity={0}
                        />
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                    <XAxis dataKey="date" tick={{ fontSize: 11 }} />
                    <YAxis tick={{ fontSize: 11 }} />
                    <Tooltip />
                    <Area
                      type="monotone"
                      dataKey="fatal"
                      stroke="#dc2626"
                      fill="url(#fatal)"
                      strokeWidth={2}
                      name="Fatal"
                    />
                    <Area
                      type="monotone"
                      dataKey="nonFatal"
                      stroke="#2563eb"
                      fill="url(#nonFatal)"
                      strokeWidth={2}
                      name="Não fatal"
                    />
                  </AreaChart>
                </ResponsiveContainer>
              </div>
            )}
          </CardBody>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Top issues</CardTitle>
          </CardHeader>
          <CardBody>
            {loading ? (
              <Skeleton className="h-72" />
            ) : topIssues.length === 0 ? (
              <p className="text-sm text-gray-500 dark:text-slate-400">
                Nenhum evento encontrado no Firestore nem no fallback publicado.
              </p>
            ) : (
              <div className="h-72 w-full">
                <ResponsiveContainer>
                  <BarChart
                    data={topIssues}
                    layout="vertical"
                    margin={{ top: 8, right: 16, left: 12, bottom: 0 }}
                  >
                    <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                    <XAxis type="number" tick={{ fontSize: 11 }} />
                    <YAxis
                      type="category"
                      dataKey="issue"
                      width={170}
                      tick={{ fontSize: 11 }}
                    />
                    <Tooltip />
                    <Bar dataKey="total" fill="#37475A" radius={[0, 4, 4, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            )}
          </CardBody>
        </Card>
      </div>
    </div>
  );
}
