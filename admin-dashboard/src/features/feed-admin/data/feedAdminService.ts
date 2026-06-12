import {
  collection,
  deleteDoc,
  doc,
  getDocs,
  limit,
  orderBy,
  query,
  Timestamp,
  updateDoc,
  writeBatch,
  where,
} from "firebase/firestore";
import { db } from "@core/firebase/client";
import { recordAudit } from "@core/audit/auditLog";
import type { AdminUser } from "@core/auth/roles";

export interface PostReportIndicator {
  notificationIds: string[];
  reportIds: string[];
  totalReports: number;
  unreadReports: number;
  highPriority: boolean;
  lastReportedAt?: Date;
  reasons: string[];
}

export interface FeedPost {
  id: string;
  title: string;
  description?: string;
  postType?: string;
  city?: string;
  state?: string;
  authorProfileId?: string;
  authorName?: string;
  createdAt?: Date;
  featured?: boolean;
  promoted?: boolean;
  pinned?: boolean;
  expiresAt?: Date;
  reports?: PostReportIndicator;
}

function parseDate(value: unknown): Date | undefined {
  if (value instanceof Timestamp) return value.toDate();
  if (value instanceof Date) return value;
  return undefined;
}

function cleanString(value: unknown): string | undefined {
  if (typeof value !== "string") return undefined;
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

function truncateText(value: string, maxLength = 72): string {
  return value.length > maxLength ? `${value.slice(0, maxLength - 1)}…` : value;
}

function buildPostTitle(data: Record<string, any>): string {
  const explicitTitle = cleanString(data.title) ?? cleanString(data.name);
  if (explicitTitle) return explicitTitle;

  const contentTitle =
    cleanString(data.content) ??
    cleanString(data.description) ??
    cleanString(data.text) ??
    cleanString(data.targetInfo?.content);
  if (contentTitle) return truncateText(contentTitle.replace(/\s+/g, " "));

  const authorName =
    cleanString(data.authorName) ?? cleanString(data.profileName);
  if (authorName) return `Post de ${authorName}`;

  return "Post sem título";
}

function mapPost(id: string, data: Record<string, any>): FeedPost {
  return {
    id,
    title: buildPostTitle(data),
    description:
      cleanString(data.description) ??
      cleanString(data.text) ??
      cleanString(data.content),
    postType: cleanString(data.postType) ?? cleanString(data.type),
    city: cleanString(data.city) ?? cleanString(data.locationCity),
    state: cleanString(data.state) ?? cleanString(data.locationState),
    authorProfileId:
      cleanString(data.profileId) ?? cleanString(data.authorProfileId),
    authorName: cleanString(data.authorName) ?? cleanString(data.profileName),
    createdAt: parseDate(data.createdAt),
    featured: data.featured === true,
    promoted: data.promoted === true,
    pinned: data.pinned === true,
    expiresAt: parseDate(data.expiresAt),
  };
}

export interface FeedListParams {
  filter?: "all" | "featured" | "promoted" | "pinned" | "reported";
  pageSize?: number;
  searchTerm?: string;
}

function isActiveReportStatus(status: unknown): boolean {
  return (
    status !== "resolved" && status !== "removed" && status !== "dismissed"
  );
}

export async function listPostReportIndicators(): Promise<
  Map<string, PostReportIndicator>
> {
  const snap = await getDocs(
    query(
      collection(db, "adminNotifications"),
      where("type", "==", "new_report"),
      where("targetType", "==", "post"),
      orderBy("timestamp", "desc"),
      limit(250),
    ),
  );
  const indicators = new Map<string, PostReportIndicator>();

  snap.docs.forEach((reportDoc) => {
    const data = reportDoc.data();
    if (!data.targetId) {
      return;
    }
    if (!isActiveReportStatus(data.status)) return;

    const targetId = String(data.targetId);
    const current = indicators.get(targetId) ?? {
      notificationIds: [],
      reportIds: [],
      totalReports: 0,
      unreadReports: 0,
      highPriority: false,
      reasons: [],
    };
    const totalReports = Number(data.totalReports ?? 1);
    const reportedAt = parseDate(data.timestamp);

    current.notificationIds.push(reportDoc.id);
    if (typeof data.reportId === "string" && data.reportId.trim()) {
      current.reportIds.push(data.reportId.trim());
    }
    current.totalReports += Number.isFinite(totalReports) ? totalReports : 1;
    current.unreadReports += data.read ? 0 : 1;
    current.highPriority = current.highPriority || data.priority === "high";

    if (
      reportedAt &&
      (!current.lastReportedAt || reportedAt > current.lastReportedAt)
    ) {
      current.lastReportedAt = reportedAt;
    }

    if (
      typeof data.reason === "string" &&
      !current.reasons.includes(data.reason)
    ) {
      current.reasons.push(data.reason);
    }

    indicators.set(targetId, current);
  });

  return indicators;
}

export async function listFeedPosts(
  params: FeedListParams = {},
): Promise<FeedPost[]> {
  const pageSize = params.pageSize ?? 60;
  const constraints: any[] = [];

  if (params.filter === "featured") {
    constraints.push(where("featured", "==", true));
  } else if (params.filter === "promoted") {
    constraints.push(where("promoted", "==", true));
  } else if (params.filter === "pinned") {
    constraints.push(where("pinned", "==", true));
  }

  constraints.push(orderBy("createdAt", "desc"));
  constraints.push(limit(pageSize));

  const [snap, reportIndicators] = await Promise.all([
    getDocs(query(collection(db, "posts"), ...constraints)),
    listPostReportIndicators(),
  ]);
  let items = snap.docs.map((d) => ({
    ...mapPost(d.id, d.data()),
    reports: reportIndicators.get(d.id),
  }));

  if (params.filter === "reported") {
    items = items.filter((post) => Boolean(post.reports));
  }

  const term = params.searchTerm?.trim().toLowerCase();
  if (term) {
    items = items.filter(
      (post) =>
        post.title.toLowerCase().includes(term) ||
        (post.description ?? "").toLowerCase().includes(term) ||
        (post.authorName ?? "").toLowerCase().includes(term) ||
        (post.authorProfileId ?? "").toLowerCase().includes(term) ||
        (post.city ?? "").toLowerCase().includes(term) ||
        (post.state ?? "").toLowerCase().includes(term),
    );
  }

  return items;
}

export async function resolvePostReports(
  post: FeedPost,
  admin: AdminUser,
): Promise<void> {
  if (!post.reports?.notificationIds.length && !post.reports?.reportIds.length) {
    return;
  }

  const batch = writeBatch(db);
  post.reports?.reportIds.forEach((reportId) => {
    batch.update(doc(db, "reports", reportId), {
      status: "resolved",
      reviewedAt: Timestamp.now(),
      reviewedBy: admin.uid,
      resolutionAction: "content_kept",
    });
  });
  post.reports.notificationIds.forEach((notificationId) => {
    batch.update(doc(db, "adminNotifications", notificationId), {
      read: true,
      status: "resolved",
      resolvedAt: Timestamp.now(),
      reviewedBy: admin.uid,
    });
  });
  await batch.commit();

  await recordAudit(admin, {
    action: "report.resolve",
    targetType: "post",
    targetId: post.id,
    metadata: {
      reportIds: post.reports?.reportIds ?? [],
      notificationIds: post.reports?.notificationIds ?? [],
      reasons: post.reports?.reasons ?? [],
    },
  });
}

export async function deleteFeedPost(
  post: FeedPost,
  admin: AdminUser,
): Promise<void> {
  await deleteDoc(doc(db, "posts", post.id));

  if (!post.reports?.notificationIds.length && !post.reports?.reportIds.length) {
    await recordAudit(admin, {
      action: "post.delete",
      targetType: "post",
      targetId: post.id,
      metadata: { source: "feed_admin" },
    });
    return;
  }

  const batch = writeBatch(db);
  post.reports?.reportIds.forEach((reportId) => {
    batch.update(doc(db, "reports", reportId), {
      status: "resolved",
      reviewedAt: Timestamp.now(),
      reviewedBy: admin.uid,
      resolutionAction: "content_removed",
    });
  });
  post.reports.notificationIds.forEach((notificationId) => {
    batch.update(doc(db, "adminNotifications", notificationId), {
      read: true,
      status: "removed",
      resolvedAt: Timestamp.now(),
      reviewedBy: admin.uid,
    });
  });
  await batch.commit();

  await recordAudit(admin, {
    action: "post.delete",
    targetType: "post",
    targetId: post.id,
    metadata: {
      source: "feed_admin",
      reportIds: post.reports?.reportIds ?? [],
      notificationIds: post.reports?.notificationIds ?? [],
      reasons: post.reports?.reasons ?? [],
    },
  });
}

export type FeedFlag = "featured" | "promoted" | "pinned";

export async function setFeedFlag(
  postId: string,
  flag: FeedFlag,
  value: boolean,
): Promise<void> {
  await updateDoc(doc(db, "posts", postId), {
    [flag]: value,
    [`${flag}UpdatedAt`]: Timestamp.now(),
  });
}
