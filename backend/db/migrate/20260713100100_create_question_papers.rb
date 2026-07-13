# frozen_string_literal: true

class CreateQuestionPapers < ActiveRecord::Migration[7.2]
  def change
    create_table :question_papers do |t|
      t.references :school, null: false, foreign_key: true
      t.references :teacher, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.string :subject, null: false
      t.string :class_name, null: false
      t.string :topic, null: false
      t.string :difficulty, null: false, default: "mixed"
      t.string :language, null: false, default: "en"
      t.integer :total_marks, null: false
      t.jsonb :questions, null: false, default: []

      t.timestamps
    end

    add_index :question_papers, %i[school_id created_at]
    add_index :question_papers, %i[school_id teacher_id]
    add_index :question_papers, %i[school_id subject]
    add_index :question_papers, %i[school_id class_name]
  end
end
