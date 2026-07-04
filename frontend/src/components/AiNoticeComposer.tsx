import { useState, type FormEvent } from "react";
import { useTranslation } from "react-i18next";
import axios from "axios";
import { generateAiNotice } from "../api/ai";
import { createNotice } from "../api/notices";
import type { AiGenerateInput } from "../types/ai";

const CATEGORIES: AiGenerateInput["category"][] = ["holiday", "fee", "exam", "event"];

function extractApiError(err: unknown, fallback: string): string {
  if (!axios.isAxiosError(err)) return fallback;
  const data = err.response?.data as { errors?: string[]; error?: string } | undefined;
  if (data?.errors?.length) return data.errors.join(", ");
  if (data?.error) return data.error;
  return fallback;
}

export function AiNoticeComposer({ onPosted }: { onPosted?: () => void }) {
  const { t, i18n } = useTranslation(["ai", "common"]);
  const [roughInput, setRoughInput] = useState("");
  const [category, setCategory] = useState<AiGenerateInput["category"]>("holiday");
  const [bilingual, setBilingual] = useState(false);
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [whatsapp, setWhatsapp] = useState("");
  const [usage, setUsage] = useState<{ today: number; limit: number } | null>(null);
  const [generating, setGenerating] = useState(false);
  const [posting, setPosting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);

  const hasDraft = Boolean(title || body || whatsapp);

  async function handleGenerate(event: FormEvent) {
    event.preventDefault();
    setGenerating(true);
    setError(null);
    setCopied(false);

    try {
      const result = await generateAiNotice({
        rough_input: roughInput,
        category,
        bilingual,
        language: i18n.language === "en" ? "en" : "hi",
      });
      setTitle(result.generated.notice_title);
      setBody(result.generated.notice_body);
      setWhatsapp(result.generated.whatsapp_message);
      setUsage(result.usage);
    } catch (err) {
      if (axios.isAxiosError(err) && err.response?.status === 429) {
        setError(t("ai:limitReached"));
      } else {
        setError(extractApiError(err, t("ai:generateFailed")));
      }
    } finally {
      setGenerating(false);
    }
  }

  async function handlePost() {
    setPosting(true);
    setError(null);
    try {
      await createNotice({ title, body });
      setRoughInput("");
      setTitle("");
      setBody("");
      setWhatsapp("");
      onPosted?.();
    } catch (err) {
      setError(extractApiError(err, t("ai:postFailed")));
    } finally {
      setPosting(false);
    }
  }

  async function handleCopyWhatsapp() {
    try {
      await navigator.clipboard.writeText(whatsapp);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      setError(t("ai:generateFailed"));
    }
  }

  return (
    <section className="panel ai-composer">
      <div className="panel-header">
        <div className="panel-icon ai-panel-icon" aria-hidden>
          AI
        </div>
        <div>
          <h2>{t("ai:panelTitle")}</h2>
          <p className="muted">{t("ai:panelHint")}</p>
        </div>
      </div>

      <form onSubmit={handleGenerate}>
        <label>
          {t("ai:roughInput")}
          <textarea
            value={roughInput}
            onChange={(e) => setRoughInput(e.target.value)}
            placeholder={t("ai:roughInputPlaceholder")}
            rows={3}
            required
          />
        </label>

        <div className="ai-composer-options">
          <label>
            {t("ai:category")}
            <select value={category} onChange={(e) => setCategory(e.target.value as AiGenerateInput["category"])}>
              {CATEGORIES.map((value) => (
                <option key={value} value={value}>
                  {t(`ai:categories.${value}`)}
                </option>
              ))}
            </select>
          </label>

          <label className="ai-bilingual-toggle">
            <input
              type="checkbox"
              checked={bilingual}
              onChange={(e) => setBilingual(e.target.checked)}
            />
            {t("ai:bilingualOutput")}
          </label>
        </div>

        {error && <p className="error">{error}</p>}

        <div className="notice-form-actions">
          <button type="submit" disabled={generating || !roughInput.trim()}>
            {generating ? t("ai:generating") : t("ai:generate")}
          </button>
        </div>
      </form>

      {usage && (
        <p className="muted ai-usage">
          {t("ai:usageToday", { used: usage.today, limit: usage.limit })}
        </p>
      )}

      {hasDraft && (
        <div className="panel-subsection ai-draft">
          <label>
            {t("ai:noticeTitle")}
            <input value={title} onChange={(e) => setTitle(e.target.value)} required />
          </label>
          <label>
            {t("ai:noticeBody")}
            <textarea value={body} onChange={(e) => setBody(e.target.value)} rows={5} required />
          </label>
          <label>
            {t("ai:whatsappMessage")}
            <textarea value={whatsapp} onChange={(e) => setWhatsapp(e.target.value)} rows={3} required />
          </label>

          <div className="notice-form-actions">
            <button type="button" onClick={handlePost} disabled={posting || !title.trim() || !body.trim()}>
              {posting ? t("ai:posting") : t("ai:postToBoard")}
            </button>
            <button type="button" className="secondary-button" onClick={handleCopyWhatsapp} disabled={!whatsapp.trim()}>
              {copied ? t("ai:copied") : t("ai:copyWhatsapp")}
            </button>
          </div>
        </div>
      )}
    </section>
  );
}
