# frozen_string_literal: true

# Demo tenants for multi-tenancy testing (T02 acceptance criteria)
[
  { name: "Green Valley School", subdomain: "greenvalley" },
  { name: "Sunrise Public School", subdomain: "sunrise" }
].each do |attrs|
  School.find_or_create_by!(subdomain: attrs[:subdomain]) do |school|
    school.name = attrs[:name]
  end
end

puts "Seeded #{School.count} schools: #{School.pluck(:subdomain).join(', ')}"
