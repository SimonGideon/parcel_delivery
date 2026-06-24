FactoryBot.define do
  factory :driver_location do
    driver
    latitude { Faker::Address.latitude }
    longitude { Faker::Address.longitude }
    recorded_at { Time.current }
  end
end
