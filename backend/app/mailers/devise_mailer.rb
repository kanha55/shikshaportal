# frozen_string_literal: true

class DeviseMailer < Devise::Mailer
  default template_path: "devise/mailer"
end
