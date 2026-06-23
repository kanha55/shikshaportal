import { apiClient } from "./client";
import type { LoginResponse, User } from "../types/user";

export async function login(email: string, password: string): Promise<{ user: User; token: string }> {
  const response = await apiClient.post<LoginResponse>(
    "/auth/login",
    { user: { email, password } },
    { withCredentials: true }
  );

  const authHeader = response.headers.authorization ?? response.headers.Authorization;
  const token = typeof authHeader === "string" ? authHeader.replace(/^Bearer\s+/i, "") : "";

  if (!token) {
    throw new Error("No JWT returned from server");
  }

  return { user: response.data.user, token };
}

export async function fetchCurrentUser(): Promise<User> {
  const response = await apiClient.get<{ user: User }>("/auth/me");
  return response.data.user;
}

export async function logout(): Promise<void> {
  await apiClient.delete("/auth/logout");
}
