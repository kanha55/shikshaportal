import { apiClient } from "./client";
import type {
  AttendanceReport,
  AttendanceSheet,
  AttendanceStatus,
  StudentAttendanceSummary,
} from "../types/attendance";

export async function fetchAttendanceSheet(
  date: string,
  class_name: string,
  section: string
): Promise<AttendanceSheet> {
  const response = await apiClient.get<AttendanceSheet>("/admin/attendance", {
    params: { date, class_name, section },
  });
  return response.data;
}

export async function saveAttendance(input: {
  date: string;
  class_name: string;
  section: string;
  records: Array<{ student_id: number; status: AttendanceStatus }>;
}): Promise<void> {
  await apiClient.post("/admin/attendance", input);
}

export async function fetchAttendanceReport(date?: string): Promise<AttendanceReport> {
  const response = await apiClient.get<AttendanceReport>("/admin/attendance/report", {
    params: date ? { date } : undefined,
  });
  return response.data;
}

export async function fetchStudentAttendance(): Promise<StudentAttendanceSummary> {
  const response = await apiClient.get<StudentAttendanceSummary>("/attendance");
  return response.data;
}
