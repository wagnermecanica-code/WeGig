import {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import { onAuthStateChanged, signOut, type User } from 'firebase/auth';
import { doc, getDoc, Timestamp } from 'firebase/firestore';
import { auth, db } from '../firebase/client';
import {
  hasPermission,
  type AdminRole,
  type AdminUser,
  type Permission,
} from './roles';

interface AuthState {
  user: User | null;
  admin: AdminUser | null;
  loading: boolean;
  isAdmin: boolean;
  hasPermission: (permission: Permission) => boolean;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthState | null>(null);

const VALID_ROLES: AdminRole[] = ['superadmin', 'admin', 'moderator', 'support', 'analytics'];

function normalizeRole(value: unknown): AdminRole {
  // Default conservador: documentos admins criados sem 'role' são tratados como 'admin'
  if (typeof value === 'string' && (VALID_ROLES as string[]).includes(value)) {
    return value as AdminRole;
  }
  return 'admin';
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [admin, setAdmin] = useState<AdminUser | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    return onAuthStateChanged(auth, async (firebaseUser) => {
      setLoading(true);
      if (!firebaseUser) {
        setUser(null);
        setAdmin(null);
        setLoading(false);
        return;
      }
      try {
        const snap = await getDoc(doc(db, 'admins', firebaseUser.uid));
        if (snap.exists()) {
          const data = snap.data();
          const createdAtRaw = data.createdAt;
          const createdAt =
            createdAtRaw instanceof Timestamp ? createdAtRaw.toDate() : undefined;
          setAdmin({
            uid: firebaseUser.uid,
            email: firebaseUser.email,
            displayName: firebaseUser.displayName,
            role: normalizeRole(data.role),
            createdAt,
          });
        } else {
          setAdmin(null);
        }
      } catch {
        setAdmin(null);
      }
      setUser(firebaseUser);
      setLoading(false);
    });
  }, []);

  const value = useMemo<AuthState>(
    () => ({
      user,
      admin,
      loading,
      isAdmin: admin !== null,
      hasPermission: (permission: Permission) =>
        admin ? hasPermission(admin.role, permission) : false,
      signOut: () => signOut(auth),
    }),
    [user, admin, loading],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthState {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within <AuthProvider>');
  return ctx;
}
