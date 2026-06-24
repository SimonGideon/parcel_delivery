# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

EAST_AFRICAN_COUNTRIES = {
  "Kenya" => "KE",
  "Uganda" => "UG",
  "Tanzania" => "TZ",
  "Rwanda" => "RW",
  "Burundi" => "BI",
  "South Sudan" => "SS",
  "Ethiopia" => "ET",
  "Somalia" => "SO"
}.freeze

KENYA_COUNTIES = %w[
  Mombasa Kwale Kilifi Tana\ River Lamu Taita/Taveta Garissa Wajir Mandera
  Marsabit Isiolo Meru Tharaka-Nithi Embu Kitui Machakos Makueni Nyandarua
  Nyeri Kirinyaga Murang'a Kiambu Turkana West\ Pokot Samburu Trans-Nzoia
  Uasin\ Gishu Elgeyo-Marakwet Nandi Baringo Laikipia Nakuru Narok Kajiado
  Kericho Bomet Kakamega Vihiga Bungoma Busia Siaya Kisumu Homa\ Bay Migori
  Kisii Nyamira Nairobi
].freeze

EAST_AFRICAN_COUNTRIES.each do |name, code|
  country = Country.find_or_create_by!(name: name) { |c| c.code = code }
  puts "Seeded country: #{country.name} (#{country.code})"
end

# Counties (Kenya's top-level administrative unit) are only modeled for Kenya --
# neighboring countries use different terms (Uganda's districts, Tanzania's
# regions, etc.) which aren't represented by this table yet.
kenya = Country.find_by!(name: "Kenya")
KENYA_COUNTIES.each do |county_name|
  County.find_or_create_by!(name: county_name, country: kenya)
end

puts "Seeded #{kenya.name} with #{kenya.counties.count} counties."
