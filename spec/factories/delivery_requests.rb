FactoryBot.define do
  factory :delivery_request do
    user
    pickup_address { association :address }
    delivery_address { association :address }
    package_description { Faker::Commerce.product_name }
    package_weight { Faker::Number.decimal(l_digits: 1, r_digits: 2) }
    status { :pending }

    trait :assigned do
      driver
      status { :assigned }
    end

    trait :accepted do
      driver
      status { :accepted }
    end
  end
end
