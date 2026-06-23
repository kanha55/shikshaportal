# frozen_string_literal: true

class CreateSchools < ActiveRecord::Migration[7.2]
  def change
    create_table :schools do |t|
      t.string :name, null: false
      t.string :subdomain, null: false

      t.timestamps
    end

    add_index :schools, :subdomain, unique: true
  end
end
