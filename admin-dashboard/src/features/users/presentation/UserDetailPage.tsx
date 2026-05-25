import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import {
  ArrowLeft,
  Ban,
  FileText,
  MessageSquare,
  ShieldAlert,
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
import { db } from "@core/firebase/client";

export function UserDetailPage() {
  const { id = "" } = useParams();
  const { admin, hasPermission } = useAuth();
  const [profile, setProfile] = useState<ProfileDetail | null>(null);
  const [activity, setActivity] = useState<UserActivity | null>(null);
  const [loading, setLoading] = useState(true);
  const [actionInProgress, setActionInProgress] = useState(false);
  const [error, setError] = useState<string | null>(null);

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
  }, [id]);

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
          {canModerate ? (
            <Button
              variant={profile.banned ? "secondary" : "danger"}
              onClick={handleToggleBan}
              disabled={actionInProgress}
            >
              <Ban className="h-4 w-4" />
              {profile.banned ? "Desbanir" : "Banir"}
            </Button>
          ) : null}
        </CardBody>
      </Card>

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
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
      </div>

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

      <Card>
        <CardHeader>
          <CardTitle>Dados brutos</CardTitle>
        </CardHeader>
        <CardBody>
          <pre className="text-[11px] bg-gray-50 dark:bg-slate-800 p-3 rounded overflow-auto max-h-80">
            {JSON.stringify(profile.raw, null, 2)}
          </pre>
        </CardBody>
      </Card>
    </div>
  );
}
