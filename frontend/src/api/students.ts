import { apiClient } from "./client";
import type {
  StudentCreateResult,
  StudentImportResult,
  StudentInput,
  StudentRecord,
} from "../types/student";

const IMPORT_POLL_INTERVAL_MS = 500;
const IMPORT_POLL_MAX_ATTEMPTS = 120;

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export async function fetchStudents(): Promise<StudentRecord[]> {
  const response = await apiClient.get<{ students: StudentRecord[] }>("/admin/students");
  return response.data.students;
}

export async function createStudent(input: StudentInput): Promise<StudentCreateResult> {
  const response = await apiClient.post<StudentCreateResult>("/admin/students", { student: input });
  return response.data;
}

async function pollImportStatus(importId: number): Promise<StudentImportResult> {
  for (let attempt = 0; attempt < IMPORT_POLL_MAX_ATTEMPTS; attempt += 1) {
    const response = await apiClient.get<StudentImportResult>(
      `/admin/students/imports/${importId}`
    );
    const result = response.data;

    if (result.status === "completed" || result.status === "failed") {
      return result;
    }

    await sleep(IMPORT_POLL_INTERVAL_MS);
  }

  throw new Error("Import timed out");
}

export async function importStudents(file: File): Promise<StudentImportResult> {
  const formData = new FormData();
  formData.append("file", file);

  const queued = await apiClient.post<{ import_id: number; status: string }>(
    "/admin/students/import",
    formData,
    { headers: { "Content-Type": "multipart/form-data" } }
  );

  const result = await pollImportStatus(queued.data.import_id);

  if (result.status === "failed") {
    throw new Error(result.error_message ?? "Import failed");
  }

  return {
    ...result,
    created_count: result.created_count ?? 0,
    emails_sent: result.emails_sent ?? 0,
    errors: result.errors ?? [],
    created: result.created ?? [],
  };
}
