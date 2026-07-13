import { useTranslation } from "react-i18next";
import type { Question, QuestionType } from "../types/questionPaper";

const TYPE_LABEL_KEYS: Record<QuestionType, string> = {
  mcq: "types.mcq",
  short_answer: "types.shortAnswer",
  long_answer: "types.longAnswer",
  true_false: "types.trueFalse",
  fill_blank: "types.fillBlank",
};

export function questionTypeLabel(type: QuestionType, t: (key: string) => string): string {
  return t(TYPE_LABEL_KEYS[type]);
}

export function nextQuestionId(questions: Question[]): string {
  const numbers = questions
    .map((question) => Number.parseInt(question.id.replace(/\D/g, ""), 10))
    .filter((value) => !Number.isNaN(value));
  const next = numbers.length ? Math.max(...numbers) + 1 : 1;
  return `q${next}`;
}

export function QuestionSkeletonList({ count = 3 }: { count?: number }) {
  return (
    <div className="qp-skeleton-list" aria-hidden>
      {Array.from({ length: count }).map((_, index) => (
        <div key={index} className="qp-skeleton-card">
          <div className="qp-skeleton-line qp-skeleton-line--short" />
          <div className="qp-skeleton-line" />
          <div className="qp-skeleton-line" />
          <div className="qp-skeleton-line qp-skeleton-line--medium" />
        </div>
      ))}
    </div>
  );
}

export function McqOptionsView({ options }: { options: string[] }) {
  return (
    <ul className="qp-mcq-options">
      {options.map((option) => (
        <li key={option}>
          <label className="qp-mcq-option">
            <input type="radio" disabled />
            <span>{option}</span>
          </label>
        </li>
      ))}
    </ul>
  );
}

export function QuestionMetaBadges({
  type,
  marks,
  difficulty,
}: {
  type: QuestionType;
  marks: number;
  difficulty: string;
}) {
  const { t } = useTranslation("questionPaper");

  return (
    <div className="qp-question-badges">
      <span className="qp-badge">{questionTypeLabel(type, t)}</span>
      <span className="qp-badge qp-badge--marks">
        {t("marks", { count: marks })}
      </span>
      <span className="qp-badge qp-badge--difficulty">{difficulty}</span>
    </div>
  );
}
