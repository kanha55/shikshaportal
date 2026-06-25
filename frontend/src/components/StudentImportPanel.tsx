import { useCallback, useEffect, useState, type FormEvent } from "react";
import { useTranslation } from "react-i18next";
import axios from "axios";
import { createStudent, fetchStudents, importStudents } from "../api/students";
import type { ImportError, StudentRecord } from "../types/student";

const emptyForm = {
  name: "",
  roll_number: "",
  class_name: "",
  section: "",
  parent_phone: "",
  email: "",
};

export function StudentImportPanel({
  onStudentsChange,
}: {
  onStudentsChange?: (count: number) => void;
}) {
  const { t } = useTranslation(["students", "common"]);
  const [file, setFile] = useState<File | null>(null);
  const [form, setForm] = useState(emptyForm);
  const [students, setStudents] = useState<StudentRecord[]>([]);
  const [errors, setErrors] = useState<ImportError[]>([]);
  const [message, setMessage] = useState<string | null>(null);
  const [formError, setFormError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [adding, setAdding] = useState(false);
  const [loading, setLoading] = useState(true);

  const reloadStudents = useCallback(async () => {
    const rows = await fetchStudents();
    setStudents(rows);
    onStudentsChange?.(rows.length);
  }, [onStudentsChange]);

  useEffect(() => {
    reloadStudents()
      .catch(() => setStudents([]))
      .finally(() => setLoading(false));
  }, [reloadStudents]);

  async function handleAddStudent(event: FormEvent) {
    event.preventDefault();
    setAdding(true);
    setFormError(null);
    setMessage(null);

    try {
      await createStudent({
        name: form.name,
        roll_number: form.roll_number,
        class_name: form.class_name,
        section: form.section,
        parent_phone: form.parent_phone,
        email: form.email || undefined,
      });
      setForm(emptyForm);
      setMessage(t("students:createSuccess"));
      await reloadStudents();
    } catch (err) {
      if (axios.isAxiosError(err) && err.response?.data?.errors) {
        const apiErrors = err.response.data.errors as string[];
        setFormError(apiErrors.join(", "));
      } else {
        setFormError(t("students:createFailed"));
      }
    } finally {
      setAdding(false);
    }
  }

  async function handleCsvSubmit(event: FormEvent) {
    event.preventDefault();
    if (!file) return;

    setSubmitting(true);
    setMessage(null);
    setFormError(null);
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

      await reloadStudents();
      setFile(null);
    } catch {
      setMessage(t("students:importFailed"));
    } finally {
      setSubmitting(false);
    }
  }

  function updateForm(field: keyof typeof emptyForm, value: string) {
    setForm((prev) => ({ ...prev, [field]: value }));
  }

  return (
    <section className="dashboard-section card public-section">
      <h2>{t("students:pageTitle")}</h2>

      <h3>{t("students:addStudentTitle")}</h3>
      <form className="student-form" onSubmit={handleAddStudent}>
        <label>
          {t("students:name")}
          <input
            value={form.name}
            onChange={(e) => updateForm("name", e.target.value)}
            required
          />
        </label>
        <label>
          {t("students:rollNumber")}
          <input
            value={form.roll_number}
            onChange={(e) => updateForm("roll_number", e.target.value)}
            required
          />
        </label>
        <label>
          {t("students:className")}
          <input
            value={form.class_name}
            onChange={(e) => updateForm("class_name", e.target.value)}
            required
          />
        </label>
        <label>
          {t("students:section")}
          <input
            value={form.section}
            onChange={(e) => updateForm("section", e.target.value)}
            required
          />
        </label>
        <label>
          {t("students:parentPhone")}
          <input
            value={form.parent_phone}
            onChange={(e) => updateForm("parent_phone", e.target.value)}
            required
          />
        </label>
        <label>
          {t("students:email")}
          <input
            type="email"
            value={form.email}
            onChange={(e) => updateForm("email", e.target.value)}
          />
        </label>
        {formError && <p className="error">{formError}</p>}
        <button type="submit" disabled={adding}>
          {adding ? t("students:addingStudent") : t("students:addStudent")}
        </button>
      </form>

      <h3>{t("students:importTitle")}</h3>
      <p className="muted">{t("students:importHint")}</p>

      <form className="import-form" onSubmit={handleCsvSubmit}>
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
