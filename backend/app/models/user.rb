# frozen_string_literal: true

class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  ROLES = %w[super_admin school_admin student coaching_admin teacher].freeze

  devise :database_authenticatable, :recoverable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  belongs_to :school, optional: true
  has_many :question_papers, foreign_key: :teacher_id, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :role, inclusion: { in: ROLES }
  validates :language_preference, inclusion: { in: School::LANGUAGES }
  validates :school, presence: true, if: -> { school_admin? || student? || coaching_admin? || teacher? }
  validate :school_must_be_coaching_center, if: -> { coaching_admin? || teacher? }
  validates :roll_number, :class_name, :section, :parent_phone, presence: true, if: :student?
  validates :roll_number, uniqueness: { scope: :school_id }, allow_nil: true, if: :student?

  before_validation :normalize_email

  scope :super_admins, -> { where(role: "super_admin") }
  scope :school_admins, -> { where(role: "school_admin") }
  scope :students, -> { where(role: "student") }
  scope :coaching_admins, -> { where(role: "coaching_admin") }
  scope :teachers, -> { where(role: "teacher") }

  def super_admin?
    role == "super_admin"
  end

  def school_admin?
    role == "school_admin"
  end

  def student?
    role == "student"
  end

  def coaching_admin?
    role == "coaching_admin"
  end

  def teacher?
    role == "teacher"
  end

  def coaching_staff?
    coaching_admin? || teacher?
  end

  private

  def school_must_be_coaching_center
    return if school&.coaching_center?

    errors.add(:school, "must be a coaching center")
  end

  def normalize_email
    self.email = email.to_s.strip.downcase if email.present?
  end
end
