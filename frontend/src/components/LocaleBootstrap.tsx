import { useEffect } from "react";
import { useAuth } from "../auth/AuthContext";
import { fetchPublicSchool } from "../api/public";
import {
  applyLocale,
  normalizeLocale,
  readStoredLocale,
} from "../lib/locale";

/** Applies school default or logged-in user language on first load. */
export function LocaleBootstrap() {
  const { user } = useAuth();

  useEffect(() => {
    if (user) {
      void applyLocale(normalizeLocale(user.language_preference));
      return;
    }

    if (readStoredLocale()) {
      return;
    }

    fetchPublicSchool()
      .then((school) => {
        void applyLocale(normalizeLocale(school.default_language));
      })
      .catch(() => {
        // Non-tenant hosts keep the Hindi default from i18n init
      });
  }, [user]);

  return null;
}
