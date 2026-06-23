# frozen_string_literal: true

class Notice < TenantRecord
  belongs_to :school

  validates :title, presence: true
  validates :body, presence: true
  validates :published_at, presence: true

  scope :published, -> { where("published_at <= ?", Time.current) }
  scope :recent, -> { published.order(published_at: :desc) }
end
