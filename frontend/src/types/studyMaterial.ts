export interface StudyMaterial {
  id: number;
  title: string;
  class_name: string;
  subject: string;
  filename: string;
  byte_size: number;
  content_type: string;
  download_url: string;
  created_at: string;
}

export interface StudyMaterialInput {
  title: string;
  class_name: string;
  subject: string;
  file: File;
}
