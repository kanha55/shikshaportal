import { useState } from "react";
import { useTranslation } from "react-i18next";
import axios from "axios";
import { saveQuestionPaper, updateQuestionPaper } from "../api/questionPapers";
import type { GeneratedPaper, QuestionPaper } from "../types/questionPaper";
import { GeneratedPaperPreview } from "./GeneratedPaperPreview";
import { QuestionPaperGenerator } from "./QuestionPaperGenerator";
import { QuestionPaperList } from "./QuestionPaperList";
import { QuestionPaperPrintView } from "./QuestionPaperPrintView";

function extractApiError(err: unknown, fallback: string): string {
  if (!axios.isAxiosError(err)) return fallback;
  const data = err.response?.data as { errors?: string[]; error?: string } | undefined;
  if (data?.errors?.length) return data.errors.join(", ");
  if (data?.error) return data.error;
  return fallback;
}

export function QuestionPaperWorkspace({ canDelete }: { canDelete: boolean }) {
  const { t } = useTranslation("questionPaper");
  const [generated, setGenerated] = useState<GeneratedPaper | null>(null);
  const [editingPaper, setEditingPaper] = useState<QuestionPaper | null>(null);
  const [printTarget, setPrintTarget] = useState<{
    paper: GeneratedPaper | QuestionPaper;
    mode: "paper" | "answer_key";
  } | null>(null);
  const [saving, setSaving] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);
  const [listRefreshKey, setListRefreshKey] = useState(0);
  const [showGenerator, setShowGenerator] = useState(true);

  const activePaper = editingPaper ?? generated;

  async function handleSave() {
    if (!activePaper) return;
    setSaving(true);
    setSaveError(null);

    const title: string =
      "title" in activePaper ? String(activePaper.title) : activePaper.paper_title;

    const payload = {
      title,
      subject: activePaper.subject,
      class_name: activePaper.class_name,
      topic: activePaper.topic,
      difficulty: activePaper.difficulty,
      language: activePaper.language,
      total_marks: activePaper.total_marks,
      questions: activePaper.questions,
    };

    try {
      if (editingPaper) {
        await updateQuestionPaper(editingPaper.id, payload);
      } else {
        await saveQuestionPaper(payload);
      }
      setGenerated(null);
      setEditingPaper(null);
      setShowGenerator(true);
      setListRefreshKey((key) => key + 1);
    } catch (err) {
      setSaveError(extractApiError(err, t("saveFailed")));
    } finally {
      setSaving(false);
    }
  }

  function handleGenerated(paper: GeneratedPaper) {
    setGenerated(paper);
    setEditingPaper(null);
    setShowGenerator(false);
  }

  function handleRegenerate() {
    setGenerated(null);
    setEditingPaper(null);
    setShowGenerator(true);
  }

  function handleSelectPaper(paper: QuestionPaper) {
    setEditingPaper(paper);
    setGenerated(null);
    setShowGenerator(false);
  }

  if (printTarget) {
    return (
      <QuestionPaperPrintView
        paper={printTarget.paper}
        mode={printTarget.mode}
        onClose={() => setPrintTarget(null)}
      />
    );
  }

  return (
    <>
      {showGenerator ? (
        <QuestionPaperGenerator
          onGenerated={(paper) => handleGenerated(paper)}
        />
      ) : null}

      {activePaper ? (
        <GeneratedPaperPreview
          paper={
            editingPaper
              ? {
                  paper_title: editingPaper.title,
                  subject: editingPaper.subject,
                  class_name: editingPaper.class_name,
                  topic: editingPaper.topic,
                  total_marks: editingPaper.total_marks,
                  language: editingPaper.language,
                  difficulty: editingPaper.difficulty,
                  questions: editingPaper.questions,
                }
              : generated!
          }
          onChange={(paper) => {
            if (editingPaper) {
              setEditingPaper({
                ...editingPaper,
                title: paper.paper_title,
                subject: paper.subject,
                class_name: paper.class_name,
                topic: paper.topic,
                total_marks: paper.total_marks,
                language: paper.language,
                difficulty: paper.difficulty,
                questions: paper.questions,
              });
            } else {
              setGenerated(paper);
            }
          }}
          onRegenerate={handleRegenerate}
          onSave={() => void handleSave()}
          saving={saving}
          saveError={saveError}
        />
      ) : null}

      <QuestionPaperList
        canDelete={canDelete}
        refreshKey={listRefreshKey}
        onSelect={handleSelectPaper}
        onPrint={(paper, mode) => setPrintTarget({ paper, mode })}
      />
    </>
  );
}
