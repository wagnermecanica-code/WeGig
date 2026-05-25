import CommentsTab from "../../../components/CommentsTab.jsx";

export function CommentsPage() {
  return (
    <div className="space-y-4">
      <div>
        <h2 className="text-xl font-semibold tracking-tight dark:text-white">
          Comentários
        </h2>
        <p className="text-sm text-gray-500 dark:text-slate-400">
          Busca e moderação de comentários em todo o sistema.
        </p>
      </div>
      <div className="rounded-xl border border-gray-200 bg-white dark:bg-slate-900 dark:border-slate-800 p-2 sm:p-4">
        <CommentsTab />
      </div>
    </div>
  );
}
