import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import {
  ArrowLeft,
  Ban,
  Copy,
  FileText,
  Mail,
  MessageSquare,
  Phone,
  RefreshCw,
  Send,
  ShieldAlert,
  UserCheck,
} from "lucide-react";
import {
  Card,
  CardBody,
  CardHeader,
  CardTitle,
} from "@shared/components/ui/Card";
import { Badge } from "@shared/components/ui/Badge";
import { Button } from "@shared/components/ui/Button";
import { Skeleton } from "@shared/components/ui/Skeleton";
import { StatCard } from "@shared/components/ui/StatCard";
import { useAuth } from "@core/auth/AuthProvider";
import { recordAudit } from "@core/audit/auditLog";
import {
  getProfile,
  getUserActivity,
  type ProfileDetail,
  type UserActivity,
} from "../data/usersService";
import { doc, updateDoc, serverTimestamp } from "firebase/firestore";
import { sendPasswordResetEmail } from "firebase/auth";
import { auth, db } from "@core/firebase/client";

export function UserDetailPage() {
  const { id = "" } = useParams();
  const { admin, hasPermission } = useAuth();
  const [profile, setProfile] = useState<ProfileDetail | null>(null);
  const [activity, setActivity] = useState<UserActivity | null>(null);
  const [loading, setLoading] = useState(true);
  const [actionInProgress, setActionInProgress] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [reloadKey, setReloadKey] = useState(0);

  useEffect(() => {
    let active = true;
    setLoading(true);
    (async () => {
      try {
        const p = await getProfile(id);
        if (!active) return;
        setProfile(p);
        if (p) {
          const act = await getUserActivity(p.id, p.ownerUid);
          if (active) setActivity(act);
        }
      } catch (err) {
        if (active) setError(err instanceof Error ? err.message : "Erro");
      } finally {
        if (active) setLoading(false);
      }
    })();
    return () => {
      active = false;
    };
  }, [id, reloadKey]);

  function formatDate(value?: Date) {
    if (!value) return "—";
    return new Intl.DateTimeFormat("pt-BR", {
      dateStyle: "medium",
      timeStyle: "short",
    }).format(value);
  }

  function renderFlag(value?: boolean) {
    if (value === true) return "Sim";
    if (value === false) return "Não";
    return "—";
  }

  async function copyToClipboard(value: string, label: string) {
    try {
      await navigator.clipboard.writeText(value);
      setSuccess(`${label} copiado.`);
    } catch {
      setError(`Não foi possível copiar ${label}.`);
    }
  }

  async function handleSendPasswordReset() {
    if (!profile?.email || !admin) return;
    setActionInProgress(true);
    setError(null);
    setSuccess(null);
    try {
      await sendPasswordResetEmail(auth, profile.email);
      await recordAudit(admin, {
        action: "user.password_reset_email",
        targetType: "user",
        targetId: profile.id,
        metadata: { email: profile.email, name: profile.name },
      });
      setSuccess(`Email de reset de senha enviado para ${profile.email}.`);
    } catch (err) {
      setError(
        err instanceof Error
          ? err.message
          : "Erro ao enviar email de reset de senha",
      );
    } finally {
      setActionInProgress(false);
    }
  }

  async function handleToggleBan() {
    if (!profile || !admin) return;
    const newBanned = !profile.banned;
    setActionInProgress(true);
    try {
      await updateDoc(doc(db, "profiles", profile.id), {
        banned: newBanned,
        moderationStatus: newBanned ? "banned" : "active",
        moderatedAt: serverTimestamp(),
        moderatedBy: admin.uid,
      });
      await recordAudit(admin, {
        action: newBanned ? "user.ban" : "user.unban",
        targetType: "user",
        targetId: profile.id,
        metadata: { name: profile.name },
      });
      setProfile({ ...profile, banned: newBanned });
    } catch (err) {
      setError(err instanceof Error ? err.message : "Erro ao atualizar status");
    } finally {
      setActionInProgress(false);
    }
  }

  if (loading) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-8 w-48" />
        <Skeleton className="h-32" />
        <Skeleton className="h-48" />
      </div>
    );
  }

  if (!profile) {
    return (
      <div className="text-center py-12">
        <p className="text-gray-500 dark:text-slate-400">
          Perfil não encontrado.
        </p>
        <Link
          to="/users"
          className="text-primary hover:underline text-sm mt-2 inline-block"
        >
          ← Voltar para lista
        </Link>
      </div>
    );
  }

  const canModerate = hasPermission("users.moderate");

  return (
    <div className="space-y-6">
      <Link
        to="/users"
        className="inline-flex items-center gap-1 text-sm text-gray-500 hover:text-primary"
      >
        <ArrowLeft className="h-4 w-4" /> Voltar
      </Link>

      {error ? (
        <div className="rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-700">
          {error}
        </div>
      ) : null}

      {success ? (
        <div className="rounded-lg border border-green-200 bg-green-50 p-3 text-sm text-green-700 dark:border-green-900 dark:bg-green-900/30 dark:text-green-300">
          {success}
        </div>
      ) : null}

      <Card>
        <CardBody className="flex flex-col sm:flex-row gap-4 sm:items-center">
          <div className="h-16 w-16 rounded-full bg-primary/20 text-primary flex items-center justify-center text-xl font-bold">
            {profile.name.slice(0, 2).toUpperCase()}
          </div>
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 flex-wrap">
              <h2 className="text-lg font-semibold dark:text-white">
                {profile.name}
              </h2>
              {profile.banned ? (
                <Badge tone="danger">Banido</Badge>
              ) : (
                <Badge tone="success">Ativo</Badge>
              )}
              {profile.profileType ? (
                <Badge tone="info">{profile.profileType}</Badge>
              ) : null}
            </div>
            <p className="text-sm text-gray-500 dark:text-slate-400 mt-1">
              {[profile.city, profile.state].filter(Boolean).join(" · ") || "—"}
            </p>
            <p className="text-xs font-mono text-gray-400 mt-1">{profile.id}</p>
          </div>
          <div className="flex flex-wrap gap-2">
            <Button
              variant="secondary"
              onClick={() => setReloadKey((x) => x + 1)}
              disabled={loading || actionInProgress}
            >
              <RefreshCw className="h-4 w-4" /> Atualizar
            </Button>
            <Button
              variant="ghost"
              onClick={() => void copyToClipboard(profile.id, "ID do perfil")}
            >
              <Copy className="h-4 w-4" /> Copiar ID
            </Button>
            {profile.ownerUid ? (
              <Button
                variant="ghost"
                onClick={() =>
                  void copyToClipboard(
                    profile.ownerUid ?? "",
                    "UID proprietário",
                  )
                }
              >
                <Copy className="h-4 w-4" /> Copiar UID
              </Button>
            ) : null}
            {canModerate ? (
              <>
                <Button
                  variant="secondary"
                  onClick={handleSendPasswordReset}
                  disabled={actionInProgress || !profile.email}
                  title={
                    profile.email
                      ? "Enviar email de reset de senha"
                      : "Perfil sem email cadastrado"
                  }
                >
                  <Send className="h-4 w-4" /> Resetar senha
                </Button>
                <Button
                  variant={profile.banned ? "secondary" : "danger"}
                  onClick={handleToggleBan}
                  disabled={actionInProgress}
                >
                  <Ban className="h-4 w-4" />
                  {profile.banned ? "Desbanir" : "Banir"}
                </Button>
              </>
            ) : null}
          </div>
        </CardBody>
      </Card>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
        <StatCard
          label="Posts"
          value={activity?.postsCount ?? "—"}
          icon={<FileText className="h-4 w-4" />}
        />
        <StatCard
          label="Conversas"
          value={activity?.conversationsCount ?? "—"}
          icon={<MessageSquare className="h-4 w-4" />}
        />
        <StatCard
          label="Reports recebidos"
          value={activity?.reportsAgainst ?? "—"}
          icon={<ShieldAlert className="h-4 w-4" />}
        />
        <StatCard
          label="Reports abertos"
          value={activity?.reportsOpened ?? "—"}
          icon={<ShieldAlert className="h-4 w-4" />}
        />
        <StatCard
          label="Comentários"
          value={activity?.commentsCount ?? "—"}
          icon={<MessageSquare className="h-4 w-4" />}
        />
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Dados do Perfil</CardTitle>
        </CardHeader>
        <CardBody>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 text-sm">
            <div>
              <p className="text-gray-500 dark:text-slate-400">
                UID proprietário
              </p>
              <p className="font-mono text-xs break-all">
                {profile.ownerUid ?? "—"}
              </p>
            </div>
            <div>
              <p className="text-gray-500 dark:text-slate-400">Username</p>
              <p>{profile.username ?? "—"}</p>
            </div>
            <div>
              <p className="text-gray-500 dark:text-slate-400">Email</p>
              <p className="inline-flex items-center gap-1">
                <Mail className="h-3.5 w-3.5" /> {profile.email ?? "—"}
              </p>
            </div>
            <div>
              <p className="text-gray-500 dark:text-slate-400">Telefone</p>
              <p className="inline-flex items-center gap-1">
                <Phone className="h-3.5 w-3.5" /> {profile.phone ?? "—"}
              </p>
            </div>
            <div>
              <p className="text-gray-500 dark:text-slate-400">Verificado</p>
              <p className="inline-flex items-center gap-1">
                <UserCheck className="h-3.5 w-3.5" />{" "}
                {renderFlag(profile.verified)}
              </p>
            </div>
            <div>
              <p className="text-gray-500 dark:text-slate-400">
                Status de moderação
              </p>
              <p>{profile.moderationStatus ?? "—"}</p>
            </div>
            <div>
              <p className="text-gray-500 dark:text-slate-400">Criado em</p>
              <p>{formatDate(profile.createdAt)}</p>
            </div>
            <div>
              <p className="text-gray-500 dark:text-slate-400">Atualizado em</p>
              <p>{formatDate(profile.updatedAt)}</p>
            </div>
            <div>
              <p className="text-gray-500 dark:text-slate-400">Último acesso</p>
              <p>{formatDate(profile.lastSeenAt)}</p>
            </div>
            <div>
              <p className="text-gray-500 dark:text-slate-400">
                Permite sugestões de conexão
              </p>
              <p>{renderFlag(profile.allowConnectionSuggestions)}</p>
            </div>
            <div>
              <p className="text-gray-500 dark:text-slate-400">
                Permite solicitações de conexão
              </p>
              <p>{renderFlag(profile.allowConnectionRequests)}</p>
            </div>
            <div>
              <p className="text-gray-500 dark:text-slate-400">
                Bloqueados / bloqueado por
              </p>
              <p>
                {(profile.blockedProfilesCount ?? 0).toString()} /{" "}
                {(profile.blockedByProfilesCount ?? 0).toString()}
              </p>
            </div>
          </div>
        </CardBody>
      </Card>

      {profile.genres?.length || profile.instruments?.length ? (
        <Card>
          <CardHeader>
            <CardTitle>Preferências Musicais</CardTitle>
          </CardHeader>
          <CardBody className="space-y-3 text-sm">
            <div>
              <p className="text-gray-500 dark:text-slate-400">Gêneros</p>
              <p>{profile.genres?.join(", ") ?? "—"}</p>
            </div>
            <div>
              <p className="text-gray-500 dark:text-slate-400">Instrumentos</p>
              <p>{profile.instruments?.join(", ") ?? "—"}</p>
            </div>
          </CardBody>
        </Card>
      ) : null}

      {profile.bio ? (
        <Card>
          <CardHeader>
            <CardTitle>Bio</CardTitle>
          </CardHeader>
          <CardBody className="text-sm text-gray-700 dark:text-slate-300 whitespace-pre-wrap">
            {profile.bio}
          </CardBody>
        </Card>
      ) : null}

    </div>
  );
}
