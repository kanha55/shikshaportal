import { useState, type FormEvent } from "react";
import { useTranslation } from "react-i18next";
import { Navigate, useLocation, useNavigate } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";
import { dashboardPathForRole } from "../lib/config";

export function LoginPage() {
  const { t } = useTranslation(["auth", "common"]);
  const { user, login } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  if (user) {
    const redirect = (location.state as { from?: string } | null)?.from;
    return <Navigate to={redirect ?? dashboardPathForRole(user.role)} replace />;
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError(null);
    setSubmitting(true);

    try {
      const path = await login(email, password);
      const redirect = (location.state as { from?: string } | null)?.from;
      navigate(redirect ?? path, { replace: true });
    } catch {
      setError(t("auth:invalidCredentials"));
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="page-center">
      <form className="card login-card" onSubmit={handleSubmit}>
        <h1>{t("common:appName")}</h1>
        <p className="muted">{t("auth:signInSubtitle")}</p>

        {error && <p className="error">{error}</p>}

        <label>
          {t("auth:email")}
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            autoComplete="username"
            required
          />
        </label>

        <label>
          {t("auth:password")}
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            autoComplete="current-password"
            required
          />
        </label>

        <button type="submit" disabled={submitting}>
          {submitting ? t("auth:signingIn") : t("auth:signIn")}
        </button>
      </form>
    </div>
  );
}
