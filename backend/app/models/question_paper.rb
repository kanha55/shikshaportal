# frozen_string_literal: true

class QuestionPaper < TenantRecord
  DIFFICULTIES = %w[easy medium hard mixed].freeze
  LANGUAGES = %w[en hi both].freeze
  QUESTION_TYPES = %w[mcq short_answer long_answer true_false fill_blank].freeze

  belongs_to :school
  belongs_to :teacher, class_name: "User"

  validates :title, :subject, :class_name, :topic, :total_marks, presence: true
  validates :difficulty, inclusion: { in: DIFFICULTIES }
  validates :language, inclusion: { in: LANGUAGES }
  validates :total_marks, numericality: { greater_than: 0, less_than_or_equal_to: 500 }
  validate :questions_must_be_array

  scope :recent, -> { order(created_at: :desc) }
  scope :for_teacher, ->(teacher_id) { where(teacher_id: teacher_id) }
  scope :filter_by_subject, ->(subject) { where("LOWER(subject) = ?", subject.to_s.downcase) if subject.present? }
  scope :filter_by_class_name, ->(class_name) { where(class_name: class_name) if class_name.present? }
  scope :filter_by_date, lambda { |date|
    return all if date.blank?

    begin
      day = Date.parse(date.to_s)
      where(created_at: day.beginning_of_day..day.end_of_day)
    rescue ArgumentError
      all
    end
  }

  def self.auto_title(subject:, class_name:, topic:)
    date = Time.current.strftime("%d %b %Y")
    "#{subject} — #{class_name} — #{topic} (#{date})"
  end

  private

  def questions_must_be_array
    return if questions.is_a?(Array)

    errors.add(:questions, "must be an array")
  end
end
