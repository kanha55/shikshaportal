# frozen_string_literal: true

class SchoolRegistrationMailer < ApplicationMailer
  def welcome(admin, temporary_password, school)
    @admin = admin
    @temporary_password = temporary_password
    @school = school
    @login_url = "https://#{school.subdomain}.#{ENV.fetch('APP_HOST', 'shikshaportal.in')}/login"

    mail(
      to: admin.email,
      subject: "Welcome to Shiksha Portal — #{school.name}"
    )
  end
end
