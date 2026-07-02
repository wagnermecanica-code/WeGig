import { useEffect, useState } from "react";
import {
  collection,
  getDocs,
  limit,
  orderBy,
  query,
  Timestamp,
} from "firebase/firestore";
import { db } from "@core/firebase/client";
import { Card } from "@shared/components/ui/Card";
import { Badge } from "@shared/components/ui/Badge";
import { Skeleton } from "@shared/components/ui/Skeleton";
import { RefreshCw } from "lucide-react";

interface AuditEntry {
  id: string;
  actorEmail?: string;
  actorRole?: string;
  action: string;
  targetType: string;
  targetId: string;
  metadata?: Record<string, unknown>;
  timestamp?: Date;
}

const ACTION_TONE: Record<
  string,
  "neutral" | "success" | "warning" | "danger" | "info"
> = {
  "user.ban": "danger",
  "user.unban": "success",
  "content.delete": "danger",
  "comment.delete": "warning",
  "post.delete": "danger",
  "report.resolve": "success",
  "report.dismiss": "neutral",
  "catalog.update": "info",
};

export function AuditLogPage() {
  const [entries, setEntries] = useState<AuditEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  async function loadEntries({ silent = false } = {}) {
    if (!silent) setLoading(true);

    const q = query(
      collection(db, "audit_logs"),
      orderBy("timestamp", "desc"),
      limit(100),
    );

    try {
      const snap = await getDocs(q);
      const items: AuditEntry[] = snap.docs.map((d) => {
        const data = d.data() as Record<string, any>;
        const ts = data.timestamp;
        return {
          id: d.id,
          actorEmail: data.actorEmail,
          actorRole: data.actorRole,
          action: data.action,
          targetType: data.targetType,
          targetId: data.targetId,
          metadata: data.metadata,
          timestamp: ts instanceof Timestamp ? ts.toDate() : undefined,
        };
      });
      setEntries(items);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }

  useEffect(() => {
    loadEntries();
  }, []);

  async function handleRefresh() {
    setRefreshing(true);
    await loadEntries({ silent: true });
  }

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-3">
        <div>
          <h2 className="text-xl font-semibold tracking-tight dark:text-white">
            Log de Auditoria
          </h2>
          <p className="text-sm text-gray-500 dark:text-slate-400">
            Histórico completo de ações administrativas (últimas 100).
          </p>
        </div>
        <button
          onClick={handleRefresh}
          disabled={refreshing}
          className="inline-flex items-center gap-2 px-3 py-2 rounded-md text-sm font-medium bg-white text-gray-700 border border-gray-300 hover:bg-gray-50 disabled:opacity-50 dark:bg-slate-900 dark:border-slate-700 dark:text-slate-100"
        >
          <RefreshCw className={`h-4 w-4 ${refreshing ? "animate-spin" : ""}`} />
          {refreshing ? "Atualizando..." : "Atualizar"}
        </button>
      </div>

      <Card>
        <div className="overflow-x-auto">
          <table className="min-w-full text-sm">
            <thead className="bg-gray-50 dark:bg-slate-800/50 text-xs uppercase tracking-wider text-gray-500 dark:text-slate-400">
              <tr>
                <th className="px-4 py-3 text-left">Quando</th>
                <th className="px-4 py-3 text-left">Quem</th>
                <th className="px-4 py-3 text-left">Ação</th>
                <th className="px-4 py-3 text-left">Alvo</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 dark:divide-slate-800">
              {loading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <tr key={i}>
                    <td colSpan={4} className="px-4 py-3">
                      <Skeleton className="h-5 w-full" />
                    </td>
                  </tr>
                ))
              ) : entries.length === 0 ? (
                <tr>
                  <td
                    colSpan={4}
                    className="px-4 py-10 text-center text-gray-500 dark:text-slate-400"
                  >
                    Nenhum evento registrado ainda.
                  </td>
                </tr>
              ) : (
                entries.map((e) => (
                  <tr
                    key={e.id}
                    className="hover:bg-gray-50 dark:hover:bg-slate-800/50"
                  >
                    <td className="px-4 py-3 text-xs text-gray-500 dark:text-slate-400 whitespace-nowrap">
                      {e.timestamp ? e.timestamp.toLocaleString("pt-BR") : "—"}
                    </td>
                    <td className="px-4 py-3">
                      <div className="text-xs font-medium dark:text-slate-200">
                        {e.actorEmail ?? "—"}
                      </div>
                      <div className="text-[10px] uppercase text-gray-400">
                        {e.actorRole}
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <Badge tone={ACTION_TONE[e.action] ?? "neutral"}>
                        {e.action}
                      </Badge>
                    </td>
                    <td className="px-4 py-3 text-xs text-gray-600 dark:text-slate-300">
                      <span className="uppercase text-[10px] text-gray-400 mr-2">
                        {e.targetType}
                      </span>
                      <span className="font-mono">{e.targetId}</span>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </Card>
    </div>
  );
}
