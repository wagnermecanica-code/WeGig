import { Shield, Mail } from 'lucide-react';
import { useAuth } from '@core/auth/AuthProvider';
import { Button } from '@shared/components/ui/Button';

export function AccessDeniedPage() {
  const { user, signOut } = useAuth();
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-slate-950 p-4">
      <div className="max-w-md w-full bg-white dark:bg-slate-900 border border-gray-100 dark:border-slate-800 rounded-2xl shadow-sm p-8 text-center">
        <div className="mx-auto h-14 w-14 rounded-xl bg-red-100 dark:bg-red-900/40 text-red-600 dark:text-red-300 flex items-center justify-center mb-4">
          <Shield className="h-7 w-7" />
        </div>
        <h1 className="text-lg font-semibold mb-2 dark:text-white">Acesso negado</h1>
        <p className="text-sm text-gray-500 dark:text-slate-400 mb-6">
          Sua conta não tem permissão para acessar o painel. Solicite acesso a um administrador.
        </p>
        {user ? (
          <div className="text-xs text-left bg-gray-50 dark:bg-slate-800 rounded-lg p-3 mb-6 space-y-1">
            <div className="flex items-center gap-2 text-gray-600 dark:text-slate-300">
              <Mail className="h-3 w-3" /> {user.email}
            </div>
            <div className="font-mono text-[10px] break-all text-gray-400">{user.uid}</div>
          </div>
        ) : null}
        <Button variant="secondary" className="w-full" onClick={() => signOut()}>
          Sair
        </Button>
      </div>
    </div>
  );
}
