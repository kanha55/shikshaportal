import { useTranslation } from "react-i18next";
import { useAuth } from "../auth/AuthContext";
import { DashboardNav, StatCard } from "../components/DashboardNav";

function DashboardShell({
  titleKey,
  children,
  nav,
}: {
  titleKey: "superAdmin" | "schoolAdmin" | "student";
  children?: React.ReactNode;
  nav?: React.ReactNode;
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
      {nav}
      <main>{children ?? <p>{t("dashboard:comingSoon")}</p>}</main>
    </div>
  );
}

export function SuperAdminDashboard() {
  return <DashboardShell titleKey="superAdmin" />;
}

export function AdminDashboard() {
  const { t } = useTranslation(["dashboard", "attendance", "notices", "fees"]);

  return (
    <DashboardShell titleKey="schoolAdmin" nav={<DashboardNav variant="admin" />}>
      <section className="dashboard-section">
        <h2>{t("dashboard:quickActions")}</h2>
        <div className="stat-grid">
          <StatCard label={t("dashboard:totalStudents")} value={t("dashboard:statsPlaceholder")} />
          <StatCard label={t("attendance:todayAttendance")} value={t("dashboard:statsPlaceholder")} />
          <StatCard label={t("fees:unpaidCount")} value={t("dashboard:statsPlaceholder")} />
        </div>
      </section>
      <section className="dashboard-section">
        <h2>{t("notices:recentNotices")}</h2>
        <p className="muted">{t("notices:noNoticesAdmin")}</p>
      </section>
    </DashboardShell>
  );
}

export function StudentDashboard() {
  const { t } = useTranslation(["dashboard", "attendance", "notices", "fees"]);

  return (
    <DashboardShell titleKey="student" nav={<DashboardNav variant="student" />}>
      <p className="dashboard-greeting">{t("dashboard:welcomeStudent")}</p>
      <div className="stat-grid">
        <StatCard label={t("attendance:attendancePercent")} value={t("dashboard:statsPlaceholder")} />
        <StatCard label={t("fees:pendingFees")} value={t("dashboard:statsPlaceholder")} />
      </div>
      <section className="dashboard-section">
        <h2>{t("dashboard:myNotices")}</h2>
        <p className="muted">{t("notices:noNoticesAdmin")}</p>
      </section>
      <section className="dashboard-section">
        <h2>{t("dashboard:classMaterials")}</h2>
        <p className="muted">{t("dashboard:comingSoon")}</p>
      </section>
    </DashboardShell>
  );
}
