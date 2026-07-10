# frozen_string_literal: true

Rails.application.config.after_initialize do
  next unless Rails.env.production?
  next unless ActiveStorage::Blob.service.is_a?(ActiveStorage::Service::DiskService)

  FileUtils.mkdir_p(ActiveStorage::Blob.service.root)
end
