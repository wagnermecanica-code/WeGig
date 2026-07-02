import React, { useState, useEffect, useCallback } from "react";
import {
  collection,
  query,
  orderBy,
  doc,
  getDoc,
  getDocs,
  deleteDoc,
  limit,
  serverTimestamp,
  updateDoc,
  where,
  writeBatch,
} from "firebase/firestore";
import { useNavigate } from "react-router-dom";
import { db } from "../firebase";
import { useAuth } from "../core/auth/AuthProvider";
import { recordAudit } from "../core/audit/auditLog";
import {
  AlertTriangle,
  ArrowRightCircle,
  Ban,
  CheckCircle,
  Clock,
  Flag,
  Eye,
  EyeOff,
  Trash2,
  ShieldOff,
  RefreshCw,
} from "lucide-react";

function toDate(value) {
  if (value?.toDate) return value.toDate();
  if (value instanceof Date) return value;
  return null;
}

function normalizeTargetType(value) {
  if (value === "post") return "post";
  if (value === "perfil" || value === "profile") return "profile";
  return null;
}

function isTerminalStatus(status) {
  return (
    status === "resolved" ||
    status === "removed" ||
    status === "dismissed"
  );
}

function buildTargetKey(targetType, targetId) {
  return `${targetType}:${targetId}`;
}

function inferTargetFromReport(data) {
  if (typeof data.reportedPostId === "string" && data.reportedPostId.trim()) {
    return { targetType: "post", targetId: data.reportedPostId.trim() };
  }

  if (
    typeof data.reportedProfileId === "string" &&
    data.reportedProfileId.trim()
  ) {
    return { targetType: "profile", targetId: data.reportedProfileId.trim() };
  }

  return null;
}

function summarizeGroupStatus(reports) {
  const activeReports = reports.filter((report) => !isTerminalStatus(report.status));
  if (activeReports.length > 0) return "pending";
  if (reports.some((report) => report.status === "removed")) return "removed";
  if (reports.some((report) => report.status === "dismissed")) return "dismissed";
  return "resolved";
}

function buildReportGroups(reportDocs, notifications) {
  const notificationsByTargetKey = new Map();

  notifications.forEach((notification) => {
    const targetType = normalizeTargetType(notification.targetType);
    const targetId =
      typeof notification.targetId === "string" ? notification.targetId.trim() : "";

    if (!targetType || !targetId) return;

    const key = buildTargetKey(targetType, targetId);
    const current = notificationsByTargetKey.get(key) ?? [];
    current.push(notification);
    notificationsByTargetKey.set(key, current);
  });

  const groups = new Map();

  reportDocs.forEach((reportDoc) => {
    const data = reportDoc.data();
    const target = inferTargetFromReport(data);
    if (!target) return;

    const key = buildTargetKey(target.targetType, target.targetId);
    const currentGroup =
      groups.get(key) ??
      {
        id: key,
        targetType: target.targetType,
        targetId: target.targetId,
        reports: [],
        reportIds: [],
        relatedNotifications: notificationsByTargetKey.get(key) ?? [],
      };

    currentGroup.reports.push({
      id: reportDoc.id,
      reporterUid: data.reporterUid ?? null,
      reason: data.reason ?? "Sem motivo",
      description: data.description ?? null,
      status: data.status ?? "pending",
      timestamp: toDate(data.timestamp),
      reviewedAt: toDate(data.reviewedAt),
      reviewedBy: data.reviewedBy ?? null,
      adminNotes: data.adminNotes ?? null,
      resolutionAction: data.resolutionAction ?? null,
    });
    currentGroup.reportIds.push(reportDoc.id);
    groups.set(key, currentGroup);
  });

  return Array.from(groups.values())
    .map((group) => {
      const reports = group.reports.sort((left, right) => {
        const leftTime = left.timestamp?.getTime?.() ?? 0;
        const rightTime = right.timestamp?.getTime?.() ?? 0;
        return rightTime - leftTime;
      });
      const activeReports = reports.filter((report) => !isTerminalStatus(report.status));
      const notificationsForGroup = group.relatedNotifications;
      const unreadNotifications = notificationsForGroup.filter(
        (notification) => notification.read !== true,
      );
      const reasons = Array.from(
        new Set(reports.map((report) => report.reason).filter(Boolean)),
      );

      return {
        ...group,
        reports,
        activeReports,
        status: summarizeGroupStatus(reports),
        totalReports: reports.length,
        activeReportsCount: activeReports.length,
        reasons,
        latestDescription:
          reports.find((report) => report.description)?.description ?? null,
        latestTimestamp: reports[0]?.timestamp ?? null,
        priority:
          activeReports.length >= 3 ||
          notificationsForGroup.some((notification) => notification.priority === "high")
            ? "high"
            : "normal",
        read: unreadNotifications.length === 0,
        unreadCount: unreadNotifications.length,
        notificationIds: notificationsForGroup.map((notification) => notification.id),
      };
    })
    .sort((left, right) => {
      const leftTime = left.latestTimestamp?.getTime?.() ?? 0;
      const rightTime = right.latestTimestamp?.getTime?.() ?? 0;
      return rightTime - leftTime;
    });
}

function getPriorityColor(priority) {
  if (priority === "high") return "text-red-600 bg-red-100";
  if (priority === "normal") return "text-yellow-600 bg-yellow-100";
  return "text-gray-600 bg-gray-100";
}

function pickReporterName(data) {
  if (!data || typeof data !== "object") return null;

  const candidates = [
    data.name,
    data.displayName,
    data.username,
    data.userName,
    data.handle,
    data.email,
  ];

  for (const value of candidates) {
    if (typeof value === "string" && value.trim()) {
      return value.trim();
    }
  }

  return null;
}

function pickTargetName(data, targetType) {
  if (!data || typeof data !== "object") return null;

  const postCandidates = [
    data.authorName,
    data.name,
    data.displayName,
    data.authorProfileId,
  ];
  const profileCandidates = [
    data.displayName,
    data.name,
    data.username,
    data.userName,
    data.handle,
  ];

  const candidates = targetType === "post" ? postCandidates : profileCandidates;

  for (const value of candidates) {
    if (typeof value === "string" && value.trim()) {
      return value.trim();
    }
  }

  return null;
}

function getReportedName(report, cachedContent) {
  const contentName = pickTargetName(cachedContent, report.targetType);
  if (contentName) return contentName;

  for (const notification of report.relatedNotifications ?? []) {
    const targetName = pickTargetName(notification.targetInfo, report.targetType);
    if (targetName) return targetName;
  }

  return report.targetId;
}

function getReporterNames(reportItems, reporterNameCache) {
  return Array.from(
    new Set(
      reportItems
        .map((item) => {
          if (!item.reporterUid) return null;
          return reporterNameCache[item.reporterUid] ?? item.reporterUid;
        })
        .filter(Boolean),
    ),
  );
}

async function resolveReporterName(reporterUid) {
  if (!reporterUid) return null;

  try {
    const userSnap = await getDoc(doc(db, "users", reporterUid));
    if (userSnap.exists()) {
      const reporterName = pickReporterName(userSnap.data());
      if (reporterName) return reporterName;
    }
  } catch {
    // Fallback below.
  }

  const profileQueries = [
    query(collection(db, "profiles"), where("ownerUid", "==", reporterUid), limit(1)),
    query(collection(db, "profiles"), where("uid", "==", reporterUid), limit(1)),
    query(collection(db, "profiles"), where("userId", "==", reporterUid), limit(1)),
  ];

  for (const profileQuery of profileQueries) {
    try {
      const profileSnap = await getDocs(profileQuery);
      const reporterName = pickReporterName(profileSnap.docs[0]?.data());
      if (reporterName) return reporterName;
    } catch {
      // Try the next fallback shape.
    }
  }

  return null;
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
  const navigate = useNavigate();
  const { admin, hasPermission } = useAuth();
  const [reports, setReports] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState("all");
  const [expandedId, setExpandedId] = useState(null);
  const [contentCache, setContentCache] = useState({});
  const [reporterNameCache, setReporterNameCache] = useState({});
  const [loadingContent, setLoadingContent] = useState({});
  const [actionLoading, setActionLoading] = useState({});
  const [refreshing, setRefreshing] = useState(false);

  const loadReports = useCallback(async ({ silent = false } = {}) => {
    if (!silent) setLoading(true);

    try {
      const reportsQuery = query(
        collection(db, "reports"),
        orderBy("timestamp", "desc"),
        limit(100),
      );

      const notificationsQuery = query(
        collection(db, "adminNotifications"),
        orderBy("timestamp", "desc"),
        limit(100),
      );

      const [reportsSnap, notificationsSnap] = await Promise.all([
        getDocs(reportsQuery),
        getDocs(notificationsQuery),
      ]);

      const notifications = notificationsSnap.docs.map((docSnap) => ({
        id: docSnap.id,
        ...docSnap.data(),
      }));

      setReports(buildReportGroups(reportsSnap.docs, notifications));
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => {
    loadReports();
  }, [loadReports]);

  const handleRefresh = async () => {
    setRefreshing(true);
    await loadReports({ silent: true });
  };

  useEffect(() => {
    const reporterUids = Array.from(
      new Set(
        reports
          .flatMap((report) => report.reports)
          .map((item) => item.reporterUid)
          .filter(Boolean),
      ),
    ).filter((reporterUid) => !(reporterUid in reporterNameCache));

    if (reporterUids.length === 0) return;

    let isCancelled = false;

    Promise.all(
      reporterUids.map(async (reporterUid) => [
        reporterUid,
        (await resolveReporterName(reporterUid)) ?? null,
      ]),
    ).then((entries) => {
      if (isCancelled) return;

      setReporterNameCache((current) => {
        const next = { ...current };
        entries.forEach(([reporterUid, reporterName]) => {
          next[reporterUid] = reporterName;
        });
        return next;
      });
    });

    return () => {
      isCancelled = true;
    };
  }, [reports, reporterNameCache]);

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

  const markAsRead = async (report) => {
    if (!report.notificationIds.length) return;

    const key = `${report.id}_read`;
    setActionLoading((prev) => ({ ...prev, [key]: true }));
    try {
      const batch = writeBatch(db);
      report.notificationIds.forEach((notificationId) => {
        batch.update(doc(db, "adminNotifications", notificationId), {
          read: true,
        });
      });
      await batch.commit();
      await loadReports({ silent: true });
    } finally {
      setActionLoading((prev) => ({ ...prev, [key]: false }));
    }
  };

  const dismissReports = async (report) => {
    if (!admin || !hasPermission("reports.resolve")) return;

    setActionLoading((prev) => ({ ...prev, [report.id + "_dismiss"]: true }));
    try {
      const batch = writeBatch(db);

      report.activeReports.forEach((item) => {
        batch.update(doc(db, "reports", item.id), {
          status: "dismissed",
          reviewedAt: serverTimestamp(),
          reviewedBy: admin.uid,
        });
      });

      report.notificationIds.forEach((notificationId) => {
        batch.update(doc(db, "adminNotifications", notificationId), {
          read: true,
          status: "dismissed",
          resolvedAt: serverTimestamp(),
          reviewedBy: admin.uid,
        });
      });

      await batch.commit();
      await recordAudit(admin, {
        action: "report.dismiss",
        targetType: "report",
        targetId: report.id,
        metadata: {
          targetType: report.targetType,
          targetEntityId: report.targetId,
          reportIds: report.activeReports.map((item) => item.id),
          reasons: report.reasons,
        },
      });
      await loadReports({ silent: true });
    } finally {
      setActionLoading((prev) => ({ ...prev, [report.id + "_dismiss"]: false }));
    }
  };

  const removeContent = async (report) => {
    if (!admin || !hasPermission("content.delete")) return;

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

      const batch = writeBatch(db);
      report.activeReports.forEach((item) => {
        batch.update(doc(db, "reports", item.id), {
          status: "resolved",
          reviewedAt: serverTimestamp(),
          reviewedBy: admin.uid,
          resolutionAction: "content_removed",
        });
      });

      report.notificationIds.forEach((notificationId) => {
        batch.update(doc(db, "adminNotifications", notificationId), {
          read: true,
          status: "removed",
          resolvedAt: serverTimestamp(),
          reviewedBy: admin.uid,
        });
      });

      await batch.commit();
      await recordAudit(admin, {
        action: "content.delete",
        targetType: report.targetType === "post" ? "post" : "user",
        targetId: report.targetId,
        metadata: {
          source: "moderation_reports",
          reportIds: report.activeReports.map((item) => item.id),
          reasons: report.reasons,
        },
      });

      setContentCache((prev) => ({ ...prev, [report.id]: null }));
      setExpandedId(null);
      await loadReports({ silent: true });
    } catch (e) {
      alert("Erro ao remover: " + e.message);
    } finally {
      setActionLoading((prev) => ({ ...prev, [report.id + "_remove"]: false }));
    }
  };

  const moderateProfile = async (report, shouldBan) => {
    if (!admin || !hasPermission("users.moderate")) return;
    if (report.targetType !== "profile") return;

    const actionKey = `${report.id}_${shouldBan ? "ban" : "unban"}`;
    const actionLabel = shouldBan ? "banir" : "desbanir";

    if (
      !confirm(
        `${shouldBan ? "Banir" : "Desbanir"} este perfil agora?`,
      )
    ) {
      return;
    }

    setActionLoading((prev) => ({ ...prev, [actionKey]: true }));
    try {
      const profileRef = doc(db, "profiles", report.targetId);
      const batch = writeBatch(db);

      batch.update(profileRef, {
        banned: shouldBan,
        moderationStatus: shouldBan ? "banned" : "active",
        moderatedAt: serverTimestamp(),
        moderatedBy: admin.uid,
      });

      if (shouldBan) {
        report.activeReports.forEach((item) => {
          batch.update(doc(db, "reports", item.id), {
            status: "resolved",
            reviewedAt: serverTimestamp(),
            reviewedBy: admin.uid,
            resolutionAction: "profile_banned",
          });
        });

        report.notificationIds.forEach((notificationId) => {
          batch.update(doc(db, "adminNotifications", notificationId), {
            read: true,
            status: "resolved",
            resolvedAt: serverTimestamp(),
            reviewedBy: admin.uid,
          });
        });
      }

      await batch.commit();

      await recordAudit(admin, {
        action: shouldBan ? "user.ban" : "user.unban",
        targetType: "user",
        targetId: report.targetId,
        metadata: {
          source: "moderation_reports",
          reportIds: report.activeReports.map((item) => item.id),
          reasons: report.reasons,
        },
      });
      await loadReports({ silent: true });

      setContentCache((prev) => {
        const current = prev[report.id];
        if (!current) return prev;
        return {
          ...prev,
          [report.id]: {
            ...current,
            banned: shouldBan,
            moderationStatus: shouldBan ? "banned" : "active",
          },
        };
      });
    } catch (e) {
      alert(`Erro ao ${actionLabel} perfil: ` + e.message);
    } finally {
      setActionLoading((prev) => ({ ...prev, [actionKey]: false }));
    }
  };

  const filteredReports = reports.filter((r) => {
    if (r.status === "removed") return false;
    if (filter === "unread") return !r.read;
    if (filter === "high") return r.priority === "high";
    if (filter === "resolved") {
      return r.status === "resolved" || r.status === "dismissed";
    }
    return true;
  });

  const unreadCount = reports.filter(
    (r) => !r.read && r.status === "pending",
  ).length;
  const highCount = reports.filter(
    (r) => r.priority === "high" && r.status === "pending",
  ).length;
  const pendingCount = reports.filter((r) => r.status === "pending").length;

  const canResolveReports = hasPermission("reports.resolve");
  const canDeleteContent = hasPermission("content.delete");
  const canModerateUsers = hasPermission("users.moderate");
  const canViewUsers = hasPermission("users.view");

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
      <div className="mb-6 flex flex-wrap items-center gap-2">
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
        <button
          onClick={handleRefresh}
          disabled={refreshing}
          className="inline-flex items-center gap-2 px-4 py-2 rounded-md text-sm font-medium bg-white text-gray-700 border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
        >
          <RefreshCw className={`h-4 w-4 ${refreshing ? "animate-spin" : ""}`} />
          {refreshing ? "Atualizando..." : "Atualizar"}
        </button>
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
              const cachedContent = contentCache[report.id];
              const reportedName = getReportedName(report, cachedContent);
              const reporterNames = getReporterNames(report.reports, reporterNameCache);
              const isProfileBanned =
                report.targetType === "profile" &&
                (cachedContent?.banned === true ||
                  cachedContent?.moderationStatus === "banned");

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
                        {report.activeReportsCount || report.totalReports} denúncia
                        {report.activeReportsCount === 1 || report.totalReports === 1
                          ? ""
                          : "s"}
                        {report.status !== "pending" ? " concluída" : ""} · {report.reasons[0]}
                      </p>
                      {report.reasons.length > 1 ? (
                        <p className="text-sm text-gray-500 mt-0.5">
                          Motivos: {report.reasons.join(", ")}
                        </p>
                      ) : null}
                      {report.latestDescription && (
                        <p className="text-sm text-gray-500 italic mt-0.5">
                          "{report.latestDescription}"
                        </p>
                      )}
                      <p className="text-xs text-gray-400 mt-1">
                        ID alvo: {report.targetId} ·{" "}
                        {report.latestTimestamp?.toLocaleString?.("pt-BR") ?? "—"}
                      </p>
                      <div className="mt-2 space-y-1 text-xs text-gray-600">
                        <p>
                          <span className="font-semibold text-gray-700">Denunciado:</span>{" "}
                          {reportedName}
                        </p>
                        <p>
                          <span className="font-semibold text-gray-700">Denunciante{reporterNames.length > 1 ? "s" : ""}:</span>{" "}
                          {reporterNames.length > 0 ? reporterNames.join(", ") : "—"}
                        </p>
                      </div>

                      {/* Expanded content */}
                      {isExpanded && (
                        <div className="mt-3 space-y-3">
                          <div className="p-3 bg-gray-50 border border-gray-200 rounded-md">
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

                          <div className="p-3 bg-white border border-gray-200 rounded-md">
                            <p className="text-xs font-semibold text-gray-500 uppercase mb-2">
                              Lastro das denúncias
                            </p>
                            <div className="space-y-2">
                              {report.reports.map((item) => (
                                <div
                                  key={item.id}
                                  className="rounded-md border border-gray-100 bg-gray-50 px-3 py-2"
                                >
                                  <div className="flex flex-wrap items-center gap-2 text-xs">
                                    <span className="font-medium text-gray-700">
                                      {item.reason}
                                    </span>
                                    <span className="text-gray-400">•</span>
                                    <span className="text-gray-500">
                                      {item.status}
                                    </span>
                                    <span className="text-gray-400">•</span>
                                    <span className="text-gray-500">
                                      {item.timestamp?.toLocaleString?.("pt-BR") ?? "—"}
                                    </span>
                                  </div>
                                  <p className="mt-1 text-xs text-gray-500">
                                    Report: {item.id}
                                    {item.reporterUid
                                      ? ` · Denunciante: ${reporterNameCache[item.reporterUid] ?? item.reporterUid}`
                                      : ""}
                                  </p>
                                  {item.description ? (
                                    <p className="mt-1 text-sm text-gray-700 italic">
                                      "{item.description}"
                                    </p>
                                  ) : null}
                                  {item.reviewedBy || item.reviewedAt ? (
                                    <p className="mt-1 text-xs text-gray-400">
                                      Revisado por {item.reviewedBy ?? "—"} em{" "}
                                      {item.reviewedAt?.toLocaleString?.("pt-BR") ?? "—"}
                                    </p>
                                  ) : null}
                                </div>
                              ))}
                            </div>
                          </div>
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
                          onClick={() => markAsRead(report)}
                          disabled={actionLoading[report.id + "_read"]}
                          className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium rounded-md text-white bg-green-600 hover:bg-green-700"
                        >
                          <CheckCircle className="w-3 h-3" />
                          Lido
                        </button>
                      )}

                      {report.targetType === "profile" && canViewUsers && (
                        <button
                          onClick={() => navigate(`/users/${report.targetId}`)}
                          className="inline-flex items-center gap-1 px-3 py-1.5 border border-gray-300 text-xs font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
                        >
                          <ArrowRightCircle className="w-3 h-3" />
                          Abrir usuário
                        </button>
                      )}

                      {report.targetType === "profile" && canModerateUsers ? (
                        <button
                          onClick={() =>
                            moderateProfile(report, !isProfileBanned)
                          }
                          disabled={
                            actionLoading[
                              `${report.id}_${isProfileBanned ? "unban" : "ban"}`
                            ]
                          }
                          className={`inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium rounded-md text-white disabled:opacity-50 ${
                            isProfileBanned
                              ? "bg-slate-600 hover:bg-slate-700"
                              : "bg-amber-600 hover:bg-amber-700"
                          }`}
                        >
                          <Ban className="w-3 h-3" />
                          {isProfileBanned ? "Desbanir" : "Banir perfil"}
                        </button>
                      ) : null}

                      {!isResolved && canResolveReports && (
                        <button
                          onClick={() => dismissReports(report)}
                          disabled={actionLoading[report.id + "_dismiss"]}
                          className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50"
                        >
                          <ShieldOff className="w-3 h-3" />
                          Dispensar
                        </button>
                      )}

                      {!isResolved && canDeleteContent && (
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
