import { useEffect, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { Search, Filter } from 'lucide-react';
import { Card, CardBody } from '@shared/components/ui/Card';
import { Badge } from '@shared/components/ui/Badge';
import { Skeleton } from '@shared/components/ui/Skeleton';
import { listProfiles, type ProfileSummary } from '../data/usersService';

const TYPE_OPTIONS = ['', 'musico', 'banda', 'produtor', 'casa_de_show', 'fa'];

export function UsersListPage() {
  const [items, setItems] = useState<ProfileSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [term, setTerm] = useState('');
  const [type, setType] = useState('');
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    setLoading(true);
    listProfiles({ profileType: type || undefined, pageSize: 100 })
      .then((rows) => {
        if (!active) return;
        setItems(rows);
        setError(null);
      })
      .catch((err) => {
        if (!active) return;
        setError(err instanceof Error ? err.message : 'Erro ao listar perfis');
      })
      .finally(() => active && setLoading(false));
    return () => {
      active = false;
    };
  }, [type]);

  const filtered = useMemo(() => {
    const q = term.trim().toLowerCase();
    if (!q) return items;
    return items.filter(
      (p) =>
        p.name.toLowerCase().includes(q) ||
        (p.city ?? '').toLowerCase().includes(q) ||
        p.id.toLowerCase().includes(q),
    );
  }, [term, items]);

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-xl font-semibold tracking-tight dark:text-white">Gestão de Usuários</h2>
        <p className="text-sm text-gray-500 dark:text-slate-400">
          Busca, filtros e ações administrativas sobre perfis.
        </p>
      </div>

      <Card>
        <CardBody className="flex flex-col sm:flex-row gap-3">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
            <input
              placeholder="Buscar por nome, cidade ou ID…"
              value={term}
              onChange={(e) => setTerm(e.target.value)}
              className="w-full pl-9 h-10 rounded-lg border border-gray-300 bg-white text-sm focus:outline-none focus:ring-2 focus:ring-primary dark:bg-slate-800 dark:border-slate-700 dark:text-slate-100"
            />
          </div>
          <div className="relative">
            <Filter className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400 pointer-events-none" />
            <select
              value={type}
              onChange={(e) => setType(e.target.value)}
              className="pl-9 pr-3 h-10 rounded-lg border border-gray-300 bg-white text-sm focus:outline-none focus:ring-2 focus:ring-primary dark:bg-slate-800 dark:border-slate-700 dark:text-slate-100"
            >
              {TYPE_OPTIONS.map((opt) => (
                <option key={opt} value={opt}>
                  {opt === '' ? 'Todos os tipos' : opt}
                </option>
              ))}
            </select>
          </div>
        </CardBody>
      </Card>

      {error ? (
        <div className="rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-700">{error}</div>
      ) : null}

      <Card>
        <div className="overflow-x-auto">
          <table className="min-w-full text-sm">
            <thead className="bg-gray-50 dark:bg-slate-800/50 text-xs uppercase tracking-wider text-gray-500 dark:text-slate-400">
              <tr>
                <th className="px-4 py-3 text-left">Nome</th>
                <th className="px-4 py-3 text-left">Tipo</th>
                <th className="px-4 py-3 text-left">Cidade</th>
                <th className="px-4 py-3 text-left">Status</th>
                <th className="px-4 py-3 text-left">ID</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 dark:divide-slate-800">
              {loading ? (
                Array.from({ length: 6 }).map((_, i) => (
                  <tr key={i}>
                    <td colSpan={5} className="px-4 py-3">
                      <Skeleton className="h-5 w-full" />
                    </td>
                  </tr>
                ))
              ) : filtered.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-4 py-10 text-center text-gray-500 dark:text-slate-400">
                    Nenhum perfil encontrado.
                  </td>
                </tr>
              ) : (
                filtered.map((p) => (
                  <tr key={p.id} className="hover:bg-gray-50 dark:hover:bg-slate-800/50">
                    <td className="px-4 py-3">
                      <Link
                        to={`/users/${p.id}`}
                        className="font-medium text-primary hover:underline dark:text-white"
                      >
                        {p.name}
                      </Link>
                    </td>
                    <td className="px-4 py-3 text-gray-600 dark:text-slate-300">{p.profileType ?? '—'}</td>
                    <td className="px-4 py-3 text-gray-600 dark:text-slate-300">{p.city ?? '—'}</td>
                    <td className="px-4 py-3">
                      {p.banned ? (
                        <Badge tone="danger">Banido</Badge>
                      ) : (
                        <Badge tone="success">Ativo</Badge>
                      )}
                    </td>
                    <td className="px-4 py-3 font-mono text-[10px] text-gray-400">{p.id}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </Card>
    </div>
  );
}
