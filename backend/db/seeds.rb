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
  },
  {
    name: "IPS",
    subdomain: "ips",
    address: "Station Road, Indrapur, Madhya Pradesh",
    phone: "9876543212",
    principal_name: "Principal Meera Joshi",
    principal_email: "principal@ips.test",
    board: "cbse",
    default_language: "hi",
    about_us: "IPS School provides quality education with digital attendance, fee tracking, notices, and study materials for parents and students.",
    admin_password: "password123",
    notices: [
      { title: "IPS Digital Portal Launched", body: "Parents and students can now check notices, attendance, fee status, and study materials from the portal." },
      { title: "Monthly Fee Reminder", body: "Please submit the monthly fee before the 10th of this month. Online and office payments are both accepted." },
      { title: "Parent Teacher Meeting", body: "The next parent teacher meeting will be held this Saturday at 10 AM in the school auditorium." },
      { title: "Unit Test Schedule", body: "Classes 6 to 10 unit tests will start from next Monday. The detailed timetable is available at the school office." }
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

  admin_user = User.find_or_create_by!(email: attrs[:principal_email]) do |user|
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

  if attrs[:subdomain] == "ips"
    ips_students = [
      { name: "Aarav Sharma", email: "aarav@ips.test", roll_number: "101", class_name: "10", section: "A", parent_phone: "9876543220" },
      { name: "Ananya Singh", email: "ananya@ips.test", roll_number: "102", class_name: "10", section: "A", parent_phone: "9876543221" },
      { name: "Rohan Gupta", email: "rohan@ips.test", roll_number: "103", class_name: "10", section: "B", parent_phone: "9876543222" },
      { name: "Sneha Verma", email: "sneha@ips.test", roll_number: "104", class_name: "9", section: "A", parent_phone: "9876543223" },
      { name: "Aditya Yadav", email: "aditya@ips.test", roll_number: "105", class_name: "9", section: "B", parent_phone: "9876543224" },
      { name: "Priya Kumari", email: "priya@ips.test", roll_number: "106", class_name: "8", section: "A", parent_phone: "9876543225" },
      { name: "Karan Mehta", email: "karan@ips.test", roll_number: "107", class_name: "8", section: "B", parent_phone: "9876543226" },
      { name: "Neha Patel", email: "neha@ips.test", roll_number: "108", class_name: "7", section: "A", parent_phone: "9876543227" }
    ]

    created_ips_students = ips_students.map do |student_attrs|
      student = User.find_or_initialize_by(email: student_attrs[:email])
      student.assign_attributes(
        student_attrs.merge(
          role: "student",
          school: school,
          language_preference: school.default_language,
          password: "password123",
          password_confirmation: "password123"
        )
      )
      student.save!
      student
    end

    attendance_dates = (1..5).map { |days_ago| Time.zone.today - days_ago }
    attendance_dates.each_with_index do |date, date_index|
      created_ips_students.each_with_index do |student, student_index|
        status = ((student_index + date_index) % 5).zero? ? "absent" : "present"
        AttendanceRecord.find_or_initialize_by(school: school, student: student, date: date).tap do |record|
          record.assign_attributes(
            marked_by: admin_user,
            status: status,
            class_name: student.class_name,
            section: student.section
          )
          record.save!
        end
      end
    end

    fee_examples = [
      { student: created_ips_students[0], fee_type: "tuition", amount: 1500, status: "paid", paid_on: Time.zone.today - 2, receipt_number: "IPS-#{Time.zone.today.year}-001", notes: "July tuition fee" },
      { student: created_ips_students[1], fee_type: "transport", amount: 800, status: "paid", paid_on: Time.zone.today - 1, receipt_number: "IPS-#{Time.zone.today.year}-002", notes: "July transport fee" },
      { student: created_ips_students[2], fee_type: "tuition", amount: 1500, status: "pending", due_date: Time.zone.today + 7, notes: "July tuition fee pending" },
      { student: created_ips_students[3], fee_type: "exam", amount: 500, status: "pending", due_date: Time.zone.today + 10, notes: "Term exam fee pending" }
    ]

    fee_examples.each do |fee_attrs|
      lookup = if fee_attrs[:receipt_number].present?
                 { receipt_number: fee_attrs[:receipt_number] }
               else
                 { student: fee_attrs[:student], fee_type: fee_attrs[:fee_type], notes: fee_attrs[:notes] }
               end
      FeeRecord.find_or_initialize_by({ school: school }.merge(lookup)).tap do |fee|
        fee.assign_attributes(fee_attrs.merge(school: school, recorded_by: admin_user))
        fee.save!
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
