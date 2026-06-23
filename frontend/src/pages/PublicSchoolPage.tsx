import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { fetchPublicNotices, fetchPublicSchool } from "../api/public";
import type { PublicNotice, PublicSchool } from "../types/public";

export function PublicSchoolPage() {
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
        setError("School not found. Check the subdomain URL.");
      } finally {
        setLoading(false);
      }
    }

    load();
  }, []);

  if (loading) {
    return <div className="page-center">Loading…</div>;
  }

  if (error || !school) {
    return (
      <div className="page-center">
        <div className="card">
          <h1>Shiksha Portal</h1>
          <p className="error">{error ?? "School not found"}</p>
          <Link to="/login" className="link-button">
            Staff login
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
            <p className="muted">{school.board?.toUpperCase()} Board</p>
          </div>
        </div>
        <Link to="/login" className="link-button">
          Login
        </Link>
      </header>

      <main className="public-main">
        <section className="card public-section">
          <h2>About</h2>
          <p>{school.about_us ?? "Welcome to our school."}</p>
        </section>

        <section className="card public-section">
          <h2>Contact</h2>
          <ul className="contact-list">
            {school.address && <li>{school.address}</li>}
            {school.phone && <li>Phone: {school.phone}</li>}
            {school.principal_name && <li>Principal: {school.principal_name}</li>}
          </ul>
        </section>

        <section className="card public-section">
          <h2>Latest Notices</h2>
          {notices.length === 0 ? (
            <p className="muted">No notices yet.</p>
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
