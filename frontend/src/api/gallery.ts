import { apiClient } from "./client";
import type { GalleryPhoto, GalleryPhotoInput } from "../types/gallery";

const MAX_BYTES = 5 * 1024 * 1024;

export async function fetchPublicGalleryPhotos(): Promise<GalleryPhoto[]> {
  const response = await apiClient.get<{ gallery_photos: GalleryPhoto[] }>("/public/gallery_photos");
  return response.data.gallery_photos;
}

export async function fetchAdminGalleryPhotos(): Promise<GalleryPhoto[]> {
  const response = await apiClient.get<{ gallery_photos: GalleryPhoto[] }>("/admin/gallery_photos");
  return response.data.gallery_photos;
}

export async function uploadGalleryPhoto(input: GalleryPhotoInput): Promise<GalleryPhoto> {
  if (input.image.size > MAX_BYTES) {
    throw new Error("FILE_TOO_LARGE");
  }

  const formData = new FormData();
  if (input.caption) {
    formData.append("gallery_photo[caption]", input.caption);
  }
  formData.append("gallery_photo[image]", input.image);

  const response = await apiClient.post<{ gallery_photo: GalleryPhoto }>(
    "/admin/gallery_photos",
    formData
  );
  return response.data.gallery_photo;
}

export async function deleteGalleryPhoto(id: number): Promise<void> {
  await apiClient.delete(`/admin/gallery_photos/${id}`);
}

export async function moveGalleryPhoto(id: number, direction: "up" | "down"): Promise<GalleryPhoto> {
  const response = await apiClient.patch<{ gallery_photo: GalleryPhoto }>(
    `/admin/gallery_photos/${id}/move`,
    { direction }
  );
  return response.data.gallery_photo;
}
