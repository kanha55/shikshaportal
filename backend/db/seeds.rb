# frozen_string_literal: true

# Demo tenants for multi-tenancy testing (T02 acceptance criteria)
[
  {
    name: "Green Valley School",
    subdomain: "greenvalley",
    address: "Village Road, Green Valley",
    phone: "9876543210",
    principal_name: "Principal Sharma",
    principal_email: "principal@greenvalley.test",
    board: "cbse",
    default_language: "hi"
  },
  {
    name: "Sunrise Public School",
    subdomain: "sunrise",
    address: "Main Street, Sunrise",
    phone: "9876543211",
    principal_name: "Principal Patel",
    principal_email: "principal@sunrise.test",
    board: "state",
    default_language: "hi"
  }
].each do |attrs|
  School.find_or_create_by!(subdomain: attrs[:subdomain]) do |school|
    school.assign_attributes(attrs)
  end
end

puts "Seeded #{School.count} schools: #{School.pluck(:subdomain).join(', ')}"
