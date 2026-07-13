import { useCallback, useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import axios from "axios";
import { deleteQuestionPaper, fetchQuestionPapers } from "../api/questionPapers";
import type { QuestionPaper } from "../types/questionPaper";

function extractApiError(err: unknown, fallback: string): string {
  if (!axios.isAxiosError(err)) return fallback;
  const data = err.response?.data as { errors?: string[]; error?: string } | undefined;
  if (data?.errors?.length) return data.errors.join(", ");
  if (data?.error) return data.error;
  return fallback;
}

export function QuestionPaperList({
  canDelete,
  onSelect,
  onPrint,
  refreshKey = 0,
}: {
  canDelete: boolean;
  onSelect?: (paper: QuestionPaper) => void;
  onPrint?: (paper: QuestionPaper, mode: "paper" | "answer_key") => void;
  refreshKey?: number;
}) {
  const { t } = useTranslation("questionPaper");
  const [papers, setPapers] = useState<QuestionPaper[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [subject, setSubject] = useState("");
  const [className, setClassName] = useState("");
  const [date, setDate] = useState("");
  const [deletingId, setDeletingId] = useState<number | null>(null);

  const loadPapers = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const rows = await fetchQuestionPapers({
        subject: subject.trim() || undefined,
        class_name: className.trim() || undefined,
        date: date || undefined,
      });
      setPapers(rows);
    } catch (err) {
      setError(extractApiError(err, t("loadFailed")));
    } finally {
      setLoading(false);
    }
  }, [subject, className, date, t]);

  useEffect(() => {
    void loadPapers();
  }, [loadPapers, refreshKey]);

  async function handleDelete(id: number) {
    if (!window.confirm(t("deleteConfirm"))) return;
    setDeletingId(id);
    try {
      await deleteQuestionPaper(id);
      setPapers((current) => current.filter((paper) => paper.id !== id));
    } catch (err) {
      setError(extractApiError(err, t("deleteFailed")));
    } finally {
      setDeletingId(null);
    }
  }

  return (
    <section className="panel qp-list">
      <div className="panel-header">
        <div>
          <h2>{t("listTitle")}</h2>
          <p className="muted">{t("listHint")}</p>
        </div>
      </div>

      <div className="qp-filters">
        <label>
          {t("filterSubject")}
          <input value={subject} onChange={(e) => setSubject(e.target.value)} />
        </label>
        <label>
          {t("filterClass")}
          <input value={className} onChange={(e) => setClassName(e.target.value)} />
        </label>
        <label>
          {t("filterDate")}
          <input type="date" value={date} onChange={(e) => setDate(e.target.value)} />
        </label>
        <button type="button" className="btn-secondary" onClick={() => void loadPapers()}>
          {t("applyFilters")}
        </button>
      </div>

      {loading ? <p className="muted">{t("loading")}</p> : null}
      {error ? <p className="error-banner">{error}</p> : null}

      {!loading && papers.length === 0 ? (
        <p className="muted qp-empty">{t("emptyList")}</p>
      ) : null}

      <ul className="qp-paper-list">
        {papers.map((paper) => (
          <li key={paper.id} className="qp-paper-row">
            <div>
              <strong>{paper.title}</strong>
              <p className="muted">
                {paper.subject} · {paper.class_name} · {paper.topic}
              </p>
              <p className="muted">
                {t("listMeta", {
                  marks: paper.total_marks,
                  questions: paper.questions.length,
                  date: new Date(paper.created_at).toLocaleDateString(),
                })}
                {paper.teacher_name ? ` · ${paper.teacher_name}` : ""}
              </p>
            </div>
            <div className="qp-row-actions">
              {onSelect ? (
                <button type="button" className="btn-secondary" onClick={() => onSelect(paper)}>
                  {t("edit")}
                </button>
              ) : null}
              {onPrint ? (
                <>
                  <button type="button" className="btn-secondary" onClick={() => onPrint(paper, "paper")}>
                    {t("printPaper")}
                  </button>
                  <button
                    type="button"
                    className="btn-secondary"
                    onClick={() => onPrint(paper, "answer_key")}
                  >
                    {t("printAnswerKey")}
                  </button>
                </>
              ) : null}
              {canDelete ? (
                <button
                  type="button"
                  className="btn-danger"
                  disabled={deletingId === paper.id}
                  onClick={() => void handleDelete(paper.id)}
                >
                  {deletingId === paper.id ? t("deleting") : t("delete")}
                </button>
              ) : null}
            </div>
          </li>
        ))}
      </ul>
    </section>
  );
}
