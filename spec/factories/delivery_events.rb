FactoryBot.define do
  factory :delivery_event do
    delivery_request { nil }
    event_type { 1 }
    metadata { "" }
    occurred_at { "2026-06-24 14:24:14" }
  end
end
