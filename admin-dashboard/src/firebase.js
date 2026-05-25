// Re-exporta o cliente Firebase unificado (TypeScript) para compatibilidade
// com componentes JSX legados que ainda importam de "../firebase".
import { signInWithEmailAndPassword } from "firebase/auth";
import { auth, db, firebaseApp, functions } from "./core/firebase/client";

export { auth, db, firebaseApp, functions };

export const signInAsAdmin = async (email, password) => {
  try {
    const userCredential = await signInWithEmailAndPassword(auth, email, password);
    return userCredential.user;
  } catch (error) {
    throw error;
  }
};
