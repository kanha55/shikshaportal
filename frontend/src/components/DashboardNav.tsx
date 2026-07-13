import { useTranslation } from "react-i18next";

type NavItem = {
  key: string;
  labelKey: string;
  sectionId: string;
};

const adminNavItems: NavItem[] = [
  { key: "students", labelKey: "nav:students", sectionId: "admin-students" },
  { key: "attendance", labelKey: "nav:attendance", sectionId: "admin-attendance" },
  { key: "notices", labelKey: "nav:notices", sectionId: "admin-notices" },
  { key: "fees", labelKey: "nav:fees", sectionId: "admin-fees" },
  { key: "materials", labelKey: "nav:materials", sectionId: "admin-materials" },
  { key: "gallery", labelKey: "nav:gallery", sectionId: "admin-gallery" },
];

const questionPapersNavItem: NavItem = {
  key: "questionPapers",
  labelKey: "nav:questionPapers",
  sectionId: "admin-question-papers",
};

const teacherNavItems: NavItem[] = [questionPapersNavItem];

const adminQuickActions = [
  { labelKey: "dashboard:quickActionAddStudent", sectionId: "admin-students" },
  { labelKey: "dashboard:quickActionMarkAttendance", sectionId: "admin-attendance" },
  { labelKey: "dashboard:quickActionPostNotice", sectionId: "admin-notices" },
  { labelKey: "dashboard:quickActionRecordFee", sectionId: "admin-fees" },
] as const;

const studentNavItems: NavItem[] = [
  { key: "notices", labelKey: "nav:notices", sectionId: "student-notices" },
  { key: "materials", labelKey: "nav:materials", sectionId: "student-materials" },
  { key: "attendance", labelKey: "nav:myAttendance", sectionId: "student-attendance" },
  { key: "fees", labelKey: "nav:myFees", sectionId: "student-fees" },
];

export function DashboardNav({
  variant,
  activeSection,
  onSectionChange,
  showQuestionPapers = false,
}: {
  variant: "admin" | "student" | "teacher";
  activeSection: string;
  onSectionChange: (sectionId: string) => void;
  showQuestionPapers?: boolean;
}) {
  const { t } = useTranslation(["nav", "dashboard"]);

  let items: NavItem[];
  if (variant === "student") {
    items = studentNavItems;
  } else if (variant === "teacher") {
    items = teacherNavItems;
  } else {
    items = showQuestionPapers ? [...adminNavItems, questionPapersNavItem] : adminNavItems;
  }

  return (
    <nav className="dashboard-nav" aria-label={t("dashboard:menu")}>
      <ul className="dashboard-nav-list" role="tablist">
        {items.map((item) => {
          const isActive = item.sectionId === activeSection;

          return (
            <li key={item.key} role="presentation">
              <button
                type="button"
                role="tab"
                id={`tab-${item.sectionId}`}
                aria-selected={isActive}
                aria-controls={`panel-${item.sectionId}`}
                className={`dashboard-nav-item${isActive ? " is-active" : ""}`}
                onClick={() => onSectionChange(item.sectionId)}
              >
                {t(item.labelKey)}
              </button>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}

export function StatCard({ label, value }: { label: string; value: string }) {
  return (
    <div className="stat-card">
      <p className="stat-label">{label}</p>
      <p className="stat-value">{value}</p>
    </div>
  );
}

export function QuickActions({ onSectionChange }: { onSectionChange: (sectionId: string) => void }) {
  const { t } = useTranslation("dashboard");

  return (
    <div className="quick-actions">
      <h2 className="quick-actions-title">{t("quickActions")}</h2>
      <div className="quick-actions-grid">
        {adminQuickActions.map((action) => (
          <button
            key={action.sectionId}
            type="button"
            className="quick-action-btn"
            onClick={() => onSectionChange(action.sectionId)}
          >
            {t(action.labelKey.replace("dashboard:", ""))}
          </button>
        ))}
      </div>
    </div>
  );
}
