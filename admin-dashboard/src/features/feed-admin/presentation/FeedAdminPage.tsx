import { useCallback, useEffect, useMemo, useState } from "react";
import {
  Download,
  Pin,
  Sparkles,
  Star,
  RefreshCw,
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
  listFeedPosts,
  setFeedFlag,
  type FeedFlag,
  type FeedPost,
} from "../data/feedAdminService";

type FilterKey = "all" | "featured" | "promoted" | "pinned";

const FILTERS: { key: FilterKey; label: string }[] = [
  { key: "all", label: "Todos" },
  { key: "featured", label: "Destacados" },
  { key: "promoted", label: "Promovidos" },
  { key: "pinned", label: "Fixados" },
];

function formatDate(value?: Date) {
  if (!value) return "—";
  return value.toLocaleString("pt-BR");
}

export function FeedAdminPage() {
  const [filter, setFilter] = useState<FilterKey>("all");
  const [search, setSearch] = useState("");
  const [posts, setPosts] = useState<FeedPost[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [pendingId, setPendingId] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const list = await listFeedPosts({
        filter,
        searchTerm: search,
        pageSize: 80,
      });
      setPosts(list);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Erro ao carregar feed");
    } finally {
      setLoading(false);
    }
  }, [filter, search]);

  useEffect(() => {
    load();
  }, [load]);

  async function handleToggle(post: FeedPost, flag: FeedFlag) {
    setPendingId(post.id);
    try {
      const current = Boolean(post[flag]);
      await setFeedFlag(post.id, flag, !current);
      setPosts((prev) =>
        prev.map((p) => (p.id === post.id ? { ...p, [flag]: !current } : p)),
      );
    } catch (err) {
      console.warn("[FeedAdminPage] toggle failed", err);
    } finally {
      setPendingId(null);
    }
  }

  function handleExport() {
    exportRowsToXlsx(
      `wegig-feed-${filter}`,
      "Feed",
      posts.map((p) => ({
        id: p.id,
        titulo: p.title,
        descricao: p.description ?? "",
        cidade: p.city ?? "",
        estado: p.state ?? "",
        autor: p.authorProfileId ?? "",
        criado_em: p.createdAt ? p.createdAt.toISOString() : "",
        destacado: p.featured ? "sim" : "não",
        promovido: p.promoted ? "sim" : "não",
        fixado: p.pinned ? "sim" : "não",
      })),
    );
  }

  const summary = useMemo(() => {
    return {
      total: posts.length,
      featured: posts.filter((p) => p.featured).length,
      promoted: posts.filter((p) => p.promoted).length,
      pinned: posts.filter((p) => p.pinned).length,
    };
  }, [posts]);

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-3">
        <div>
          <h2 className="text-xl font-semibold tracking-tight dark:text-white">
            Conteúdo do Feed
          </h2>
          <p className="text-sm text-gray-500 dark:text-slate-400">
            Destaque, promova e fixe posts no feed para curadoria editorial.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="secondary" onClick={load} disabled={loading}>
            <RefreshCw className="h-4 w-4" /> Atualizar
          </Button>
          <Button onClick={handleExport} disabled={posts.length === 0}>
            <Download className="h-4 w-4" /> Exportar .xlsx
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        {([
          ["Total", summary.total],
          ["Destacados", summary.featured],
          ["Promovidos", summary.promoted],
          ["Fixados", summary.pinned],
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
            <CardTitle>Posts</CardTitle>
            <div className="flex flex-wrap items-center gap-2">
              <input
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Buscar título, cidade, autor…"
                className="h-9 rounded-lg border border-gray-200 dark:border-slate-700 bg-white dark:bg-slate-900 px-3 text-sm focus:outline-none focus:ring-2 focus:ring-primary"
              />
              <div className="flex gap-1">
                {FILTERS.map((f) => (
                  <button
                    key={f.key}
                    onClick={() => setFilter(f.key)}
                    className={`px-3 h-9 rounded-lg text-xs font-medium border transition-colors ${
                      filter === f.key
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
          ) : posts.length === 0 ? (
            <p className="text-sm text-gray-500 dark:text-slate-400">
              Nenhum post encontrado para o filtro atual.
            </p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="text-left text-xs uppercase text-gray-500 dark:text-slate-400">
                    <th className="px-3 py-2">Post</th>
                    <th className="px-3 py-2">Localização</th>
                    <th className="px-3 py-2">Criado</th>
                    <th className="px-3 py-2">Estado</th>
                    <th className="px-3 py-2 text-right">Ações</th>
                  </tr>
                </thead>
                <tbody>
                  {posts.map((post) => (
                    <tr
                      key={post.id}
                      className="border-t border-gray-100 dark:border-slate-800"
                    >
                      <td className="px-3 py-3">
                        <p className="font-medium text-gray-900 dark:text-white">
                          {post.title}
                        </p>
                        <p className="text-xs text-gray-500 dark:text-slate-400 line-clamp-1">
                          {post.description}
                        </p>
                      </td>
                      <td className="px-3 py-3 text-xs text-gray-500 dark:text-slate-400">
                        {[post.city, post.state].filter(Boolean).join(", ") ||
                          "—"}
                      </td>
                      <td className="px-3 py-3 text-xs text-gray-500 dark:text-slate-400">
                        {formatDate(post.createdAt)}
                      </td>
                      <td className="px-3 py-3">
                        <div className="flex flex-wrap gap-1">
                          {post.featured ? (
                            <Badge tone="warning">Destacado</Badge>
                          ) : null}
                          {post.promoted ? (
                            <Badge tone="info">Promovido</Badge>
                          ) : null}
                          {post.pinned ? (
                            <Badge tone="success">Fixado</Badge>
                          ) : null}
                          {!post.featured && !post.promoted && !post.pinned ? (
                            <Badge tone="neutral">Normal</Badge>
                          ) : null}
                        </div>
                      </td>
                      <td className="px-3 py-3">
                        <div className="flex justify-end gap-1">
                          <Button
                            size="sm"
                            variant={post.featured ? "primary" : "secondary"}
                            disabled={pendingId === post.id}
                            onClick={() => handleToggle(post, "featured")}
                          >
                            <Star className="h-3.5 w-3.5" /> Destaque
                          </Button>
                          <Button
                            size="sm"
                            variant={post.promoted ? "primary" : "secondary"}
                            disabled={pendingId === post.id}
                            onClick={() => handleToggle(post, "promoted")}
                          >
                            <Sparkles className="h-3.5 w-3.5" /> Promover
                          </Button>
                          <Button
                            size="sm"
                            variant={post.pinned ? "primary" : "secondary"}
                            disabled={pendingId === post.id}
                            onClick={() => handleToggle(post, "pinned")}
                          >
                            <Pin className="h-3.5 w-3.5" /> Fixar
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
