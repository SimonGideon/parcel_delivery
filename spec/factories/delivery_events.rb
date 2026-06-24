FactoryBot.define do
  factory :delivery_event do
    delivery_request
    event_type { :created }
    metadata { {} }
    occurred_at { Time.current }
  end
end
