# frozen_string_literal: true

class AddInstitutionTypeToSchools < ActiveRecord::Migration[7.2]
  def change
    add_column :schools, :institution_type, :string, null: false, default: "school"
    add_index :schools, :institution_type
  end
end
