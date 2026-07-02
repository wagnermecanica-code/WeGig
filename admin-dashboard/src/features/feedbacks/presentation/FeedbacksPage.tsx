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
import { Skeleton } from "@shared/components/ui/Skeleton";
import { Badge } from "@shared/components/ui/Badge";
import { RefreshCw } from "lucide-react";

interface Feedback {
  id: string;
  message?: string;
  category?: string;
  rating?: number;
  userEmail?: string;
  createdAt?: Date;
}

export function FeedbacksPage() {
  const [items, setItems] = useState<Feedback[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  async function loadFeedbacks({ silent = false } = {}) {
    if (!silent) setLoading(true);

    const q = query(
      collection(db, "feedbacks"),
      orderBy("createdAt", "desc"),
      limit(100),
    );

    try {
      const snap = await getDocs(q);
      setItems(
        snap.docs.map((d) => {
          const data = d.data() as any;
          const ts = data.createdAt;
          return {
            id: d.id,
            message: data.message ?? data.text,
            category: data.category,
            rating: data.rating,
            userEmail: data.userEmail ?? data.email,
            createdAt: ts instanceof Timestamp ? ts.toDate() : undefined,
          };
        }),
      );
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }

  useEffect(() => {
    loadFeedbacks();
  }, []);

  async function handleRefresh() {
    setRefreshing(true);
    await loadFeedbacks({ silent: true });
  }

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-3">
        <div>
          <h2 className="text-xl font-semibold tracking-tight dark:text-white">
            Feedbacks
          </h2>
          <p className="text-sm text-gray-500 dark:text-slate-400">
            Sugestões e reclamações recebidas dos usuários.
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

      <div className="space-y-3">
        {loading ? (
          Array.from({ length: 3 }).map((_, i) => (
            <Skeleton key={i} className="h-24" />
          ))
        ) : items.length === 0 ? (
          <Card>
            <div className="p-8 text-center text-sm text-gray-500 dark:text-slate-400">
              Nenhum feedback recebido ainda.
            </div>
          </Card>
        ) : (
          items.map((f) => (
            <Card key={f.id}>
              <div className="p-4">
                <div className="flex items-center justify-between gap-2 mb-2">
                  <div className="flex items-center gap-2">
                    {f.category ? (
                      <Badge tone="info">{f.category}</Badge>
                    ) : null}
                    {f.rating != null ? (
                      <Badge tone="warning">★ {f.rating}</Badge>
                    ) : null}
                  </div>
                  <span className="text-xs text-gray-400">
                    {f.createdAt ? f.createdAt.toLocaleString("pt-BR") : ""}
                  </span>
                </div>
                <p className="text-sm text-gray-700 dark:text-slate-200 whitespace-pre-wrap">
                  {f.message ?? "(sem mensagem)"}
                </p>
                {f.userEmail ? (
                  <p className="text-xs text-gray-400 mt-2">{f.userEmail}</p>
                ) : null}
              </div>
            </Card>
          ))
        )}
      </div>
    </div>
  );
}
