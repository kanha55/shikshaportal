# frozen_string_literal: true

module StudyMaterialSerializer
  module_function

  def serialize(material, request:)
    {
      id: material.id,
      title: material.title,
      class_name: material.class_name,
      subject: material.subject,
      filename: material.file.filename.to_s,
      byte_size: material.file.byte_size,
      content_type: material.file.content_type,
      download_url: blob_download_url(material, request),
      created_at: material.created_at.iso8601
    }
  end

  def blob_download_url(material, request)
    Rails.application.routes.url_helpers.rails_blob_url(
      material.file,
      host: request.host,
      port: request.port,
      protocol: request.protocol.delete_suffix("://"),
      disposition: "attachment"
    )
  end
end
