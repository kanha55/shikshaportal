import { useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import type { StudentRecord } from "../types/student";

const PAGE_SIZES = [10, 25, 50] as const;

function compareRoll(a: string, b: string) {
  const numA = Number.parseInt(a, 10);
  const numB = Number.parseInt(b, 10);
  if (!Number.isNaN(numA) && !Number.isNaN(numB)) return numA - numB;
  return a.localeCompare(b, undefined, { numeric: true, sensitivity: "base" });
}

function sortStudents(rows: StudentRecord[]) {
  return [...rows].sort((a, b) => {
    const byClass = a.class_name.localeCompare(b.class_name, undefined, { numeric: true });
    if (byClass !== 0) return byClass;
    const bySection = a.section.localeCompare(b.section, undefined, { numeric: true });
    if (bySection !== 0) return bySection;
    return compareRoll(a.roll_number, b.roll_number);
  });
}

function matchesSearch(student: StudentRecord, query: string) {
  if (!query) return true;
  const haystack = [
    student.name,
    student.roll_number,
    student.class_name,
    student.section,
    student.parent_phone,
    student.email,
  ]
    .join(" ")
    .toLowerCase();
  return haystack.includes(query);
}

export function StudentListTable({ students }: { students: StudentRecord[] }) {
  const { t } = useTranslation(["students", "common"]);
  const [search, setSearch] = useState("");
  const [classFilter, setClassFilter] = useState("");
  const [sectionFilter, setSectionFilter] = useState("");
  const [pageSize, setPageSize] = useState<(typeof PAGE_SIZES)[number]>(10);
  const [page, setPage] = useState(1);

  const searchQuery = search.trim().toLowerCase();

  const classOptions = useMemo(() => {
    const values = new Set(students.map((s) => s.class_name));
    return Array.from(values).sort((a, b) => a.localeCompare(b, undefined, { numeric: true }));
  }, [students]);

  const sectionOptions = useMemo(() => {
    const pool = classFilter
      ? students.filter((s) => s.class_name === classFilter)
      : students;
    const values = new Set(pool.map((s) => s.section));
    return Array.from(values).sort((a, b) => a.localeCompare(b, undefined, { numeric: true }));
  }, [students, classFilter]);

  const filtered = useMemo(() => {
    return sortStudents(
      students.filter((student) => {
        if (classFilter && student.class_name !== classFilter) return false;
        if (sectionFilter && student.section !== sectionFilter) return false;
        return matchesSearch(student, searchQuery);
      })
    );
  }, [students, classFilter, sectionFilter, searchQuery]);

  const totalPages = Math.max(1, Math.ceil(filtered.length / pageSize));
  const safePage = Math.min(page, totalPages);
  const pageStart = (safePage - 1) * pageSize;
  const pageRows = filtered.slice(pageStart, pageStart + pageSize);

  const hasFilters = Boolean(searchQuery || classFilter || sectionFilter);

  function handleClassChange(value: string) {
    setClassFilter(value);
    setSectionFilter("");
    setPage(1);
  }

  function handleSectionChange(value: string) {
    setSectionFilter(value);
    setPage(1);
  }

  function handleSearchChange(value: string) {
    setSearch(value);
    setPage(1);
  }

  function clearFilters() {
    setSearch("");
    setClassFilter("");
    setSectionFilter("");
    setPage(1);
  }

  if (students.length === 0) {
    return <p className="muted">{t("students:noStudents")}</p>;
  }

  return (
    <div className="student-list-table-wrap">
      <div className="student-filters">
        <label className="student-filter-search">
          {t("students:searchLabel")}
          <input
            type="search"
            value={search}
            onChange={(e) => handleSearchChange(e.target.value)}
            placeholder={t("students:searchPlaceholder")}
          />
        </label>

        <label>
          {t("students:className")}
          <select value={classFilter} onChange={(e) => handleClassChange(e.target.value)}>
            <option value="">{t("students:filterAllClasses")}</option>
            {classOptions.map((value) => (
              <option key={value} value={value}>
                {value}
              </option>
            ))}
          </select>
        </label>

        <label>
          {t("students:section")}
          <select value={sectionFilter} onChange={(e) => handleSectionChange(e.target.value)}>
            <option value="">{t("students:filterAllSections")}</option>
            {sectionOptions.map((value) => (
              <option key={value} value={value}>
                {value}
              </option>
            ))}
          </select>
        </label>

        {hasFilters && (
          <button type="button" className="secondary-button student-clear-filters" onClick={clearFilters}>
            {t("students:clearFilters")}
          </button>
        )}
      </div>

      <p className="student-list-summary muted">
        {filtered.length === 0
          ? t("students:noMatches")
          : t("students:showingCount", {
              from: pageStart + 1,
              to: Math.min(pageStart + pageSize, filtered.length),
              total: filtered.length,
            })}
      </p>

      {filtered.length > 0 && (
        <>
          <div className="student-table-scroll">
            <table className="student-table">
              <thead>
                <tr>
                  <th>{t("students:rollNumber")}</th>
                  <th>{t("students:name")}</th>
                  <th>{t("students:className")}</th>
                  <th>{t("students:section")}</th>
                  <th>{t("students:parentPhone")}</th>
                  <th>{t("students:email")}</th>
                </tr>
              </thead>
              <tbody>
                {pageRows.map((student) => (
                  <tr key={student.id}>
                    <td data-label={t("students:rollNumber")}>{student.roll_number}</td>
                    <td data-label={t("students:name")}>{student.name}</td>
                    <td data-label={t("students:className")}>{student.class_name}</td>
                    <td data-label={t("students:section")}>{student.section}</td>
                    <td data-label={t("students:parentPhone")}>{student.parent_phone}</td>
                    <td data-label={t("students:email")}>{student.email || "—"}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="student-pagination">
            <label className="student-page-size">
              {t("students:perPage")}
              <select
                value={pageSize}
                onChange={(e) => {
                  setPageSize(Number(e.target.value) as (typeof PAGE_SIZES)[number]);
                  setPage(1);
                }}
              >
                {PAGE_SIZES.map((size) => (
                  <option key={size} value={size}>
                    {size}
                  </option>
                ))}
              </select>
            </label>

            <div className="student-page-controls">
              <button
                type="button"
                className="secondary-button"
                disabled={safePage <= 1}
                onClick={() => setPage((p) => p - 1)}
              >
                {t("students:prevPage")}
              </button>
              <span className="student-page-indicator">
                {t("students:pageOf", { page: safePage, total: totalPages })}
              </span>
              <button
                type="button"
                className="secondary-button"
                disabled={safePage >= totalPages}
                onClick={() => setPage((p) => p + 1)}
              >
                {t("students:nextPage")}
              </button>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
