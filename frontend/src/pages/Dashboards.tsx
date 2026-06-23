import { useTranslation } from "react-i18next";
import { useAuth } from "../auth/AuthContext";

function DashboardShell({
  titleKey,
  children,
}: {
  titleKey: "superAdmin" | "schoolAdmin" | "student";
  children?: React.ReactNode;
}) {
  const { t } = useTranslation(["dashboard", "common"]);
  const { user, logout } = useAuth();

  return (
    <div className="dashboard">
      <header className="dashboard-header">
        <div>
          <h1>{t(`dashboard:${titleKey}`)}</h1>
          <p className="muted">
            {user?.name} · {user?.email}
            {user?.school_subdomain ? ` · ${user.school_subdomain}` : ""}
          </p>
        </div>
        <button type="button" onClick={() => logout()}>
          {t("common:logOut")}
        </button>
      </header>
      <main>{children ?? <p>{t("dashboard:comingSoon")}</p>}</main>
    </div>
  );
}

export function SuperAdminDashboard() {
  return <DashboardShell titleKey="superAdmin" />;
}

export function AdminDashboard() {
  return <DashboardShell titleKey="schoolAdmin" />;
}

export function StudentDashboard() {
  return <DashboardShell titleKey="student" />;
}
