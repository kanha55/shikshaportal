# frozen_string_literal: true

class StudentCredentialsMailer < ApplicationMailer
  def login_details(student, temporary_password, school)
    @student = student
    @temporary_password = temporary_password
    @school = school
    @login_url = "https://#{school.subdomain}.#{ENV.fetch('APP_HOST', 'campixo.com')}/login"

    mail(
      to: student.email,
      subject: I18n.t("mailers.student_credentials.subject", school: school.name)
    )
  end
end
