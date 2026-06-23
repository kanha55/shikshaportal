import { useTranslation } from "react-i18next";
import type { Notice } from "../types/notice";

export function NoticeList({ notices }: { notices: Notice[] }) {
  const { t } = useTranslation("notices");

  if (notices.length === 0) {
    return <p className="muted">{t("noNoticesAdmin")}</p>;
  }

  return (
    <ul className="notice-list">
      {notices.map((notice) => (
        <li key={notice.id} className="notice-item">
          <h3>{notice.title}</h3>
          <p className="notice-date">{new Date(notice.published_at).toLocaleDateString()}</p>
          <p>{notice.body}</p>
        </li>
      ))}
    </ul>
  );
}
