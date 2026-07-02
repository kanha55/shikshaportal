import { useTranslation } from "react-i18next";

type NavItem = {
  key: string;
  labelKey: string;
  sectionId?: string;
};

const adminNavItems: NavItem[] = [
  { key: "students", labelKey: "nav:students", sectionId: "admin-students" },
  { key: "attendance", labelKey: "nav:attendance", sectionId: "admin-attendance" },
  { key: "notices", labelKey: "nav:notices", sectionId: "admin-notices" },
  { key: "fees", labelKey: "nav:fees", sectionId: "admin-fees" },
  { key: "materials", labelKey: "nav:materials", sectionId: "admin-materials" },
];

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

function scrollToSection(sectionId: string) {
  document.getElementById(sectionId)?.scrollIntoView({ behavior: "smooth", block: "start" });
}

export function DashboardNav({
  variant,
  activeSection,
}: {
  variant: "admin" | "student";
  activeSection?: string;
}) {
  const { t } = useTranslation(["nav", "dashboard"]);
  const items = variant === "admin" ? adminNavItems : studentNavItems;

  return (
    <nav className="dashboard-nav" aria-label={t("dashboard:menu")}>
      <ul className="dashboard-nav-list">
        {items.map((item) => {
          const isActive = item.sectionId != null && item.sectionId === activeSection;

          if (item.sectionId) {
            return (
              <li key={item.key}>
                <button
                  type="button"
                  className={`dashboard-nav-item${isActive ? " is-active" : ""}`}
                  onClick={() => scrollToSection(item.sectionId!)}
                  aria-current={isActive ? "true" : undefined}
                >
                  {t(item.labelKey)}
                </button>
              </li>
            );
          }

          return (
            <li key={item.key}>
              <span className="dashboard-nav-item">{t(item.labelKey)}</span>
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

export function QuickActions() {
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
            onClick={() => scrollToSection(action.sectionId)}
          >
            {t(action.labelKey.replace("dashboard:", ""))}
          </button>
        ))}
      </div>
    </div>
  );
}
