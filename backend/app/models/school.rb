# frozen_string_literal: true

class School < ApplicationRecord
  BOARDS = %w[cbse state other].freeze
  LANGUAGES = %w[hi en].freeze

  has_many :users, dependent: :destroy
  has_many :notices, dependent: :destroy
  has_many :ai_generation_logs, dependent: :destroy
  has_many :study_materials, dependent: :destroy
  has_many :student_imports, dependent: :destroy

  validates :name, presence: true
  validates :subdomain, presence: true,
                        uniqueness: { case_sensitive: false },
                        format: { with: /\A[a-z0-9-]+\z/, message: "only lowercase letters, numbers, and hyphens" }
  validates :principal_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :board, inclusion: { in: BOARDS }, allow_nil: true
  validates :default_language, inclusion: { in: LANGUAGES }

  before_validation :normalize_subdomain

  private

  def normalize_subdomain
    self.subdomain = subdomain.to_s.strip.downcase if subdomain.present?
  end
end
