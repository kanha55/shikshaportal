import { useState, type FormEvent } from "react";
import { useTranslation } from "react-i18next";
import axios from "axios";
import { generateQuestionPaper } from "../api/questionPapers";
import type {
  GenerateQuestionPaperInput,
  GeneratedPaper,
  PaperDifficulty,
  PaperLanguage,
  QuestionCounts,
} from "../types/questionPaper";
import { QuestionSkeletonList } from "./questionPaperShared";

const DEFAULT_COUNTS: QuestionCounts = {
  mcq: 5,
  short_answer: 2,
  long_answer: 1,
  true_false: 2,
  fill_blank: 0,
};

function extractApiError(err: unknown, fallback: string): string {
  if (!axios.isAxiosError(err)) return fallback;
  const data = err.response?.data as { errors?: string[]; error?: string } | undefined;
  if (data?.errors?.length) return data.errors.join(", ");
  if (data?.error) return data.error;
  return fallback;
}

export function QuestionPaperGenerator({
  onGenerated,
}: {
  onGenerated: (paper: GeneratedPaper, usage: { this_hour: number; limit: number }) => void;
}) {
  const { t } = useTranslation("questionPaper");
  const [subject, setSubject] = useState("");
  const [className, setClassName] = useState("");
  const [topic, setTopic] = useState("");
  const [difficulty, setDifficulty] = useState<PaperDifficulty>("mixed");
  const [totalMarks, setTotalMarks] = useState(50);
  const [language, setLanguage] = useState<PaperLanguage>("en");
  const [instructions, setInstructions] = useState("");
  const [counts, setCounts] = useState<QuestionCounts>(DEFAULT_COUNTS);
  const [enabledTypes, setEnabledTypes] = useState<Record<keyof QuestionCounts, boolean>>({
    mcq: true,
    short_answer: true,
    long_answer: true,
    true_false: true,
    fill_blank: false,
  });
  const [generating, setGenerating] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [usage, setUsage] = useState<{ this_hour: number; limit: number } | null>(null);

  function updateCount(type: keyof QuestionCounts, value: number) {
    setCounts((current) => ({ ...current, [type]: Math.max(0, value) }));
  }

  function toggleType(type: keyof QuestionCounts, checked: boolean) {
    setEnabledTypes((current) => ({ ...current, [type]: checked }));
    if (!checked) updateCount(type, 0);
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setGenerating(true);
    setError(null);

    const question_counts: Partial<QuestionCounts> = {};
    (Object.keys(counts) as Array<keyof QuestionCounts>).forEach((type) => {
      if (enabledTypes[type] && counts[type] > 0) {
        question_counts[type] = counts[type];
      }
    });

    const input: GenerateQuestionPaperInput = {
      subject: subject.trim(),
      class_name: className.trim(),
      topic: topic.trim(),
      question_counts,
      difficulty,
      total_marks: totalMarks,
      language,
      instructions: instructions.trim() || undefined,
    };

    try {
      const result = await generateQuestionPaper(input);
      setUsage(result.usage);
      onGenerated(result.generated, result.usage);
    } catch (err) {
      if (axios.isAxiosError(err) && err.response?.status === 429) {
        setError(t("limitReached"));
      } else {
        setError(extractApiError(err, t("generateFailed")));
      }
    } finally {
      setGenerating(false);
    }
  }

  return (
    <section className="panel qp-generator">
      <div className="panel-header">
        <div className="panel-icon qp-panel-icon" aria-hidden>
          QP
        </div>
        <div>
          <h2>{t("generatorTitle")}</h2>
          <p className="muted">{t("generatorHint")}</p>
        </div>
      </div>

      <form onSubmit={handleSubmit}>
        <div className="qp-form-grid">
          <label>
            {t("subject")}
            <input value={subject} onChange={(e) => setSubject(e.target.value)} required />
          </label>
          <label>
            {t("className")}
            <input
              value={className}
              onChange={(e) => setClassName(e.target.value)}
              placeholder={t("classPlaceholder")}
              required
            />
          </label>
          <label className="qp-form-grid--full">
            {t("topic")}
            <input value={topic} onChange={(e) => setTopic(e.target.value)} required />
          </label>
        </div>

        <fieldset className="qp-fieldset">
          <legend>{t("questionTypes")}</legend>
          <div className="qp-type-grid">
            {(Object.keys(counts) as Array<keyof QuestionCounts>).map((type) => (
              <div key={type} className="qp-type-row">
                <label className="qp-type-checkbox">
                  <input
                    type="checkbox"
                    checked={enabledTypes[type]}
                    onChange={(e) => toggleType(type, e.target.checked)}
                  />
                  <span>{t(`types.${type === "short_answer" ? "shortAnswer" : type === "long_answer" ? "longAnswer" : type === "true_false" ? "trueFalse" : type === "fill_blank" ? "fillBlank" : type}`)}</span>
                </label>
                <input
                  type="number"
                  min={0}
                  max={50}
                  value={counts[type]}
                  disabled={!enabledTypes[type]}
                  onChange={(e) => updateCount(type, Number(e.target.value))}
                />
              </div>
            ))}
          </div>
        </fieldset>

        <div className="qp-form-grid">
          <label>
            {t("difficulty")}
            <select value={difficulty} onChange={(e) => setDifficulty(e.target.value as PaperDifficulty)}>
              <option value="easy">{t("difficultyEasy")}</option>
              <option value="medium">{t("difficultyMedium")}</option>
              <option value="hard">{t("difficultyHard")}</option>
              <option value="mixed">{t("difficultyMixed")}</option>
            </select>
          </label>
          <label>
            {t("totalMarks")}
            <input
              type="number"
              min={1}
              max={500}
              value={totalMarks}
              onChange={(e) => setTotalMarks(Number(e.target.value))}
              required
            />
          </label>
          <label>
            {t("language")}
            <select value={language} onChange={(e) => setLanguage(e.target.value as PaperLanguage)}>
              <option value="en">{t("languageEn")}</option>
              <option value="hi">{t("languageHi")}</option>
              <option value="both">{t("languageBoth")}</option>
            </select>
          </label>
        </div>

        <label>
          {t("instructions")}
          <textarea
            value={instructions}
            onChange={(e) => setInstructions(e.target.value)}
            rows={3}
            placeholder={t("instructionsPlaceholder")}
          />
        </label>

        {usage ? (
          <p className="muted qp-usage">
            {t("usage", { used: usage.this_hour, limit: usage.limit })}
          </p>
        ) : null}

        {error ? <p className="error-banner">{error}</p> : null}

        <div className="qp-actions">
          <button type="submit" className="btn-primary" disabled={generating}>
            {generating ? t("generating") : t("generate")}
          </button>
        </div>
      </form>

      {generating ? <QuestionSkeletonList count={4} /> : null}
    </section>
  );
}
