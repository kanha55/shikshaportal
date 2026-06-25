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
    about_us: "Green Valley School serves rural communities with quality education since 1998.",
    admin_password: "password123",
    notices: [
      { title: "Summer Holiday", body: "School closed from 1 May to 15 June." },
      { title: "Parent Meeting", body: "Annual parent-teacher meeting on Saturday at 10 AM." }
    ]
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
    about_us: "Sunrise Public School — learning with values.",
    admin_password: "password123",
    notices: [
      { title: "Exam Schedule", body: "Half-yearly exams begin next Monday." }
    ]
  }
]

schools_data.each do |attrs|
  notices = attrs.delete(:notices)
  password = attrs.delete(:admin_password)
  school = School.find_or_create_by!(subdomain: attrs[:subdomain]) do |s|
    s.assign_attributes(attrs)
  end
  school.update!(attrs)

  User.find_or_create_by!(email: attrs[:principal_email]) do |user|
    user.name = attrs[:principal_name]
    user.role = "school_admin"
    user.school = school
    user.language_preference = school.default_language
    user.password = password
    user.password_confirmation = password
  end

  ActsAsTenant.with_tenant(school) do
    notices.each do |notice_attrs|
      Notice.find_or_create_by!(title: notice_attrs[:title]) do |n|
        n.body = notice_attrs[:body]
        n.published_at = Time.current
        n.school = school
      end
    end
  end

  next unless attrs[:subdomain] == "greenvalley"

  demo_student = User.find_or_initialize_by(email: "rahul@greenvalley.test")
  demo_student.assign_attributes(
    name: "Rahul Kumar",
    role: "student",
    school: school,
    roll_number: "101",
    class_name: "10",
    section: "A",
    parent_phone: "9876543210",
    language_preference: school.default_language,
    password: "password123",
    password_confirmation: "password123"
  )
  demo_student.save!
end

User.find_or_create_by!(email: "super@shikshaportal.test") do |user|
  user.name = "Super Admin"
  user.role = "super_admin"
  user.language_preference = "en"
  user.password = "password123"
  user.password_confirmation = "password123"
end

puts "Seeded #{School.count} schools, #{User.count} users, #{Notice.count} notices"
