FactoryBot.define do
  factory :address, class: "Address" do
    line1 { Faker::Address.street_address }
    city { Faker::Address.city }
    transient do
      country { create(:country) }
      county { create(:county, country: country) }
    end
    country_id { country&.id }
    county_id { county&.id }
    nearest_town { Faker::Address.city }
    postal_code { Faker::Address.zip_code }
    latitude { Faker::Address.latitude }
    longitude { Faker::Address.longitude }

    initialize_with { new(attributes) }
    skip_create
  end
end
