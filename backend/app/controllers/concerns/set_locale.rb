# frozen_string_literal: true

module SetLocale
  extend ActiveSupport::Concern

  included do
    before_action :set_locale
  end

  private

  def set_locale
    I18n.locale = resolve_locale
  end

  def resolve_locale
    locale = locale_from_user ||
             locale_from_email_param ||
             locale_from_header ||
             locale_from_tenant ||
             I18n.default_locale

    locale.to_s.in?(School::LANGUAGES) ? locale.to_s.to_sym : I18n.default_locale
  end

  def locale_from_user
    return unless respond_to?(:current_user, true)

    current_user&.language_preference
  end

  def locale_from_email_param
    email = params.dig(:user, :email)&.downcase
    return if email.blank?

    User.find_by(email: email)&.language_preference
  end

  def locale_from_header
    accept = request.headers["Accept-Language"].to_s.downcase
    return "hi" if accept.match?(/\bhi\b/)
    return "en" if accept.match?(/\ben\b/)

    nil
  end

  def locale_from_tenant
    ActsAsTenant.current_tenant&.default_language
  end
end
