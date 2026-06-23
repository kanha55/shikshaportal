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
    table = CSV.parse(@csv_io, headers: true, strip: true)
    headers = table.headers.compact.map { |h| h.to_s.strip.downcase.to_sym }

    missing = REQUIRED_HEADERS - headers
    raise ArgumentError, "Missing CSV columns: #{missing.join(', ')}" if missing.any?

    table
  end

  def process_row(row, line_number, seen_roll_numbers, result)
    data = normalize_row(row)
    roll_number = data[:roll_number]

    if data.values_at(:name, :roll_number, :class_name, :section, :parent_phone).any?(&:blank?)
      result.errors << error_entry(line_number, roll_number, "Missing required fields")
      return
    end

    if seen_roll_numbers.include?(roll_number)
      result.errors << error_entry(line_number, roll_number, "Duplicate roll number in CSV")
      return
    end

    seen_roll_numbers.add(roll_number)

    if @school.users.students.exists?(roll_number: roll_number)
      result.errors << error_entry(line_number, roll_number, "Roll number already exists")
      return
    end

    password = SecureRandom.alphanumeric(10)
    email = data[:email].presence || generated_email(roll_number)

    user = @school.users.build(
      name: data[:name],
      email: email,
      role: "student",
      roll_number: roll_number,
      class_name: data[:class_name],
      section: data[:section],
      parent_phone: data[:parent_phone],
      language_preference: @school.default_language,
      password: password,
      password_confirmation: password
    )

    if user.save
      StudentCredentialsMailer.login_details(user, password, @school).deliver_now
      result.created_count += 1
      result.emails_sent += 1
      result.created << student_json(user)
    else
      result.errors << error_entry(line_number, roll_number, user.errors.full_messages.join(", "))
    end
  end

  def normalize_row(row)
    ALL_HEADERS.index_with do |header|
      row[header.to_s]&.to_s&.strip
    end
  end

  def generated_email(roll_number)
    host = ENV.fetch("APP_HOST", "shikshaportal.in")
    "#{roll_number}.#{@school.subdomain}@students.#{host}".downcase
  end

  def error_entry(line, roll_number, message)
    { line: line, roll_number: roll_number, error: message }
  end

  def student_json(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      roll_number: user.roll_number,
      class_name: user.class_name,
      section: user.section,
      parent_phone: user.parent_phone
    }
  end
end
