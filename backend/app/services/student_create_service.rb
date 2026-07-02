# frozen_string_literal: true

class StudentCreateService
  Result = Struct.new(:success, :student, :errors, keyword_init: true)

  PERMITTED = %i[name roll_number class_name section parent_phone email].freeze

  def self.call(school:, attributes:)
    new(school, attributes).call
  end

  def initialize(school, attributes)
    @school = school
    @attributes = attributes.to_h.symbolize_keys.slice(*PERMITTED).transform_values { |v| v.to_s.strip }
  end

  def call
    roll_number = @attributes[:roll_number]

    if @attributes.values_at(:name, :roll_number, :class_name, :section, :parent_phone).any?(&:blank?)
      return failure([I18n.t("services.students.missing_fields")])
    end

    if @school.users.students.exists?(roll_number: roll_number)
      return failure([I18n.t("services.students.roll_exists")])
    end

    password = SecureRandom.alphanumeric(10)
    email = @attributes[:email].presence || generated_email(roll_number)

    user = @school.users.build(
      name: @attributes[:name],
      email: email,
      role: "student",
      roll_number: roll_number,
      class_name: @attributes[:class_name],
      section: @attributes[:section],
      parent_phone: @attributes[:parent_phone],
      language_preference: @school.default_language,
      password: password,
      password_confirmation: password
    )

    if user.save
      I18n.with_locale(user.language_preference) do
        StudentCredentialsMailer.login_details(user, password, @school).deliver_now
      end
      Result.new(success: true, student: student_json(user), errors: [])
    else
      failure(user.errors.full_messages)
    end
  end

  private

  def failure(errors)
    Result.new(success: false, student: nil, errors: errors)
  end

  def generated_email(roll_number)
    host = ENV.fetch("APP_HOST", "shikshaportal.in")
    "#{roll_number}.#{@school.subdomain}@students.#{host}".downcase
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
