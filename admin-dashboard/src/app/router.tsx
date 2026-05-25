import { lazy, Suspense } from "react";
import {
  createBrowserRouter,
  Navigate,
  RouterProvider,
} from "react-router-dom";
import { AppShell } from "./AppShell";
import { RequireAdmin } from "./guards/RequireAdmin";
import { useAuth } from "@core/auth/AuthProvider";
import { LoginPage } from "@features/auth/presentation/LoginPage";
import { AccessDeniedPage } from "@features/auth/presentation/AccessDeniedPage";

const CHUNK_RELOAD_KEY = "admin_chunk_reload_once";

function isChunkImportError(error: unknown): boolean {
  const message = error instanceof Error ? error.message : String(error ?? "");

  return /Importing a module script failed|Failed to fetch dynamically imported module|ChunkLoadError|Loading chunk/i.test(
    message,
  );
}

async function lazyImportWithReload<T>(
  importer: () => Promise<{ default: T }>,
): Promise<{ default: T }> {
  try {
    const mod = await importer();
    if (typeof window !== "undefined") {
      window.sessionStorage.removeItem(CHUNK_RELOAD_KEY);
    }
    return mod;
  } catch (error) {
    if (typeof window !== "undefined" && isChunkImportError(error)) {
      const alreadyReloaded =
        window.sessionStorage.getItem(CHUNK_RELOAD_KEY) === "1";

      if (!alreadyReloaded) {
        window.sessionStorage.setItem(CHUNK_RELOAD_KEY, "1");
        window.location.reload();
        return new Promise(() => {
          // Aguarda o reload da página; evita propagar erro transitório de chunk.
        });
      }
    }

    throw error;
  }
}

const DashboardPage = lazy(() =>
  lazyImportWithReload(() =>
    import("@features/dashboard/presentation/DashboardPage").then((m) => ({
      default: m.DashboardPage,
    })),
  ),
);
const ModerationReportsPage = lazy(() =>
  lazyImportWithReload(() =>
    import("@features/moderation/presentation/ModerationReportsPage").then(
      (m) => ({
        default: m.ModerationReportsPage,
      }),
    ),
  ),
);
const UsersListPage = lazy(() =>
  lazyImportWithReload(() =>
    import("@features/users/presentation/UsersListPage").then((m) => ({
      default: m.UsersListPage,
    })),
  ),
);
const UserDetailPage = lazy(() =>
  lazyImportWithReload(() =>
    import("@features/users/presentation/UserDetailPage").then((m) => ({
      default: m.UserDetailPage,
    })),
  ),
);
const CommentsPage = lazy(() =>
  lazyImportWithReload(() =>
    import("@features/comments/presentation/CommentsPage").then((m) => ({
      default: m.CommentsPage,
    })),
  ),
);
const FeedbacksPage = lazy(() =>
  lazyImportWithReload(() =>
    import("@features/feedbacks/presentation/FeedbacksPage").then((m) => ({
      default: m.FeedbacksPage,
    })),
  ),
);
const CatalogPage = lazy(() =>
  lazyImportWithReload(() =>
    import("@features/catalog/presentation/CatalogPage").then((m) => ({
      default: m.CatalogPage,
    })),
  ),
);
const AuditLogPage = lazy(() =>
  lazyImportWithReload(() =>
    import("@features/audit/presentation/AuditLogPage").then((m) => ({
      default: m.AuditLogPage,
    })),
  ),
);
const SettingsPage = lazy(() =>
  lazyImportWithReload(() =>
    import("@features/settings/presentation/SettingsPage").then((m) => ({
      default: m.SettingsPage,
    })),
  ),
);
const AnalyticsPage = lazy(() =>
  lazyImportWithReload(() =>
    import("@features/analytics/presentation/AnalyticsPage").then((m) => ({
      default: m.AnalyticsPage,
    })),
  ),
);
const HeatmapPage = lazy(() =>
  lazyImportWithReload(() =>
    import("@features/heatmap/presentation/HeatmapPage").then((m) => ({
      default: m.HeatmapPage,
    })),
  ),
);
const FeedAdminPage = lazy(() =>
  lazyImportWithReload(() =>
    import("@features/feed-admin/presentation/FeedAdminPage").then((m) => ({
      default: m.FeedAdminPage,
    })),
  ),
);
const ReputationPage = lazy(() =>
  lazyImportWithReload(() =>
    import("@features/reputation/presentation/ReputationPage").then((m) => ({
      default: m.ReputationPage,
    })),
  ),
);
const CrashlyticsPage = lazy(() =>
  lazyImportWithReload(() =>
    import("@features/crashlytics/presentation/CrashlyticsPage").then((m) => ({
      default: m.CrashlyticsPage,
    })),
  ),
);

function Suspended({ children }: { children: React.ReactNode }) {
  return (
    <Suspense
      fallback={
        <div className="py-12 text-center text-sm text-gray-500 dark:text-slate-400">
          Carregando…
        </div>
      }
    >
      {children}
    </Suspense>
  );
}

const router = createBrowserRouter(
  [
    { path: "/login", element: <LoginPage /> },
    { path: "/access-denied", element: <AccessDeniedPage /> },
    {
      path: "/",
      element: (
        <RequireAdmin>
          <AppShell />
        </RequireAdmin>
      ),
      children: [
        { index: true, element: <Navigate to="/dashboard" replace /> },
        {
          path: "dashboard",
          element: (
            <RequireAdmin permission="dashboard.view">
              <Suspended>
                <DashboardPage />
              </Suspended>
            </RequireAdmin>
          ),
        },
        {
          path: "moderation/reports",
          element: (
            <RequireAdmin permission="reports.view">
              <Suspended>
                <ModerationReportsPage />
              </Suspended>
            </RequireAdmin>
          ),
        },
        {
          path: "users",
          element: (
            <RequireAdmin permission="users.view">
              <Suspended>
                <UsersListPage />
              </Suspended>
            </RequireAdmin>
          ),
        },
        {
          path: "users/:id",
          element: (
            <RequireAdmin permission="users.view">
              <Suspended>
                <UserDetailPage />
              </Suspended>
            </RequireAdmin>
          ),
        },
        {
          path: "comments",
          element: (
            <RequireAdmin permission="comments.view">
              <Suspended>
                <CommentsPage />
              </Suspended>
            </RequireAdmin>
          ),
        },
        {
          path: "feedbacks",
          element: (
            <RequireAdmin permission="feedbacks.view">
              <Suspended>
                <FeedbacksPage />
              </Suspended>
            </RequireAdmin>
          ),
        },
        {
          path: "catalog",
          element: (
            <RequireAdmin permission="catalog.view">
              <Suspended>
                <CatalogPage />
              </Suspended>
            </RequireAdmin>
          ),
        },
        {
          path: "audit",
          element: (
            <RequireAdmin permission="audit.view">
              <Suspended>
                <AuditLogPage />
              </Suspended>
            </RequireAdmin>
          ),
        },
        {
          path: "settings",
          element: (
            <RequireAdmin>
              <Suspended>
                <SettingsPage />
              </Suspended>
            </RequireAdmin>
          ),
        },
        {
          path: "analytics",
          element: (
            <RequireAdmin permission="analytics.view">
              <Suspended>
                <AnalyticsPage />
              </Suspended>
            </RequireAdmin>
          ),
        },
        {
          path: "crashlytics",
          element: (
            <RequireAdmin permission="analytics.view">
              <Suspended>
                <CrashlyticsPage />
              </Suspended>
            </RequireAdmin>
          ),
        },
        {
          path: "heatmap",
          element: (
            <RequireAdmin permission="heatmap.view">
              <Suspended>
                <HeatmapPage />
              </Suspended>
            </RequireAdmin>
          ),
        },
        {
          path: "feed-admin",
          element: (
            <RequireAdmin permission="feed.manage">
              <Suspended>
                <FeedAdminPage />
              </Suspended>
            </RequireAdmin>
          ),
        },
        {
          path: "reputation",
          element: (
            <RequireAdmin permission="reputation.manage">
              <Suspended>
                <ReputationPage />
              </Suspended>
            </RequireAdmin>
          ),
        },
        { path: "*", element: <Navigate to="/dashboard" replace /> },
      ],
    },
  ],
  { basename: "/admin" },
);

export function AppRouter() {
  // Roteia automaticamente um usuário autenticado mas não-admin para /access-denied
  const { user, isAdmin, loading } = useAuth();
  if (
    !loading &&
    user &&
    !isAdmin &&
    window.location.pathname !== "/admin/access-denied"
  ) {
    return <AccessDeniedPage />;
  }
  return <RouterProvider router={router} />;
}
