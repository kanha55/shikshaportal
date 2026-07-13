import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import { AuthProvider } from "./auth/AuthContext";
import { ProtectedRoute } from "./auth/ProtectedRoute";
import { LocaleBootstrap } from "./components/LocaleBootstrap";
import { LoginPage } from "./pages/LoginPage";
import { PublicSchoolPage } from "./pages/PublicSchoolPage";
import { AdminDashboard, StudentDashboard, SuperAdminDashboard } from "./pages/Dashboards";

export default function App() {
  return (
    <AuthProvider>
      <LocaleBootstrap />
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route
            path="/super-admin"
            element={
              <ProtectedRoute roles={["super_admin"]}>
                <SuperAdminDashboard />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin"
            element={
              <ProtectedRoute roles={["school_admin", "coaching_admin"]}>
                <AdminDashboard />
              </ProtectedRoute>
            }
          />
          <Route
            path="/teacher"
            element={
              <ProtectedRoute roles={["teacher"]}>
                <AdminDashboard papersOnly />
              </ProtectedRoute>
            }
          />
          <Route
            path="/coaching-admin"
            element={<Navigate to="/admin" replace />}
          />
          <Route
            path="/student"
            element={
              <ProtectedRoute roles={["student"]}>
                <StudentDashboard />
              </ProtectedRoute>
            }
          />
          <Route path="/" element={<PublicSchoolPage />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}
