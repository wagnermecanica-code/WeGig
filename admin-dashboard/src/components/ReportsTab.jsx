import React, { useState, useEffect } from "react";
import {
  collection,
  query,
  orderBy,
  onSnapshot,
  doc,
  updateDoc,
  getDoc,
  deleteDoc,
} from "firebase/firestore";
import { db } from "../firebase";
import {
  AlertTriangle,
  CheckCircle,
  Clock,
  Flag,
  Eye,
  EyeOff,
  Trash2,
  ShieldOff,
} from "lucide-react";

function getPriorityColor(priority) {
  if (priority === "high") return "text-red-600 bg-red-100";
  if (priority === "normal") return "text-yellow-600 bg-yellow-100";
  return "text-gray-600 bg-gray-100";
}

function ContentPreview({ content, targetType }) {
  if (!content)
    return (
      <p className="text-sm text-gray-500 italic">
        Conteúdo não encontrado (já removido ou inexistente).
      </p>
    );

  if (targetType === "post") {
    return (
      <div className="space-y-1 text-sm">
        {content.description && (
          <p className="text-gray-800 whitespace-pre-wrap">
            "{content.description}"
          </p>
        )}
        <p className="text-gray-500">
          Autor:{" "}
          <span className="font-medium">
            {content.authorName || content.authorProfileId || "—"}
          </span>
          {content.postType && ` · Tipo: ${content.postType}`}
          {content.city && ` · ${content.city}`}
        </p>
        {content.createdAt && (
          <p className="text-xs text-gray-400">
            Criado em:{" "}
            {new Date(content.createdAt.toDate()).toLocaleString("pt-BR")}
          </p>
        )}
      </div>
    );
  }

  if (targetType === "profile") {
    return (
      <div className="space-y-1 text-sm">
        <p className="text-gray-800 font-medium">
          {content.displayName || content.name || "—"}
        </p>
        <p className="text-gray-500">
          {content.profileType && `Tipo: ${content.profileType}`}
          {content.city && ` · ${content.city}`}
          {content.state && `, ${content.state}`}
        </p>
        {content.bio && <p className="text-gray-600 italic">"{content.bio}"</p>}
      </div>
    );
  }

  return null;
}

export default function ReportsTab() {
  const [reports, setReports] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState("all");
  const [expandedId, setExpandedId] = useState(null);
  const [contentCache, setContentCache] = useState({});
  const [loadingContent, setLoadingContent] = useState({});
  const [actionLoading, setActionLoading] = useState({});

  useEffect(() => {
    const q = query(
      collection(db, "adminNotifications"),
      orderBy("timestamp", "desc"),
    );
    const unsubscribe = onSnapshot(q, (snap) => {
      setReports(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
      setLoading(false);
    });
    return unsubscribe;
  }, []);

  const toggleExpand = async (report) => {
    if (expandedId === report.id) {
      setExpandedId(null);
      return;
    }
    setExpandedId(report.id);
    if (report.id in contentCache) return;

    setLoadingContent((prev) => ({ ...prev, [report.id]: true }));
    try {
      const collName = report.targetType === "post" ? "posts" : "profiles";
      const snap = await getDoc(doc(db, collName, report.targetId));
      setContentCache((prev) => ({
        ...prev,
        [report.id]: snap.exists() ? snap.data() : null,
      }));
    } catch {
      setContentCache((prev) => ({ ...prev, [report.id]: null }));
    } finally {
      setLoadingContent((prev) => ({ ...prev, [report.id]: false }));
    }
  };

  const markAsRead = async (reportId) => {
    await updateDoc(doc(db, "adminNotifications", reportId), { read: true });
  };

  const resolveWithoutAction = async (reportId) => {
    setActionLoading((prev) => ({ ...prev, [reportId + "_resolve"]: true }));
    try {
      await updateDoc(doc(db, "adminNotifications", reportId), {
        read: true,
        status: "resolved",
      });
    } finally {
      setActionLoading((prev) => ({ ...prev, [reportId + "_resolve"]: false }));
    }
  };

  const removeContent = async (report) => {
    const label = report.targetType === "post" ? "post" : "perfil";
    if (
      !confirm(
        `Remover este ${label} definitivamente? Esta ação não pode ser desfeita.`,
      )
    )
      return;

    setActionLoading((prev) => ({ ...prev, [report.id + "_remove"]: true }));
    try {
      const collName = report.targetType === "post" ? "posts" : "profiles";
      await deleteDoc(doc(db, collName, report.targetId));
      await updateDoc(doc(db, "adminNotifications", report.id), {
        read: true,
        status: "removed",
      });
      setContentCache((prev) => ({ ...prev, [report.id]: null }));
      setExpandedId(null);
    } catch (e) {
      alert("Erro ao remover: " + e.message);
    } finally {
      setActionLoading((prev) => ({ ...prev, [report.id + "_remove"]: false }));
    }
  };

  const filteredReports = reports.filter((r) => {
    if (r.status === "removed") return false;
    if (filter === "unread") return !r.read;
    if (filter === "high") return r.priority === "high";
    if (filter === "resolved") return r.status === "resolved";
    return true;
  });

  const unreadCount = reports.filter(
    (r) => !r.read && r.status !== "removed",
  ).length;
  const highCount = reports.filter(
    (r) => r.priority === "high" && r.status !== "removed",
  ).length;
  const pendingCount = reports.filter(
    (r) => !r.status || r.status === "pending",
  ).length;

  if (loading) {
    return (
      <div className="flex items-center justify-center py-16">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary" />
      </div>
    );
  }

  return (
    <>
      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div className="bg-white overflow-hidden shadow rounded-lg p-5">
          <div className="flex items-center">
            <Clock className="h-6 w-6 text-gray-400 flex-shrink-0" />
            <div className="ml-5">
              <p className="text-sm font-medium text-gray-500">Pendentes</p>
              <p className="text-lg font-medium text-gray-900">
                {pendingCount}
              </p>
            </div>
          </div>
        </div>
        <div className="bg-white overflow-hidden shadow rounded-lg p-5">
          <div className="flex items-center">
            <AlertTriangle className="h-6 w-6 text-yellow-400 flex-shrink-0" />
            <div className="ml-5">
              <p className="text-sm font-medium text-gray-500">Não Lidas</p>
              <p className="text-lg font-medium text-gray-900">{unreadCount}</p>
            </div>
          </div>
        </div>
        <div className="bg-white overflow-hidden shadow rounded-lg p-5">
          <div className="flex items-center">
            <AlertTriangle className="h-6 w-6 text-red-400 flex-shrink-0" />
            <div className="ml-5">
              <p className="text-sm font-medium text-gray-500">
                Prioridade Alta
              </p>
              <p className="text-lg font-medium text-gray-900">{highCount}</p>
            </div>
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="mb-6 flex flex-wrap gap-2">
        {[
          {
            key: "all",
            label: `Todas (${reports.filter((r) => r.status !== "removed").length})`,
          },
          { key: "unread", label: `Não Lidas (${unreadCount})` },
          { key: "high", label: `Alta Prioridade (${highCount})` },
          { key: "resolved", label: `Resolvidas` },
        ].map(({ key, label }) => (
          <button
            key={key}
            onClick={() => setFilter(key)}
            className={`px-4 py-2 rounded-md text-sm font-medium ${
              filter === key
                ? "bg-primary text-white"
                : "bg-white text-gray-700 border border-gray-300 hover:bg-gray-50"
            }`}
          >
            {label}
          </button>
        ))}
      </div>

      {/* List */}
      <div className="bg-white shadow overflow-hidden sm:rounded-md">
        <ul className="divide-y divide-gray-200">
          {filteredReports.length === 0 ? (
            <li className="px-6 py-8 text-center text-gray-500">
              Nenhuma denúncia encontrada.
            </li>
          ) : (
            filteredReports.map((report) => {
              const isExpanded = expandedId === report.id;
              const isResolved = report.status === "resolved";

              return (
                <li
                  key={report.id}
                  className={`px-6 py-4 ${!report.read && !isResolved ? "bg-blue-50" : ""}`}
                >
                  <div className="flex items-start justify-between gap-4">
                    <div className="flex-1 min-w-0">
                      {/* Badges */}
                      <div className="flex flex-wrap items-center gap-2 mb-2">
                        <span
                          className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-medium ${getPriorityColor(report.priority)}`}
                        >
                          <AlertTriangle className="w-3 h-3" />
                          {report.priority === "high" ? "Alta" : "Normal"}
                        </span>
                        <span className="text-xs px-2 py-0.5 rounded-full bg-gray-100 text-gray-700">
                          {report.targetType === "post" ? "Post" : "Perfil"}
                        </span>
                        {!report.read && !isResolved && (
                          <span className="text-xs px-2 py-0.5 rounded-full bg-blue-100 text-blue-800">
                            Novo
                          </span>
                        )}
                        {isResolved && (
                          <span className="text-xs px-2 py-0.5 rounded-full bg-green-100 text-green-700">
                            Resolvida
                          </span>
                        )}
                      </div>

                      {/* Main info */}
                      <p className="text-sm font-medium text-gray-900">
                        {report.totalReports} denúncia
                        {report.totalReports > 1 ? "s" : ""} · {report.reason}
                      </p>
                      {report.description && (
                        <p className="text-sm text-gray-500 italic mt-0.5">
                          "{report.description}"
                        </p>
                      )}
                      <p className="text-xs text-gray-400 mt-1">
                        ID alvo: {report.targetId} ·{" "}
                        {report.timestamp &&
                          new Date(report.timestamp.toDate()).toLocaleString(
                            "pt-BR",
                          )}
                      </p>

                      {/* Expanded content */}
                      {isExpanded && (
                        <div className="mt-3 p-3 bg-gray-50 border border-gray-200 rounded-md">
                          <p className="text-xs font-semibold text-gray-500 uppercase mb-2">
                            Conteúdo reportado
                          </p>
                          {loadingContent[report.id] ? (
                            <div className="flex items-center gap-2 text-sm text-gray-500">
                              <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-gray-400" />
                              Carregando...
                            </div>
                          ) : (
                            <ContentPreview
                              content={contentCache[report.id]}
                              targetType={report.targetType}
                            />
                          )}
                        </div>
                      )}
                    </div>

                    {/* Actions */}
                    <div className="flex flex-col gap-2 flex-shrink-0">
                      <button
                        onClick={() => toggleExpand(report)}
                        className="inline-flex items-center gap-1 px-3 py-1.5 border border-gray-300 text-xs font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
                      >
                        {isExpanded ? (
                          <EyeOff className="w-3 h-3" />
                        ) : (
                          <Eye className="w-3 h-3" />
                        )}
                        {isExpanded ? "Fechar" : "Ver conteúdo"}
                      </button>

                      {!report.read && !isResolved && (
                        <button
                          onClick={() => markAsRead(report.id)}
                          className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium rounded-md text-white bg-green-600 hover:bg-green-700"
                        >
                          <CheckCircle className="w-3 h-3" />
                          Lido
                        </button>
                      )}

                      {!isResolved && (
                        <button
                          onClick={() => resolveWithoutAction(report.id)}
                          disabled={actionLoading[report.id + "_resolve"]}
                          className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50"
                        >
                          <ShieldOff className="w-3 h-3" />
                          Ignorar
                        </button>
                      )}

                      {!isResolved && (
                        <button
                          onClick={() => removeContent(report)}
                          disabled={actionLoading[report.id + "_remove"]}
                          className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium rounded-md text-white bg-red-600 hover:bg-red-700 disabled:opacity-50"
                        >
                          <Trash2 className="w-3 h-3" />
                          Remover
                        </button>
                      )}
                    </div>
                  </div>
                </li>
              );
            })
          )}
        </ul>
      </div>
    </>
  );
}
