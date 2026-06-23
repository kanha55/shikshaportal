import { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { Link } from "react-router-dom";
import { LanguageToggle } from "../components/LanguageToggle";
import { fetchPublicNotices, fetchPublicSchool } from "../api/public";
import type { PublicNotice, PublicSchool } from "../types/public";

export function PublicSchoolPage() {
  const { t } = useTranslation("common");
  const [school, setSchool] = useState<PublicSchool | null>(null);
  const [notices, setNotices] = useState<PublicNotice[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      try {
        const [schoolData, noticeData] = await Promise.all([
          fetchPublicSchool(),
          fetchPublicNotices(),
        ]);
        setSchool(schoolData);
        setNotices(noticeData);
      } catch {
        setError(t("schoolNotFoundHint"));
      } finally {
        setLoading(false);
      }
    }

    load();
  }, []);

  if (loading) {
    return <div className="page-center">{t("loading")}</div>;
  }

  if (error || !school) {
    return (
      <div className="page-center">
        <div className="card">
          <h1>{t("appName")}</h1>
          <p className="error">{error ?? t("schoolNotFound")}</p>
          <Link to="/login" className="link-button">
            {t("staffLogin")}
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="public-page">
      <header className="public-header">
        <div className="school-brand">
          <div className="school-logo" aria-hidden>
            {school.name.charAt(0)}
          </div>
          <div>
            <h1>{school.name}</h1>
            <p className="muted">{t("board", { board: school.board?.toUpperCase() ?? "" })}</p>
          </div>
        </div>
        <div className="public-header-actions">
          <LanguageToggle />
          <Link to="/login" className="link-button">
            {t("login")}
          </Link>
        </div>
      </header>

      <main className="public-main">
        <section className="card public-section">
          <h2>{t("about")}</h2>
          <p>{school.about_us ?? t("welcomeFallback")}</p>
        </section>

        <section className="card public-section">
          <h2>{t("contact")}</h2>
          <ul className="contact-list">
            {school.address && <li>{school.address}</li>}
            {school.phone && (
              <li>
                {t("phone")}: {school.phone}
              </li>
            )}
            {school.principal_name && (
              <li>
                {t("principal")}: {school.principal_name}
              </li>
            )}
          </ul>
        </section>

        <section className="card public-section">
          <h2>{t("latestNotices")}</h2>
          {notices.length === 0 ? (
            <p className="muted">{t("noNotices")}</p>
          ) : (
            <ul className="notice-list">
              {notices.map((notice) => (
                <li key={notice.id} className="notice-item">
                  <h3>{notice.title}</h3>
                  <p className="notice-date">
                    {new Date(notice.published_at).toLocaleDateString()}
                  </p>
                  <p>{notice.body}</p>
                </li>
              ))}
            </ul>
          )}
        </section>
      </main>
    </div>
  );
}
