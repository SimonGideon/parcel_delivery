FactoryBot.define do
  factory :driver do
    name { Faker::Name.name }
    sequence(:email) { |n| "driver#{n}@example.com" }
    password { "password123" }
    phone { Faker::PhoneNumber.phone_number }
    status { :available }

    trait :with_location do
      after(:create) do |driver|
        create(:driver_location, driver: driver)
      end
    end
  end
end
