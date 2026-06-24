FactoryBot.define do
  factory :delivery_request do
    user { nil }
    driver { nil }
    pickup_address { nil }
    delivery_address { nil }
    package_description { "MyString" }
    package_weight { "9.99" }
    status { 1 }
  end
end
