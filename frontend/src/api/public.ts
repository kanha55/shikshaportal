import { apiClient } from "./client";
import type { PublicNotice, PublicSchool } from "../types/public";

export async function fetchPublicSchool(): Promise<PublicSchool> {
  const response = await apiClient.get<PublicSchool>("/public/school");
  return response.data;
}

export async function fetchPublicNotices(): Promise<PublicNotice[]> {
  const response = await apiClient.get<{ notices: PublicNotice[] }>("/public/notices");
  return response.data.notices;
}
