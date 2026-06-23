export interface Notice {
  id: number;
  title: string;
  body: string;
  published_at: string;
}

export interface NoticeInput {
  title: string;
  body: string;
  published_at?: string;
}
