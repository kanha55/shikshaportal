# frozen_string_literal: true

class AddStudentProfileToUsers < ActiveRecord::Migration[7.2]
  def change
    change_table :users, bulk: true do |t|
      t.string :roll_number
      t.string :class_name
      t.string :section
      t.string :parent_phone
    end

    add_index :users, %i[school_id roll_number],
              unique: true,
              where: "role = 'student'",
              name: "index_users_on_school_roll_number_for_students"
  end
end
