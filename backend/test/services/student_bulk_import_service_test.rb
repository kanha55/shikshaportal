# frozen_string_literal: true

require "test_helper"

class StudentBulkImportServiceTest < ActiveSupport::TestCase
  setup do
    @school = School.find_by!(subdomain: "greenvalley")
  end

  test "accepts title-case csv headers" do
    csv = <<~CSV
      Name,Roll_Number,Class_Name,Section,Parent_Phone
      Header Test Student,8801,10,A,9876543210
    CSV

    result = StudentBulkImportService.call(school: @school, csv_io: csv)

    assert_equal 1, result.created_count
    assert_empty result.errors
    assert User.students.exists?(roll_number: "8801", school: @school)
  end

  test "accepts utf-8 bom on first header" do
    csv = "\uFEFFname,roll_number,class_name,section,parent_phone\nBOM Student,8802,10,A,9876543210\n"

    result = StudentBulkImportService.call(school: @school, csv_io: csv)

    assert_equal 1, result.created_count
    assert_empty result.errors
  end
end
