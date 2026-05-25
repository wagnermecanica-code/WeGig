import { useCallback, useEffect, useMemo, useState } from "react";
import {
  BadgeCheck,
  Download,
  RefreshCw,
  ShieldCheck,
  ShieldOff,
  ShieldQuestion,
} from "lucide-react";
import {
  Card,
  CardBody,
  CardHeader,
  CardTitle,
} from "@shared/components/ui/Card";
import { Button } from "@shared/components/ui/Button";
import { Badge } from "@shared/components/ui/Badge";
import { Skeleton } from "@shared/components/ui/Skeleton";
import { exportRowsToXlsx } from "@shared/utils/exportXlsx";
import {
  adjustReputationScore,
  listReputationProfiles,
  setVerificationStatus,
  type ReputationProfile,
  type VerificationStatus,
} from "../data/reputationService";

const STATUS_FILTERS: {
  key: VerificationStatus | "all";
  label: string;
}[] = [
  { key: "all", label: "Todos" },
  { key: "pending", label: "Pendentes" },
  { key: "verified", label: "Verificados" },
  { key: "rejected", label: "Rejeitados" },
  { key: "unverified", label: "Não verificados" },
];

const STATUS_TONE: Record<VerificationStatus, Parameters<typeof Badge>[0]["tone"]> = {
  verified: "success",
  pending: "warning",
  rejected: "danger",
  unverified: "neutral",
};

const STATUS_LABEL: Record<VerificationStatus, string> = {
  verified: "Verificado",
  pending: "Pendente",
  rejected: "Rejeitado",
  unverified: "Não verificado",
};

function formatDate(date?: Date) {
  if (!date) return "—";
  return date.toLocaleDateString("pt-BR");
}

export function ReputationPage() {
  const [status, setStatus] = useState<VerificationStatus | "all">("all");
  const [search, setSearch] = useState("");
  const [profiles, setProfiles] = useState<ReputationProfile[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [pendingId, setPendingId] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const items = await listReputationProfiles({
        status,
        search,
        pageSize: 100,
      });
      setProfiles(items);
    } catch (err) {
      setError(
        err instanceof Error ? err.message : "Erro ao carregar perfis",
      );
    } finally {
      setLoading(false);
    }
  }, [status, search]);

  useEffect(() => {
    load();
  }, [load]);

  async function handleSetStatus(
    profile: ReputationProfile,
    next: VerificationStatus,
  ) {
    setPendingId(profile.id);
    try {
      await setVerificationStatus(profile.id, next);
      setProfiles((prev) =>
        prev.map((p) =>
          p.id === profile.id ? { ...p, verification: next } : p,
        ),
      );
    } catch (err) {
      console.warn("[ReputationPage] set status failed", err);
    } finally {
      setPendingId(null);
    }
  }

  async function handleAdjust(profile: ReputationProfile, delta: number) {
    const next = Math.max(0, Math.min(100, profile.reputationScore + delta));
    setPendingId(profile.id);
    try {
      await adjustReputationScore(profile.id, next);
      setProfiles((prev) =>
        prev.map((p) =>
          p.id === profile.id ? { ...p, reputationScore: next } : p,
        ),
      );
    } catch (err) {
      console.warn("[ReputationPage] adjust failed", err);
    } finally {
      setPendingId(null);
    }
  }

  const summary = useMemo(() => {
    return {
      total: profiles.length,
      verified: profiles.filter((p) => p.verification === "verified").length,
      pending: profiles.filter((p) => p.verification === "pending").length,
      avgScore:
        profiles.length === 0
          ? 0
          : Math.round(
              profiles.reduce((acc, p) => acc + p.reputationScore, 0) /
                profiles.length,
            ),
    };
  }, [profiles]);

  function handleExport() {
    exportRowsToXlsx(
      "wegig-reputation",
      "Reputacao",
      profiles.map((p) => ({
        id: p.id,
        nome: p.name,
        tipo: p.profileType ?? "",
        cidade: p.city ?? "",
        estado: p.state ?? "",
        status: STATUS_LABEL[p.verification],
        reputacao: p.reputationScore,
        reports: p.reportsAgainst,
        posts: p.postsCount,
        ultimo_acesso: p.lastActiveAt ? p.lastActiveAt.toISOString() : "",
      })),
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-3">
        <div>
          <h2 className="text-xl font-semibold tracking-tight dark:text-white">
            Reputação & Verificação
          </h2>
          <p className="text-sm text-gray-500 dark:text-slate-400">
            Aprove verificações e ajuste a reputação dos perfis.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="secondary" onClick={load} disabled={loading}>
            <RefreshCw className="h-4 w-4" /> Atualizar
          </Button>
          <Button onClick={handleExport} disabled={profiles.length === 0}>
            <Download className="h-4 w-4" /> Exportar .xlsx
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        {([
          ["Perfis", summary.total],
          ["Verificados", summary.verified],
          ["Pendentes", summary.pending],
          ["Score médio", summary.avgScore],
        ] as [string, number][]).map(([label, value]) => (
          <Card key={label}>
            <CardBody>
              <p className="text-xs uppercase tracking-wide text-gray-500 dark:text-slate-400">
                {label}
              </p>
              <p className="mt-1 text-2xl font-semibold dark:text-white">
                {value}
              </p>
            </CardBody>
          </Card>
        ))}
      </div>

      <Card>
        <CardHeader>
          <div className="flex flex-wrap items-center justify-between gap-2">
            <CardTitle>Perfis</CardTitle>
            <div className="flex flex-wrap items-center gap-2">
              <input
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Buscar nome, cidade…"
                className="h-9 rounded-lg border border-gray-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-3 text-sm focus:outline-none focus:ring-2 focus:ring-primary"
              />
              <div className="flex flex-wrap gap-1">
                {STATUS_FILTERS.map((f) => (
                  <button
                    key={f.key}
                    onClick={() => setStatus(f.key)}
                    className={`px-3 h-9 rounded-lg text-xs font-medium border transition-colors ${
                      status === f.key
                        ? "bg-primary text-white border-primary"
                        : "bg-white dark:bg-slate-900 border-gray-200 dark:border-slate-700 text-gray-600 dark:text-slate-300"
                    }`}
                  >
                    {f.label}
                  </button>
                ))}
              </div>
            </div>
          </div>
        </CardHeader>
        <CardBody>
          {error ? (
            <p className="text-sm text-red-600 dark:text-red-300">{error}</p>
          ) : null}

          {loading ? (
            <div className="space-y-2">
              <Skeleton className="h-12" />
              <Skeleton className="h-12" />
              <Skeleton className="h-12" />
            </div>
          ) : profiles.length === 0 ? (
            <p className="text-sm text-gray-500 dark:text-slate-400">
              Nenhum perfil encontrado.
            </p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="text-left text-xs uppercase text-gray-500 dark:text-slate-400">
                    <th className="px-3 py-2">Perfil</th>
                    <th className="px-3 py-2">Status</th>
                    <th className="px-3 py-2">Reputação</th>
                    <th className="px-3 py-2">Reports</th>
                    <th className="px-3 py-2">Último acesso</th>
                    <th className="px-3 py-2 text-right">Ações</th>
                  </tr>
                </thead>
                <tbody>
                  {profiles.map((profile) => (
                    <tr
                      key={profile.id}
                      className="border-t border-gray-100 dark:border-slate-800"
                    >
                      <td className="px-3 py-3">
                        <div className="flex items-center gap-2">
                          {profile.photoUrl ? (
                            <img
                              src={profile.photoUrl}
                              alt=""
                              className="h-8 w-8 rounded-full object-cover"
                            />
                          ) : (
                            <div className="h-8 w-8 rounded-full bg-gray-100 dark:bg-slate-800 flex items-center justify-center text-xs font-medium text-gray-500 dark:text-slate-300">
                              {profile.name.slice(0, 2).toUpperCase()}
                            </div>
                          )}
                          <div>
                            <p className="font-medium text-gray-900 dark:text-white">
                              {profile.name}
                            </p>
                            <p className="text-xs text-gray-500 dark:text-slate-400">
                              {[profile.profileType, profile.city, profile.state]
                                .filter(Boolean)
                                .join(" · ")}
                            </p>
                          </div>
                        </div>
                      </td>
                      <td className="px-3 py-3">
                        <Badge tone={STATUS_TONE[profile.verification]}>
                          {STATUS_LABEL[profile.verification]}
                        </Badge>
                      </td>
                      <td className="px-3 py-3">
                        <div className="flex items-center gap-2">
                          <div className="h-2 w-24 rounded-full bg-gray-100 dark:bg-slate-800 overflow-hidden">
                            <div
                              className="h-full bg-primary"
                              style={{ width: `${profile.reputationScore}%` }}
                            />
                          </div>
                          <span className="text-xs font-medium text-gray-700 dark:text-slate-200">
                            {profile.reputationScore}
                          </span>
                        </div>
                      </td>
                      <td className="px-3 py-3 text-xs text-gray-500 dark:text-slate-400">
                        {profile.reportsAgainst}
                      </td>
                      <td className="px-3 py-3 text-xs text-gray-500 dark:text-slate-400">
                        {formatDate(profile.lastActiveAt)}
                      </td>
                      <td className="px-3 py-3">
                        <div className="flex flex-wrap justify-end gap-1">
                          <Button
                            size="sm"
                            variant={
                              profile.verification === "verified"
                                ? "primary"
                                : "secondary"
                            }
                            disabled={pendingId === profile.id}
                            onClick={() => handleSetStatus(profile, "verified")}
                          >
                            <ShieldCheck className="h-3.5 w-3.5" /> Verificar
                          </Button>
                          <Button
                            size="sm"
                            variant={
                              profile.verification === "pending"
                                ? "primary"
                                : "secondary"
                            }
                            disabled={pendingId === profile.id}
                            onClick={() => handleSetStatus(profile, "pending")}
                          >
                            <ShieldQuestion className="h-3.5 w-3.5" /> Pendente
                          </Button>
                          <Button
                            size="sm"
                            variant="danger"
                            disabled={pendingId === profile.id}
                            onClick={() => handleSetStatus(profile, "rejected")}
                          >
                            <ShieldOff className="h-3.5 w-3.5" /> Rejeitar
                          </Button>
                          <Button
                            size="sm"
                            variant="ghost"
                            disabled={pendingId === profile.id}
                            onClick={() => handleAdjust(profile, +5)}
                          >
                            <BadgeCheck className="h-3.5 w-3.5" /> +5
                          </Button>
                          <Button
                            size="sm"
                            variant="ghost"
                            disabled={pendingId === profile.id}
                            onClick={() => handleAdjust(profile, -5)}
                          >
                            <BadgeCheck className="h-3.5 w-3.5" /> -5
                          </Button>
                        </div>
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
