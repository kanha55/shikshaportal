export type AttendanceStatus = "present" | "absent" | "leave";

export type AttendanceStudentRow = {
  student_id: number;
  name: string;
  roll_number: string;
  status: AttendanceStatus | null;
};

export type AttendanceSheet = {
  date: string;
  class_name: string;
  section: string;
  students: AttendanceStudentRow[];
  summary: {
    total: number;
    marked: number;
    present: number;
    absent: number;
    unmarked: number;
  };
};

export type AttendanceReport = {
  date: string;
  class_name: string | null;
  section: string | null;
  total_students: number;
  marked: number;
  present: number;
  absent: number;
  attendance_percent: number;
};

export type StudentAttendanceSummary = {
  attendance_percent: number;
  records: Array<{ date: string; status: AttendanceStatus }>;
};
