# frozen_string_literal: true

class CreateQuestionPaperGenerationLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :question_paper_generation_logs do |t|
      t.references :school, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :question_paper_generation_logs, %i[school_id created_at]
  end
end
