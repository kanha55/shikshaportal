# frozen_string_literal: true

require "test_helper"
require "rack/test"
require "json"

class I18nIntegrationTest < ActionDispatch::IntegrationTest
  def test_invalid_login_returns_hindi_error_by_default
    host! "greenvalley.localhost"

    post api_v1_user_session_path,
         params: { user: { email: "principal@greenvalley.test", password: "wrong" } },
         as: :json

    assert_response :unauthorized
    body = JSON.parse(response.body)
    assert_equal I18n.t("errors.invalid_credentials", locale: :hi), body["error"]
  end

  def test_invalid_login_returns_english_for_en_user
    host! "greenvalley.localhost"
    user = User.find_by!(email: "principal@greenvalley.test")
    user.update!(language_preference: "en")

    post api_v1_user_session_path,
         params: { user: { email: user.email, password: "wrong" } },
         as: :json

    assert_response :unauthorized
    body = JSON.parse(response.body)
    assert_equal I18n.t("errors.invalid_credentials", locale: :en), body["error"]
  end

  def test_unauthorized_returns_localized_error
    host! "greenvalley.localhost"

    get api_v1_auth_me_path, as: :json

    assert_response :unauthorized
    body = JSON.parse(response.body)
    assert_equal I18n.t("errors.unauthorized", locale: :hi), body["error"]
  end

  def test_password_reset_email_uses_user_locale
    host! "greenvalley.localhost"
    user = User.find_by!(email: "principal@greenvalley.test")
    user.update!(language_preference: "hi")

    assert_emails 1 do
      post api_v1_user_password_path,
           params: { user: { email: user.email } },
           as: :json
    end

    email = ActionMailer::Base.deliveries.last
    assert_includes email.subject, I18n.t("mailers.devise.reset_password.subject", locale: :hi)
    assert_includes email.body.to_s, I18n.t("mailers.devise.reset_password.intro", locale: :hi)
  end

  def test_student_credentials_email_in_hindi
    school = School.find_by!(subdomain: "greenvalley")
    user = User.new(
      name: "Test Student",
      email: "i18n-student@test.local",
      role: "student",
      school: school,
      roll_number: "I18N99",
      class_name: "10",
      section: "A",
      parent_phone: "9999999999",
      language_preference: "hi",
      password: "password123",
      password_confirmation: "password123"
    )
    user.save!

    I18n.with_locale("hi") do
      StudentCredentialsMailer.login_details(user, "temp123", school).deliver_now
    end

    email = ActionMailer::Base.deliveries.last
    assert_includes email.body.to_s, I18n.t("mailers.student_credentials.intro", locale: :hi, school: school.name)
  end
end
