# frozen_string_literal: true

class GalleryPhoto < TenantRecord
  belongs_to :school
  has_one_attached :image

  MAX_PER_SCHOOL = 6
  ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
  MAX_FILE_SIZE = 5.megabytes

  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validate :school_photo_limit, on: :create
  validate :acceptable_image, if: -> { image.attached? }

  scope :ordered, -> { order(:position) }

  before_validation :assign_position, on: :create

  def move(direction)
    neighbor = case direction.to_s
               when "up"
                 self.class.where(school_id: school_id).where("position < ?", position).order(position: :desc).first
               when "down"
                 self.class.where(school_id: school_id).where("position > ?", position).order(:position).first
               end
    return false unless neighbor

    self.class.transaction do
      my_pos = position
      other_pos = neighbor.position
      temp = (self.class.where(school_id: school_id).maximum(:position) || 0) + 1000
      update_column(:position, temp)
      neighbor.update_column(:position, my_pos)
      update_column(:position, other_pos)
    end
    true
  end

  private

  def assign_position
    return if position.present?

    self.position = (self.class.where(school_id: school_id).maximum(:position) || 0) + 1
  end

  def school_photo_limit
    return unless school_id

    count = self.class.where(school_id: school_id).count
    return if count < MAX_PER_SCHOOL

    errors.add(:base, "cannot exceed #{MAX_PER_SCHOOL} gallery photos per school")
  end

  def acceptable_image
    unless image.attached?
      errors.add(:image, "must be attached")
      return
    end

    unless ALLOWED_CONTENT_TYPES.include?(image.blob.content_type)
      errors.add(:image, "must be a JPEG, PNG, or WebP image")
      return
    end

    return if image.blob.byte_size <= MAX_FILE_SIZE

    errors.add(:image, "must be smaller than 5 MB")
  end
end
