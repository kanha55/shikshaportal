# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_07_13_100200) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "ai_generation_logs", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id", "created_at"], name: "index_ai_generation_logs_on_school_id_and_created_at"
    t.index ["school_id"], name: "index_ai_generation_logs_on_school_id"
  end

  create_table "attendance_records", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.bigint "student_id", null: false
    t.bigint "marked_by_id", null: false
    t.date "date", null: false
    t.string "status", null: false
    t.string "class_name", null: false
    t.string "section", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["marked_by_id"], name: "index_attendance_records_on_marked_by_id"
    t.index ["school_id", "date", "class_name", "section"], name: "idx_on_school_id_date_class_name_section_435c487ab0"
    t.index ["school_id", "student_id", "date"], name: "index_attendance_records_on_school_id_and_student_id_and_date", unique: true
    t.index ["school_id"], name: "index_attendance_records_on_school_id"
    t.index ["student_id"], name: "index_attendance_records_on_student_id"
  end

  create_table "fee_records", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.bigint "student_id", null: false
    t.bigint "recorded_by_id", null: false
    t.string "fee_type", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.date "due_date"
    t.date "paid_on"
    t.string "status", default: "pending", null: false
    t.string "receipt_number"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recorded_by_id"], name: "index_fee_records_on_recorded_by_id"
    t.index ["school_id", "receipt_number"], name: "index_fee_records_on_school_id_and_receipt_number", unique: true, where: "(receipt_number IS NOT NULL)"
    t.index ["school_id", "student_id", "status"], name: "index_fee_records_on_school_id_and_student_id_and_status"
    t.index ["school_id"], name: "index_fee_records_on_school_id"
    t.index ["student_id"], name: "index_fee_records_on_student_id"
  end

  create_table "gallery_photos", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.integer "position", null: false
    t.string "caption"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id", "position"], name: "index_gallery_photos_on_school_id_and_position", unique: true
    t.index ["school_id"], name: "index_gallery_photos_on_school_id"
  end

  create_table "notices", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.string "title", null: false
    t.text "body", null: false
    t.datetime "published_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id", "published_at"], name: "index_notices_on_school_id_and_published_at"
    t.index ["school_id"], name: "index_notices_on_school_id"
  end

  create_table "question_paper_generation_logs", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id", "created_at"], name: "idx_on_school_id_created_at_1a745a46c6"
    t.index ["school_id"], name: "index_question_paper_generation_logs_on_school_id"
    t.index ["user_id"], name: "index_question_paper_generation_logs_on_user_id"
  end

  create_table "question_papers", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.bigint "teacher_id", null: false
    t.string "title", null: false
    t.string "subject", null: false
    t.string "class_name", null: false
    t.string "topic", null: false
    t.string "difficulty", default: "mixed", null: false
    t.string "language", default: "en", null: false
    t.integer "total_marks", null: false
    t.jsonb "questions", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id", "class_name"], name: "index_question_papers_on_school_id_and_class_name"
    t.index ["school_id", "created_at"], name: "index_question_papers_on_school_id_and_created_at"
    t.index ["school_id", "subject"], name: "index_question_papers_on_school_id_and_subject"
    t.index ["school_id", "teacher_id"], name: "index_question_papers_on_school_id_and_teacher_id"
    t.index ["school_id"], name: "index_question_papers_on_school_id"
    t.index ["teacher_id"], name: "index_question_papers_on_teacher_id"
  end

  create_table "schools", force: :cascade do |t|
    t.string "name", null: false
    t.string "subdomain", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "address"
    t.string "phone"
    t.string "principal_name"
    t.string "principal_email"
    t.string "board", default: "cbse", null: false
    t.string "default_language", default: "hi", null: false
    t.text "about_us"
    t.string "institution_type", default: "school", null: false
    t.index ["institution_type"], name: "index_schools_on_institution_type"
    t.index ["subdomain"], name: "index_schools_on_subdomain", unique: true
  end

  create_table "study_materials", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.string "title", null: false
    t.string "class_name", null: false
    t.string "subject", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id", "class_name", "subject"], name: "index_study_materials_on_school_id_and_class_name_and_subject"
    t.index ["school_id"], name: "index_study_materials_on_school_id"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "school_id"
    t.string "name", null: false
    t.string "email", null: false
    t.string "encrypted_password"
    t.string "role", default: "student", null: false
    t.string "language_preference", default: "hi", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.string "jti", null: false
    t.string "roll_number"
    t.string "class_name"
    t.string "section"
    t.string "parent_phone"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["school_id", "roll_number"], name: "index_users_on_school_roll_number_for_students", unique: true, where: "((role)::text = 'student'::text)"
    t.index ["school_id"], name: "index_users_on_school_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "ai_generation_logs", "schools"
  add_foreign_key "attendance_records", "schools"
  add_foreign_key "attendance_records", "users", column: "marked_by_id"
  add_foreign_key "attendance_records", "users", column: "student_id"
  add_foreign_key "fee_records", "schools"
  add_foreign_key "fee_records", "users", column: "recorded_by_id"
  add_foreign_key "fee_records", "users", column: "student_id"
  add_foreign_key "gallery_photos", "schools"
  add_foreign_key "notices", "schools"
  add_foreign_key "question_paper_generation_logs", "schools"
  add_foreign_key "question_paper_generation_logs", "users"
  add_foreign_key "question_papers", "schools"
  add_foreign_key "question_papers", "users", column: "teacher_id"
  add_foreign_key "study_materials", "schools"
  add_foreign_key "users", "schools"
end
