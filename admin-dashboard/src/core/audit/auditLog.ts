import { addDoc, collection, serverTimestamp } from "firebase/firestore";
import { db } from "../firebase/client";
import type { AdminUser } from "../auth/roles";

export type AuditAction =
  | "report.resolve"
  | "report.dismiss"
  | "content.delete"
  | "comment.delete"
  | "post.delete"
  | "user.ban"
  | "user.unban"
  | "user.delete"
  | "catalog.update"
  | "admin.role.update"
  | "admin.create"
  | "admin.delete";

export interface AuditPayload {
  action: AuditAction;
  targetType: "user" | "post" | "comment" | "report" | "catalog" | "admin";
  targetId: string;
  metadata?: Record<string, unknown>;
}

/**
 * Grava um evento de auditoria. Best-effort — falhas são logadas mas não bloqueiam o fluxo.
 * Regras de Firestore restringem a coleção a admins; gravação client-side é permitida
 * (com `actorUid == request.auth.uid`) para garantir rastreabilidade mesmo sem callable.
 */
export async function recordAudit(
  actor: AdminUser | null,
  payload: AuditPayload,
): Promise<void> {
  if (!actor) return;
  try {
    await addDoc(collection(db, "audit_logs"), {
      actorUid: actor.uid,
      actorEmail: actor.email,
      actorRole: actor.role,
      action: payload.action,
      targetType: payload.targetType,
      targetId: payload.targetId,
      metadata: payload.metadata ?? {},
      timestamp: serverTimestamp(),
    });
  } catch (err) {
    console.warn("[audit] failed to record event", payload.action, err);
  }
}
