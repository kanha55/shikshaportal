export type QuestionType =
  | "mcq"
  | "short_answer"
  | "long_answer"
  | "true_false"
  | "fill_blank";

export type QuestionDifficulty = "easy" | "medium" | "hard";
export type PaperDifficulty = QuestionDifficulty | "mixed";
export type PaperLanguage = "en" | "hi" | "both";

export interface Question {
  id: string;
  type: QuestionType;
  question: string;
  options?: string[];
  correct_answer: string;
  model_answer?: string;
  marks: number;
  difficulty: QuestionDifficulty;
}

export interface GeneratedPaper {
  paper_title: string;
  subject: string;
  class_name: string;
  topic: string;
  total_marks: number;
  language: PaperLanguage;
  difficulty: PaperDifficulty;
  questions: Question[];
}

export interface QuestionPaper extends GeneratedPaper {
  id: number;
  coaching_center_id: number;
  teacher_id: number;
  teacher_name?: string;
  title: string;
  created_at: string;
  updated_at: string;
}

export interface QuestionCounts {
  mcq: number;
  short_answer: number;
  long_answer: number;
  true_false: number;
  fill_blank: number;
}

export interface GenerateQuestionPaperInput {
  subject: string;
  class_name: string;
  topic: string;
  question_counts: Partial<QuestionCounts>;
  difficulty: PaperDifficulty;
  total_marks: number;
  language: PaperLanguage;
  instructions?: string;
}

export interface GenerateQuestionPaperResult {
  generated: GeneratedPaper;
  usage: {
    this_hour: number;
    limit: number;
  };
}

export interface SaveQuestionPaperInput {
  title?: string;
  subject: string;
  class_name: string;
  topic: string;
  difficulty: PaperDifficulty;
  language: PaperLanguage;
  total_marks: number;
  questions: Question[];
}

export interface QuestionPaperFilters {
  subject?: string;
  class_name?: string;
  date?: string;
}
