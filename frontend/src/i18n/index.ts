import i18n from "i18next";
import { initReactI18next } from "react-i18next";
import enAuth from "./locales/en/auth.json";
import enCommon from "./locales/en/common.json";
import enDashboard from "./locales/en/dashboard.json";
import hiAuth from "./locales/hi/auth.json";
import hiCommon from "./locales/hi/common.json";
import hiDashboard from "./locales/hi/dashboard.json";

export const SCHOOL_DEFAULT_LOCALE = "hi";

/** School tenant sites default to Hindi per product requirements. */
export function getSchoolDefaultLocale(): string {
  return SCHOOL_DEFAULT_LOCALE;
}

void i18n.use(initReactI18next).init({
  resources: {
    en: { common: enCommon, auth: enAuth, dashboard: enDashboard },
    hi: { common: hiCommon, auth: hiAuth, dashboard: hiDashboard },
  },
  lng: getSchoolDefaultLocale(),
  fallbackLng: "en",
  defaultNS: "common",
  ns: ["common", "auth", "dashboard"],
  interpolation: { escapeValue: false },
});

i18n.on("languageChanged", (lng) => {
  document.documentElement.lang = lng;
});

export default i18n;
