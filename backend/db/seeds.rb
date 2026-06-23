# frozen_string_literal: true

# Demo tenants for multi-tenancy testing (T02)
schools_data = [
  {
    name: "Green Valley School",
    subdomain: "greenvalley",
    address: "Village Road, Green Valley",
    phone: "9876543210",
    principal_name: "Principal Sharma",
    principal_email: "principal@greenvalley.test",
    board: "cbse",
    default_language: "hi",
    admin_password: "password123"
  },
  {
    name: "Sunrise Public School",
    subdomain: "sunrise",
    address: "Main Street, Sunrise",
    phone: "9876543211",
    principal_name: "Principal Patel",
    principal_email: "principal@sunrise.test",
    board: "state",
    default_language: "hi",
    admin_password: "password123"
  }
]

schools_data.each do |attrs|
  password = attrs.delete(:admin_password)
  school = School.find_or_create_by!(subdomain: attrs[:subdomain]) do |s|
    s.assign_attributes(attrs)
  end

  User.find_or_create_by!(email: attrs[:principal_email]) do |user|
    user.name = attrs[:principal_name]
    user.role = "school_admin"
    user.school = school
    user.language_preference = school.default_language
    user.password = password
    user.password_confirmation = password
  end
end

User.find_or_create_by!(email: "super@shikshaportal.test") do |user|
  user.name = "Super Admin"
  user.role = "super_admin"
  user.language_preference = "en"
  user.password = "password123"
  user.password_confirmation = "password123"
end

puts "Seeded #{School.count} schools, #{User.count} users"
