export type UserRole = "super_admin" | "school_admin" | "student";

export interface User {
  id: number;
  email: string;
  name: string;
  role: UserRole;
  language_preference: string;
  school_id: number | null;
  school_subdomain: string | null;
}

export interface LoginResponse {
  user: User;
}
