# frozen_string_literal: true

class AddDeviseToUsers < ActiveRecord::Migration[7.2]
  class MigrationUser < ApplicationRecord
    self.table_name = "users"
  end

  def up
    rename_column :users, :password_digest, :encrypted_password
    change_column_null :users, :encrypted_password, true

    add_column :users, :reset_password_token, :string
    add_column :users, :reset_password_sent_at, :datetime
    add_column :users, :jti, :string

    add_index :users, :reset_password_token, unique: true
    add_index :users, :jti, unique: true

    MigrationUser.find_each do |user|
      user.update_column(:jti, SecureRandom.uuid)
    end

    change_column_null :users, :jti, false
  end

  def down
    change_column_null :users, :jti, true
    remove_index :users, :jti
    remove_index :users, :reset_password_token
    remove_column :users, :jti
    remove_column :users, :reset_password_sent_at
    remove_column :users, :reset_password_token
    rename_column :users, :encrypted_password, :password_digest
    change_column_null :users, :password_digest, false
  end
end
