# frozen_string_literal: true

class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  ROLES = %w[super_admin school_admin student].freeze

  devise :database_authenticatable, :recoverable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  belongs_to :school, optional: true

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :role, inclusion: { in: ROLES }
  validates :language_preference, inclusion: { in: School::LANGUAGES }
  validates :school, presence: true, if: -> { school_admin? || student? }

  before_validation :normalize_email

  scope :super_admins, -> { where(role: "super_admin") }
  scope :school_admins, -> { where(role: "school_admin") }

  def super_admin?
    role == "super_admin"
  end

  def school_admin?
    role == "school_admin"
  end

  def student?
    role == "student"
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase if email.present?
  end
end
