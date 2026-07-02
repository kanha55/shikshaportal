import { useCallback, useEffect, useState, type FormEvent } from "react";
import { useTranslation } from "react-i18next";
import axios from "axios";
import {
  deleteStudyMaterial,
  fetchAdminStudyMaterials,
  uploadStudyMaterial,
} from "../api/studyMaterials";
import type { StudyMaterial } from "../types/studyMaterial";

const MAX_BYTES = 10 * 1024 * 1024;

export function StudyMaterialPanel() {
  const { t } = useTranslation(["materials", "common"]);
  const [materials, setMaterials] = useState<StudyMaterial[]>([]);
  const [title, setTitle] = useState("");
  const [className, setClassName] = useState("");
  const [subject, setSubject] = useState("");
  const [file, setFile] = useState<File | null>(null);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const reload = useCallback(async () => {
    setMaterials(await fetchAdminStudyMaterials());
  }, []);

  useEffect(() => {
    reload()
      .catch(() => setMaterials([]))
      .finally(() => setLoading(false));
  }, [reload]);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (!file) return;

    if (file.size > MAX_BYTES) {
      setError(t("materials:fileTooLarge"));
      return;
    }

    setSubmitting(true);
    setError(null);
    setMessage(null);

    try {
      await uploadStudyMaterial({ title, class_name: className, subject, file });
      setTitle("");
      setClassName("");
      setSubject("");
      setFile(null);
      setMessage(t("materials:uploadSuccess"));
      await reload();
    } catch (err) {
      if (axios.isAxiosError(err) && err.response?.data?.errors) {
        setError((err.response.data.errors as string[]).join(", "));
      } else {
        setError(t("materials:uploadFailed"));
      }
    } finally {
      setSubmitting(false);
    }
  }

  async function handleDelete(id: number) {
    setError(null);
    try {
      await deleteStudyMaterial(id);
      await reload();
    } catch {
      setError(t("materials:deleteFailed"));
    }
  }

  function formatSize(bytes: number) {
    if (bytes < 1024 * 1024) return `${Math.round(bytes / 1024)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  }

  return (
    <section className="panel">
      <div className="panel-header">
        <div className="panel-icon" aria-hidden>
          M
        </div>
        <div>
          <h2>{t("materials:panelTitle")}</h2>
          <p className="muted">{t("materials:panelHint")}</p>
        </div>
      </div>

      <form className="student-form" onSubmit={handleSubmit}>
        <label>
          {t("materials:title")}
          <input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder={t("materials:titlePlaceholder")}
            required
          />
        </label>
        <label>
          {t("materials:className")}
          <input value={className} onChange={(e) => setClassName(e.target.value)} required />
        </label>
        <label>
          {t("materials:subject")}
          <input
            value={subject}
            onChange={(e) => setSubject(e.target.value)}
            placeholder={t("materials:subjectPlaceholder")}
            required
          />
        </label>
        <label className="file-input-label">
          {t("materials:chooseFile")}
          <input
            type="file"
            accept="application/pdf,.pdf"
            onChange={(e) => setFile(e.target.files?.[0] ?? null)}
            required
          />
        </label>
        {error && <p className="error">{error}</p>}
        {message && <p className="import-message">{message}</p>}
        <button type="submit" disabled={submitting || !file}>
          {submitting ? t("materials:uploading") : t("materials:upload")}
        </button>
      </form>

      <div className="panel-subsection">
        <h3>{t("materials:materialList")}</h3>
        {loading ? (
          <div className="loading-state">
            <div className="spinner" aria-hidden />
            <span>{t("common:loading")}</span>
          </div>
        ) : materials.length === 0 ? (
          <p className="muted">{t("materials:noMaterials")}</p>
        ) : (
          <ul className="material-list">
            {materials.map((material) => (
              <li key={material.id} className="material-list-item">
                <div>
                  <strong>{material.title}</strong>
                  <span>
                    {material.class_name} · {material.subject} · {formatSize(material.byte_size)}
                  </span>
                </div>
                <div className="notice-item-actions">
                  <a
                    href={material.download_url}
                    className="link-button material-download-link"
                    target="_blank"
                    rel="noreferrer"
                  >
                    {t("materials:download")}
                  </a>
                  <button
                    type="button"
                    className="danger-button"
                    onClick={() => handleDelete(material.id)}
                  >
                    {t("materials:delete")}
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
