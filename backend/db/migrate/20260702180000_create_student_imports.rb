# frozen_string_literal: true

class CreateStudentImports < ActiveRecord::Migration[7.2]
  def change
    create_table :student_imports do |t|
      t.references :school, null: false, foreign_key: true
      t.string :status, null: false, default: "queued"
      t.jsonb :result, null: false, default: {}
      t.text :error_message

      t.timestamps
    end

    add_index :student_imports, %i[school_id status]
  end
end
