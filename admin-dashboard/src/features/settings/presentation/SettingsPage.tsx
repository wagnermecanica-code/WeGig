import { Card, CardBody, CardHeader, CardTitle } from '@shared/components/ui/Card';
import { Badge } from '@shared/components/ui/Badge';
import { useAuth } from '@core/auth/AuthProvider';
import { permissionsForRole } from '@core/auth/roles';

export function SettingsPage() {
  const { admin } = useAuth();
  if (!admin) return null;
  const perms = permissionsForRole(admin.role);

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-xl font-semibold tracking-tight dark:text-white">Configurações</h2>
        <p className="text-sm text-gray-500 dark:text-slate-400">
          Informações da sua conta administrativa.
        </p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Sua sessão</CardTitle>
        </CardHeader>
        <CardBody className="space-y-3 text-sm">
          <div className="flex justify-between">
            <span className="text-gray-500 dark:text-slate-400">E-mail</span>
            <span className="font-medium dark:text-white">{admin.email}</span>
          </div>
          <div className="flex justify-between">
            <span className="text-gray-500 dark:text-slate-400">UID</span>
            <span className="font-mono text-xs text-gray-400">{admin.uid}</span>
          </div>
          <div className="flex justify-between items-center">
            <span className="text-gray-500 dark:text-slate-400">Role</span>
            <Badge tone="info">{admin.role}</Badge>
          </div>
        </CardBody>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Permissões ativas</CardTitle>
        </CardHeader>
        <CardBody className="flex flex-wrap gap-2">
          {perms.map((p) => (
            <Badge key={p} tone="neutral" className="font-mono">
              {p}
            </Badge>
          ))}
        </CardBody>
      </Card>
    </div>
  );
}
