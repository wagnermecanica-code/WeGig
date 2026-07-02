import React, { useState, useEffect } from "react";
import {
  collectionGroup,
  query,
  orderBy,
  limit,
  getDocs,
  deleteDoc,
} from "firebase/firestore";
import { db } from "../firebase";
import { MessageSquare, Trash2, Search, RefreshCw } from "lucide-react";

export default function CommentsTab() {
  const [comments, setComments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [removingId, setRemovingId] = useState(null);
  const [error, setError] = useState(null);
  const [refreshing, setRefreshing] = useState(false);

  const mapComments = (snap) =>
    snap.docs.map((d) => ({
      id: d.id,
      postId: d.ref.parent.parent?.id ?? "—",
      ...d.data(),
      _ref: d.ref,
    }));

  const sortByCreatedAtDesc = (items) =>
    [...items].sort((a, b) => {
      const aMs = a?.createdAt?.toMillis ? a.createdAt.toMillis() : 0;
      const bMs = b?.createdAt?.toMillis ? b.createdAt.toMillis() : 0;
      return bMs - aMs;
    });

  const formatLoadError = (err) => {
    if (err?.code === "permission-denied") {
      return "Erro ao carregar comentários: sem permissão de leitura no Firestore (permission-denied).";
    }

    if (err?.code === "failed-precondition") {
      return "Erro ao carregar comentários: índice necessário ainda não está pronto no Firestore.";
    }

    return "Erro ao carregar comentários no Firestore.";
  };

  async function loadComments({ silent = false } = {}) {
    if (!silent) setLoading(true);

    const indexedQuery = query(
      collectionGroup(db, "comments"),
      orderBy("createdAt", "desc"),
      limit(200),
    );

    const fallbackQuery = query(collectionGroup(db, "comments"), limit(200));

    try {
      const snap = await getDocs(indexedQuery);
      setComments(mapComments(snap));
      setError(null);
    } catch (err) {
      if (err?.code === "failed-precondition") {
        try {
          const fallbackSnap = await getDocs(fallbackQuery);
          setComments(sortByCreatedAtDesc(mapComments(fallbackSnap)));
          setError(null);
        } catch (fallbackErr) {
          setError(formatLoadError(fallbackErr));
          console.error("CommentsTab fallback:", fallbackErr);
        }
      } else {
        setError(formatLoadError(err));
        console.error("CommentsTab:", err);
      }
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }

  useEffect(() => {
    loadComments();
  }, []);

  async function handleRefresh() {
    setRefreshing(true);
    await loadComments({ silent: true });
  }

  const removeComment = async (comment) => {
    if (
      !confirm(
        `Remover o comentário de "${comment.authorName || "usuário"}" definitivamente?`,
      )
    )
      return;

    setRemovingId(comment.id);
    try {
      await deleteDoc(comment._ref);
      setComments((current) => current.filter((item) => item.id !== comment.id));
    } catch (e) {
      alert("Erro ao remover comentário: " + e.message);
    } finally {
      setRemovingId(null);
    }
  };

  const filtered = comments.filter((c) => {
    if (!search) return true;
    const term = search.toLowerCase();
    return (
      c.text?.toLowerCase().includes(term) ||
      c.authorName?.toLowerCase().includes(term) ||
      c.postId?.toLowerCase().includes(term)
    );
  });

  if (loading) {
    return (
      <div className="flex items-center justify-center py-16">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-yellow-50 border border-yellow-200 rounded-md p-4 text-sm text-yellow-800">
        <strong>Atenção:</strong> {error}
      </div>
    );
  }

  return (
    <>
      {/* Header stats */}
      <div className="mb-6 flex items-center justify-between">
        <p className="text-sm text-gray-600">
          Exibindo os <span className="font-semibold">{comments.length}</span>{" "}
          comentários mais recentes.
        </p>
        <div className="flex items-center gap-3">
          <button
            onClick={handleRefresh}
            disabled={refreshing}
            className="inline-flex items-center gap-2 px-3 py-2 rounded-md text-sm font-medium bg-white text-gray-700 border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
          >
            <RefreshCw className={`h-4 w-4 ${refreshing ? "animate-spin" : ""}`} />
            {refreshing ? "Atualizando..." : "Atualizar"}
          </button>
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
            <input
              type="text"
              placeholder="Buscar por texto, autor ou post ID..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="pl-9 pr-4 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent w-80"
            />
          </div>
        </div>
      </div>

      {/* List */}
      <div className="bg-white shadow overflow-hidden sm:rounded-md">
        <ul className="divide-y divide-gray-200">
          {filtered.length === 0 ? (
            <li className="px-6 py-8 text-center text-gray-500">
              Nenhum comentário encontrado.
            </li>
          ) : (
            filtered.map((comment) => (
              <li key={comment.id} className="px-6 py-4">
                <div className="flex items-start justify-between gap-4">
                  <div className="flex items-start gap-3 flex-1 min-w-0">
                    {/* Avatar placeholder */}
                    <div className="flex-shrink-0 w-8 h-8 rounded-full bg-gray-200 flex items-center justify-center">
                      <MessageSquare className="w-4 h-4 text-gray-400" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-0.5 flex-wrap">
                        <span className="text-sm font-medium text-gray-900">
                          {comment.authorName || "—"}
                        </span>
                        {comment.parentCommentId && (
                          <span className="text-xs px-2 py-0.5 rounded-full bg-purple-100 text-purple-700">
                            Resposta
                          </span>
                        )}
                        {comment.mentionedProfileIds?.length > 0 && (
                          <span className="text-xs px-2 py-0.5 rounded-full bg-blue-100 text-blue-700">
                            Menção
                          </span>
                        )}
                      </div>
                      <p className="text-sm text-gray-800 whitespace-pre-wrap break-words">
                        {comment.text || (
                          <em className="text-gray-400">sem texto</em>
                        )}
                      </p>
                      <p className="text-xs text-gray-400 mt-1">
                        Post ID: {comment.postId}
                        {comment.createdAt && (
                          <>
                            {" "}
                            ·{" "}
                            {new Date(
                              comment.createdAt.toDate(),
                            ).toLocaleString("pt-BR")}
                          </>
                        )}
                      </p>
                    </div>
                  </div>

                  <button
                    onClick={() => removeComment(comment)}
                    disabled={removingId === comment.id}
                    className="flex-shrink-0 inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium rounded-md text-white bg-red-600 hover:bg-red-700 disabled:opacity-50"
                  >
                    <Trash2 className="w-3 h-3" />
                    {removingId === comment.id ? "Removendo…" : "Remover"}
                  </button>
                </div>
              </li>
            ))
          )}
        </ul>
      </div>
    </>
  );
}
