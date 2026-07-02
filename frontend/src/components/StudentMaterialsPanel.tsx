import { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import { fetchStudentStudyMaterials } from "../api/studyMaterials";
import type { StudyMaterial } from "../types/studyMaterial";

export function StudentMaterialsPanel() {
  const { t } = useTranslation(["materials", "common"]);
  const [materials, setMaterials] = useState<StudyMaterial[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStudentStudyMaterials()
      .then(setMaterials)
      .catch(() => setMaterials([]))
      .finally(() => setLoading(false));
  }, []);

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
          <h2>{t("materials:studentPanelTitle")}</h2>
          <p className="muted">{t("materials:studentPanelHint")}</p>
        </div>
      </div>

      {loading ? (
        <div className="loading-state">
          <div className="spinner" aria-hidden />
          <span>{t("common:loading")}</span>
        </div>
      ) : materials.length === 0 ? (
        <p className="muted">{t("materials:noClassMaterials")}</p>
      ) : (
        <ul className="material-list">
          {materials.map((material) => (
            <li key={material.id} className="material-list-item">
              <div>
                <strong>{material.title}</strong>
                <span>
                  {material.subject} · {formatSize(material.byte_size)}
                </span>
              </div>
              <a
                href={material.download_url}
                className="link-button material-download-link"
                target="_blank"
                rel="noreferrer"
              >
                {t("materials:download")}
              </a>
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
