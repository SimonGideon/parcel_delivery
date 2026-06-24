FactoryBot.define do
  factory :address do
    line1 { Faker::Address.street_address }
    city { Faker::Address.city }
    country
    county { association :county, country: country }
    nearest_town { Faker::Address.city }
    postal_code { Faker::Address.zip_code }
    latitude { Faker::Address.latitude }
    longitude { Faker::Address.longitude }
  end
end
