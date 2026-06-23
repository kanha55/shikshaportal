import { useAuth } from "../auth/AuthContext";

function DashboardShell({ title, children }: { title: string; children?: React.ReactNode }) {
  const { user, logout } = useAuth();

  return (
    <div className="dashboard">
      <header className="dashboard-header">
        <div>
          <h1>{title}</h1>
          <p className="muted">
            {user?.name} · {user?.email}
            {user?.school_subdomain ? ` · ${user.school_subdomain}` : ""}
          </p>
        </div>
        <button type="button" onClick={() => logout()}>
          Log out
        </button>
      </header>
      <main>{children ?? <p>Dashboard coming in upcoming sprints.</p>}</main>
    </div>
  );
}

export function SuperAdminDashboard() {
  return <DashboardShell title="Super Admin" />;
}

export function AdminDashboard() {
  return <DashboardShell title="School Admin" />;
}

export function StudentDashboard() {
  return <DashboardShell title="Student" />;
}
