# frozen_string_literal: true

class AddDetailsToSchools < ActiveRecord::Migration[7.2]
  def change
    change_table :schools, bulk: true do |t|
      t.string :address
      t.string :phone
      t.string :principal_name
      t.string :principal_email
      t.string :board, default: "cbse", null: false
      t.string :default_language, default: "hi", null: false
    end
  end
end
