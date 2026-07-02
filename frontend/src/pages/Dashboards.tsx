import { useState } from "react";
import { useTranslation } from "react-i18next";
import { useAuth } from "../auth/AuthContext";
import { AiNoticeComposer } from "../components/AiNoticeComposer";
import { DashboardNav, StatCard } from "../components/DashboardNav";
import { LanguageToggle } from "../components/LanguageToggle";
import { NoticeManager } from "../components/NoticeManager";
import { StudentImportPanel } from "../components/StudentImportPanel";
import { StudentMaterialsPanel } from "../components/StudentMaterialsPanel";
import { StudentNoticesPanel } from "../components/StudentNoticesPanel";
import { StudyMaterialPanel } from "../components/StudyMaterialPanel";

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
        <div className="dashboard-header-actions">
          <LanguageToggle />
          <button type="button" onClick={() => logout()}>
            {t("common:logOut")}
          </button>
        </div>
      </header>
      {nav}
      <main>
        <div className="content-wrap">{children ?? <p>{t("dashboard:comingSoon")}</p>}</div>
      </main>
    </div>
  );
}

export function SuperAdminDashboard() {
  return <DashboardShell titleKey="superAdmin" />;
}

export function AdminDashboard() {
  const { t } = useTranslation(["dashboard", "attendance", "notices", "fees"]);
  const [studentCount, setStudentCount] = useState<string>(t("dashboard:statsPlaceholder"));
  const [noticeRefreshKey, setNoticeRefreshKey] = useState(0);

  return (
    <DashboardShell titleKey="schoolAdmin" nav={<DashboardNav variant="admin" />}>
      <div className="stat-grid">
        <StatCard label={t("dashboard:totalStudents")} value={studentCount} />
        <StatCard label={t("attendance:todayAttendance")} value={t("dashboard:statsPlaceholder")} />
        <StatCard label={t("fees:unpaidCount")} value={t("dashboard:statsPlaceholder")} />
      </div>

      <AiNoticeComposer onPosted={() => setNoticeRefreshKey((key) => key + 1)} />
      <StudentImportPanel onStudentsChange={(count) => setStudentCount(String(count))} />
      <NoticeManager refreshKey={noticeRefreshKey} />
      <StudyMaterialPanel />
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
      <StudentNoticesPanel />
      <StudentMaterialsPanel />
    </DashboardShell>
  );
}
