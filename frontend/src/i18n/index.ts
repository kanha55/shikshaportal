import i18n from "i18next";
import { initReactI18next } from "react-i18next";
import { readStoredLocale } from "../lib/localeStorage";
import enAttendance from "./locales/en/attendance.json";
import enAuth from "./locales/en/auth.json";
import enCommon from "./locales/en/common.json";
import enDashboard from "./locales/en/dashboard.json";
import enFees from "./locales/en/fees.json";
import enNav from "./locales/en/nav.json";
import enNotices from "./locales/en/notices.json";
import enStudents from "./locales/en/students.json";
import hiAttendance from "./locales/hi/attendance.json";
import hiAuth from "./locales/hi/auth.json";
import hiCommon from "./locales/hi/common.json";
import hiDashboard from "./locales/hi/dashboard.json";
import hiFees from "./locales/hi/fees.json";
import hiNav from "./locales/hi/nav.json";
import hiNotices from "./locales/hi/notices.json";
import hiStudents from "./locales/hi/students.json";

export const SCHOOL_DEFAULT_LOCALE = "hi";

const namespaces = [
  "common",
  "auth",
  "dashboard",
  "nav",
  "attendance",
  "notices",
  "fees",
  "students",
] as const;

/** School tenant sites default to Hindi per product requirements. */
export function getSchoolDefaultLocale(): string {
  return SCHOOL_DEFAULT_LOCALE;
}

void i18n.use(initReactI18next).init({
  resources: {
    en: {
      common: enCommon,
      auth: enAuth,
      dashboard: enDashboard,
      nav: enNav,
      attendance: enAttendance,
      notices: enNotices,
      fees: enFees,
      students: enStudents,
    },
    hi: {
      common: hiCommon,
      auth: hiAuth,
      dashboard: hiDashboard,
      nav: hiNav,
      attendance: hiAttendance,
      notices: hiNotices,
      fees: hiFees,
      students: hiStudents,
    },
  },
  lng: readStoredLocale() ?? getSchoolDefaultLocale(),
  fallbackLng: "en",
  defaultNS: "common",
  ns: [...namespaces],
  interpolation: { escapeValue: false },
  returnEmptyString: false,
});

i18n.on("languageChanged", (lng) => {
  document.documentElement.lang = lng;
});

export default i18n;
