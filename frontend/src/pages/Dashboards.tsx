import { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { useAuth } from "../auth/AuthContext";
import { fetchAttendanceReport, fetchStudentAttendance } from "../api/attendance";
import { fetchAdminFees, fetchStudentFees } from "../api/fees";
import { fetchAdminNotices } from "../api/notices";
import { AiNoticeComposer } from "../components/AiNoticeComposer";
import { AttendanceMarkingPanel } from "../components/AttendanceMarkingPanel";
import { DashboardNav, QuickActions, StatCard } from "../components/DashboardNav";
import { FeeRecordingPanel } from "../components/FeeRecordingPanel";
import { LanguageToggle } from "../components/LanguageToggle";
import { NoticeManager } from "../components/NoticeManager";
import { StudentAttendancePanel } from "../components/StudentAttendancePanel";
import { StudentFeesPanel } from "../components/StudentFeesPanel";
import { StudentImportPanel } from "../components/StudentImportPanel";
import { StudentMaterialsPanel } from "../components/StudentMaterialsPanel";
import { StudentNoticesPanel } from "../components/StudentNoticesPanel";
import { StudyMaterialPanel } from "../components/StudyMaterialPanel";
import { GalleryPhotoPanel } from "../components/GalleryPhotoPanel";
import { QuestionPaperWorkspace } from "../components/QuestionPaperWorkspace";

const STUDENT_SECTIONS = [
  "student-notices",
  "student-materials",
  "student-attendance",
  "student-fees",
] as const;

const ADMIN_SECTIONS = [
  "admin-students",
  "admin-attendance",
  "admin-notices",
  "admin-fees",
  "admin-materials",
  "admin-gallery",
  "admin-question-papers",
] as const;

type StudentSection = (typeof STUDENT_SECTIONS)[number];
type AdminSection = (typeof ADMIN_SECTIONS)[number];

function DashboardShell({
  titleKey,
  children,
  nav,
}: {
  titleKey: "superAdmin" | "schoolAdmin" | "student" | "coachingAdmin" | "teacher";
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

function DashboardPanel({
  sectionId,
  activeSection,
  children,
}: {
  sectionId: string;
  activeSection: string;
  children: React.ReactNode;
}) {
  if (sectionId !== activeSection) return null;

  return (
    <div
      id={`panel-${sectionId}`}
      role="tabpanel"
      aria-labelledby={`tab-${sectionId}`}
      className="dashboard-section"
    >
      {children}
    </div>
  );
}

function adminTitleKey(role: string | undefined): "schoolAdmin" | "coachingAdmin" | "teacher" {
  if (role === "coaching_admin") return "coachingAdmin";
  if (role === "teacher") return "teacher";
  return "schoolAdmin";
}

export function AdminDashboard({ papersOnly = false }: { papersOnly?: boolean }) {
  const { t } = useTranslation(["dashboard", "attendance", "notices", "fees"]);
  const { user } = useAuth();
  const isCoaching = user?.institution_type === "coaching";
  const showQuestionPapers = isCoaching && (user?.role === "coaching_admin" || user?.role === "teacher");
  const showAdminFeatures = !papersOnly && user?.role !== "teacher";
  const defaultSection: AdminSection = papersOnly || user?.role === "teacher"
    ? "admin-question-papers"
    : "admin-students";

  const [activeSection, setActiveSection] = useState<AdminSection>(defaultSection);
  const [studentCount, setStudentCount] = useState<string>(t("dashboard:statsPlaceholder"));
  const [noticeRefreshKey, setNoticeRefreshKey] = useState(0);
  const [todayAttendance, setTodayAttendance] = useState<string>(t("dashboard:statsPlaceholder"));
  const [unpaidCount, setUnpaidCount] = useState<string>(t("dashboard:statsPlaceholder"));
  const [noticeCount, setNoticeCount] = useState<string>(t("dashboard:statsPlaceholder"));

  useEffect(() => {
    if (!showAdminFeatures) return;

    void fetchAttendanceReport()
      .then((report) => setTodayAttendance(`${report.attendance_percent}%`))
      .catch(() => setTodayAttendance(t("dashboard:statsPlaceholder")));
    void fetchAdminNotices()
      .then((rows) => setNoticeCount(String(rows.length)))
      .catch(() => setNoticeCount(t("dashboard:statsPlaceholder")));
    void fetchAdminFees()
      .then((data) => setUnpaidCount(String(data.summary.pending_count)))
      .catch(() => setUnpaidCount(t("dashboard:statsPlaceholder")));
  }, [t, showAdminFeatures]);

  const bannerValue = user?.school_subdomain ?? "";

  return (
    <DashboardShell
      titleKey={adminTitleKey(user?.role)}
      nav={
        <DashboardNav
          variant={papersOnly || user?.role === "teacher" ? "teacher" : "admin"}
          activeSection={activeSection}
          onSectionChange={(id) => setActiveSection(id as AdminSection)}
          showQuestionPapers={showQuestionPapers}
        />
      }
    >
      <p className="dashboard-greeting">
        {t("dashboard:welcomeAdmin", { name: user?.name ?? "" })}
      </p>
      {user?.school_subdomain ? (
        <p className="student-profile-banner">
          {isCoaching
            ? t("dashboard:coachingBanner", { center: bannerValue })
            : t("dashboard:schoolBanner", { school: bannerValue })}
        </p>
      ) : null}

      {showAdminFeatures ? (
        <>
          <div className="stat-grid">
            <StatCard label={t("dashboard:totalStudents")} value={studentCount} />
            <StatCard label={t("attendance:todayAttendance")} value={todayAttendance} />
            <StatCard label={t("fees:unpaidCount")} value={unpaidCount} />
            <StatCard label={t("dashboard:activeNotices")} value={noticeCount} />
          </div>

          <QuickActions onSectionChange={(id) => setActiveSection(id as AdminSection)} />
        </>
      ) : null}

      {showAdminFeatures ? (
        <>
          <DashboardPanel sectionId="admin-students" activeSection={activeSection}>
            <StudentImportPanel onStudentsChange={(count) => setStudentCount(String(count))} />
          </DashboardPanel>
          <DashboardPanel sectionId="admin-attendance" activeSection={activeSection}>
            <AttendanceMarkingPanel />
          </DashboardPanel>
          <DashboardPanel sectionId="admin-notices" activeSection={activeSection}>
            <AiNoticeComposer onPosted={() => setNoticeRefreshKey((key) => key + 1)} />
            <NoticeManager
              refreshKey={noticeRefreshKey}
              onNoticesChange={(count) => setNoticeCount(String(count))}
            />
          </DashboardPanel>
          <DashboardPanel sectionId="admin-fees" activeSection={activeSection}>
            <FeeRecordingPanel onSummaryChange={(count) => setUnpaidCount(String(count))} />
          </DashboardPanel>
          <DashboardPanel sectionId="admin-materials" activeSection={activeSection}>
            <StudyMaterialPanel />
          </DashboardPanel>
          <DashboardPanel sectionId="admin-gallery" activeSection={activeSection}>
            <GalleryPhotoPanel />
          </DashboardPanel>
        </>
      ) : null}

      {showQuestionPapers ? (
        <DashboardPanel sectionId="admin-question-papers" activeSection={activeSection}>
          <QuestionPaperWorkspace canDelete={user?.role === "coaching_admin"} />
        </DashboardPanel>
      ) : null}
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

export function StudentDashboard() {
  const { t } = useTranslation(["dashboard", "attendance", "notices", "fees"]);
  const [activeSection, setActiveSection] = useState<StudentSection>(STUDENT_SECTIONS[0]);
  const [attendancePercent, setAttendancePercent] = useState<string>(t("dashboard:statsPlaceholder"));
  const [pendingFees, setPendingFees] = useState<string>(t("dashboard:statsPlaceholder"));

  useEffect(() => {
    void fetchStudentAttendance()
      .then((data) => setAttendancePercent(`${data.attendance_percent}%`))
      .catch(() => setAttendancePercent(t("dashboard:statsPlaceholder")));
    void fetchStudentFees()
      .then((data) => setPendingFees(`Rs. ${data.summary.pending_amount}`))
      .catch(() => setPendingFees(t("dashboard:statsPlaceholder")));
  }, [t]);

  return (
    <DashboardShell
      titleKey="student"
      nav={
        <DashboardNav
          variant="student"
          activeSection={activeSection}
          onSectionChange={(id) => setActiveSection(id as StudentSection)}
        />
      }
    >
      <p className="dashboard-greeting">{t("dashboard:welcomeStudent")}</p>
      <StudentProfileBanner />
      <div className="stat-grid">
        <StatCard label={t("attendance:attendancePercent")} value={attendancePercent} />
        <StatCard label={t("fees:pendingFees")} value={pendingFees} />
      </div>

      <DashboardPanel sectionId="student-notices" activeSection={activeSection}>
        <StudentNoticesPanel />
      </DashboardPanel>
      <DashboardPanel sectionId="student-materials" activeSection={activeSection}>
        <StudentMaterialsPanel />
      </DashboardPanel>
      <DashboardPanel sectionId="student-attendance" activeSection={activeSection}>
        <StudentAttendancePanel onPercentChange={setAttendancePercent} />
      </DashboardPanel>
      <DashboardPanel sectionId="student-fees" activeSection={activeSection}>
        <StudentFeesPanel onSummaryChange={setPendingFees} />
      </DashboardPanel>
    </DashboardShell>
  );
}
