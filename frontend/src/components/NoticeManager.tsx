import { useEffect, useState, type FormEvent } from "react";
import { useTranslation } from "react-i18next";
import {
  createNotice,
  deleteNotice,
  fetchAdminNotices,
  updateNotice,
} from "../api/notices";
import type { Notice } from "../types/notice";

export function NoticeManager({ refreshKey = 0 }: { refreshKey?: number }) {
  const { t } = useTranslation(["notices", "common"]);
  const [notices, setNotices] = useState<Notice[]>([]);
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [editingId, setEditingId] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function loadNotices() {
    setLoading(true);
    try {
      setNotices(await fetchAdminNotices());
    } catch {
      setNotices([]);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void loadNotices();
  }, [refreshKey]);

  function resetForm() {
    setTitle("");
    setBody("");
    setEditingId(null);
    setError(null);
  }

  function startEdit(notice: Notice) {
    setEditingId(notice.id);
    setTitle(notice.title);
    setBody(notice.body);
    setError(null);
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setSubmitting(true);
    setError(null);

    try {
      if (editingId) {
        await updateNotice(editingId, { title, body });
      } else {
        await createNotice({ title, body });
      }
      resetForm();
      await loadNotices();
    } catch {
      setError(t("saveFailed"));
    } finally {
      setSubmitting(false);
    }
  }

  async function handleDelete(id: number) {
    setSubmitting(true);
    setError(null);
    try {
      await deleteNotice(id);
      if (editingId === id) resetForm();
      await loadNotices();
    } catch {
      setError(t("deleteFailed"));
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <section className="panel">
      <div className="panel-header">
        <div className="panel-icon" aria-hidden>
          N
        </div>
        <h2>{t("manageNotices")}</h2>
      </div>

      <form className="notice-form" onSubmit={handleSubmit}>
        <label>
          {t("noticeTitle")}
          <input value={title} onChange={(e) => setTitle(e.target.value)} required />
        </label>
        <label>
          {t("noticeBody")}
          <textarea value={body} onChange={(e) => setBody(e.target.value)} rows={4} required />
        </label>
        {error && <p className="error">{error}</p>}
        <div className="notice-form-actions">
          <button type="submit" disabled={submitting}>
            {editingId ? t("saveNotice") : t("createNotice")}
          </button>
          {editingId && (
            <button type="button" className="secondary-button" onClick={resetForm}>
              {t("common:cancel")}
            </button>
          )}
        </div>
      </form>

      <div className="panel-subsection">
      <h3>{t("recentNotices")}</h3>
      {loading ? (
        <p className="muted">{t("common:loading")}</p>
      ) : notices.length === 0 ? (
        <p className="muted">{t("noNoticesAdmin")}</p>
      ) : (
        <ul className="notice-list">
          {notices.map((notice) => (
            <li key={notice.id} className="notice-item">
              <h3>{notice.title}</h3>
              <p className="notice-date">{new Date(notice.published_at).toLocaleDateString()}</p>
              <p>{notice.body}</p>
              <div className="notice-item-actions">
                <button type="button" className="secondary-button" onClick={() => startEdit(notice)}>
                  {t("editNotice")}
                </button>
                <button type="button" className="danger-button" onClick={() => handleDelete(notice.id)}>
                  {t("deleteNotice")}
                </button>
              </div>
            </li>
          ))}
        </ul>
      )}
      </div>
    </section>
  );
}
