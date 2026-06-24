FactoryBot.define do
  factory :country do
    sequence(:name) { |n| "Country #{n}" }
    sequence(:code) { |n| "C#{n}" }

    trait :kenya do
      name { "Kenya" }
      code { "KE" }
    end
  end
end
