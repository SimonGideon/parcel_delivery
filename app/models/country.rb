class Country < ApplicationRecord
  has_many :counties, dependent: :restrict_with_error
  has_many :addresses, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
end
