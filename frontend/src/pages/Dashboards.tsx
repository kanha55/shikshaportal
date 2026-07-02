import { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { useAuth } from "../auth/AuthContext";
import { fetchAttendanceReport } from "../api/attendance";
import { AiNoticeComposer } from "../components/AiNoticeComposer";
import { AttendanceMarkingPanel } from "../components/AttendanceMarkingPanel";
import { DashboardNav, StatCard } from "../components/DashboardNav";
import { FeeRecordingPanel } from "../components/FeeRecordingPanel";
import { LanguageToggle } from "../components/LanguageToggle";
import { NoticeManager } from "../components/NoticeManager";
import { StudentAttendancePanel } from "../components/StudentAttendancePanel";
import { StudentFeesPanel } from "../components/StudentFeesPanel";
import { StudentImportPanel } from "../components/StudentImportPanel";
import { StudentMaterialsPanel } from "../components/StudentMaterialsPanel";
import { StudentNoticesPanel } from "../components/StudentNoticesPanel";
import { StudyMaterialPanel } from "../components/StudyMaterialPanel";

const STUDENT_SECTIONS = [
  "student-notices",
  "student-materials",
  "student-attendance",
  "student-fees",
] as const;

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
  const [todayAttendance, setTodayAttendance] = useState<string>(t("dashboard:statsPlaceholder"));
  const [unpaidCount, setUnpaidCount] = useState<string>(t("dashboard:statsPlaceholder"));

  useEffect(() => {
    void fetchAttendanceReport()
      .then((report) => setTodayAttendance(`${report.attendance_percent}%`))
      .catch(() => setTodayAttendance(t("dashboard:statsPlaceholder")));
  }, [t]);

  return (
    <DashboardShell titleKey="schoolAdmin" nav={<DashboardNav variant="admin" />}>
      <div className="stat-grid">
        <StatCard label={t("dashboard:totalStudents")} value={studentCount} />
        <StatCard label={t("attendance:todayAttendance")} value={todayAttendance} />
        <StatCard label={t("fees:unpaidCount")} value={unpaidCount} />
      </div>

      <AiNoticeComposer onPosted={() => setNoticeRefreshKey((key) => key + 1)} />
      <StudentImportPanel onStudentsChange={(count) => setStudentCount(String(count))} />
      <AttendanceMarkingPanel />
      <FeeRecordingPanel onSummaryChange={(count) => setUnpaidCount(String(count))} />
      <NoticeManager refreshKey={noticeRefreshKey} />
      <StudyMaterialPanel />
    </DashboardShell>
  );
}

function StudentProfileBanner() {
  const { t } = useTranslation("dashboard");
  const { user } = useAuth();

  if (!user?.class_name || !user.section) return null;

  return (
    <p className="student-profile-banner">
      {t("classSection", { class: user.class_name, section: user.section })}
      {user.roll_number ? ` · ${t("rollNumber", { roll: user.roll_number })}` : ""}
    </p>
  );
}

function useActiveSection(sectionIds: readonly string[]) {
  const [activeSection, setActiveSection] = useState(sectionIds[0]);

  useEffect(() => {
    const elements = sectionIds
      .map((id) => document.getElementById(id))
      .filter((el): el is HTMLElement => el != null);

    if (elements.length === 0) return;

    const observer = new IntersectionObserver(
      (entries) => {
        const visible = entries
          .filter((entry) => entry.isIntersecting)
          .sort((a, b) => b.intersectionRatio - a.intersectionRatio);

        if (visible[0]?.target.id) {
          setActiveSection(visible[0].target.id);
        }
      },
      { rootMargin: "-20% 0px -55% 0px", threshold: [0, 0.25, 0.5, 0.75, 1] }
    );

    elements.forEach((el) => observer.observe(el));
    return () => observer.disconnect();
  }, [sectionIds]);

  return activeSection;
}

export function StudentDashboard() {
  const { t } = useTranslation(["dashboard", "attendance", "notices", "fees"]);
  const [attendancePercent, setAttendancePercent] = useState<string>(t("dashboard:statsPlaceholder"));
  const [pendingFees, setPendingFees] = useState<string>(t("dashboard:statsPlaceholder"));
  const activeSection = useActiveSection(STUDENT_SECTIONS);

  return (
    <DashboardShell
      titleKey="student"
      nav={<DashboardNav variant="student" activeSection={activeSection} />}
    >
      <p className="dashboard-greeting">{t("dashboard:welcomeStudent")}</p>
      <StudentProfileBanner />
      <div className="stat-grid">
        <StatCard label={t("attendance:attendancePercent")} value={attendancePercent} />
        <StatCard label={t("fees:pendingFees")} value={pendingFees} />
      </div>

      <div id="student-notices" className="dashboard-section">
        <StudentNoticesPanel />
      </div>
      <div id="student-materials" className="dashboard-section">
        <StudentMaterialsPanel />
      </div>
      <div id="student-attendance" className="dashboard-section">
        <StudentAttendancePanel onPercentChange={setAttendancePercent} />
      </div>
      <div id="student-fees" className="dashboard-section">
        <StudentFeesPanel onSummaryChange={setPendingFees} />
      </div>
    </DashboardShell>
  );
}
