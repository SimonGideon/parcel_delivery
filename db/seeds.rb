# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Subset of fields from the dr5hn/countries-states-cities-database reference
# dataset -- enough for address/phone formatting without the columns nothing
# here uses yet (timezones, translations, population, etc).
EAST_AFRICAN_COUNTRIES = [
  { name: "Kenya", iso2: "KE", iso3: "KEN", phonecode: "254", capital: "Nairobi",
    currency: "KES", currency_symbol: "KSh", region: "Africa", latitude: 1.0, longitude: 38.0 },
  { name: "Uganda", iso2: "UG", iso3: "UGA", phonecode: "256", capital: "Kampala",
    currency: "UGX", currency_symbol: "USh", region: "Africa", latitude: 1.0, longitude: 32.0 },
  { name: "Tanzania", iso2: "TZ", iso3: "TZA", phonecode: "255", capital: "Dodoma",
    currency: "TZS", currency_symbol: "TSh", region: "Africa", latitude: -6.0, longitude: 35.0 },
  { name: "Rwanda", iso2: "RW", iso3: "RWA", phonecode: "250", capital: "Kigali",
    currency: "RWF", currency_symbol: "FRw", region: "Africa", latitude: -2.0, longitude: 30.0 },
  { name: "Burundi", iso2: "BI", iso3: "BDI", phonecode: "257", capital: "Bujumbura",
    currency: "BIF", currency_symbol: "FBu", region: "Africa", latitude: -3.5, longitude: 30.0 },
  { name: "South Sudan", iso2: "SS", iso3: "SSD", phonecode: "211", capital: "Juba",
    currency: "SSP", currency_symbol: "£", region: "Africa", latitude: 7.0, longitude: 30.0 },
  { name: "Ethiopia", iso2: "ET", iso3: "ETH", phonecode: "251", capital: "Addis Ababa",
    currency: "ETB", currency_symbol: "Br", region: "Africa", latitude: 8.0, longitude: 38.0 },
  { name: "Somalia", iso2: "SO", iso3: "SOM", phonecode: "252", capital: "Mogadishu",
    currency: "SOS", currency_symbol: "Sh.So.", region: "Africa", latitude: 10.0, longitude: 49.0 }
].freeze

KENYA_COUNTIES = %w[
  Mombasa Kwale Kilifi Tana\ River Lamu Taita/Taveta Garissa Wajir Mandera
  Marsabit Isiolo Meru Tharaka-Nithi Embu Kitui Machakos Makueni Nyandarua
  Nyeri Kirinyaga Murang'a Kiambu Turkana West\ Pokot Samburu Trans-Nzoia
  Uasin\ Gishu Elgeyo-Marakwet Nandi Baringo Laikipia Nakuru Narok Kajiado
  Kericho Bomet Kakamega Vihiga Bungoma Busia Siaya Kisumu Homa\ Bay Migori
  Kisii Nyamira Nairobi
].freeze

EAST_AFRICAN_COUNTRIES.each do |attrs|
  country = Country.find_or_initialize_by(name: attrs[:name])
  country.update!(attrs)
  puts "Seeded country: #{country.name} (#{country.iso2})"
end

# Counties (Kenya's top-level administrative unit) are only modeled for Kenya --
# neighboring countries use different terms (Uganda's districts, Tanzania's
# regions, etc.) which aren't represented by this table yet.
kenya = Country.find_by!(name: "Kenya")
KENYA_COUNTIES.each do |county_name|
  County.find_or_create_by!(name: county_name, country: kenya)
end

puts "Seeded #{kenya.name} with #{kenya.counties.count} counties."
