# frozen_string_literal: true

class CreateAiGenerationLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :ai_generation_logs do |t|
      t.references :school, null: false, foreign_key: true
      t.string :category, null: false

      t.timestamps
    end

    add_index :ai_generation_logs, %i[school_id created_at]
  end
end
