FactoryBot.define do
  factory :driver do
    name { "MyString" }
    email { "MyString" }
    password_digest { "MyString" }
    phone { "MyString" }
    status { 1 }
  end
end
