# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.references :school, foreign_key: true
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :role, null: false, default: "student"
      t.string :language_preference, default: "hi", null: false

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :role
  end
end
