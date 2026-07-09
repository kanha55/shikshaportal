export type GalleryPhoto = {
  id: number;
  position: number;
  caption: string | null;
  filename: string;
  byte_size: number;
  content_type: string;
  image_url: string;
  created_at: string;
};

export type GalleryPhotoInput = {
  caption?: string;
  image: File;
};
