# frozen_string_literal: true

class StudentCredentialsMailer < ApplicationMailer
  def login_details(student, temporary_password, school)
    @student = student
    @temporary_password = temporary_password
    @school = school
    @login_url = "https://#{school.subdomain}.#{ENV.fetch('APP_HOST', 'shikshaportal.in')}/login"

    mail(
      to: student.email,
      subject: "Your #{school.name} student login"
    )
  end
end
