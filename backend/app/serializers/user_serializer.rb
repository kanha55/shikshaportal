# frozen_string_literal: true

class UserSerializer
  def self.as_json(user)
    payload = {
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      language_preference: user.language_preference,
      school_id: user.school_id,
      school_subdomain: user.school&.subdomain
    }

    if user.student?
      payload.merge!(
        roll_number: user.roll_number,
        class_name: user.class_name,
        section: user.section
      )
    end

    payload
  end
end
