import { useCallback, useEffect, useState, type FormEvent } from "react";
import { useTranslation } from "react-i18next";
import axios from "axios";
import {
  deleteGalleryPhoto,
  fetchAdminGalleryPhotos,
  moveGalleryPhoto,
  uploadGalleryPhoto,
} from "../api/gallery";
import type { GalleryPhoto } from "../types/gallery";

const MAX_BYTES = 5 * 1024 * 1024;
const MAX_PHOTOS = 6;


function isFileTooLarge(file: File): boolean {
  return file.size > MAX_BYTES;
}

function mapBackendErrors(errors: string[], t: (key: string) => string): string {
  return errors
    .map((message) => {
      if (/5\s*MB/i.test(message) || /smaller than/i.test(message)) {
        return t("gallery:fileTooLarge");
      }
      if (/JPEG|PNG|WebP/i.test(message)) {
        return t("gallery:invalidType");
      }
      if (/Maximum|6 gallery photos|cannot exceed/i.test(message)) {
        return t("gallery:limitReached");
      }
      return message;
    })
    .join(", ");
}

export function GalleryPhotoPanel() {
  const { t } = useTranslation(["gallery", "common"]);
  const [photos, setPhotos] = useState<GalleryPhoto[]>([]);
  const [caption, setCaption] = useState("");
  const [file, setFile] = useState<File | null>(null);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const fileTooLarge = file !== null && isFileTooLarge(file);

  const reload = useCallback(async () => {
    setPhotos(await fetchAdminGalleryPhotos());
  }, []);

  useEffect(() => {
    reload()
      .catch(() => setPhotos([]))
      .finally(() => setLoading(false));
  }, [reload]);

  function handleFileChange(selected: File | null) {
    setFile(selected);
    setMessage(null);

    if (!selected) {
      setError(null);
      return;
    }

    if (isFileTooLarge(selected)) {
      setError(t("gallery:fileTooLarge"));
      return;
    }

    setError(null);
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (!file || fileTooLarge) return;

    if (photos.length >= MAX_PHOTOS) {
      setError(t("gallery:limitReached"));
      return;
    }

    setSubmitting(true);
    setError(null);
    setMessage(null);

    try {
      await uploadGalleryPhoto({ caption: caption || undefined, image: file });
      setCaption("");
      setFile(null);
      setMessage(t("gallery:uploadSuccess"));
      await reload();
    } catch (err) {
      if (err instanceof Error && err.message === "FILE_TOO_LARGE") {
        setError(t("gallery:fileTooLarge"));
      } else if (axios.isAxiosError(err) && err.response?.data?.errors) {
        setError(mapBackendErrors(err.response.data.errors as string[], t));
      } else {
        setError(t("gallery:uploadFailed"));
      }
    } finally {
      setSubmitting(false);
    }
  }

  async function handleDelete(id: number) {
    setError(null);
    try {
      await deleteGalleryPhoto(id);
      await reload();
    } catch {
      setError(t("gallery:deleteFailed"));
    }
  }

  async function handleMove(id: number, direction: "up" | "down") {
    setError(null);
    try {
      await moveGalleryPhoto(id, direction);
      await reload();
    } catch {
      setError(t("gallery:uploadFailed"));
    }
  }

  return (
    <section className="panel">
      <div className="panel-header">
        <div className="panel-icon" aria-hidden>
          G
        </div>
        <div>
          <h2>{t("gallery:panelTitle")}</h2>
          <p className="muted">{t("gallery:panelHint")}</p>
        </div>
      </div>

      <form className="student-form" onSubmit={handleSubmit}>
        <label>
          {t("gallery:caption")}
          <input
            value={caption}
            onChange={(e) => setCaption(e.target.value)}
            placeholder={t("gallery:captionPlaceholder")}
          />
        </label>
        <label className="file-input-label">
          {t("gallery:chooseImage")}
          <input
            type="file"
            accept="image/jpeg,image/png,image/webp,.jpg,.jpeg,.png,.webp"
            onChange={(e) => handleFileChange(e.target.files?.[0] ?? null)}
            required
          />
        </label>
        {error && <p className="error">{error}</p>}
        {message && <p className="import-message">{message}</p>}
        <button type="submit" disabled={submitting || !file || photos.length >= MAX_PHOTOS || fileTooLarge}>
          {submitting ? t("gallery:uploading") : t("gallery:upload")}
        </button>
      </form>

      <div className="panel-subsection">
        <h3>{t("gallery:photoList")}</h3>
        {loading ? (
          <div className="loading-state">
            <div className="spinner" aria-hidden />
            <span>{t("common:loading")}</span>
          </div>
        ) : photos.length === 0 ? (
          <p className="muted">{t("gallery:noPhotos")}</p>
        ) : (
          <ul className="gallery-admin-list">
            {photos.map((photo, index) => (
              <li key={photo.id} className="gallery-admin-item">
                <img src={photo.image_url} alt={photo.caption ?? photo.filename} loading="lazy" />
                <div className="gallery-admin-meta">
                  <strong>{photo.caption || photo.filename}</strong>
                  <span>#{photo.position}</span>
                </div>
                <div className="notice-item-actions">
                  <button
                    type="button"
                    disabled={index === 0}
                    onClick={() => handleMove(photo.id, "up")}
                    aria-label={t("gallery:moveUp")}
                  >
                    ▲
                  </button>
                  <button
                    type="button"
                    disabled={index === photos.length - 1}
                    onClick={() => handleMove(photo.id, "down")}
                    aria-label={t("gallery:moveDown")}
                  >
                    ▼
                  </button>
                  <button
                    type="button"
                    className="danger-button"
                    onClick={() => handleDelete(photo.id)}
                  >
                    {t("gallery:delete")}
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
