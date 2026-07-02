import { render, screen } from "@testing-library/react";
import { I18nextProvider } from "react-i18next";
import { MemoryRouter } from "react-router-dom";
import { beforeEach, describe, expect, it, vi } from "vitest";
import i18n from "../i18n";
import type { User } from "../types/user";
import { AdminDashboard } from "./Dashboards";

const adminUser: User = {
  id: 2,
  email: "admin@greenvalley.test",
  name: "Priya Sharma",
  role: "school_admin",
  language_preference: "en",
  school_id: 1,
  school_subdomain: "greenvalley",
};

vi.mock("../auth/AuthContext", () => ({
  useAuth: () => ({
    user: adminUser,
    isLoading: false,
    login: vi.fn(),
    logout: vi.fn(),
  }),
}));

vi.mock("../api/students", () => ({
  fetchStudents: vi.fn().mockResolvedValue([
    {
      id: 1,
      name: "Rahul Kumar",
      roll_number: "101",
      class_name: "10",
      section: "A",
      parent_phone: "9876543210",
      email: "rahul@greenvalley.test",
    },
  ]),
  createStudent: vi.fn(),
  importStudents: vi.fn(),
}));

vi.mock("../api/attendance", () => ({
  fetchAttendanceReport: vi.fn().mockResolvedValue({ attendance_percent: 92 }),
  fetchAttendanceSheet: vi.fn().mockResolvedValue({
    students: [{ student_id: 1, name: "Rahul Kumar", roll_number: "101", status: null }],
    summary: { present: 0, absent: 0, unmarked: 1 },
  }),
  saveAttendance: vi.fn(),
}));

vi.mock("../api/notices", () => ({
  fetchAdminNotices: vi.fn().mockResolvedValue([
    { id: 1, title: "PTM Notice", body: "Parent meeting Friday.", published_at: "2026-06-01T00:00:00Z" },
  ]),
  createNotice: vi.fn(),
  updateNotice: vi.fn(),
  deleteNotice: vi.fn(),
}));

vi.mock("../api/fees", () => ({
  fetchAdminFees: vi.fn().mockResolvedValue({
    fee_records: [
      {
        id: 1,
        student_id: 1,
        student_name: "Rahul Kumar",
        fee_type: "tuition",
        amount: 5000,
        due_date: "2026-06-15",
        paid_on: null,
        status: "pending",
        receipt_number: null,
      },
    ],
    summary: { pending_count: 3, pending_amount: 15000 },
  }),
  createFeeRecord: vi.fn(),
  downloadFeeReceipt: vi.fn(),
}));

vi.mock("../api/studyMaterials", () => ({
  fetchAdminStudyMaterials: vi.fn().mockResolvedValue([
    {
      id: 1,
      title: "Science Notes",
      class_name: "10",
      subject: "Science",
      byte_size: 4096,
      download_url: "https://example.com/science.pdf",
    },
  ]),
  uploadStudyMaterial: vi.fn(),
  deleteStudyMaterial: vi.fn(),
}));

vi.mock("../api/ai", () => ({
  generateAiNotice: vi.fn(),
}));

function renderAdminDashboard() {
  return render(
    <MemoryRouter>
      <I18nextProvider i18n={i18n}>
        <AdminDashboard />
      </I18nextProvider>
    </MemoryRouter>
  );
}

describe("AdminDashboard", () => {
  beforeEach(async () => {
    await i18n.changeLanguage("en");
  });

  it("renders stats, greeting, and all five admin sections with live data", async () => {
    renderAdminDashboard();

    expect(await screen.findByText(/Welcome back, Priya Sharma/)).toBeInTheDocument();
    expect(screen.getByText(/School: greenvalley/)).toBeInTheDocument();
    expect(await screen.findAllByText("1")).toHaveLength(2);
    expect(await screen.findAllByText(/92%/)).toHaveLength(1);
    expect(await screen.findByText("3")).toBeInTheDocument();
    expect(await screen.findByText("PTM Notice")).toBeInTheDocument();
    expect(await screen.findByText("Science Notes")).toBeInTheDocument();
  });

  it("shows quick action shortcuts", () => {
    renderAdminDashboard();

    const quickActions = document.querySelector(".quick-actions");
    expect(quickActions).toBeTruthy();
    expect(quickActions?.querySelector('[class*="quick-action-btn"]')).toBeTruthy();
    expect(screen.getByRole("heading", { name: "Quick actions" })).toBeInTheDocument();
    expect(screen.getAllByRole("button", { name: "Add student" }).length).toBeGreaterThan(0);
    expect(screen.getAllByRole("button", { name: "Mark attendance" }).length).toBeGreaterThan(0);
    expect(screen.getAllByRole("button", { name: "Post notice" }).length).toBeGreaterThan(0);
    expect(screen.getAllByRole("button", { name: "Record fee" }).length).toBeGreaterThan(0);
  });

  it("exposes scroll targets for nav sections", () => {
    renderAdminDashboard();

    expect(document.getElementById("admin-students")).toBeTruthy();
    expect(document.getElementById("admin-attendance")).toBeTruthy();
    expect(document.getElementById("admin-notices")).toBeTruthy();
    expect(document.getElementById("admin-fees")).toBeTruthy();
    expect(document.getElementById("admin-materials")).toBeTruthy();
  });
});
