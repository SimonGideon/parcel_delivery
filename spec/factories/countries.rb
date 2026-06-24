FactoryBot.define do
  factory :country do
    sequence(:name) { |n| "Country #{n}" }
    sequence(:iso2) { |n| "C#{n % 10}" }
    sequence(:iso3) { |n| "C%02d" % (n % 100) }
    region { "Africa" }

    trait :kenya do
      name { "Kenya" }
      iso2 { "KE" }
      iso3 { "KEN" }
      phonecode { "+254" }
      capital { "Nairobi" }
      currency { "KES" }
      currency_symbol { "KSh" }
      region { "Africa" }
      latitude { 1.0 }
      longitude { 38.0 }
    end
  end
end
