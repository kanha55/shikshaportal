import { useTranslation } from "react-i18next";
import { useAuth } from "../auth/AuthContext";
import { updateLanguagePreference } from "../api/auth";
import {
  applyLocale,
  normalizeLocale,
  type AppLocale,
} from "../lib/locale";

export function LanguageToggle() {
  const { t, i18n } = useTranslation("common");
  const { user } = useAuth();
  const current = normalizeLocale(i18n.resolvedLanguage ?? i18n.language);

  async function selectLocale(locale: AppLocale) {
    if (locale === current) return;

    await applyLocale(locale);

    if (user) {
      try {
        await updateLanguagePreference(locale);
      } catch {
        // UI and localStorage already updated; sync can retry on next toggle
      }
    }
  }

  return (
    <div className="language-toggle" role="group" aria-label={t("languageToggle")}>
      <button
        type="button"
        className={current === "hi" ? "active" : undefined}
        aria-pressed={current === "hi"}
        onClick={() => selectLocale("hi")}
      >
        हिंदी
      </button>
      <span className="language-toggle-sep" aria-hidden>
        |
      </span>
      <button
        type="button"
        className={current === "en" ? "active" : undefined}
        aria-pressed={current === "en"}
        onClick={() => selectLocale("en")}
      >
        English
      </button>
    </div>
  );
}
