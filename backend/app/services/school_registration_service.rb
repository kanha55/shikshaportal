# frozen_string_literal: true

class SchoolRegistrationService
  Result = Struct.new(:school, :admin_user, :temporary_password, keyword_init: true)

  def self.call(params)
    new(params).call
  end

  def initialize(params)
    @params = params.to_h.symbolize_keys
  end

  def call
    temporary_password = SecureRandom.alphanumeric(12)

    ActiveRecord::Base.transaction do
      school = School.create!(school_attributes)
      admin = school.users.create!(
        name: @params.fetch(:principal_name),
        email: @params.fetch(:principal_email),
        role: "school_admin",
        language_preference: school.default_language,
        password: temporary_password,
        password_confirmation: temporary_password
      )

      I18n.with_locale(admin.language_preference) do
        SchoolRegistrationMailer.welcome(admin, temporary_password, school).deliver_later
      end

      Result.new(school: school, admin_user: admin, temporary_password: temporary_password)
    end
  end

  private

  def school_attributes
    {
      name: @params.fetch(:name),
      subdomain: @params.fetch(:subdomain),
      address: @params[:address],
      phone: @params[:phone],
      principal_name: @params[:principal_name],
      principal_email: @params[:principal_email],
      board: @params.fetch(:board, "cbse"),
      default_language: @params.fetch(:default_language, "hi")
    }
  end
end
