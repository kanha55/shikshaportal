export const LOCALE_STORAGE_KEY = "shikshaportal_locale";
export const SUPPORTED_LOCALES = ["hi", "en"] as const;
export type AppLocale = (typeof SUPPORTED_LOCALES)[number];

export function isAppLocale(value: string): value is AppLocale {
  return SUPPORTED_LOCALES.includes(value as AppLocale);
}

export function readStoredLocale(): AppLocale | null {
  try {
    const stored = localStorage.getItem(LOCALE_STORAGE_KEY);
    if (stored && isAppLocale(stored)) {
      return stored;
    }
  } catch {
    // localStorage unavailable (private browsing)
  }
  return null;
}

export function writeStoredLocale(locale: AppLocale): void {
  try {
    localStorage.setItem(LOCALE_STORAGE_KEY, locale);
  } catch {
    // ignore write failures
  }
}

export function normalizeLocale(value: string | null | undefined): AppLocale {
  if (value && isAppLocale(value)) {
    return value;
  }
  return "hi";
}
