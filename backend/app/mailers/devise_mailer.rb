# frozen_string_literal: true

class DeviseMailer < Devise::Mailer
  default template_path: "devise/mailer"

  def reset_password_instructions(record, token, opts = {})
    I18n.with_locale(record.language_preference || I18n.default_locale) do
      opts[:subject] ||= I18n.t("mailers.devise.reset_password.subject")
      super
    end
  end
end
