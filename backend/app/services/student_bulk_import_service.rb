# frozen_string_literal: true

require "csv"
require "set"

class StudentBulkImportService
  REQUIRED_HEADERS = %i[name roll_number class_name section parent_phone].freeze
  OPTIONAL_HEADERS = %i[email].freeze
  ALL_HEADERS = (REQUIRED_HEADERS + OPTIONAL_HEADERS).freeze

  Result = Struct.new(:created_count, :emails_sent, :errors, :created, keyword_init: true)

  def self.call(school:, csv_io:)
    new(school, csv_io).call
  end

  def initialize(school, csv_io)
    @school = school
    @csv_io = csv_io
  end

  def call
    rows = parse_csv!
    result = Result.new(created_count: 0, emails_sent: 0, errors: [], created: [])
    seen_roll_numbers = Set.new

    rows.each_with_index do |row, index|
      line_number = index + 2
      process_row(row, line_number, seen_roll_numbers, result)
    end

    result
  end

  private

  def parse_csv!
    @table = CSV.parse(@csv_io, headers: true, strip: true)
    @header_map = build_header_map(@table.headers)

    missing = REQUIRED_HEADERS - @header_map.keys
    raise ArgumentError, I18n.t("services.import.missing_columns", columns: missing.join(", ")) if missing.any?

    @table
  end

  def build_header_map(headers)
    headers.compact.each_with_object({}) do |raw, map|
      key = normalize_header(raw)
      map[key] = raw unless map.key?(key)
    end
  end

  def normalize_header(raw)
    raw.to_s.strip.delete("\uFEFF").downcase.to_sym
  end

  def process_row(row, line_number, seen_roll_numbers, result)
    data = normalize_row(row)
    roll_number = data[:roll_number]

    if seen_roll_numbers.include?(roll_number)
      result.errors << error_entry(line_number, roll_number, I18n.t("services.import.duplicate_roll"))
      return
    end

    seen_roll_numbers.add(roll_number)

    create_result = StudentCreateService.call(school: @school, attributes: data)
    if create_result.success
      result.created_count += 1
      result.emails_sent += 1
      result.created << create_result.student
    else
      result.errors << error_entry(line_number, roll_number, create_result.errors.join(", "))
    end
  end

  def normalize_row(row)
    ALL_HEADERS.index_with do |header|
      col = @header_map[header]
      col ? row[col]&.to_s&.strip : nil
    end
  end

  def error_entry(line, roll_number, message)
    { line: line, roll_number: roll_number, error: message }
  end
end
