import { render, screen } from "@testing-library/react";
import { I18nextProvider } from "react-i18next";
import { MemoryRouter } from "react-router-dom";
import { beforeEach, describe, expect, it, vi } from "vitest";
import i18n from "../i18n";
import type { User } from "../types/user";
import { StudentDashboard } from "./Dashboards";

const studentUser: User = {
  id: 1,
  email: "rahul@greenvalley.test",
  name: "Rahul Kumar",
  role: "student",
  language_preference: "en",
  school_id: 1,
  school_subdomain: "greenvalley",
  class_name: "10",
  section: "A",
  roll_number: "101",
};

vi.mock("../auth/AuthContext", () => ({
  useAuth: () => ({
    user: studentUser,
    isLoading: false,
    login: vi.fn(),
    logout: vi.fn(),
  }),
}));

vi.mock("../api/attendance", () => ({
  fetchStudentAttendance: vi.fn().mockResolvedValue({
    attendance_percent: 85,
    records: [{ date: "2026-06-01", status: "present" }],
  }),
  fetchAttendanceReport: vi.fn(),
}));

vi.mock("../api/fees", () => ({
  fetchStudentFees: vi.fn().mockResolvedValue({
    fee_records: [
      {
        id: 1,
        fee_type: "tuition",
        amount: 5000,
        due_date: "2026-06-15",
        paid_on: null,
        status: "pending",
        receipt_number: null,
      },
    ],
    summary: { pending_amount: 5000, paid_amount: 0 },
  }),
}));

vi.mock("../api/notices", () => ({
  fetchSchoolNotices: vi.fn().mockResolvedValue([
    { id: 1, title: "Holiday", body: "School closed Monday.", published_at: "2026-06-01T00:00:00Z" },
  ]),
}));

vi.mock("../api/studyMaterials", () => ({
  fetchStudentStudyMaterials: vi.fn().mockResolvedValue([
    {
      id: 1,
      title: "Math Notes",
      subject: "Mathematics",
      byte_size: 2048,
      download_url: "https://example.com/math.pdf",
    },
  ]),
}));

function renderStudentDashboard() {
  return render(
    <MemoryRouter>
      <I18nextProvider i18n={i18n}>
        <StudentDashboard />
      </I18nextProvider>
    </MemoryRouter>
  );
}

describe("StudentDashboard", () => {
  beforeEach(async () => {
    await i18n.changeLanguage("en");
  });

  it("renders all four student sections with live data", async () => {
    renderStudentDashboard();

    expect(await screen.findByText("Holiday")).toBeInTheDocument();
    expect(await screen.findByText("Math Notes")).toBeInTheDocument();
    expect((await screen.findAllByText(/85%/)).length).toBeGreaterThan(0);
    expect((await screen.findAllByText(/Rs\. 5000/)).length).toBeGreaterThan(0);
  });

  it("shows class and roll profile banner", async () => {
    renderStudentDashboard();

    expect(await screen.findByText(/Class 10 · Section A/)).toBeInTheDocument();
    expect(screen.getByText(/Roll no\. 101/)).toBeInTheDocument();
  });

  it("exposes scroll targets for nav sections", () => {
    renderStudentDashboard();

    expect(document.getElementById("student-notices")).toBeTruthy();
    expect(document.getElementById("student-materials")).toBeTruthy();
    expect(document.getElementById("student-attendance")).toBeTruthy();
    expect(document.getElementById("student-fees")).toBeTruthy();
  });
});
