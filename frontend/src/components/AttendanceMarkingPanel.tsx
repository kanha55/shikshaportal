import { useCallback, useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import axios from "axios";
import {
  fetchAttendanceSheet,
  saveAttendance,
} from "../api/attendance";
import type { AttendanceStatus, AttendanceStudentRow } from "../types/attendance";

function todayIso() {
  return new Date().toISOString().slice(0, 10);
}

export function AttendanceMarkingPanel() {
  const { t } = useTranslation(["attendance", "common"]);
  const [date, setDate] = useState(todayIso());
  const [className, setClassName] = useState("10");
  const [section, setSection] = useState("A");
  const [rows, setRows] = useState<AttendanceStudentRow[]>([]);
  const [summary, setSummary] = useState<{ present: number; absent: number; unmarked: number } | null>(
    null
  );
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  const loadSheet = useCallback(async () => {
    if (!className.trim() || !section.trim()) return;
    setLoading(true);
    setError(null);
    try {
      const sheet = await fetchAttendanceSheet(date, className, section);
      setRows(sheet.students);
      setSummary({
        present: sheet.summary.present,
        absent: sheet.summary.absent,
        unmarked: sheet.summary.unmarked,
      });
    } catch {
      setRows([]);
      setSummary(null);
      setError(t("attendance:loadFailed"));
    } finally {
      setLoading(false);
    }
  }, [className, date, section, t]);

  useEffect(() => {
    void loadSheet();
  }, [loadSheet]);

  function setStatus(studentId: number, status: AttendanceStatus) {
    setRows((current) =>
      current.map((row) => (row.student_id === studentId ? { ...row, status } : row))
    );
  }

  function markAllPresent() {
    setRows((current) => current.map((row) => ({ ...row, status: "present" as const })));
  }

  async function handleSave() {
    setSaving(true);
    setError(null);
    setMessage(null);
    try {
      await saveAttendance({
        date,
        class_name: className,
        section,
        records: rows
          .filter((row) => row.status)
          .map((row) => ({ student_id: row.student_id, status: row.status as AttendanceStatus })),
      });
      setMessage(t("attendance:saveSuccess"));
      await loadSheet();
    } catch (err) {
      if (axios.isAxiosError(err) && err.response?.data?.errors) {
        setError((err.response.data.errors as string[]).join(", "));
      } else {
        setError(t("attendance:saveFailed"));
      }
    } finally {
      setSaving(false);
    }
  }

  return (
    <section className="panel">
      <div className="panel-header">
        <div className="panel-icon" aria-hidden>
          A
        </div>
        <div>
          <h2>{t("attendance:markAttendance")}</h2>
          <p className="muted">{t("attendance:markHint")}</p>
        </div>
      </div>

      <div className="attendance-filters">
        <label>
          {t("attendance:date")}
          <input type="date" value={date} max={todayIso()} onChange={(e) => setDate(e.target.value)} />
        </label>
        <label>
          {t("attendance:className")}
          <input value={className} onChange={(e) => setClassName(e.target.value)} required />
        </label>
        <label>
          {t("attendance:section")}
          <input value={section} onChange={(e) => setSection(e.target.value)} required />
        </label>
        <button type="button" className="secondary-button attendance-mark-all" onClick={markAllPresent}>
          {t("attendance:bulkMarkPresent")}
        </button>
      </div>

      {summary && (
        <p className="muted attendance-summary">
          {t("attendance:summaryLine", {
            present: summary.present,
            absent: summary.absent,
            unmarked: summary.unmarked,
          })}
        </p>
      )}

      {error && <p className="error">{error}</p>}
      {message && <p className="import-message">{message}</p>}

      {loading ? (
        <div className="loading-state">
          <div className="spinner" aria-hidden />
          <span>{t("common:loading")}</span>
        </div>
      ) : rows.length === 0 ? (
        <p className="muted">{t("attendance:noStudents")}</p>
      ) : (
        <>
          <ul className="attendance-list">
            {rows.map((row) => (
              <li key={row.student_id} className="attendance-list-item">
                <div>
                  <strong>{row.name}</strong>
                  <span>{row.roll_number}</span>
                </div>
                <div className="attendance-toggle">
                  <button
                    type="button"
                    className={row.status === "present" ? "attendance-btn active present" : "attendance-btn"}
                    onClick={() => setStatus(row.student_id, "present")}
                  >
                    {t("attendance:present")}
                  </button>
                  <button
                    type="button"
                    className={row.status === "absent" ? "attendance-btn active absent" : "attendance-btn"}
                    onClick={() => setStatus(row.student_id, "absent")}
                  >
                    {t("attendance:absent")}
                  </button>
                </div>
              </li>
            ))}
          </ul>
          <div className="notice-form-actions">
            <button type="button" onClick={handleSave} disabled={saving}>
              {saving ? t("attendance:saving") : t("attendance:saveAttendance")}
            </button>
          </div>
        </>
      )}
    </section>
  );
}
