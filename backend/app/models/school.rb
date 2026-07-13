# frozen_string_literal: true

class School < ApplicationRecord
  # Coaching centers are stored as School records with institution_type = "coaching".
  # acts_as_tenant uses School as the tenant model for both schools and coaching centers.
  INSTITUTION_TYPES = %w[school coaching].freeze
  BOARDS = %w[cbse state other].freeze
  LANGUAGES = %w[hi en].freeze

  has_many :users, dependent: :destroy
  has_many :notices, dependent: :destroy
  has_many :ai_generation_logs, dependent: :destroy
  has_many :study_materials, dependent: :destroy
  has_many :gallery_photos, dependent: :destroy
  has_many :question_papers, dependent: :destroy
  has_many :question_paper_generation_logs, dependent: :destroy

  validates :name, presence: true
  validates :institution_type, inclusion: { in: INSTITUTION_TYPES }
  validates :subdomain, presence: true,
                        uniqueness: { case_sensitive: false },
                        format: { with: /\A[a-z0-9-]+\z/, message: :invalid }
  validates :principal_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :board, inclusion: { in: BOARDS }, allow_nil: true
  validates :default_language, inclusion: { in: LANGUAGES }

  before_validation :normalize_subdomain

  def coaching_center?
    institution_type == "coaching"
  end

  def school?
    institution_type == "school"
  end

  private

  def normalize_subdomain
    self.subdomain = subdomain.to_s.strip.downcase if subdomain.present?
  end
end
