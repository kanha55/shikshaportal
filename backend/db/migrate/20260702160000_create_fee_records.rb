# frozen_string_literal: true

class CreateFeeRecords < ActiveRecord::Migration[7.2]
  def change
    create_table :fee_records do |t|
      t.references :school, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.references :recorded_by, null: false, foreign_key: { to_table: :users }
      t.string :fee_type, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.date :due_date
      t.date :paid_on
      t.string :status, null: false, default: "pending"
      t.string :receipt_number
      t.text :notes

      t.timestamps
    end

    add_index :fee_records, %i[school_id student_id status]
    add_index :fee_records, %i[school_id receipt_number], unique: true, where: "receipt_number IS NOT NULL"
  end
end
