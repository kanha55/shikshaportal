# frozen_string_literal: true

class AiGenerationLog < ApplicationRecord
  belongs_to :school

  validates :category, presence: true
end
