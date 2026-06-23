export interface PublicSchool {
  id: number;
  name: string;
  subdomain: string;
  address: string | null;
  phone: string | null;
  board: string;
  principal_name: string | null;
  about_us: string | null;
}

export interface PublicNotice {
  id: number;
  title: string;
  body: string;
  published_at: string;
}
