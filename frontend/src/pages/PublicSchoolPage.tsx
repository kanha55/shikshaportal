import { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { Link } from "react-router-dom";
import { LanguageToggle } from "../components/LanguageToggle";
import { fetchPublicGalleryPhotos } from "../api/gallery";
import { fetchPublicNotices, fetchPublicSchool } from "../api/public";
import type { GalleryPhoto } from "../types/gallery";
import type { PublicNotice, PublicSchool } from "../types/public";

export function PublicSchoolPage() {
  const { t } = useTranslation(["common", "gallery"]);
  const [school, setSchool] = useState<PublicSchool | null>(null);
  const [notices, setNotices] = useState<PublicNotice[]>([]);
  const [galleryPhotos, setGalleryPhotos] = useState<GalleryPhoto[]>([]);
  const [currentSlide, setCurrentSlide] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function load() {
      try {
        const [schoolData, noticeData, galleryData] = await Promise.all([
          fetchPublicSchool(),
          fetchPublicNotices(),
          fetchPublicGalleryPhotos().catch(() => []),
        ]);
        setSchool(schoolData);
        setNotices(noticeData);
        setGalleryPhotos(galleryData);
      } catch {
        setError(t("schoolNotFoundHint"));
      } finally {
        setLoading(false);
      }
    }

    load();
  }, [t]);

  useEffect(() => {
    if (galleryPhotos.length <= 1) {
      return;
    }
    const timer = window.setInterval(() => {
      setCurrentSlide((prev) => (prev + 1) % galleryPhotos.length);
    }, 4000);
    return () => window.clearInterval(timer);
  }, [galleryPhotos.length]);

  if (loading) {
    return (
      <div className="page-center">
        <div className="loading-state">
          <div className="spinner" aria-hidden />
          <span>{t("loading")}</span>
        </div>
      </div>
    );
  }

  if (error || !school) {
    return (
      <div className="page-center">
        <div className="card">
          <div className="login-brand">
            <div className="login-brand-mark" aria-hidden>
              श
            </div>
            <div className="login-brand-text">
              <h1>{t("appName")}</h1>
            </div>
          </div>
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
          <span className="muted">{t("appName")}</span>
        </div>
        <div className="public-header-actions">
          <LanguageToggle />
          <Link to="/login" className="link-button">
            {t("login")}
          </Link>
        </div>
      </header>

      <div className="public-hero">
        <div className="public-hero-inner">
          <div className="school-logo" aria-hidden>
            {school.name.charAt(0)}
          </div>
          <div>
            <h1>{school.name}</h1>
            <p className="hero-meta">
              {t("board", { board: school.board?.toUpperCase() ?? "" })}
              {school.principal_name ? ` · ${t("principal")}: ${school.principal_name}` : ""}
            </p>
          </div>
        </div>
      </div>

      <main className="public-main">
        {galleryPhotos.length > 0 ? (
          <section className="panel public-gallery-panel">
            <div className="panel-header">
              <div className="panel-icon" aria-hidden>
                P
              </div>
              <h2>{t("gallery:publicTitle")}</h2>
            </div>
            <div className="public-gallery-carousel">
              <div
                className="public-gallery-track"
                style={{ transform: `translateX(-${currentSlide * 100}%)` }}
              >
                {galleryPhotos.map((photo) => (
                  <figure key={photo.id} className="public-gallery-slide">
                    <img
                      src={photo.image_url}
                      alt={photo.caption ?? school.name}
                      loading="lazy"
                    />
                    {photo.caption ? (
                      <figcaption>{photo.caption}</figcaption>
                    ) : null}
                  </figure>
                ))}
              </div>
              {galleryPhotos.length > 1 ? (
                <>
                  <button
                    type="button"
                    className="public-gallery-nav prev"
                    aria-label={t("previous")}
                    onClick={() =>
                      setCurrentSlide(
                        (prev) =>
                          (prev - 1 + galleryPhotos.length) % galleryPhotos.length,
                      )
                    }
                  >
                    ‹
                  </button>
                  <button
                    type="button"
                    className="public-gallery-nav next"
                    aria-label={t("next")}
                    onClick={() =>
                      setCurrentSlide((prev) => (prev + 1) % galleryPhotos.length)
                    }
                  >
                    ›
                  </button>
                  <div className="public-gallery-dots">
                    {galleryPhotos.map((photo, index) => (
                      <button
                        key={photo.id}
                        type="button"
                        className={`public-gallery-dot${
                          index === currentSlide ? " active" : ""
                        }`}
                        aria-label={`${index + 1}`}
                        aria-current={index === currentSlide}
                        onClick={() => setCurrentSlide(index)}
                      />
                    ))}
                  </div>
                </>
              ) : null}
            </div>
          </section>
        ) : null}

        <div className="public-grid">
          <section className="panel">
            <div className="panel-header">
              <div className="panel-icon" aria-hidden>
                i
              </div>
              <h2>{t("about")}</h2>
            </div>
            <p>{school.about_us ?? t("welcomeFallback")}</p>
          </section>

          <section className="panel">
            <div className="panel-header">
              <div className="panel-icon" aria-hidden>
                C
              </div>
              <h2>{t("contact")}</h2>
            </div>
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
        </div>

        <section className="panel">
          <div className="panel-header">
            <div className="panel-icon" aria-hidden>
              N
            </div>
            <h2>{t("latestNotices")}</h2>
          </div>
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
