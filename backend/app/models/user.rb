# frozen_string_literal: true

class User < ApplicationRecord
  ROLES = %w[super_admin school_admin student].freeze
  BOARDS = %w[cbse state other].freeze

  belongs_to :school, optional: true

  has_secure_password

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :role, inclusion: { in: ROLES }
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

  private

  def normalize_email
    self.email = email.to_s.strip.downcase if email.present?
  end
end
