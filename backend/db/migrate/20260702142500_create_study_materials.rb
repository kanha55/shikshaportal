# frozen_string_literal: true

class CreateStudyMaterials < ActiveRecord::Migration[7.2]
  def change
    create_table :study_materials do |t|
      t.references :school, null: false, foreign_key: true
      t.string :title, null: false
      t.string :class_name, null: false
      t.string :subject, null: false

      t.timestamps
    end

    add_index :study_materials, %i[school_id class_name subject]
  end
end
