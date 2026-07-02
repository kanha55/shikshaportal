import { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { fetchStudentAttendance } from "../api/attendance";

export function StudentAttendancePanel({
  onPercentChange,
}: {
  onPercentChange?: (value: string) => void;
}) {
  const { t } = useTranslation(["attendance", "common"]);
  const [percent, setPercent] = useState(0);
  const [records, setRecords] = useState<Array<{ date: string; status: string }>>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStudentAttendance()
      .then((data) => {
        setPercent(data.attendance_percent);
        setRecords(data.records);
        onPercentChange?.(`${data.attendance_percent}%`);
      })
      .catch(() => {
        setPercent(0);
        setRecords([]);
      })
      .finally(() => setLoading(false));
  }, [onPercentChange]);

  return (
    <section className="panel">
      <div className="panel-header">
        <div className="panel-icon" aria-hidden>
          A
        </div>
        <div>
          <h2>{t("attendance:title")}</h2>
          <p className="muted">{t("attendance:studentHint")}</p>
        </div>
      </div>

      {loading ? (
        <div className="loading-state">
          <div className="spinner" aria-hidden />
          <span>{t("common:loading")}</span>
        </div>
      ) : (
        <>
          <p className="attendance-percent">
            {t("attendance:attendancePercent")}: <strong>{percent}%</strong>
          </p>
          {records.length === 0 ? (
            <p className="muted">{t("attendance:noRecords")}</p>
          ) : (
            <ul className="attendance-history">
              {records.map((record) => (
                <li key={record.date} className="attendance-history-item">
                  <span>{new Date(record.date).toLocaleDateString()}</span>
                  <span className={`attendance-status ${record.status}`}>
                    {t(`attendance:${record.status}`)}
                  </span>
                </li>
              ))}
            </ul>
          )}
        </>
      )}
    </section>
  );
}
