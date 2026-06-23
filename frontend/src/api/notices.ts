import { apiClient } from "./client";
import type { Notice, NoticeInput } from "../types/notice";

export async function fetchAdminNotices(): Promise<Notice[]> {
  const response = await apiClient.get<{ notices: Notice[] }>("/admin/notices");
  return response.data.notices;
}

export async function fetchSchoolNotices(): Promise<Notice[]> {
  const response = await apiClient.get<{ notices: Notice[] }>("/notices");
  return response.data.notices;
}

export async function createNotice(input: NoticeInput): Promise<Notice> {
  const response = await apiClient.post<{ notice: Notice }>("/admin/notices", { notice: input });
  return response.data.notice;
}

export async function updateNotice(id: number, input: Partial<NoticeInput>): Promise<Notice> {
  const response = await apiClient.patch<{ notice: Notice }>(`/admin/notices/${id}`, {
    notice: input,
  });
  return response.data.notice;
}

export async function deleteNotice(id: number): Promise<void> {
  await apiClient.delete(`/admin/notices/${id}`);
}
