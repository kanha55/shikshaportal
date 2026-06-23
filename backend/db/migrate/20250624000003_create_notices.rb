# frozen_string_literal: true

class CreateNotices < ActiveRecord::Migration[7.2]
  def change
    create_table :notices do |t|
      t.references :school, null: false, foreign_key: true
      t.string :title, null: false
      t.text :body, null: false
      t.datetime :published_at, null: false

      t.timestamps
    end

    add_index :notices, [:school_id, :published_at]
  end
end
