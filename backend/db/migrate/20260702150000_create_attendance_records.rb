# frozen_string_literal: true

class CreateAttendanceRecords < ActiveRecord::Migration[7.2]
  def change
    create_table :attendance_records do |t|
      t.references :school, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.references :marked_by, null: false, foreign_key: { to_table: :users }
      t.date :date, null: false
      t.string :status, null: false
      t.string :class_name, null: false
      t.string :section, null: false

      t.timestamps
    end

    add_index :attendance_records, %i[school_id student_id date], unique: true
    add_index :attendance_records, %i[school_id date class_name section]
  end
end
