import ReportsTab from "../../../components/ReportsTab.jsx";

export function ModerationReportsPage() {
  return (
    <div className="space-y-4">
      <div>
        <h2 className="text-xl font-semibold tracking-tight dark:text-white">
          Moderação · Reports
        </h2>
        <p className="text-sm text-gray-500 dark:text-slate-400">
          Conteúdo denunciado pela comunidade.
        </p>
      </div>
      <div className="rounded-xl border border-gray-200 bg-white dark:bg-slate-900 dark:border-slate-800 p-2 sm:p-4">
        <ReportsTab />
      </div>
    </div>
  );
}
