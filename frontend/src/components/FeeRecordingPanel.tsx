import { useCallback, useEffect, useMemo, useState, type FormEvent } from "react";
import { useTranslation } from "react-i18next";
import axios from "axios";
import { createFeeRecord, downloadFeeReceipt, fetchAdminFees } from "../api/fees";
import { fetchStudents } from "../api/students";
import { triggerBlobDownload } from "../lib/downloadBlob";
import type { AdminFeesFilters, CreateFeeInput, FeeRecordRow, FeeType } from "../types/fees";
import type { StudentRecord } from "../types/student";

const FEE_TYPES: FeeType[] = ["tuition", "transport", "exam", "other"];

function currentYear() {
  return new Date().getFullYear();
}

function yearOptions() {
  const end = currentYear();
  const start = end - 5;
  const years: number[] = [];
  for (let year = end; year >= start; year -= 1) {
    years.push(year);
  }
  return years;
}

export function FeeRecordingPanel({
  onSummaryChange,
}: {
  onSummaryChange?: (pendingCount: number) => void;
}) {
  const { t } = useTranslation(["fees", "common"]);
  const [students, setStudents] = useState<StudentRecord[]>([]);
  const [records, setRecords] = useState<FeeRecordRow[]>([]);
  const [studentId, setStudentId] = useState("");
  const [feeType, setFeeType] = useState<FeeType>("tuition");
  const [amount, setAmount] = useState("");
  const [notes, setNotes] = useState("");
  const [yearFilter, setYearFilter] = useState("");
  const [nameFilter, setNameFilter] = useState("");
  const [classFilter, setClassFilter] = useState("");
  const [sectionFilter, setSectionFilter] = useState("");
  const [loading, setLoading] = useState(true);
  const [recordsLoading, setRecordsLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  const feeFilters = useMemo<AdminFeesFilters>(() => {
    const filters: AdminFeesFilters = {};
    if (yearFilter) filters.year = yearFilter;
    if (nameFilter.trim()) filters.student_name = nameFilter.trim();
    if (classFilter) filters.class_name = classFilter;
    if (sectionFilter) filters.section = sectionFilter;
    return filters;
  }, [yearFilter, nameFilter, classFilter, sectionFilter]);

  const hasFilters = Boolean(yearFilter || nameFilter.trim() || classFilter || sectionFilter);

  const classOptions = useMemo(() => {
    const values = new Set(students.map((s) => s.class_name));
    return Array.from(values).sort((a, b) => a.localeCompare(b, undefined, { numeric: true }));
  }, [students]);

  const sectionOptions = useMemo(() => {
    const pool = classFilter ? students.filter((s) => s.class_name === classFilter) : students;
    const values = new Set(pool.map((s) => s.section));
    return Array.from(values).sort((a, b) => a.localeCompare(b, undefined, { numeric: true }));
  }, [students, classFilter]);

  const loadFees = useCallback(
    async (filters: AdminFeesFilters) => {
      setRecordsLoading(true);
      try {
        const feeData = await fetchAdminFees(filters);
        setRecords(feeData.fee_records);
        onSummaryChange?.(feeData.summary.pending_count);
      } catch {
        setRecords([]);
      } finally {
        setRecordsLoading(false);
      }
    },
    [onSummaryChange]
  );

  const reloadAll = useCallback(async () => {
    const [studentRows, feeData] = await Promise.all([fetchStudents(), fetchAdminFees(feeFilters)]);
    setStudents(studentRows);
    setRecords(feeData.fee_records);
    onSummaryChange?.(feeData.summary.pending_count);
    if (!studentId && studentRows[0]) {
      setStudentId(String(studentRows[0].id));
    }
  }, [feeFilters, onSummaryChange, studentId]);

  useEffect(() => {
    reloadAll()
      .catch(() => {
        setStudents([]);
        setRecords([]);
      })
      .finally(() => setLoading(false));
    // Initial load only — filter changes handled separately.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (loading) return;

    const timer = window.setTimeout(() => {
      void loadFees(feeFilters);
    }, nameFilter.trim() ? 300 : 0);

    return () => window.clearTimeout(timer);
  }, [feeFilters, loadFees, loading, nameFilter]);

  function handleClassChange(value: string) {
    setClassFilter(value);
    setSectionFilter("");
  }

  function clearFilters() {
    setYearFilter("");
    setNameFilter("");
    setClassFilter("");
    setSectionFilter("");
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (!studentId || !amount) return;

    setSaving(true);
    setError(null);
    setMessage(null);

    const input: CreateFeeInput = {
      student_id: Number(studentId),
      fee_type: feeType,
      amount: Number(amount),
      status: "paid",
      paid_on: new Date().toISOString().slice(0, 10),
      notes: notes || undefined,
    };

    try {
      const created = await createFeeRecord(input);
      setAmount("");
      setNotes("");

      try {
        const blob = await downloadFeeReceipt(created.id);
        triggerBlobDownload(blob, `${created.receipt_number || "receipt"}.pdf`);
        setMessage(t("fees:recordSuccess"));
      } catch {
        setMessage(t("fees:receiptDownloadFailed"));
      }

      await loadFees(feeFilters).catch(() => {});
    } catch (err) {
      setMessage(null);
      if (axios.isAxiosError(err) && err.response?.data?.errors) {
        setError((err.response.data.errors as string[]).join(", "));
      } else {
        setError(t("fees:recordFailed"));
      }
    } finally {
      setSaving(false);
    }
  }

  return (
    <section className="panel">
      <div className="panel-header">
        <div className="panel-icon" aria-hidden>
          F
        </div>
        <div>
          <h2>{t("fees:recordPayment")}</h2>
          <p className="muted">{t("fees:recordHint")}</p>
        </div>
      </div>

      {loading ? (
        <div className="loading-state">
          <div className="spinner" aria-hidden />
          <span>{t("common:loading")}</span>
        </div>
      ) : (
        <>
          <form className="fee-form" onSubmit={handleSubmit}>
            <label>
              {t("fees:student")}
              <select value={studentId} onChange={(e) => setStudentId(e.target.value)} required>
                {students.map((student) => (
                  <option key={student.id} value={student.id}>
                    {student.name} ({student.class_name}-{student.section})
                  </option>
                ))}
              </select>
            </label>
            <label>
              {t("fees:feeType")}
              <select value={feeType} onChange={(e) => setFeeType(e.target.value as FeeType)}>
                {FEE_TYPES.map((type) => (
                  <option key={type} value={type}>
                    {t(`fees:types.${type}`)}
                  </option>
                ))}
              </select>
            </label>
            <label>
              {t("fees:amount")}
              <input
                type="number"
                min="1"
                step="0.01"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                required
              />
            </label>
            <label>
              {t("fees:notes")}
              <input value={notes} onChange={(e) => setNotes(e.target.value)} />
            </label>
            <div className="notice-form-actions">
              <button type="submit" disabled={saving || students.length === 0}>
                {saving ? t("fees:saving") : t("fees:saveAndReceipt")}
              </button>
            </div>
          </form>

          {error && <p className="error">{error}</p>}
          {message && <p className="import-message">{message}</p>}

          <div className="panel-subsection">
            <h3>{t("fees:recentPayments")}</h3>

            <div className="fee-filters">
              <label className="fee-filter-search">
                {t("fees:searchLabel")}
                <input
                  type="search"
                  value={nameFilter}
                  onChange={(e) => setNameFilter(e.target.value)}
                  placeholder={t("fees:searchPlaceholder")}
                />
              </label>

              <label>
                {t("fees:year")}
                <select value={yearFilter} onChange={(e) => setYearFilter(e.target.value)}>
                  <option value="">{t("fees:filterAllYears")}</option>
                  {yearOptions().map((year) => (
                    <option key={year} value={String(year)}>
                      {year}
                    </option>
                  ))}
                </select>
              </label>

              <label>
                {t("fees:className")}
                <select value={classFilter} onChange={(e) => handleClassChange(e.target.value)}>
                  <option value="">{t("fees:filterAllClasses")}</option>
                  {classOptions.map((value) => (
                    <option key={value} value={value}>
                      {value}
                    </option>
                  ))}
                </select>
              </label>

              <label>
                {t("fees:section")}
                <select value={sectionFilter} onChange={(e) => setSectionFilter(e.target.value)}>
                  <option value="">{t("fees:filterAllSections")}</option>
                  {sectionOptions.map((value) => (
                    <option key={value} value={value}>
                      {value}
                    </option>
                  ))}
                </select>
              </label>

              {hasFilters && (
                <button type="button" className="secondary-button fee-clear-filters" onClick={clearFilters}>
                  {t("fees:clearFilters")}
                </button>
              )}
            </div>

            {recordsLoading ? (
              <div className="loading-state">
                <div className="spinner" aria-hidden />
                <span>{t("common:loading")}</span>
              </div>
            ) : records.length === 0 ? (
              <p className="muted">{hasFilters ? t("fees:noMatches") : t("fees:noRecords")}</p>
            ) : (
              <>
                <p className="fee-list-summary muted">
                  {t("fees:showingCount", { count: records.length })}
                </p>
                <ul className="fee-list">
                  {records.map((record) => (
                    <li key={record.id} className="fee-list-item">
                      <div>
                        <strong>{record.student_name}</strong>
                        <span>
                          {record.class_name}-{record.section} · {t(`fees:types.${record.fee_type}`)} · Rs.{" "}
                          {record.amount}
                          {record.paid_on
                            ? ` · ${new Date(record.paid_on).toLocaleDateString()}`
                            : record.due_date
                              ? ` · ${t("fees:dueDate")}: ${new Date(record.due_date).toLocaleDateString()}`
                              : ""}
                        </span>
                      </div>
                      <span className={`fee-status ${record.status}`}>{t(`fees:${record.status}`)}</span>
                    </li>
                  ))}
                </ul>
              </>
            )}
          </div>
        </>
      )}
    </section>
  );
}
