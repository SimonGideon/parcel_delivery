FactoryBot.define do
  factory :address do
    line1 { "MyString" }
    line2 { "MyString" }
    city { "MyString" }
    state { "MyString" }
    postal_code { "MyString" }
    country { "MyString" }
    latitude { "9.99" }
    longitude { "9.99" }
  end
end
