import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from "react";
import { configureApiClient } from "../api/client";
import {
  login as apiLogin,
  logout as apiLogout,
  fetchCurrentUser,
} from "../api/auth";
import { dashboardPathForRole } from "../lib/config";
import { applyLocale, normalizeLocale } from "../lib/locale";
import type { User } from "../types/user";

interface AuthContextValue {
  user: User | null;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<string>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

/** JWT kept in memory only (not localStorage) per T06 security requirement. */
export function AuthProvider({ children }: { children: ReactNode }) {
  const tokenRef = useRef<string | null>(null);
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const clearSession = useCallback(() => {
    tokenRef.current = null;
    setUser(null);
  }, []);

  useEffect(() => {
    configureApiClient({
      getToken: () => tokenRef.current,
      onUnauthorized: clearSession,
    });

    let active = true;
    // Restore the session from the httpOnly cookie after a page reload.
    (async () => {
      try {
        const currentUser = await fetchCurrentUser();
        if (!active) return;
        setUser(currentUser);
        await applyLocale(normalizeLocale(currentUser.language_preference));
      } catch {
        // No active session — stay logged out.
      } finally {
        if (active) setIsLoading(false);
      }
    })();

    return () => {
      active = false;
    };
  }, [clearSession]);

  const login = useCallback(async (email: string, password: string) => {
    const { user: loggedInUser, token } = await apiLogin(email, password);
    tokenRef.current = token;
    setUser(loggedInUser);
    await applyLocale(normalizeLocale(loggedInUser.language_preference));
    return dashboardPathForRole(loggedInUser.role);
  }, []);

  const logout = useCallback(async () => {
    try {
      if (tokenRef.current) {
        await apiLogout();
      }
    } finally {
      clearSession();
    }
  }, [clearSession]);

  const value = useMemo(
    () => ({ user, isLoading, login, logout }),
    [user, isLoading, login, logout]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
