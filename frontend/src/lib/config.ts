/** Subdomain-aware API base URL — same hostname as the SPA, Rails on port 3000. */
export function getApiBaseUrl(): string {
  const envUrl = import.meta.env.VITE_API_URL;
  if (envUrl) return envUrl.replace(/\/$/, "");

  const { protocol, hostname } = window.location;
  // Production: same-origin /api/ via nginx (Oracle VM or Railway Docker).
  if (import.meta.env.PROD) {
    return `${protocol}//${hostname}/api/v1`;
  }
  return `${protocol}//${hostname}:3000/api/v1`;
}

export function dashboardPathForRole(role: string): string {
  switch (role) {
    case "super_admin":
      return "/super-admin";
    case "school_admin":
      return "/admin";
    case "student":
      return "/student";
    default:
      return "/login";
  }
}
