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
    <section className="dashboard-section card public-section">
      <h2>{t("recentNotices")}</h2>
      {loading ? <p className="muted">{t("common:loading")}</p> : <NoticeList notices={notices} />}
    </section>
  );
}
