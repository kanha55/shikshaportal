import { useTranslation } from "react-i18next";

type NavItem = {
  key: string;
  labelKey: string;
};

const adminNavItems: NavItem[] = [
  { key: "students", labelKey: "nav:students" },
  { key: "attendance", labelKey: "nav:attendance" },
  { key: "notices", labelKey: "nav:notices" },
  { key: "fees", labelKey: "nav:fees" },
  { key: "reports", labelKey: "nav:reports" },
];

const studentNavItems: NavItem[] = [
  { key: "notices", labelKey: "nav:notices" },
  { key: "materials", labelKey: "nav:materials" },
  { key: "attendance", labelKey: "nav:myAttendance" },
  { key: "fees", labelKey: "nav:myFees" },
];

export function DashboardNav({ variant }: { variant: "admin" | "student" }) {
  const { t } = useTranslation(["nav", "dashboard"]);
  const items = variant === "admin" ? adminNavItems : studentNavItems;

  return (
    <nav className="dashboard-nav" aria-label={t("dashboard:menu")}>
      <ul className="dashboard-nav-list">
        {items.map((item) => (
          <li key={item.key}>
            <span className="dashboard-nav-item">{t(item.labelKey)}</span>
          </li>
        ))}
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
