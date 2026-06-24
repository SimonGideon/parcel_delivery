# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

KENYA_COUNTIES = %w[
  Mombasa Kwale Kilifi Tana\ River Lamu Taita/Taveta Garissa Wajir Mandera
  Marsabit Isiolo Meru Tharaka-Nithi Embu Kitui Machakos Makueni Nyandarua
  Nyeri Kirinyaga Murang'a Kiambu Turkana West\ Pokot Samburu Trans-Nzoia
  Uasin\ Gishu Elgeyo-Marakwet Nandi Baringo Laikipia Nakuru Narok Kajiado
  Kericho Bomet Kakamega Vihiga Bungoma Busia Siaya Kisumu Homa\ Bay Migori
  Kisii Nyamira Nairobi
].freeze

kenya = Country.find_or_create_by!(name: "Kenya") { |country| country.code = "KE" }

KENYA_COUNTIES.each do |county_name|
  County.find_or_create_by!(name: county_name, country: kenya)
end

puts "Seeded #{kenya.name} with #{kenya.counties.count} counties."
