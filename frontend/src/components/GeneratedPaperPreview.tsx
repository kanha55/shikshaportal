import { useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import type { GeneratedPaper, Question, QuestionType } from "../types/questionPaper";
import {
  McqOptionsView,
  QuestionMetaBadges,
  nextQuestionId,
  questionTypeLabel,
} from "./questionPaperShared";

interface EditableQuestion extends Question {
  isEditing?: boolean;
}

export function GeneratedPaperPreview({
  paper,
  onChange,
  onRegenerate,
  onSave,
  saving,
  saveError,
}: {
  paper: GeneratedPaper;
  onChange: (paper: GeneratedPaper) => void;
  onRegenerate: () => void;
  onSave: () => void;
  saving?: boolean;
  saveError?: string | null;
}) {
  const { t } = useTranslation("questionPaper");
  const [questions, setQuestions] = useState<EditableQuestion[]>(paper.questions);

  const totalMarks = useMemo(
    () => questions.reduce((sum, question) => sum + (question.marks || 0), 0),
    [questions]
  );

  function syncPaper(nextQuestions: EditableQuestion[]) {
    setQuestions(nextQuestions);
    onChange({
      ...paper,
      questions: nextQuestions.map(({ isEditing: _ignored, ...question }) => question),
      total_marks: nextQuestions.reduce((sum, q) => sum + (q.marks || 0), 0),
    });
  }

  function toggleEdit(id: string) {
    syncPaper(
      questions.map((question) =>
        question.id === id ? { ...question, isEditing: !question.isEditing } : question
      )
    );
  }

  function updateQuestion(id: string, patch: Partial<Question>) {
    syncPaper(
      questions.map((question) => (question.id === id ? { ...question, ...patch } : question))
    );
  }

  function removeQuestion(id: string) {
    syncPaper(questions.filter((question) => question.id !== id));
  }

  function addQuestion() {
    const id = nextQuestionId(questions);
    const newQuestion: EditableQuestion = {
      id,
      type: "short_answer",
      question: "",
      correct_answer: "",
      model_answer: "",
      marks: 1,
      difficulty: "medium",
      isEditing: true,
    };
    syncPaper([...questions, newQuestion]);
  }

  return (
    <section className="panel qp-preview">
      <div className="panel-header">
        <div>
          <h2>{paper.paper_title}</h2>
          <p className="muted">
            {paper.subject} · {paper.class_name} · {paper.topic}
          </p>
          <p className="muted">
            {t("totalMarksSummary", { marks: totalMarks })}
          </p>
        </div>
      </div>

      {questions.length === 0 ? (
        <p className="muted qp-empty">{t("noQuestions")}</p>
      ) : (
        <ol className="qp-question-list">
          {questions.map((question, index) => (
            <li key={question.id} className="qp-question-card">
              <div className="qp-question-header">
                <strong>
                  {t("questionNumber", { number: index + 1 })}
                </strong>
                <QuestionMetaBadges
                  type={question.type}
                  marks={question.marks}
                  difficulty={question.difficulty}
                />
                <button
                  type="button"
                  className="qp-icon-btn"
                  onClick={() => toggleEdit(question.id)}
                  aria-label={t("editQuestion")}
                >
                  ✎
                </button>
                <button
                  type="button"
                  className="qp-icon-btn qp-icon-btn--danger"
                  onClick={() => removeQuestion(question.id)}
                  aria-label={t("removeQuestion")}
                >
                  ×
                </button>
              </div>

              {question.isEditing ? (
                <QuestionEditor
                  question={question}
                  onChange={(patch) => updateQuestion(question.id, patch)}
                  onDone={() => toggleEdit(question.id)}
                />
              ) : (
                <QuestionViewer question={question} />
              )}
            </li>
          ))}
        </ol>
      )}

      <div className="qp-actions">
        <button type="button" className="btn-secondary" onClick={addQuestion}>
          {t("addQuestion")}
        </button>
        <button type="button" className="btn-secondary" onClick={onRegenerate}>
          {t("regenerate")}
        </button>
        <button type="button" className="btn-primary" onClick={onSave} disabled={saving || questions.length === 0}>
          {saving ? t("saving") : t("savePaper")}
        </button>
      </div>

      {saveError ? <p className="error-banner">{saveError}</p> : null}
    </section>
  );
}

function QuestionViewer({ question }: { question: Question }) {
  const { t } = useTranslation("questionPaper");

  return (
    <div className="qp-question-body">
      <p>{question.question}</p>
      {question.type === "mcq" && question.options ? <McqOptionsView options={question.options} /> : null}
      {question.type !== "mcq" && question.model_answer ? (
        <p className="muted qp-model-answer">
          <span>{t("modelAnswer")}: </span>
          {question.model_answer}
        </p>
      ) : null}
    </div>
  );
}

function QuestionEditor({
  question,
  onChange,
  onDone,
}: {
  question: Question;
  onChange: (patch: Partial<Question>) => void;
  onDone: () => void;
}) {
  const { t } = useTranslation("questionPaper");

  return (
    <div className="qp-question-editor">
      <label>
        {t("questionText")}
        <textarea
          value={question.question}
          onChange={(e) => onChange({ question: e.target.value })}
          rows={3}
        />
      </label>

      <div className="qp-form-grid">
        <label>
          {t("questionType")}
          <select
            value={question.type}
            onChange={(e) => onChange({ type: e.target.value as QuestionType })}
          >
            {(["mcq", "short_answer", "long_answer", "true_false", "fill_blank"] as QuestionType[]).map(
              (type) => (
                <option key={type} value={type}>
                  {questionTypeLabel(type, t)}
                </option>
              )
            )}
          </select>
        </label>
        <label>
          {t("marksLabel")}
          <input
            type="number"
            min={1}
            value={question.marks}
            onChange={(e) => onChange({ marks: Number(e.target.value) })}
          />
        </label>
      </div>

      {question.type === "mcq" ? (
        <>
          {(question.options ?? ["", "", "", ""]).map((option, index) => (
            <label key={index}>
              {t("optionLabel", { letter: String.fromCharCode(65 + index) })}
              <input
                value={option}
                onChange={(e) => {
                  const next = [...(question.options ?? ["", "", "", ""])];
                  next[index] = e.target.value;
                  onChange({ options: next });
                }}
              />
            </label>
          ))}
          <label>
            {t("correctAnswer")}
            <input
              value={question.correct_answer}
              onChange={(e) => onChange({ correct_answer: e.target.value })}
            />
          </label>
        </>
      ) : (
        <>
          <label>
            {t("correctAnswer")}
            <input
              value={question.correct_answer}
              onChange={(e) => onChange({ correct_answer: e.target.value })}
            />
          </label>
          {question.type !== "true_false" ? (
            <label>
              {t("modelAnswer")}
              <textarea
                value={question.model_answer ?? ""}
                onChange={(e) => onChange({ model_answer: e.target.value })}
                rows={3}
              />
            </label>
          ) : null}
        </>
      )}

      <button type="button" className="btn-secondary" onClick={onDone}>
        {t("doneEditing")}
      </button>
    </div>
  );
}
