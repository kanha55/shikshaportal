import { apiClient } from "./client";
import type {
  GenerateQuestionPaperInput,
  GenerateQuestionPaperResult,
  QuestionPaper,
  QuestionPaperFilters,
  SaveQuestionPaperInput,
} from "../types/questionPaper";

export async function generateQuestionPaper(
  input: GenerateQuestionPaperInput
): Promise<GenerateQuestionPaperResult> {
  const response = await apiClient.post<GenerateQuestionPaperResult>("/question_papers/generate", input);
  return response.data;
}

export async function saveQuestionPaper(
  input: SaveQuestionPaperInput
): Promise<QuestionPaper> {
  const response = await apiClient.post<{ question_paper: QuestionPaper }>("/question_papers", {
    question_paper: input,
  });
  return response.data.question_paper;
}

export async function fetchQuestionPapers(
  filters: QuestionPaperFilters = {}
): Promise<QuestionPaper[]> {
  const response = await apiClient.get<{ question_papers: QuestionPaper[] }>("/question_papers", {
    params: filters,
  });
  return response.data.question_papers;
}

export async function fetchQuestionPaper(id: number): Promise<QuestionPaper> {
  const response = await apiClient.get<{ question_paper: QuestionPaper }>(`/question_papers/${id}`);
  return response.data.question_paper;
}

export async function updateQuestionPaper(
  id: number,
  input: SaveQuestionPaperInput
): Promise<QuestionPaper> {
  const response = await apiClient.patch<{ question_paper: QuestionPaper }>(`/question_papers/${id}`, {
    question_paper: input,
  });
  return response.data.question_paper;
}

export async function deleteQuestionPaper(id: number): Promise<void> {
  await apiClient.delete(`/question_papers/${id}`);
}
