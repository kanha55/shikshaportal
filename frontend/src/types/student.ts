export interface StudentRecord {
  id: number;
  name: string;
  email: string;
  roll_number: string;
  class_name: string;
  section: string;
  parent_phone: string;
}

export interface ImportError {
  line: number;
  roll_number: string | null;
  error: string;
}

export interface StudentImportResult {
  import_id?: number;
  status: string;
  created_count: number;
  emails_sent: number;
  errors: ImportError[];
  created: StudentRecord[];
  error_message?: string | null;
}

export interface StudentInput {
  name: string;
  roll_number: string;
  class_name: string;
  section: string;
  parent_phone: string;
  email?: string;
}

export interface StudentCreateResult {
  student: StudentRecord;
  message: string;
}
