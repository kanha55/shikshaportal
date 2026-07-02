# frozen_string_literal: true

class StudyMaterial < TenantRecord
  belongs_to :school
  has_one_attached :file

  ALLOWED_CONTENT_TYPES = %w[application/pdf].freeze
  MAX_FILE_SIZE = 10.megabytes

  validates :title, :class_name, :subject, presence: true
  validate :acceptable_file, if: -> { file.attached? }

  scope :for_class, ->(class_name) { where(class_name: class_name) }
  scope :recent, -> { order(created_at: :desc) }

  private

  def acceptable_file
    unless ALLOWED_CONTENT_TYPES.include?(file.blob.content_type)
      errors.add(:file, "must be a PDF")
      return
    end

    return if file.blob.byte_size <= MAX_FILE_SIZE

    errors.add(:file, "must be smaller than 10 MB")
  end
end
