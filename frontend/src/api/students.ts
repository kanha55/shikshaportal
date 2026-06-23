import { apiClient } from "./client";
import type { StudentImportResult, StudentRecord } from "../types/student";

export async function fetchStudents(): Promise<StudentRecord[]> {
  const response = await apiClient.get<{ students: StudentRecord[] }>("/admin/students");
  return response.data.students;
}

export async function importStudents(file: File): Promise<StudentImportResult> {
  const formData = new FormData();
  formData.append("file", file);

  const response = await apiClient.post<StudentImportResult>(
    "/admin/students/import",
    formData,
    { headers: { "Content-Type": "multipart/form-data" } }
  );

  return response.data;
}
