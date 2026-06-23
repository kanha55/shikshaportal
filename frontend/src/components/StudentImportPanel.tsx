import { useEffect, useState, type FormEvent } from "react";
import { useTranslation } from "react-i18next";
import { fetchStudents, importStudents } from "../api/students";
import type { ImportError, StudentRecord } from "../types/student";

export function StudentImportPanel({
  onStudentsChange,
}: {
  onStudentsChange?: (count: number) => void;
}) {
  const { t } = useTranslation(["students", "common"]);
  const [file, setFile] = useState<File | null>(null);
  const [students, setStudents] = useState<StudentRecord[]>([]);
  const [errors, setErrors] = useState<ImportError[]>([]);
  const [message, setMessage] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStudents()
      .then((rows) => {
        setStudents(rows);
        onStudentsChange?.(rows.length);
      })
      .catch(() => setStudents([]))
      .finally(() => setLoading(false));
  }, [onStudentsChange]);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (!file) return;

    setSubmitting(true);
    setMessage(null);
    setErrors([]);

    try {
      const importResult = await importStudents(file);
      setErrors(importResult.errors);

      if (importResult.errors.length === 0) {
        setMessage(t("students:importSuccess", { count: importResult.created_count }));
      } else {
        setMessage(
          t("students:importPartial", {
            created: importResult.created_count,
            failed: importResult.errors.length,
          })
        );
      }

      const rows = await fetchStudents();
      setStudents(rows);
      onStudentsChange?.(rows.length);
      setFile(null);
    } catch {
      setMessage(t("students:importFailed"));
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <section className="dashboard-section card public-section">
      <h2>{t("students:importTitle")}</h2>
      <p className="muted">{t("students:importHint")}</p>

      <form className="import-form" onSubmit={handleSubmit}>
        <label className="file-input-label">
          {t("students:chooseFile")}
          <input
            type="file"
            accept=".csv,text/csv"
            onChange={(e) => setFile(e.target.files?.[0] ?? null)}
          />
        </label>
        <button type="submit" disabled={!file || submitting}>
          {submitting ? t("students:uploading") : t("students:upload")}
        </button>
      </form>

      {message && <p className="import-message">{message}</p>}

      {errors.length > 0 && (
        <ul className="import-errors">
          {errors.map((entry) => (
            <li key={`${entry.line}-${entry.roll_number}`}>
              {t("students:rowError", {
                line: entry.line,
                roll: entry.roll_number ?? "—",
                error: entry.error,
              })}
            </li>
          ))}
        </ul>
      )}

      <h3>{t("students:studentList")}</h3>
      {loading ? (
        <p className="muted">{t("common:loading")}</p>
      ) : students.length === 0 ? (
        <p className="muted">{t("students:noStudents")}</p>
      ) : (
        <ul className="student-list">
          {students.map((student) => (
            <li key={student.id} className="student-list-item">
              <strong>{student.name}</strong>
              <span>
                {t("students:rollNumber")}: {student.roll_number} · {t("students:classSection")}:{" "}
                {student.class_name}/{student.section}
              </span>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
