import { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { fetchSchoolNotices } from "../api/notices";
import type { Notice } from "../types/notice";
import { NoticeList } from "./NoticeList";

export function StudentNoticesPanel() {
  const { t } = useTranslation(["notices", "common"]);
  const [notices, setNotices] = useState<Notice[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchSchoolNotices()
      .then(setNotices)
      .catch(() => setNotices([]))
      .finally(() => setLoading(false));
  }, []);

  return (
    <section className="panel">
      <div className="panel-header">
        <div className="panel-icon" aria-hidden>
          N
        </div>
        <h2>{t("recentNotices")}</h2>
      </div>
      {loading ? (
        <div className="loading-state">
          <div className="spinner" aria-hidden />
          <span>{t("common:loading")}</span>
        </div>
      ) : (
        <NoticeList notices={notices} />
      )}
    </section>
  );
}
