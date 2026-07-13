import { useEffect } from "react";
import { useTranslation } from "react-i18next";
import { useAuth } from "../auth/AuthContext";
import type { GeneratedPaper, Question, QuestionPaper } from "../types/questionPaper";
import { McqOptionsView } from "./questionPaperShared";

type PrintablePaper = GeneratedPaper | QuestionPaper;

export function QuestionPaperPrintView({
  paper,
  mode,
  centerName,
  onClose,
}: {
  paper: PrintablePaper;
  mode: "paper" | "answer_key";
  centerName?: string;
  onClose?: () => void;
}) {
  const { t } = useTranslation("questionPaper");
  const { user } = useAuth();
  const title = "title" in paper ? paper.title : paper.paper_title;
  const displayCenter = centerName || user?.school_subdomain || t("coachingCenter");

  useEffect(() => {
    document.body.classList.add("qp-print-mode");
    return () => document.body.classList.remove("qp-print-mode");
  }, []);

  function handlePrint() {
    window.print();
  }

  return (
    <div className="qp-print-shell">
      <div className="qp-print-toolbar no-print">
        <button type="button" className="btn-primary" onClick={handlePrint}>
          {mode === "paper" ? t("printPaper") : t("printAnswerKey")}
        </button>
        {onClose ? (
          <button type="button" className="btn-secondary" onClick={onClose}>
            {t("closePrint")}
          </button>
        ) : null}
      </div>

      <article className="qp-print-document">
        <header className="qp-print-header">
          <div className="qp-print-logo" aria-hidden>
            {displayCenter.slice(0, 1).toUpperCase()}
          </div>
          <div>
            <h1>{displayCenter}</h1>
            <p>{title}</p>
            <p className="qp-print-meta">
              {paper.subject} · {paper.class_name} · {t("totalMarksSummary", { marks: paper.total_marks })}
            </p>
          </div>
        </header>

        <div className="qp-print-student-fields">
          <span>{t("studentName")}: ______________________</span>
          <span>{t("rollNumber")}: ______________________</span>
          <span>{t("date")}: ______________________</span>
        </div>

        <ol className="qp-print-questions">
          {paper.questions.map((question, index) => (
            <li key={question.id}>
              <PrintQuestion question={question} index={index} mode={mode} />
            </li>
          ))}
        </ol>

        {mode === "answer_key" ? (
          <footer className="qp-print-footer">
            <p>{t("answerKeyFooter")}</p>
          </footer>
        ) : null}
      </article>
    </div>
  );
}

function PrintQuestion({
  question,
  index,
  mode,
}: {
  question: Question;
  index: number;
  mode: "paper" | "answer_key";
}) {
  const { t } = useTranslation("questionPaper");

  return (
    <div className="qp-print-question">
      <div className="qp-print-question-title">
        <strong>
          {index + 1}. {question.question}
        </strong>
        <span className="qp-print-marks">[{question.marks}]</span>
      </div>

      {question.type === "mcq" && question.options ? <McqOptionsView options={question.options} /> : null}

      {mode === "answer_key" ? (
        <div className="qp-print-answer">
          <strong>{t("answer")}: </strong>
          <span>{question.correct_answer}</span>
          {question.model_answer ? (
            <p className="qp-print-model">
              <strong>{t("modelAnswer")}: </strong>
              {question.model_answer}
            </p>
          ) : null}
        </div>
      ) : null}
    </div>
  );
}
