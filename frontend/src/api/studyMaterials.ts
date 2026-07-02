import { apiClient } from "./client";
import type { StudyMaterial, StudyMaterialInput } from "../types/studyMaterial";

export async function fetchAdminStudyMaterials(): Promise<StudyMaterial[]> {
  const response = await apiClient.get<{ study_materials: StudyMaterial[] }>("/admin/study_materials");
  return response.data.study_materials;
}

export async function fetchStudentStudyMaterials(): Promise<StudyMaterial[]> {
  const response = await apiClient.get<{ study_materials: StudyMaterial[] }>("/study_materials");
  return response.data.study_materials;
}

export async function uploadStudyMaterial(input: StudyMaterialInput): Promise<StudyMaterial> {
  const formData = new FormData();
  formData.append("study_material[title]", input.title);
  formData.append("study_material[class_name]", input.class_name);
  formData.append("study_material[subject]", input.subject);
  formData.append("study_material[file]", input.file);

  const response = await apiClient.post<{ study_material: StudyMaterial }>(
    "/admin/study_materials",
    formData,
    { headers: { "Content-Type": "multipart/form-data" } }
  );
  return response.data.study_material;
}

export async function deleteStudyMaterial(id: number): Promise<void> {
  await apiClient.delete(`/admin/study_materials/${id}`);
}
