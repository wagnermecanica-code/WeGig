import { useEffect, useState } from "react";
import {
  ResponsiveContainer,
  AreaChart,
  Area,
  CartesianGrid,
  XAxis,
  YAxis,
  Tooltip,
} from "recharts";
import {
  Users,
  FileText,
  MessageSquare,
  MessageCircle,
  ShieldAlert,
  TrendingUp,
  Activity,
  Heart,
} from "lucide-react";
import { StatCard } from "@shared/components/ui/StatCard";
import {
  Card,
  CardBody,
  CardHeader,
  CardTitle,
} from "@shared/components/ui/Card";
import { Skeleton } from "@shared/components/ui/Skeleton";
import {
  fetchDailySnapshots,
  fetchOverviewMetrics,
  fetchTodaySnapshot,
  type DailySnapshot,
  type OverviewMetrics,
} from "../data/metricsService";

function formatNumber(value: number): string {
  return new Intl.NumberFormat("pt-BR").format(value);
}

function buildEmptySeries(days: number): DailySnapshot[] {
  const result: DailySnapshot[] = [];
  const now = new Date();

  for (let i = days - 1; i >= 0; i -= 1) {
    const d = new Date(now);
    d.setDate(now.getDate() - i);
    result.push({
      date: d.toISOString().slice(0, 10),
      dau: 0,
      newPosts: 0,
      newUsers: 0,
      messagesSent: 0,
    });
  }

  return result;
}

export function DashboardPage() {
  const chartDays = 14;
  const [overview, setOverview] = useState<OverviewMetrics | null>(null);
  const [series, setSeries] = useState<DailySnapshot[]>([]);
  const [seriesIsFallback, setSeriesIsFallback] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    (async () => {
      try {
        const [ov, snaps] = await Promise.all([
          fetchOverviewMetrics(),
          fetchDailySnapshots(chartDays),
        ]);
        if (!active) return;

        if (snaps.length === 0) {
          const today = await fetchTodaySnapshot();
          if (today) {
            setSeries([today]);
            setSeriesIsFallback(false);
          } else {
            setSeries(buildEmptySeries(chartDays));
            setSeriesIsFallback(true);
          }
        } else {
          setSeries(snaps);
          setSeriesIsFallback(false);
        }

        setOverview(ov);
      } catch (err) {
        if (!active) return;
        setError(
          err instanceof Error ? err.message : "Erro ao carregar métricas",
        );
      } finally {
        if (active) setLoading(false);
      }
    })();
    return () => {
      active = false;
    };
  }, []);

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-xl font-semibold tracking-tight dark:text-white">
          Dashboard Executivo
        </h2>
        <p className="text-sm text-gray-500 dark:text-slate-400">
          Visão geral da plataforma em tempo real.
        </p>
      </div>

      {error ? (
        <div className="rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-700 dark:bg-red-900/30 dark:border-red-900 dark:text-red-300">
          {error}
        </div>
      ) : null}

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        {loading || !overview ? (
          Array.from({ length: 8 }).map((_, i) => (
            <Skeleton key={i} className="h-28" />
          ))
        ) : (
          <>
            <StatCard
              label="Usuários totais"
              value={formatNumber(overview.totalUsers)}
              icon={<Users className="h-5 w-5" />}
              hint="Perfis cadastrados"
            />
            <StatCard
              label="Posts ativos"
              value={formatNumber(overview.activePosts)}
              icon={<FileText className="h-5 w-5" />}
              hint={`${formatNumber(overview.totalPosts)} no total`}
            />
            <StatCard
              label="Conversas"
              value={formatNumber(overview.totalConversations)}
              icon={<MessageSquare className="h-5 w-5" />}
            />
            <StatCard
              label="Comentários"
              value={formatNumber(overview.totalComments)}
              icon={<MessageCircle className="h-5 w-5" />}
            />
            <StatCard
              label="Interesses"
              value={formatNumber(overview.totalInterests)}
              icon={<Heart className="h-5 w-5" />}
            />
            <StatCard
              label="Reports pendentes"
              value={formatNumber(overview.pendingReports)}
              icon={<ShieldAlert className="h-5 w-5" />}
              hint="Aguardando moderação"
            />
            <StatCard
              label="Feedbacks"
              value={formatNumber(overview.pendingFeedbacks)}
              icon={<Activity className="h-5 w-5" />}
            />
            <StatCard
              label="Engajamento"
              value={
                overview.totalUsers > 0
                  ? `${((overview.totalConversations / overview.totalUsers) * 100).toFixed(1)}%`
                  : "—"
              }
              icon={<TrendingUp className="h-5 w-5" />}
              hint="Conversas / Usuários"
            />
          </>
        )}
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Atividade diária (últimos {chartDays} dias)</CardTitle>
        </CardHeader>
        <CardBody>
          {seriesIsFallback ? (
            <div className="mb-3 rounded-md border border-amber-200 bg-amber-50 px-3 py-2 text-xs text-amber-800 dark:border-amber-800 dark:bg-amber-900/30 dark:text-amber-300">
              Dados agregados ainda não disponíveis. Exibindo série temporária
              até a primeira execução do agregador diário.
            </div>
          ) : null}

          <div className="h-72 w-full">
            <ResponsiveContainer>
              <AreaChart
                data={series}
                margin={{ top: 8, right: 16, left: 0, bottom: 0 }}
              >
                <defs>
                  <linearGradient id="dau" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#37475A" stopOpacity={0.4} />
                    <stop offset="100%" stopColor="#37475A" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                <XAxis dataKey="date" tick={{ fontSize: 11 }} />
                <YAxis tick={{ fontSize: 11 }} />
                <Tooltip />
                <Area
                  type="monotone"
                  dataKey="dau"
                  stroke="#37475A"
                  fill="url(#dau)"
                  strokeWidth={2}
                  name="DAU"
                />
                <Area
                  type="monotone"
                  dataKey="newPosts"
                  stroke="#E47911"
                  fill="transparent"
                  strokeWidth={2}
                  name="Novos posts"
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </CardBody>
      </Card>
    </div>
  );
}
