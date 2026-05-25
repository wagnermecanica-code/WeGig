import { type FormEvent, useState } from "react";
import { signInWithEmailAndPassword } from "firebase/auth";
import { useLocation, useNavigate } from "react-router-dom";
import { Shield } from "lucide-react";
import { auth } from "@core/firebase/client";
import { useAuth } from "@core/auth/AuthProvider";
import { Button } from "@shared/components/ui/Button";

export function LoginPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const { isAdmin, loading } = useAuth();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  if (!loading && isAdmin) {
    const from =
      (location.state as { from?: string } | null)?.from ?? "/dashboard";
    navigate(from, { replace: true });
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError(null);
    setSubmitting(true);
    try {
      await signInWithEmailAndPassword(auth, email.trim(), password);
    } catch (err) {
      const message =
        err instanceof Error ? err.message : "Erro ao fazer login";
      setError(message);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-slate-100 to-slate-200 dark:from-slate-950 dark:to-slate-900 p-4">
      <div className="w-full max-w-md rounded-2xl bg-white shadow-xl border border-gray-100 dark:bg-slate-900 dark:border-slate-800 p-8">
        <div className="flex flex-col items-center gap-2 mb-6">
          <div className="h-12 w-12 rounded-xl bg-primary flex items-center justify-center text-white">
            <Shield className="h-6 w-6" />
          </div>
          <h1 className="text-lg font-semibold dark:text-white">WeGig Admin</h1>
          <p className="text-xs text-gray-500 dark:text-slate-400">
            Acesso restrito
          </p>
        </div>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label
              htmlFor="email"
              className="block text-xs font-medium text-gray-600 dark:text-slate-300 mb-1"
            >
              E-mail
            </label>
            <input
              id="email"
              type="email"
              autoComplete="username"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full h-10 px-3 rounded-lg border border-gray-300 bg-white text-sm focus:outline-none focus:ring-2 focus:ring-primary dark:bg-slate-800 dark:border-slate-700 dark:text-slate-100"
            />
          </div>
          <div>
            <label
              htmlFor="password"
              className="block text-xs font-medium text-gray-600 dark:text-slate-300 mb-1"
            >
              Senha
            </label>
            <input
              id="password"
              type="password"
              autoComplete="current-password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full h-10 px-3 rounded-lg border border-gray-300 bg-white text-sm focus:outline-none focus:ring-2 focus:ring-primary dark:bg-slate-800 dark:border-slate-700 dark:text-slate-100"
            />
          </div>
          {error ? <p className="text-xs text-red-600">{error}</p> : null}
          <Button type="submit" className="w-full" disabled={submitting}>
            {submitting ? "Entrando…" : "Entrar"}
          </Button>
        </form>
      </div>
    </div>
  );
}
