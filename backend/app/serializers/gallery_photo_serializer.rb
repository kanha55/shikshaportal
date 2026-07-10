# frozen_string_literal: true

module GalleryPhotoSerializer
  module_function

  def serialize(photo, request:)
    return nil unless photo.image.attached?

    {
      id: photo.id,
      position: photo.position,
      caption: photo.caption,
      filename: photo.image.filename.to_s,
      byte_size: photo.image.byte_size,
      content_type: photo.image.content_type,
      image_url: blob_url(photo, request),
      created_at: photo.created_at.iso8601
    }
  end

  def blob_url(photo, request)
    Rails.application.routes.url_helpers.rails_blob_url(
      photo.image,
      host: request.host,
      protocol: request.ssl? ? "https" : "http"
    )
  end
end
