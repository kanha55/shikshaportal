import i18n from "../i18n";
import {
  normalizeLocale,
  writeStoredLocale,
  type AppLocale,
} from "./localeStorage";

export {
  LOCALE_STORAGE_KEY,
  SUPPORTED_LOCALES,
  isAppLocale,
  readStoredLocale,
  writeStoredLocale,
  normalizeLocale,
  type AppLocale,
} from "./localeStorage";

export function getActiveLocale(): AppLocale {
  return normalizeLocale(i18n.resolvedLanguage ?? i18n.language);
}

export async function applyLocale(locale: AppLocale): Promise<void> {
  writeStoredLocale(locale);
  await i18n.changeLanguage(locale);
}
