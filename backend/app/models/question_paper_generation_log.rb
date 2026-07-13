# frozen_string_literal: true

class QuestionPaperGenerationLog < ApplicationRecord
  belongs_to :school
  belongs_to :user

  validates :school, :user, presence: true
end
