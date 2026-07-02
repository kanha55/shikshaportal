import { apiClient } from "./client";
import type { AiGenerateInput, AiGenerateResult } from "../types/ai";

export async function generateAiNotice(input: AiGenerateInput): Promise<AiGenerateResult> {
  const response = await apiClient.post<AiGenerateResult>("/admin/ai/notices", input);
  return response.data;
}
