export interface AiGenerateInput {
  rough_input: string;
  category: "holiday" | "fee" | "exam" | "event";
  bilingual?: boolean;
  language?: "hi" | "en";
}

export interface AiGeneratedNotice {
  notice_title: string;
  notice_body: string;
  whatsapp_message: string;
}

export interface AiGenerateResult {
  generated: AiGeneratedNotice;
  usage: {
    today: number;
    limit: number;
  };
}
