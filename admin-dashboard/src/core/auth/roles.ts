/**
 * Roles disponíveis no painel admin.
 * Hierarquia (do mais alto ao mais baixo):
 *   superadmin > admin > moderator > support > analytics
 */
export type AdminRole =
  | "superadmin"
  | "admin"
  | "moderator"
  | "support"
  | "analytics";

export interface AdminUser {
  uid: string;
  email: string | null;
  displayName: string | null;
  role: AdminRole;
  createdAt?: Date;
}

/**
 * Permissões granulares. Cada role mapeia para um conjunto.
 * Use o hook usePermissions() para checar.
 */
export type Permission =
  | "dashboard.view"
  | "users.view"
  | "users.moderate"
  | "users.delete"
  | "users.impersonate"
  | "content.view"
  | "content.moderate"
  | "content.delete"
  | "reports.view"
  | "reports.resolve"
  | "comments.view"
  | "comments.delete"
  | "feedbacks.view"
  | "catalog.view"
  | "catalog.edit"
  | "analytics.view"
  | "audit.view"
  | "admins.manage"
  | "heatmap.view"
  | "feed.manage"
  | "reputation.manage";

const PERMISSION_MATRIX: Record<AdminRole, Permission[]> = {
  superadmin: [
    "dashboard.view",
    "users.view",
    "users.moderate",
    "users.delete",
    "users.impersonate",
    "content.view",
    "content.moderate",
    "content.delete",
    "reports.view",
    "reports.resolve",
    "comments.view",
    "comments.delete",
    "feedbacks.view",
    "catalog.view",
    "catalog.edit",
    "analytics.view",
    "audit.view",
    "admins.manage",
    "heatmap.view",
    "feed.manage",
    "reputation.manage",
  ],
  admin: [
    "dashboard.view",
    "users.view",
    "users.moderate",
    "content.view",
    "content.moderate",
    "content.delete",
    "reports.view",
    "reports.resolve",
    "comments.view",
    "comments.delete",
    "feedbacks.view",
    "catalog.view",
    "catalog.edit",
    "analytics.view",
    "audit.view",
    "heatmap.view",
    "feed.manage",
    "reputation.manage",
  ],
  moderator: [
    "dashboard.view",
    "users.view",
    "users.moderate",
    "content.view",
    "content.moderate",
    "content.delete",
    "reports.view",
    "reports.resolve",
    "comments.view",
    "comments.delete",
    "feedbacks.view",
    "audit.view",
  ],
  support: ["dashboard.view", "users.view", "reports.view", "feedbacks.view"],
  analytics: [
    "dashboard.view",
    "analytics.view",
    "heatmap.view",
  ],
};

export function permissionsForRole(role: AdminRole): Permission[] {
  return PERMISSION_MATRIX[role] ?? [];
}

export function hasPermission(
  role: AdminRole | null,
  permission: Permission,
): boolean {
  if (!role) return false;
  return permissionsForRole(role).includes(permission);
}
