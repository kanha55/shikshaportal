import { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { fetchStudentFees } from "../api/fees";

export function StudentFeesPanel({
  onSummaryChange,
}: {
  onSummaryChange?: (pendingAmount: string) => void;
}) {
  const { t } = useTranslation(["fees", "common"]);
  const [records, setRecords] = useState<
    Array<{
      id: number;
      fee_type: string;
      amount: number;
      due_date: string | null;
      paid_on: string | null;
      status: string;
      receipt_number: string | null;
    }>
  >([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStudentFees()
      .then((data) => {
        setRecords(data.fee_records);
        onSummaryChange?.(`Rs. ${data.summary.pending_amount}`);
      })
      .catch(() => {
        setRecords([]);
        onSummaryChange?.("—");
      })
      .finally(() => setLoading(false));
  }, [onSummaryChange]);

  return (
    <section className="panel">
      <div className="panel-header">
        <div className="panel-icon" aria-hidden>
          F
        </div>
        <div>
          <h2>{t("fees:title")}</h2>
          <p className="muted">{t("fees:studentHint")}</p>
        </div>
      </div>

      {loading ? (
        <div className="loading-state">
          <div className="spinner" aria-hidden />
          <span>{t("common:loading")}</span>
        </div>
      ) : records.length === 0 ? (
        <p className="muted">{t("fees:noRecords")}</p>
      ) : (
        <ul className="fee-list">
          {records.map((record) => (
            <li key={record.id} className="fee-list-item">
              <div>
                <strong>{t(`fees:types.${record.fee_type}`)}</strong>
                <span>
                  Rs. {record.amount}
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
      )}
    </section>
  );
}
