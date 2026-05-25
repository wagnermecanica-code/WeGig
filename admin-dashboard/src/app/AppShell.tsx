import { NavLink, Outlet } from "react-router-dom";
import { useState } from "react";
import {
  LayoutDashboard,
  ShieldAlert,
  Users,
  MessageSquare,
  BookOpen,
  Inbox,
  Settings,
  LogOut,
  Sun,
  Moon,
  Menu,
  X,
  ScrollText,
} from "lucide-react";
import { clsx } from "clsx";
import { useAuth } from "@core/auth/AuthProvider";
import type { Permission } from "@core/auth/roles";
import { useTheme } from "@core/theme/ThemeProvider";

interface NavItem {
  to: string;
  label: string;
  icon: React.ComponentType<{ className?: string }>;
  permission: Permission;
}

const NAV: NavItem[] = [
  {
    to: "/dashboard",
    label: "Dashboard",
    icon: LayoutDashboard,
    permission: "dashboard.view",
  },
  {
    to: "/moderation/reports",
    label: "Moderação",
    icon: ShieldAlert,
    permission: "reports.view",
  },
  { to: "/users", label: "Usuários", icon: Users, permission: "users.view" },
  {
    to: "/comments",
    label: "Comentários",
    icon: MessageSquare,
    permission: "comments.view",
  },
  {
    to: "/feedbacks",
    label: "Feedbacks",
    icon: Inbox,
    permission: "feedbacks.view",
  },
  {
    to: "/catalog",
    label: "Catálogo",
    icon: BookOpen,
    permission: "catalog.view",
  },
  {
    to: "/audit",
    label: "Auditoria",
    icon: ScrollText,
    permission: "audit.view",
  },
  {
    to: "/settings",
    label: "Configurações",
    icon: Settings,
    permission: "dashboard.view",
  },
];

export function AppShell() {
  const { admin, hasPermission, signOut } = useAuth();
  const { theme, toggle } = useTheme();
  const [sidebarOpen, setSidebarOpen] = useState(false);

  const visibleNav = NAV.filter((item) => hasPermission(item.permission));

  return (
    <div className="min-h-screen bg-gray-50 text-gray-900 dark:bg-slate-950 dark:text-slate-100">
      {/* Sidebar mobile backdrop */}
      {sidebarOpen ? (
        <div
          className="fixed inset-0 z-30 bg-black/40 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      ) : null}

      {/* Sidebar */}
      <aside
        className={clsx(
          "fixed inset-y-0 left-0 z-40 w-64 transform border-r bg-white transition-transform duration-200 ease-out",
          "border-gray-200 dark:bg-slate-900 dark:border-slate-800",
          "lg:translate-x-0",
          sidebarOpen ? "translate-x-0" : "-translate-x-full",
        )}
      >
        <div className="flex h-16 items-center justify-between px-5 border-b border-gray-100 dark:border-slate-800">
          <div className="flex items-center gap-2">
            <div className="h-8 w-8 rounded-lg bg-primary flex items-center justify-center text-white font-bold text-sm">
              W
            </div>
            <div>
              <p className="text-sm font-semibold leading-none">WeGig</p>
              <p className="text-[10px] uppercase tracking-wider text-gray-500 dark:text-slate-400">
                Admin
              </p>
            </div>
          </div>
          <button
            className="lg:hidden text-gray-500 hover:text-gray-700 dark:text-slate-400"
            onClick={() => setSidebarOpen(false)}
            aria-label="Fechar menu"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <nav className="px-3 py-4 space-y-1">
          {visibleNav.map((item) => {
            const Icon = item.icon;
            return (
              <NavLink
                key={item.to}
                to={item.to}
                onClick={() => setSidebarOpen(false)}
                className={({ isActive }) =>
                  clsx(
                    "flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors",
                    isActive
                      ? "bg-primary/10 text-primary dark:bg-primary/20 dark:text-white"
                      : "text-gray-600 hover:bg-gray-100 dark:text-slate-300 dark:hover:bg-slate-800",
                  )
                }
              >
                <Icon className="h-4 w-4" />
                {item.label}
              </NavLink>
            );
          })}
        </nav>

        <div className="absolute bottom-0 left-0 right-0 p-3 border-t border-gray-100 dark:border-slate-800">
          <div className="flex items-center gap-3 px-2 py-2">
            <div className="h-8 w-8 rounded-full bg-primary/20 text-primary dark:text-white flex items-center justify-center text-xs font-bold">
              {admin?.email?.slice(0, 2).toUpperCase() ?? "AD"}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-xs font-medium truncate">{admin?.email}</p>
              <p className="text-[10px] uppercase tracking-wider text-gray-500 dark:text-slate-400">
                {admin?.role}
              </p>
            </div>
            <button
              onClick={() => signOut()}
              className="text-gray-500 hover:text-red-600"
              title="Sair"
              aria-label="Sair"
            >
              <LogOut className="h-4 w-4" />
            </button>
          </div>
        </div>
      </aside>

      {/* Main */}
      <div className="lg:pl-64">
        <header className="sticky top-0 z-20 flex h-16 items-center justify-between border-b border-gray-200 bg-white/80 px-4 backdrop-blur dark:border-slate-800 dark:bg-slate-900/80 sm:px-6">
          <div className="flex items-center gap-3">
            <button
              className="lg:hidden text-gray-500"
              onClick={() => setSidebarOpen(true)}
              aria-label="Abrir menu"
            >
              <Menu className="h-5 w-5" />
            </button>
            <h1 className="text-sm font-semibold text-gray-700 dark:text-slate-200">
              Painel de Controle
            </h1>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={toggle}
              className="p-2 rounded-lg text-gray-500 hover:bg-gray-100 dark:text-slate-400 dark:hover:bg-slate-800"
              aria-label="Alternar tema"
            >
              {theme === "dark" ? (
                <Sun className="h-4 w-4" />
              ) : (
                <Moon className="h-4 w-4" />
              )}
            </button>
          </div>
        </header>
        <main className="p-4 sm:p-6 lg:p-8">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
