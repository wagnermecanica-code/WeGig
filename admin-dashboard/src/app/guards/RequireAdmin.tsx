import { type ReactNode } from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '@core/auth/AuthProvider';
import type { Permission } from '@core/auth/roles';

interface GuardProps {
  children: ReactNode;
  permission?: Permission;
}

export function RequireAdmin({ children, permission }: GuardProps) {
  const { loading, isAdmin, hasPermission } = useAuth();
  const location = useLocation();

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-slate-950">
        <div className="text-sm text-gray-500 dark:text-slate-400">Carregando…</div>
      </div>
    );
  }
  if (!isAdmin) {
    return <Navigate to="/login" replace state={{ from: location.pathname }} />;
  }
  if (permission && !hasPermission(permission)) {
    return <Navigate to="/dashboard" replace />;
  }
  return <>{children}</>;
}
