FactoryBot.define do
  factory :county do
    country
    sequence(:name) { |n| "County #{n}" }
  end
end
